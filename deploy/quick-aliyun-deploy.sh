#!/bin/bash

# 阿里云服务器快速部署脚本
# 直接在服务器上运行，优化构建速度

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

# 检查Docker配置
check_docker_config() {
    log_info "检查Docker镜像源配置..."
    
    if [ ! -f /etc/docker/daemon.json ]; then
        log_warning "Docker镜像源未配置，正在配置阿里云镜像..."
        setup_docker_mirrors
    else
        if grep -q "mirrors.cloud.aliyuncs.com" /etc/docker/daemon.json; then
            log_success "Docker镜像源已配置阿里云加速"
        else
            log_warning "Docker镜像源配置需要优化..."
            setup_docker_mirrors
        fi
    fi
}

# 配置Docker镜像源
setup_docker_mirrors() {
    log_info "配置Docker阿里云镜像源（参考官方文档）..."
    
    sudo mkdir -p /etc/docker
    
    # 根据阿里云官方文档配置镜像源
    sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://mirrors.aliyun.com",
    "https://dockerproxy.com",
    "https://mirror.baidubce.com",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    log_success "Docker镜像源配置完成"
}

# 优化系统DNS
optimize_dns() {
    log_info "优化DNS配置..."
    
    # 备份原始DNS配置
    if [ ! -f /etc/resolv.conf.backup ]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    fi
    
    # 使用阿里云DNS
    sudo tee /etc/resolv.conf > /dev/null << 'EOF'
nameserver 223.5.5.5
nameserver 223.6.6.6
nameserver 8.8.8.8
EOF
    
    log_success "DNS优化完成"
}

# 清理Docker缓存
cleanup_docker() {
    log_info "清理Docker缓存和镜像..."
    
    # 停止当前容器
    docker compose -f docker-compose-minimal.yml down 2>/dev/null || true
    
    # 清理未使用的镜像和容器
    docker system prune -f
    
    # 清理构建缓存
    docker builder prune -f
    
    log_success "Docker清理完成"
}

# 预拉取基础镜像
pull_base_images() {
    log_info "预拉取基础镜像（使用配置的镜像源）..."
    
    # 使用官方镜像，通过Docker镜像源加速
    docker pull openjdk:17-jdk-slim
    
    log_success "基础镜像拉取完成"
}

# 构建和部署
build_and_deploy() {
    log_info "开始构建和部署..."
    
    # 检查必要文件
    if [ ! -f "Dockerfile.aliyun-fixed" ]; then
        log_error "Dockerfile.aliyun-fixed 不存在，请确保文件已上传"
        exit 1
    fi
    
    if [ ! -f "docker-compose-minimal.yml" ]; then
        log_error "docker-compose-minimal.yml 不存在"
        exit 1
    fi
    
    # 设置环境变量
    if [ ! -f ".env" ]; then
        log_info "创建.env文件..."
        cat > .env << 'EOF'
SILICONFLOW_API_KEY=your_api_key_here
EOF
        log_warning "请编辑 .env 文件设置正确的API密钥"
    fi
    
    # 构建镜像（使用阿里云优化版本）
    log_info "构建Docker镜像（使用阿里云优化配置）..."
    docker compose -f docker-compose-minimal.yml build --no-cache
    
    # 启动服务
    log_info "启动服务..."
    docker compose -f docker-compose-minimal.yml up -d springmvc-app
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 15
    
    # 检查服务状态
    check_service_status
}

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    # 检查容器状态
    docker compose -f docker-compose-minimal.yml ps
    
    # 检查健康状态
    for i in {1..30}; do
        if curl -f http://localhost:8080/api/health >/dev/null 2>&1; then
            log_success "✅ 应用启动成功！"
            
            # 获取服务器公网IP
            PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
            
            log_success "🎉 部署完成！"
            echo "======================================"
            echo "访问地址: http://$PUBLIC_IP:8080"
            echo "健康检查: http://$PUBLIC_IP:8080/api/health"
            echo "======================================"
            
            return 0
        fi
        echo "等待应用启动... ($i/30)"
        sleep 2
    done
    
    log_error "应用启动超时，请检查日志"
    docker compose -f docker-compose-minimal.yml logs springmvc-app
    return 1
}

# 显示日志
show_logs() {
    log_info "显示应用日志..."
    docker compose -f docker-compose-minimal.yml logs -f springmvc-app
}

# 主函数
main() {
    log_info "开始阿里云服务器快速部署优化..."
    
    # 检查是否在项目目录
    if [ ! -f "pom.xml" ]; then
        log_error "请在项目根目录运行此脚本"
        exit 1
    fi
    
    case "${1:-deploy}" in
        "setup")
            check_docker_config
            optimize_dns
            cleanup_docker
            pull_base_images
            log_success "环境优化完成"
            ;;
        "deploy")
            check_docker_config
            cleanup_docker
            pull_base_images
            build_and_deploy
            ;;
        "logs")
            show_logs
            ;;
        "clean")
            cleanup_docker
            log_success "清理完成"
            ;;
        *)
            echo "使用方法: $0 [setup|deploy|logs|clean]"
            echo "  setup  - 优化环境配置"
            echo "  deploy - 构建和部署（默认）"
            echo "  logs   - 查看应用日志"
            echo "  clean  - 清理Docker缓存"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"