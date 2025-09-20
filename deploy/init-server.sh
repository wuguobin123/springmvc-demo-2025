#!/bin/bash

# 阿里云ECS服务器环境初始化脚本
# 在目标服务器上运行此脚本来安装必要的依赖

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

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root用户运行此脚本"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_info "更新系统软件包..."
    
    # 检测系统类型
    if [ -f /etc/centos-release ]; then
        # CentOS/RHEL
        yum update -y
        yum install -y curl wget git vim
    elif [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        apt-get update
        apt-get upgrade -y
        apt-get install -y curl wget git vim
    else
        log_error "不支持的操作系统"
        exit 1
    fi
    
    log_success "系统更新完成"
}

# 安装Docker
install_docker() {
    log_info "安装Docker..."
    
    # 检查Docker是否已安装
    if command -v docker &> /dev/null; then
        log_warning "Docker已安装，跳过安装步骤"
        return
    fi
    
    # 安装Docker
    curl -fsSL https://get.docker.com | sh
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 添加当前用户到docker组
    usermod -aG docker $USER
    
    log_success "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log_info "安装Docker Compose..."
    
    # 检查Docker Compose是否已安装
    if command -v docker-compose &> /dev/null; then
        log_warning "Docker Compose已安装，跳过安装步骤"
        return
    fi
    
    # 下载Docker Compose
    DOCKER_COMPOSE_VERSION="2.21.0"
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 添加执行权限
    chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose安装完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    if command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL firewalld
        systemctl start firewalld
        systemctl enable firewalld
        
        # 开放端口
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=3306/tcp
        firewall-cmd --permanent --add-port=6379/tcp
        firewall-cmd --permanent --add-port=5672/tcp
        firewall-cmd --permanent --add-port=15672/tcp
        
        # 重载防火墙规则
        firewall-cmd --reload
        
    elif command -v ufw &> /dev/null; then
        # Ubuntu ufw
        ufw --force enable
        
        # 开放端口
        ufw allow 80/tcp
        ufw allow 8080/tcp
        ufw allow 3306/tcp
        ufw allow 6379/tcp
        ufw allow 5672/tcp
        ufw allow 15672/tcp
        
    else
        log_warning "未检测到防火墙工具，请手动配置"
    fi
    
    log_success "防火墙配置完成"
}

# 创建应用目录
create_app_directory() {
    log_info "创建应用目录..."
    
    # 创建应用目录
    mkdir -p /opt/springmvc-demo
    mkdir -p /opt/springmvc-demo/logs
    mkdir -p /opt/springmvc-demo/data/mysql
    mkdir -p /opt/springmvc-demo/data/redis
    mkdir -p /opt/springmvc-demo/data/rabbitmq
    
    # 设置权限
    chown -R 1000:1000 /opt/springmvc-demo
    
    log_success "应用目录创建完成"
}

# 配置系统优化
configure_system_optimization() {
    log_info "配置系统优化..."
    
    # 调整文件描述符限制
    cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF
    
    # 调整内核参数
    cat >> /etc/sysctl.conf << EOF
# 网络优化
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_fin_timeout = 10

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
    
    # 应用内核参数
    sysctl -p
    
    log_success "系统优化配置完成"
}

# 安装监控工具
install_monitoring() {
    log_info "安装监控工具..."
    
    # 安装htop
    if [ -f /etc/centos-release ]; then
        yum install -y htop iotop
    elif [ -f /etc/debian_version ]; then
        apt-get install -y htop iotop
    fi
    
    log_success "监控工具安装完成"
}

# 主函数
main() {
    log_info "开始初始化阿里云ECS服务器环境..."
    
    check_root
    update_system
    install_docker
    install_docker_compose
    configure_firewall
    create_app_directory
    configure_system_optimization
    install_monitoring
    
    log_success "服务器环境初始化完成！"
    log_info "请重新登录以使用户组更改生效"
    log_info "然后您可以部署应用了"
}

# 执行主函数
main "$@"