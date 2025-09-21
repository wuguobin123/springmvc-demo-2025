#!/bin/bash

# 简化部署脚本验证工具
# 适用于开发环境和生产环境的基本验证

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

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 验证计数器
SUCCESS_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0

# 验证结果记录
check_result() {
    case $1 in
        "success") ((SUCCESS_COUNT++)) ;;
        "warning") ((WARNING_COUNT++)) ;;
        "error") ((ERROR_COUNT++)) ;;
    esac
}

# 1. 验证部署脚本
validate_scripts() {
    log_info "验证部署脚本..."
    
    local scripts=(
        "deploy.sh"
        "deploy-light.sh" 
        "deploy-minimal.sh"
        "init-server.sh"
        "monitor.sh"
    )
    
    for script in "${scripts[@]}"; do
        local script_path="$SCRIPT_DIR/$script"
        if [ -f "$script_path" ]; then
            if bash -n "$script_path" 2>/dev/null; then
                log_success "脚本语法正确: $script"
                check_result "success"
            else
                log_error "脚本语法错误: $script"
                check_result "error"
            fi
            
            # 检查执行权限
            if [ -x "$script_path" ]; then
                log_success "脚本权限正确: $script"
                check_result "success"
            else
                log_warning "脚本缺少执行权限: $script"
                check_result "warning"
            fi
        else
            log_warning "脚本不存在: $script"
            check_result "warning"
        fi
    done
}

# 2. 验证配置文件
validate_configs() {
    log_info "验证配置文件..."
    
    # 检查Dockerfile
    if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
        if grep -q "FROM" "$PROJECT_ROOT/Dockerfile" && \
           grep -q "EXPOSE" "$PROJECT_ROOT/Dockerfile"; then
            log_success "Dockerfile格式正确"
            check_result "success"
        else
            log_warning "Dockerfile可能缺少必要指令"
            check_result "warning"
        fi
    else
        log_error "Dockerfile不存在"
        check_result "error"
    fi
    
    # 检查Docker Compose文件
    local compose_files=(
        "docker-compose.yml"
        "docker-compose-light.yml"
        "docker-compose-cloud.yml"
    )
    
    for file in "${compose_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            if grep -q "version:" "$PROJECT_ROOT/$file" && \
               grep -q "services:" "$PROJECT_ROOT/$file"; then
                log_success "Docker Compose文件格式正确: $file"
                check_result "success"
            else
                log_warning "Docker Compose文件格式可能有问题: $file"
                check_result "warning"
            fi
        else
            log_warning "Docker Compose文件不存在: $file"
            check_result "warning"
        fi
    done
    
    # 检查环境变量模板
    if [ -f "$PROJECT_ROOT/.env.example" ]; then
        local required_vars=(
            "DB_HOST" "DB_PASSWORD" "REDIS_HOST" 
            "SILICONFLOW_API_KEY"
        )
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" "$PROJECT_ROOT/.env.example"; then
                log_success "环境变量模板包含: $var"
                check_result "success"
            else
                log_warning "环境变量模板缺少: $var"
                check_result "warning"
            fi
        done
    else
        log_error "缺少.env.example模板文件"
        check_result "error"
    fi
}

# 3. 验证应用配置
validate_app_configs() {
    log_info "验证应用配置..."
    
    local app_configs=(
        "src/main/resources/application.yml"
        "src/main/resources/application-dev.yml"
        "src/main/resources/application-prod.yml"
    )
    
    for config in "${app_configs[@]}"; do
        if [ -f "$PROJECT_ROOT/$config" ]; then
            # 简单的YAML格式检查
            if grep -q "spring:" "$PROJECT_ROOT/$config"; then
                log_success "配置文件格式正确: $(basename "$config")"
                check_result "success"
            else
                log_warning "配置文件格式可能有问题: $(basename "$config")"
                check_result "warning"
            fi
        else
            log_warning "配置文件不存在: $(basename "$config")"
            check_result "warning"
        fi
    done
    
    # 检查POM文件
    if [ -f "$PROJECT_ROOT/pom.xml" ]; then
        if grep -q "<groupId>" "$PROJECT_ROOT/pom.xml" && \
           grep -q "<artifactId>" "$PROJECT_ROOT/pom.xml"; then
            log_success "Maven POM文件格式正确"
            check_result "success"
        else
            log_warning "Maven POM文件格式可能有问题"
            check_result "warning"
        fi
    else
        log_error "Maven POM文件不存在"
        check_result "error"
    fi
}

# 4. 验证端口配置
validate_ports() {
    log_info "验证端口配置..."
    
    local ports=(8080 3306 6379 5672 80)
    
    for port in "${ports[@]}"; do
        if command -v netstat &> /dev/null; then
            if netstat -an | grep -q ":$port "; then
                log_warning "端口 $port 已被占用"
                check_result "warning"
            else
                log_success "端口 $port 可用"
                check_result "success"
            fi
        elif command -v lsof &> /dev/null; then
            if lsof -i ":$port" &> /dev/null; then
                log_warning "端口 $port 已被占用"
                check_result "warning"
            else
                log_success "端口 $port 可用"
                check_result "success"
            fi
        else
            log_info "无法检查端口状态（缺少netstat或lsof）"
        fi
    done
}

