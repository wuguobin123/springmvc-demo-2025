#!/bin/bash

# 2核2GB服务器轻量化部署脚本
set -e

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

# 检查系统资源
check_resources() {
    log_info "检查系统资源..."
    
    # 检查内存
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [ $TOTAL_MEM -lt 1800 ]; then
        log_error "系统内存不足！当前: ${TOTAL_MEM}MB，建议至少2GB"
        exit 1
    fi
    
    # 检查CPU核心数
    CPU_CORES=$(nproc)
    if [ $CPU_CORES -lt 2 ]; then
        log_warning "CPU核心数较少，当前: ${CPU_CORES}核"
    fi
    
    # 检查磁盘空间
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $DISK_SPACE -lt 10 ]; then
        log_error "磁盘空间不足！当前可用: ${DISK_SPACE}GB，建议至少10GB"
        exit 1
    fi
    
    log_success "系统资源检查通过 - CPU: ${CPU_CORES}核, 内存: ${TOTAL_MEM}MB, 磁盘: ${DISK_SPACE}GB"
}

# 优化系统设置
optimize_system() {
    log_info "优化系统设置..."
    
    # 设置swap
    if [ ! -f /swapfile ]; then
        log_info "创建1GB swap文件..."
        sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    # 调整swappiness
    echo 'vm.swappiness=30' | sudo tee -a /etc/sysctl.conf
    sudo sysctl vm.swappiness=30
    
    log_success "系统优化完成"
}

# 选择部署模式
select_deployment_mode() {
    echo "请选择部署模式："
    echo "1) 轻量化本地部署（所有服务在本地，适合测试）"
    echo "2) 云服务部署（使用阿里云RDS/Redis，推荐生产）"
    read -p "请输入选择 (1-2): " mode
    
    case $mode in
        1)
            COMPOSE_FILE="docker-compose-light.yml"
            log_info "使用轻量化本地部署模式"
            ;;
        2)
            COMPOSE_FILE="docker-compose-cloud.yml"
            log_info "使用云服务部署模式"
            check_cloud_config
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
}

# 检查云服务配置
check_cloud_config() {
    log_info "检查云服务配置..."
    
    if [ -z "$ALIYUN_RDS_HOST" ]; then
        log_error "请设置阿里云RDS配置环境变量"
        log_info "示例："
        log_info "export ALIYUN_RDS_HOST=rm-xxxxx.mysql.rds.aliyuncs.com"
        log_info "export ALIYUN_RDS_DATABASE=springmvc_demo"
        log_info "export ALIYUN_RDS_USERNAME=your_username"
        log_info "export ALIYUN_RDS_PASSWORD=your_password"
        exit 1
    fi
    
    log_success "云服务配置检查通过"
}

# 轻量化部署
deploy_light() {
    log_info "开始轻量化部署..."
    
    # 停止旧容器
    docker-compose -f $COMPOSE_FILE down --remove-orphans || true
    
    # 清理资源
    docker system prune -f
    
    # 构建镜像
    log_info "构建轻量化Docker镜像..."
    docker build -t springmvc-demo:light .
    
    # 启动服务
    log_info "启动轻量化服务..."
    docker-compose -f $COMPOSE_FILE up -d
    
    # 等待启动
    log_info "等待服务启动（60秒）..."
    sleep 60
    
    # 检查服务状态
    check_services
}

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    # 检查容器状态
    docker-compose -f $COMPOSE_FILE ps
    
    # 检查应用健康
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8080/api/health > /dev/null 2>&1; then
            log_success "应用健康检查通过！"
            return 0
        fi
        
        log_info "健康检查失败，等待重试... ($attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    log_error "应用健康检查失败"
    docker-compose -f $COMPOSE_FILE logs springmvc-app
    return 1
}

# 显示内存使用情况
show_memory_usage() {
    log_info "当前内存使用情况："
    docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}"
    
    log_info "系统内存使用情况："
    free -h
}

# 主函数
main() {
    log_info "开始2核2GB服务器轻量化部署..."
    
    check_resources
    optimize_system
    select_deployment_mode
    deploy_light
    show_memory_usage
    
    log_success "部署完成！"
    log_info "访问地址: http://$(curl -s ifconfig.me):8080/api/health"
}

# 执行主函数
main "$@"