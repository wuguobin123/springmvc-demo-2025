#!/bin/bash

# 测试优化后的init-server.sh脚本的功能
# 本脚本用于验证主要功能是否正常工作

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

# 测试系统检测功能
test_system_detection() {
    log_info "测试系统检测功能..."
    
    # 模拟detect_system函数
    if [ -f /etc/alinux-release ]; then
        ALINUX_VERSION=$(grep 'Alibaba Cloud Linux' /etc/alinux-release | grep -oE '[0-9]+' | head -n1)
        if [ "$ALINUX_VERSION" = "3" ]; then
            SYSTEM_TYPE="alinux3"
            log_success "检测到Alibaba Cloud Linux 3系统"
        else
            SYSTEM_TYPE="alinux2"
            log_success "检测到Alibaba Cloud Linux 2系统"
        fi
    elif grep -q "Alibaba Cloud Linux" /etc/os-release 2>/dev/null; then
        if grep -q "Alibaba Cloud Linux 3" /etc/os-release; then
            SYSTEM_TYPE="alinux3"
            log_success "检测到Alibaba Cloud Linux 3系统"
        else
            SYSTEM_TYPE="alinux2"
            log_success "检测到Alibaba Cloud Linux 2系统"
        fi
    elif [ -f /etc/centos-release ]; then
        SYSTEM_TYPE="centos"
        log_success "检测到CentOS系统"
    elif [ -f /etc/debian_version ]; then
        if grep -q "Ubuntu" /etc/os-release; then
            SYSTEM_TYPE="ubuntu"
            log_success "检测到Ubuntu系统"
        else
            SYSTEM_TYPE="debian"
            log_success "检测到Debian系统"
        fi
    else
        SYSTEM_TYPE="unknown"
        log_warning "未知系统类型"
    fi
    
    echo "检测到的系统类型: $SYSTEM_TYPE"
}

# 测试Docker状态
test_docker_status() {
    log_info "检查Docker状态..."
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//' || echo "unknown")
        log_success "Docker已安装: $docker_version"
        
        if systemctl is-active --quiet docker 2>/dev/null; then
            log_success "Docker服务正在运行"
        else
            log_warning "Docker服务未运行"
        fi
        
        # 测试Docker镜像源
        if docker info 2>/dev/null | grep -q "Registry Mirrors"; then
            log_success "Docker镜像源已配置"
        else
            log_warning "Docker镜像源未配置"
        fi
    else
        log_error "Docker未安装"
    fi
}

# 测试Docker Compose状态
test_docker_compose_status() {
    log_info "检查Docker Compose状态..."
    
    # 检查Docker Compose插件
    if docker compose version &> /dev/null 2>&1; then
        local compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        log_success "Docker Compose插件已安装: $compose_version"
    elif command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version 2>/dev/null | awk '{print $3}' | sed 's/,//' | head -n1 || echo "unknown")
        log_warning "Docker Compose独立版本已安装: $compose_version"
        log_info "建议使用 'docker compose' 命令替代 'docker-compose'"
    else
        log_error "Docker Compose未安装"
    fi
}

# 测试防火墙状态
test_firewall_status() {
    log_info "检查防火墙状态..."
    
    if command -v firewall-cmd &> /dev/null; then
        if systemctl is-active --quiet firewalld; then
            log_success "firewalld正在运行"
            
            # 检查开放的端口
            local open_ports=$(firewall-cmd --list-ports 2>/dev/null || echo "")
            if [ -n "$open_ports" ]; then
                log_info "开放的端口: $open_ports"
            else
                log_warning "没有开放的端口"
            fi
        else
            log_warning "firewalld未运行"
        fi
    elif command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            log_success "ufw已启用"
        else
            log_warning "ufw未启用"
        fi
    else
        log_warning "未检测到防火墙工具"
    fi
}

# 测试应用目录
test_app_directory() {
    log_info "检查应用目录..."
    
    if [ -d "/opt/springmvc-demo" ]; then
        log_success "应用目录存在: /opt/springmvc-demo"
        
        # 检查子目录
        for subdir in logs data/mysql data/redis data/rabbitmq; do
            if [ -d "/opt/springmvc-demo/$subdir" ]; then
                log_success "子目录存在: $subdir"
            else
                log_warning "子目录不存在: $subdir"
            fi
        done
    else
        log_error "应用目录不存在: /opt/springmvc-demo"
    fi
}

# 测试系统优化
test_system_optimization() {
    log_info "检查系统优化配置..."
    
    # 检查文件描述符限制
    if grep -q "65536" /etc/security/limits.conf 2>/dev/null; then
        log_success "文件描述符限制已配置"
    else
        log_warning "文件描述符限制未配置"
    fi
    
    # 检查内核参数
    if grep -q "net.core.somaxconn" /etc/sysctl.conf 2>/dev/null; then
        log_success "网络内核参数已配置"
    else
        log_warning "网络内核参数未配置"
    fi
    
    # 检查当前文件描述符限制
    local current_limit=$(ulimit -n 2>/dev/null || echo "unknown")
    log_info "当前文件描述符限制: $current_limit"
}

# 测试监控工具
test_monitoring_tools() {
    log_info "检查监控工具..."
    
    if command -v htop &> /dev/null; then
        log_success "htop已安装"
    else
        log_warning "htop未安装"
    fi
    
    if command -v iotop &> /dev/null; then
        log_success "iotop已安装"
    else
        log_warning "iotop未安装"
    fi
}

# 快速Docker测试
quick_docker_test() {
    log_info "运行快速Docker测试..."
    
    if command -v docker &> /dev/null && systemctl is-active --quiet docker 2>/dev/null; then
        log_info "尝试运行hello-world容器..."
        if docker run --rm hello-world &> /dev/null; then
            log_success "Docker测试成功"
        else
            log_warning "Docker测试失败，可能需要重新登录以获取docker组权限"
        fi
    else
        log_warning "跳过Docker测试（Docker未安装或未运行）"
    fi
}

# 生成测试报告
generate_report() {
    log_info "\n========== 测试报告 =========="
    echo "测试时间: $(date)"
    echo "系统类型: $SYSTEM_TYPE"
    echo ""
    
    # Docker状态
    if command -v docker &> /dev/null; then
        echo "✓ Docker: 已安装"
    else
        echo "✗ Docker: 未安装"
    fi
    
    # Docker Compose状态
    if docker compose version &> /dev/null 2>&1; then
        echo "✓ Docker Compose: 插件已安装"
    elif command -v docker-compose &> /dev/null; then
        echo "✓ Docker Compose: 独立版本已安装"
    else
        echo "✗ Docker Compose: 未安装"
    fi
    
    # 应用目录
    if [ -d "/opt/springmvc-demo" ]; then
        echo "✓ 应用目录: 已创建"
    else
        echo "✗ 应用目录: 未创建"
    fi
    
    echo "================================"
}

# 主测试函数
main() {
    log_info "开始测试优化后的init-server.sh脚本功能..."
    echo ""
    
    test_system_detection
    echo ""
    
    test_docker_status
    echo ""
    
    test_docker_compose_status
    echo ""
    
    test_firewall_status
    echo ""
    
    test_app_directory
    echo ""
    
    test_system_optimization
    echo ""
    
    test_monitoring_tools
    echo ""
    
    quick_docker_test
    echo ""
    
    generate_report
    
    log_info "\n测试完成！"
    log_info "如果发现问题，请运行优化后的init-server.sh脚本进行修复"
}

# 执行主函数
main "$@"