# 5. 验证文档
validate_documentation() {
    log_info "验证部署文档..."
    
    local docs=(
        "README.md"
        "DEPLOYMENT.md"
        "QUICK_DEPLOY.md"
    )
    
    for doc in "${docs[@]}"; do
        if [ -f "$PROJECT_ROOT/$doc" ]; then
            if [ -s "$PROJECT_ROOT/$doc" ]; then
                log_success "文档存在且不为空: $doc"
                check_result "success"
            else
                log_warning "文档存在但为空: $doc"
                check_result "warning"
            fi
        else
            log_warning "文档不存在: $doc"
            check_result "warning"
        fi
    done
}

# 6. 验证目录结构
validate_structure() {
    log_info "验证项目结构..."
    
    local required_dirs=(
        "src/main/java"
        "src/main/resources"
        "deploy"
        "docker"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            log_success "目录存在: $dir"
            check_result "success"
        else
            log_error "目录不存在: $dir"
            check_result "error"
        fi
    done
    
    local required_files=(
        "pom.xml"
        "Dockerfile"
        ".env.example"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            log_success "文件存在: $file"
            check_result "success"
        else
            log_error "文件不存在: $file"
            check_result "error"
        fi
    done
}

# 7. 验证工具可用性
validate_tools() {
    log_info "验证部署工具..."
    
    local tools=(
        "java:Java运行环境"
        "mvn:Maven构建工具"
        "git:Git版本控制"
        "curl:网络工具"
    )
    
    for tool_info in "${tools[@]}"; do
        local tool="${tool_info%%:*}"
        local desc="${tool_info#*:}"
        
        if command -v "$tool" &> /dev/null; then
            log_success "$desc 已安装"
            check_result "success"
        else
            log_warning "$desc 未安装"
            check_result "warning"
        fi
    done
    
    # Docker检查（可选）
    if command -v docker &> /dev/null; then
        log_success "Docker 已安装"
        check_result "success"
        
        if docker info &> /dev/null; then
            log_success "Docker 服务运行正常"
            check_result "success"
        else
            log_warning "Docker 服务未运行"
            check_result "warning"
        fi
    else
        log_info "Docker 未安装（容器化部署需要）"
    fi
}

# 生成验证报告
generate_report() {
    echo ""
    echo "========== 部署脚本验证报告 =========="
    echo "验证时间: $(date)"
    echo "项目路径: $PROJECT_ROOT"
    echo ""
    echo -e "${GREEN}成功项目: $SUCCESS_COUNT${NC}"
    echo -e "${YELLOW}警告项目: $WARNING_COUNT${NC}"
    echo -e "${RED}错误项目: $ERROR_COUNT${NC}"
    echo ""
    
    if [ "$ERROR_COUNT" -eq 0 ]; then
        if [ "$WARNING_COUNT" -eq 0 ]; then
            echo -e "${GREEN}✅ 部署脚本验证完全通过！可以安全部署。${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  部署脚本验证基本通过，但有一些警告需要注意。${NC}"
            return 0
        fi
    else
        echo -e "${RED}❌ 部署脚本验证失败，请修复错误后重试！${NC}"
        return 1
    fi
}

# 提供修复建议
show_suggestions() {
    echo ""
    echo "========== 修复建议 =========="
    
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "🔧 修复错误："
        echo "  1. 检查缺失的文件和目录"
        echo "  2. 验证配置文件语法"
        echo "  3. 确保所有必需文件存在"
    fi
    
    if [ "$WARNING_COUNT" -gt 0 ]; then
        echo "💡 改进建议："
        echo "  1. 安装推荐的工具（Docker、Maven等）"
        echo "  2. 检查端口占用情况"
        echo "  3. 补充完整的环境变量配置"
        echo "  4. 为脚本添加执行权限"
    fi
    
    echo ""
    echo "📖 详细部署指南："
    echo "  - 查看 DEPLOYMENT.md 了解完整部署流程"
    echo "  - 查看 QUICK_DEPLOY.md 了解快速部署方法"
    echo "  - 查看 DEPLOYMENT_VALIDATION.md 了解验证详情"
}

# 主函数
main() {
    echo -e "${BLUE}部署脚本验证工具${NC}"
    echo "验证项目: $(basename "$PROJECT_ROOT")"
    echo ""
    
    # 执行所有验证步骤
    validate_structure
    validate_scripts
    validate_configs
    validate_app_configs
    validate_ports
    validate_documentation
    validate_tools
    
    # 生成报告
    local exit_code=0
    if ! generate_report; then
        exit_code=1
    fi
    
    # 显示建议
    show_suggestions
    
    exit $exit_code
}

# 显示帮助
show_help() {
    echo "部署脚本验证工具"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo ""
    echo "验证项目:"
    echo "  ✓ 项目结构完整性"
    echo "  ✓ 部署脚本语法"
    echo "  ✓ 配置文件格式"
    echo "  ✓ 环境变量模板"
    echo "  ✓ 端口占用情况"
    echo "  ✓ 部署工具可用性"
    echo "  ✓ 文档完整性"
}

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac