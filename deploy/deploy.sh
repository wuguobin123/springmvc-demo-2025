#!/bin/bash

# 阿里云ECS部署脚本
# 使用方法: ./deploy.sh [环境] [版本]
# 示例: ./deploy.sh prod v1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认参数
ENVIRONMENT=${1:-prod}
VERSION=${2:-latest}
PROJECT_NAME="springmvc-demo"
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"registry.cn-hangzhou.aliyuncs.com/your-namespace"}

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

# 检查环境
check_environment() {
    log_info "检查部署环境..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查环境变量文件
    if [ ! -f ".env" ]; then
        log_warning "未找到.env文件，将使用.env.example作为模板"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_warning "请编辑.env文件，配置正确的环境变量"
            exit 1
        fi
    fi
    
    log_success "环境检查完成"
}

# 构建Docker镜像
build_image() {
    log_info "构建Docker镜像..."
    
    # 清理旧的构建文件
    if [ -d "target" ]; then
        rm -rf target
    fi
    
    # 构建镜像
    docker build -t ${PROJECT_NAME}:${VERSION} .
    
    # 标记镜像
    docker tag ${PROJECT_NAME}:${VERSION} ${PROJECT_NAME}:latest
    
    log_success "Docker镜像构建完成"
}

# 推送镜像到阿里云容器镜像服务
push_image() {
    log_info "推送镜像到阿里云容器镜像服务..."
    
    # 登录阿里云容器镜像服务
    if [ -n "$ALIYUN_DOCKER_USERNAME" ] && [ -n "$ALIYUN_DOCKER_PASSWORD" ]; then
        echo "$ALIYUN_DOCKER_PASSWORD" | docker login --username "$ALIYUN_DOCKER_USERNAME" --password-stdin registry.cn-hangzhou.aliyuncs.com
    else
        log_warning "未配置阿里云容器镜像服务凭证，跳过推送步骤"
        return
    fi
    
    # 标记并推送镜像
    docker tag ${PROJECT_NAME}:${VERSION} ${DOCKER_REGISTRY}/${PROJECT_NAME}:${VERSION}
    docker tag ${PROJECT_NAME}:${VERSION} ${DOCKER_REGISTRY}/${PROJECT_NAME}:latest
    
    docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}:${VERSION}
    docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}:latest
    
    log_success "镜像推送完成"
}

# 部署到服务器
deploy_to_server() {
    log_info "部署应用到服务器..."
    
    # 停止旧容器
    log_info "停止旧容器..."
    docker-compose down --remove-orphans || true
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 启动新容器
    log_info "启动新容器..."
    docker-compose up -d
    
    # 等待应用启动
    log_info "等待应用启动..."
    sleep 30
    
    # 健康检查
    check_health
    
    log_success "应用部署完成"
}

# 健康检查
check_health() {
    log_info "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8080/api/health > /dev/null 2>&1; then
            log_success "应用健康检查通过"
            return 0
        fi
        
        log_info "健康检查失败，等待重试... ($attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    log_error "应用健康检查失败，请检查日志"
    docker-compose logs springmvc-app
    return 1
}

# 回滚
rollback() {
    log_warning "开始回滚..."
    
    # 这里可以实现回滚逻辑
    # 例如：回滚到上一个版本的镜像
    
    log_info "回滚功能待实现"
}

# 查看日志
show_logs() {
    log_info "查看应用日志..."
    docker-compose logs -f springmvc-app
}

# 主函数
main() {
    log_info "开始部署 ${PROJECT_NAME} 到 ${ENVIRONMENT} 环境，版本: ${VERSION}"
    
    case "${1:-deploy}" in
        "deploy")
            check_environment
            build_image
            push_image
            deploy_to_server
            ;;
        "rollback")
            rollback
            ;;
        "logs")
            show_logs
            ;;
        "health")
            check_health
            ;;
        *)
            echo "Usage: $0 {deploy|rollback|logs|health} [environment] [version]"
            echo "  deploy   - 构建并部署应用"
            echo "  rollback - 回滚到上一个版本"
            echo "  logs     - 查看应用日志"
            echo "  health   - 执行健康检查"
            exit 1
            ;;
    esac
    
    log_success "操作完成"
}

# 执行主函数
main "$@"