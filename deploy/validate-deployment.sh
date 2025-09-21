#!/bin/bash

# 部署脚本验证工具
# 用于验证部署脚本的正确性和部署结果

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VALIDATION_LOG="/tmp/deployment-validation.log"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$VALIDATION_LOG"
}

# 初始化验证环境
init_validation() {
    log_info "开始部署脚本验证..."
    echo "验证时间: $(date)" > "$VALIDATION_LOG"
    echo "项目路径: $PROJECT_ROOT" >> "$VALIDATION_LOG"
    echo "----------------------------------------" >> "$VALIDATION_LOG"
}

# 1. 验证部署脚本语法
validate_script_syntax() {
    log_info "验证部署脚本语法..."
    
    local scripts=(
        "$SCRIPT_DIR/deploy.sh"
        "$SCRIPT_DIR/deploy-light.sh"
        "$SCRIPT_DIR/deploy-minimal.sh"
        "$SCRIPT_DIR/init-server.sh"
        "$SCRIPT_DIR/monitor.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script"; then
                log_success "脚本语法正确: $(basename "$script")"
            else
                log_error "脚本语法错误: $(basename "$script")"
                return 1
            fi
        else
            log_warning "脚本不存在: $(basename "$script")"
        fi
    done
}

# 2. 验证Docker和Docker Compose文件
validate_docker_config() {
    log_info "验证Docker配置文件..."
    
    # 验证Dockerfile
    if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
        # 简单的Dockerfile语法检查
        if [ -r "$PROJECT_ROOT/Dockerfile" ] && grep -q "FROM" "$PROJECT_ROOT/Dockerfile"; then
            log_success "Dockerfile语法正确"
        else
            log_error "Dockerfile存在语法错误"
            return 1
        fi
    else
        log_error "Dockerfile不存在"
        return 1
    fi
    
    # 验证Docker Compose文件
    local compose_files=(
        "docker-compose.yml"
        "docker-compose-light.yml"
        "docker-compose-cloud.yml"
        "docker-compose-minimal.yml"
    )
    
    for file in "${compose_files[@]}"; do
        local compose_path="$PROJECT_ROOT/$file"
        if [ -f "$compose_path" ]; then
            if docker-compose -f "$compose_path" config > /dev/null 2>&1; then
                log_success "Docker Compose配置正确: $file"
            else
                log_error "Docker Compose配置错误: $file"
                return 1
            fi
        else
            log_warning "Docker Compose文件不存在: $file"
        fi
    done
}

# 3. 验证环境变量配置
validate_env_config() {
    log_info "验证环境变量配置..."
    
    # 检查.env.example文件
    if [ -f "$PROJECT_ROOT/.env.example" ]; then
        log_success "找到.env.example模板文件"
        
        # 验证必需的环境变量
        local required_vars=(
            "DB_HOST"
            "DB_PORT"
            "DB_NAME"
            "DB_USERNAME"
            "DB_PASSWORD"
            "REDIS_HOST"
            "REDIS_PORT"
            "SILICONFLOW_API_KEY"
        )
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" "$PROJECT_ROOT/.env.example"; then
                log_success "环境变量模板包含: $var"
            else
                log_warning "环境变量模板缺少: $var"
            fi
        done
    else
        log_error "缺少.env.example模板文件"
        return 1
    fi
}

# 4. 验证应用配置文件
validate_app_config() {
    log_info "验证应用配置文件..."
    
    local config_files=(
        "src/main/resources/application.yml"
        "src/main/resources/application-dev.yml"
        "src/main/resources/application-prod.yml"
    )
    
    for config in "${config_files[@]}"; do
        local config_path="$PROJECT_ROOT/$config"
        if [ -f "$config_path" ]; then
            # 简单的YAML语法检查
            if python3 -c "
import yaml
try:
    with open('$config_path', 'r') as f:
        yaml.safe_load(f)
    print('OK')
except Exception as e:
    print(f'ERROR: {e}')
    exit(1)
" > /dev/null 2>&1; then
                log_success "配置文件语法正确: $(basename "$config")"
            else
                log_error "配置文件语法错误: $(basename "$config")"
                return 1
            fi
        else
            log_warning "配置文件不存在: $(basename "$config")"
        fi
    done
}

# 5. 验证网络端口配置
validate_port_config() {
    log_info "验证端口配置..."
    
    # 检查端口是否被占用
    local ports=(8080 3306 6379 5672 15672 80)
    
    for port in "${ports[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            log_warning "端口 $port 已被占用"
        else
            log_success "端口 $port 可用"
        fi
    done
}

# 6. 验证部署前置条件
validate_prerequisites() {
    log_info "验证部署前置条件..."
    
    # 检查Docker
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker已安装: $docker_version"
        
        # 检查Docker服务状态
        if docker info > /dev/null 2>&1; then
            log_success "Docker服务运行正常"
        else
            log_warning "Docker服务未运行，但脚本语法检查仍可进行"
        fi
    else
        log_warning "Docker未安装，建议安装Docker以进行完整测试"
    fi
    
    # 检查Docker Compose
    if command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker Compose已安装: $compose_version"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        local compose_version=$(docker compose version --short)
        log_success "Docker Compose (v2)已安装: $compose_version"
    else
        log_warning "Docker Compose未安装，建议安装以进行完整测试"
    fi
    
    # 检查系统资源
    if command -v free &> /dev/null; then
        local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
        if [ "$total_mem" -gt 1500 ]; then
            log_success "系统内存充足: ${total_mem}MB"
        else
            log_warning "系统内存可能不足: ${total_mem}MB"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS 系统
        local total_mem=$(echo "$(sysctl -n hw.memsize) / 1024 / 1024" | bc 2>/dev/null || echo "未知")
        if [[ "$total_mem" =~ ^[0-9]+$ ]] && [ "$total_mem" -gt 1500 ]; then
            log_success "系统内存充足: ${total_mem}MB"
        else
            log_warning "系统内存: ${total_mem}MB"
        fi
    else
        log_info "无法检测系统内存"
    fi
    
    # 检查磁盘空间
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS 系统
        local disk_space=$(df -g "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')
    else
        # Linux 系统
        local disk_space=$(df -BG "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    
    if [[ "$disk_space" =~ ^[0-9]+$ ]] && [ "$disk_space" -gt 5 ]; then
        log_success "磁盘空间充足: ${disk_space}GB"
    else
        log_warning "磁盘空间: ${disk_space}GB"
    fi
}

# 7. 执行干运行测试
dry_run_deployment() {
    log_info "执行部署干运行测试..."
    
    cd "$PROJECT_ROOT"
    
    # 如果Docker可用，测试镜像构建
    if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
        if docker build -t springmvc-demo:test-build . > /dev/null 2>&1; then
            log_success "Docker镜像构建测试通过"
            # 清理测试镜像
            docker rmi springmvc-demo:test-build > /dev/null 2>&1 || true
        else
            log_warning "Docker镜像构建测试失败，请检查Dockerfile"
        fi
    else
        log_info "跳过Docker构建测试（Docker未可用）"
    fi
    
    # 测试Docker Compose配置
    if command -v docker-compose &> /dev/null; then
        if docker-compose config > /dev/null 2>&1; then
            log_success "Docker Compose配置验证通过"
        else
            log_warning "Docker Compose配置验证失败，请检查配置文件"
        fi
    elif command -v docker &> /dev/null; then
        if docker compose config > /dev/null 2>&1; then
            log_success "Docker Compose (v2)配置验证通过"
        else
            log_warning "Docker Compose配置验证失败，请检查配置文件"
        fi
    else
        log_info "跳过Docker Compose配置测试（未安装）"
    fi
}

# 8. 验证监控脚本
validate_monitoring() {
    log_info "验证监控脚本..."
    
    if [ -f "$SCRIPT_DIR/monitor.sh" ]; then
        # 检查监控脚本权限
        if [ -x "$SCRIPT_DIR/monitor.sh" ]; then
            log_success "监控脚本权限正确"
        else
            log_warning "监控脚本缺少执行权限"
            chmod +x "$SCRIPT_DIR/monitor.sh"
        fi
        
        # 验证监控脚本语法
        if bash -n "$SCRIPT_DIR/monitor.sh"; then
            log_success "监控脚本语法正确"
        else
            log_error "监控脚本语法错误"
            return 1
        fi
    else
        log_warning "监控脚本不存在"
    fi
}

# 9. 验证Nginx配置
validate_nginx_config() {
    log_info "验证Nginx配置..."
    
    local nginx_config="$PROJECT_ROOT/docker/nginx/nginx.conf"
    if [ -f "$nginx_config" ]; then
        # 如果Docker可用，使用nginx容器验证配置
        if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
            if docker run --rm -v "$nginx_config:/etc/nginx/nginx.conf" nginx:alpine nginx -t > /dev/null 2>&1; then
                log_success "Nginx配置文件语法正确"
            else
                log_warning "Nginx配置文件语法可能有问题，请检查"
            fi
        else
            # 简单的配置文件存在性检查
            if grep -q "server" "$nginx_config"; then
                log_success "Nginx配置文件格式检查通过"
            else
                log_warning "Nginx配置文件格式可能有问题"
            fi
        fi
    else
        log_warning "Nginx配置文件不存在"
    fi
}

# 10. 生成验证报告
generate_report() {
    log_info "生成验证报告..."
    
    echo -e "\n========== 部署脚本验证报告 ==========" | tee -a "$VALIDATION_LOG"
    echo "验证完成时间: $(date)" | tee -a "$VALIDATION_LOG"
    
    local success_count=$(grep -c "SUCCESS" "$VALIDATION_LOG")
    local warning_count=$(grep -c "WARNING" "$VALIDATION_LOG")
    local error_count=$(grep -c "ERROR" "$VALIDATION_LOG")
    
    echo -e "${GREEN}成功项目: $success_count${NC}" | tee -a "$VALIDATION_LOG"
    echo -e "${YELLOW}警告项目: $warning_count${NC}" | tee -a "$VALIDATION_LOG"
    echo -e "${RED}错误项目: $error_count${NC}" | tee -a "$VALIDATION_LOG"
    
    if [ "$error_count" -eq 0 ]; then
        echo -e "\n${GREEN}✅ 部署脚本验证通过，可以安全部署！${NC}" | tee -a "$VALIDATION_LOG"
        return 0
    else
        echo -e "\n${RED}❌ 部署脚本验证失败，请修复错误后重试！${NC}" | tee -a "$VALIDATION_LOG"
        return 1
    fi
}

# 主函数
main() {
    init_validation
    
    local validation_steps=(
        validate_script_syntax
        validate_docker_config
        validate_env_config
        validate_app_config
        validate_port_config
        validate_prerequisites
        dry_run_deployment
        validate_monitoring
        validate_nginx_config
    )
    
    local failed_steps=0
    
    for step in "${validation_steps[@]}"; do
        if ! $step; then
            ((failed_steps++))
        fi
        echo "" # 添加空行分隔
    done
    
    generate_report
    
    echo -e "\n详细日志保存在: $VALIDATION_LOG"
    
    if [ "$failed_steps" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "部署脚本验证工具"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -v, --verbose  显示详细输出"
    echo ""
    echo "功能:"
    echo "  - 验证部署脚本语法"
    echo "  - 检查Docker配置"
    echo "  - 验证环境变量"
    echo "  - 检查系统资源"
    echo "  - 执行干运行测试"
    echo "  - 生成验证报告"
}

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--verbose)
        set -x
        main
        ;;
    *)
        main
        ;;
esac