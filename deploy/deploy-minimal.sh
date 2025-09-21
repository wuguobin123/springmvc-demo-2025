#!/bin/bash

# 最小化部署脚本（仅AI服务调用）
# 使用方法: ./deploy-minimal.sh [操作]
# 操作: start|stop|restart|status|logs

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查环境变量
check_env() {
    if [ ! -f ".env" ]; then
        log_warning "未找到.env文件，将使用默认配置"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_info "已复制.env.example为.env，请检查配置"
        fi
    fi
    
    # 检查API密钥
    if grep -q "your-api-key-here" .env 2>/dev/null; then
        log_error "请在.env文件中配置正确的SILICONFLOW_API_KEY"
        exit 1
    fi
}

# 启动服务
start_service() {
    log_info "启动最小化SpringMVC服务..."
    check_env
    
    # 仅启动应用容器
    docker compose -f docker-compose-minimal.yml up -d springmvc-app
    
    log_info "等待应用启动..."
    sleep 30
    
    # 健康检查
    if curl -f http://localhost:8080/api/health > /dev/null 2>&1; then
        log_success "应用启动成功！"
        log_info "API文档: http://localhost:8080/api/"
        log_info "健康检查: http://localhost:8080/api/health"
    else
        log_error "应用启动失败，请检查日志"
        docker compose -f docker-compose-minimal.yml logs springmvc-app
        exit 1
    fi
}

# 启动服务（包含Nginx）
start_with_nginx() {
    log_info "启动SpringMVC服务（包含Nginx代理）..."
    check_env
    
    # 启动所有服务
    docker compose -f docker-compose-minimal.yml --profile with-nginx up -d
    
    log_info "等待服务启动..."
    sleep 30
    
    # 健康检查
    if curl -f http://localhost/api/health > /dev/null 2>&1; then
        log_success "服务启动成功！"
        log_info "访问地址: http://localhost/api/"
        log_info "健康检查: http://localhost/api/health"
    else
        log_error "服务启动失败，请检查日志"
        docker compose -f docker-compose-minimal.yml logs
        exit 1
    fi
}

# 停止服务
stop_service() {
    log_info "停止服务..."
    docker compose -f docker-compose-minimal.yml down
    log_success "服务已停止"
}

# 重启服务
restart_service() {
    log_info "重启服务..."
    stop_service
    sleep 5
    start_service
}

# 查看状态
show_status() {
    log_info "服务状态:"
    docker compose -f docker-compose-minimal.yml ps
}

# 查看日志
show_logs() {
    log_info "查看应用日志:"
    docker compose -f docker-compose-minimal.yml logs -f springmvc-app
}

# 主函数
main() {
    case "${1:-start}" in
        "start")
            start_service
            ;;
        "start-nginx")
            start_with_nginx
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            restart_service
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        *)
            echo "用法: $0 {start|start-nginx|stop|restart|status|logs}"
            echo "  start       - 启动应用（仅SpringBoot）"
            echo "  start-nginx - 启动应用（包含Nginx代理）"
            echo "  stop        - 停止服务"
            echo "  restart     - 重启服务"
            echo "  status      - 查看服务状态"
            echo "  logs        - 查看应用日志"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"