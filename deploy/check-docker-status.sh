#!/bin/bash

# Docker环境完整性检查脚本
# 适用于阿里云ECS服务器

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_separator() {
    echo "=============================================="
}

# 检查Docker基础环境
check_docker_basic() {
    log_info "检查Docker基础环境..."
    print_separator
    
    # 检查Docker是否安装
    if command -v docker &>/dev/null; then
        local version=$(docker --version 2>/dev/null)
        log_success "✓ Docker已安装: $version"
    else
        log_error "✗ Docker未安装"
        return 1
    fi
    
    # 检查Docker服务状态
    if systemctl is-active --quiet docker 2>/dev/null; then
        log_success "✓ Docker服务运行中"
        echo "   服务状态: $(systemctl is-active docker)"
        echo "   开机启动: $(systemctl is-enabled docker 2>/dev/null || echo 'unknown')"
    else
        log_error "✗ Docker服务未运行"
        log_info "  启动命令: sudo systemctl start docker"
        log_info "  开机启动: sudo systemctl enable docker"
        return 1
    fi
    
    # 检查Docker权限
    if docker ps &>/dev/null; then
        log_success "✓ Docker权限正常"
    else
        log_warning "! Docker需要sudo权限或用户不在docker组"
        log_info "  当前用户: $(whoami)"
        log_info "  docker组成员: $(getent group docker | cut -d: -f4)"
    fi
    
    echo ""
}

# 检查Docker Compose
check_docker_compose() {
    log_info "检查Docker Compose..."
    print_separator
    
    # 检查Docker Compose插件
    if docker compose version &>/dev/null; then
        local version=$(docker compose version --short 2>/dev/null || docker compose version | head -n1)
        log_success "✓ Docker Compose插件: $version"
    elif command -v docker-compose &>/dev/null; then
        local version=$(docker-compose --version 2>/dev/null)
        log_warning "✓ Docker Compose独立版本: $version"
        log_info "  建议升级到插件版本: docker compose"
    else
        log_error "✗ Docker Compose未安装"
        log_info "  安装命令参考 init-server.sh 脚本"
    fi
    
    echo ""
}

# 检查镜像状态
check_images() {
    log_info "检查Docker镜像..."
    print_separator
    
    if docker images &>/dev/null; then
        echo "本地镜像列表:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || docker images
        
        echo ""
        echo "磁盘使用情况:"
        docker system df 2>/dev/null || log_warning "无法获取磁盘使用情况"
    else
        log_error "无法访问Docker镜像信息"
    fi
    
    echo ""
}

# 检查容器状态
check_containers() {
    log_info "检查容器状态..."
    print_separator
    
    if docker ps -a &>/dev/null; then
        echo "所有容器状态:"
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" 2>/dev/null || docker ps -a
        
        echo ""
        echo "运行中的容器:"
        local running_count=$(docker ps -q 2>/dev/null | wc -l)
        log_info "运行中容器数量: $running_count"
        
        if [ "$running_count" -gt 0 ]; then
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps
        else
            log_warning "没有运行中的容器"
        fi
    else
        log_error "无法访问容器信息"
    fi
    
    echo ""
}

# 检查网络状态
check_networks() {
    log_info "检查Docker网络..."
    print_separator
    
    if docker network ls &>/dev/null; then
        echo "Docker网络列表:"
        docker network ls
        
        # 检查项目专用网络
        if docker network ls | grep -q "app-network"; then
            log_success "✓ 项目网络 app-network 存在"
        else
            log_warning "! 项目网络 app-network 不存在"
        fi
    else
        log_error "无法访问网络信息"
    fi
    
    echo ""
}

# 检查数据卷
check_volumes() {
    log_info "检查Docker数据卷..."
    print_separator
    
    if docker volume ls &>/dev/null; then
        echo "Docker数据卷列表:"
        docker volume ls
        
        # 检查项目相关数据卷
        local volumes=("mysql_data" "redis_data" "rabbitmq_data")
        for vol in "${volumes[@]}"; do
            if docker volume ls | grep -q "$vol"; then
                log_success "✓ 数据卷 $vol 存在"
            else
                log_warning "! 数据卷 $vol 不存在"
            fi
        done
    else
        log_error "无法访问数据卷信息"
    fi
    
    echo ""
}

# 检查Docker配置
check_docker_config() {
    log_info "检查Docker配置..."
    print_separator
    
    # 检查daemon.json配置
    if [ -f "/etc/docker/daemon.json" ]; then
        log_success "✓ Docker配置文件存在: /etc/docker/daemon.json"
        echo "配置内容预览:"
        head -n 10 /etc/docker/daemon.json 2>/dev/null || log_warning "无法读取配置文件"
    else
        log_warning "! Docker配置文件不存在"
    fi
    
    # 检查镜像加速器
    if docker info 2>/dev/null | grep -A 10 "Registry Mirrors:" | grep -q "mirrors"; then
        log_success "✓ 配置了镜像加速器"
        echo "镜像加速器:"
        docker info 2>/dev/null | grep -A 10 "Registry Mirrors:" | tail -n +2
    else
        log_warning "! 未配置镜像加速器，可能影响镜像下载速度"
    fi
    
    echo ""
}

# 检查项目特定依赖
check_project_dependencies() {
    log_info "检查项目特定依赖..."
    print_separator
    
    # 检查项目镜像
    local project_images=("openjdk" "mysql" "redis" "rabbitmq" "nginx")
    echo "项目所需镜像检查:"
    
    for image in "${project_images[@]}"; do
        if docker images | grep -q "$image"; then
            local image_info=$(docker images | grep "$image" | head -n1 | awk '{print $1":"$2" ("$7" "$8")"}')
            log_success "✓ $image: $image_info"
        else
            log_warning "! $image: 镜像不存在"
        fi
    done
    
    echo ""
    
    # 检查docker-compose.yml文件
    if [ -f "docker-compose.yml" ]; then
        log_success "✓ docker-compose.yml 文件存在"
        
        # 验证docker-compose文件语法
        if docker compose config &>/dev/null; then
            log_success "✓ docker-compose.yml 语法正确"
        else
            log_error "✗ docker-compose.yml 语法错误"
            log_info "  检查命令: docker compose config"
        fi
    else
        log_warning "! docker-compose.yml 文件不存在"
    fi
}

# 系统资源检查
check_system_resources() {
    log_info "检查系统资源..."
    print_separator
    
    # 内存使用情况
    echo "内存使用情况:"
    free -h
    
    echo ""
    
    # 磁盘使用情况
    echo "磁盘使用情况:"
    df -h
    
    echo ""
    
    # Docker资源使用
    if command -v docker &>/dev/null && docker ps &>/dev/null; then
        echo "Docker资源使用:"
        docker system df
        
        if [ $(docker ps -q | wc -l) -gt 0 ]; then
            echo ""
            echo "容器资源使用 (实时):"
            timeout 3 docker stats --no-stream 2>/dev/null || log_warning "无法获取容器资源使用情况"
        fi
    fi
}

# 主检查函数
main() {
    echo "====== Docker环境完整性检查 ======"
    echo "检查时间: $(date)"
    echo "服务器: $(hostname)"
    echo "用户: $(whoami)"
    echo ""
    
    # 依次执行各项检查
    check_docker_basic
    check_docker_compose
    check_images
    check_containers
    check_networks
    check_volumes
    check_docker_config
    check_project_dependencies
    check_system_resources
    
    # 生成总结报告
    echo ""
    log_info "检查完成！"
    print_separator
    
    echo "快速启动项目命令:"
    echo "  cd /path/to/project"
    echo "  docker compose up -d"
    echo ""
    echo "查看日志命令:"
    echo "  docker compose logs -f"
    echo ""
    echo "停止项目命令:"
    echo "  docker compose down"
}

# 执行检查
main "$@"