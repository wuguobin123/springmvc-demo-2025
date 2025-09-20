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
    if [ -f /etc/alinux-release ] || grep -q "Alibaba Cloud Linux" /etc/os-release 2>/dev/null; then
        # 阿里云Linux (Alinux)
        log_info "检测到阿里云Linux系统..."
        yum update -y
        yum install -y curl wget git vim yum-utils
    elif [ -f /etc/centos-release ]; then
        # CentOS/RHEL
        log_info "检测到CentOS/RHEL系统..."
        yum update -y
        yum install -y curl wget git vim yum-utils
    elif [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        log_info "检测到Ubuntu/Debian系统..."
        apt-get update
        apt-get upgrade -y
        apt-get install -y curl wget git vim ca-certificates gnupg lsb-release
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
    
    # 检测系统类型并安装Docker
    if [ -f /etc/alinux-release ] || grep -q "Alibaba Cloud Linux" /etc/os-release 2>/dev/null; then
        # 阿里云Linux (Alinux)
        log_info "检测到阿里云Linux系统，使用阿里云源安装Docker..."
        yum install -y yum-utils
        yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
    elif [ -f /etc/centos-release ]; then
        # CentOS/RHEL
        log_info "检测到CentOS/RHEL系统..."
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
    elif [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        log_info "检测到Ubuntu/Debian系统..."
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io
    else
        # 其他系统，尝试使用官方脚本
        log_info "使用Docker官方安装脚本..."
        curl -fsSL https://get.docker.com | sh
    fi
    
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
    
    # 检查Docker Compose是否已安装并可用
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        local version=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
        log_warning "Docker Compose已安装 (版本: $version)，跳过安装步骤"
        return
    fi
    
    # 如果检测到旧版本或损坏的安装，先清理
    if [ -f "/usr/local/bin/docker-compose" ]; then
        log_info "检测到旧版本或损坏的Docker Compose，正在清理..."
        rm -f /usr/local/bin/docker-compose
    fi
    
    # 定义Docker Compose版本
    DOCKER_COMPOSE_VERSION="2.21.0"
    ARCH=$(uname -m)
    OS=$(uname -s)
    
    # 定义多个下载源（优先使用国内镜像）
    declare -a DOWNLOAD_URLS=(
        "https://get.daocloud.io/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
        "https://ghproxy.com/https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
        "https://mirror.ghproxy.com/https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
        "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
    )
    
    # 尝试从不同源下载Docker Compose
    download_success=false
    for url in "${DOWNLOAD_URLS[@]}"; do
        log_info "尝试从 ${url##*/} 下载Docker Compose..."
        
        # 使用curl下载，设置超时和重试
        if curl -L --connect-timeout 10 --max-time 600 --retry 5 --retry-delay 3 \
            --retry-max-time 0 --progress-bar "$url" -o /tmp/docker-compose-download; then
            
            # 验证下载的文件
            if [ -s /tmp/docker-compose-download ]; then
                # 检查文件类型
                if file /tmp/docker-compose-download | grep -q "executable\|ELF"; then
                    log_success "Docker Compose下载成功！"
                    mv /tmp/docker-compose-download /usr/local/bin/docker-compose
                    download_success=true
                    break
                else
                    log_warning "下载的文件不是可执行文件，尝试下一个源..."
                    rm -f /tmp/docker-compose-download
                fi
            else
                log_warning "下载的文件为空，尝试下一个源..."
                rm -f /tmp/docker-compose-download
            fi
        else
            log_warning "从该源下载失败，尝试下一个源..."
            rm -f /tmp/docker-compose-download
        fi
        
        # 在尝试下一个源之前稍作等待
        sleep 2
    done
    
    # 如果所有下载都失败，尝试使用包管理器安装
    if [ "$download_success" = false ]; then
        log_warning "所有下载源都失败，尝试使用包管理器安装..."
        
        if [ -f /etc/alinux-release ] || grep -q "Alibaba Cloud Linux" /etc/os-release 2>/dev/null || [ -f /etc/centos-release ]; then
            # 阿里云Linux或CentOS系统，尝试使用pip安装
            log_info "在CentOS/Alinux系统上使用pip安装docker-compose..."
            yum install -y python3-pip
            pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple docker-compose
            download_success=true
        elif [ -f /etc/debian_version ]; then
            # Ubuntu/Debian系统，尝试使用apt安装
            log_info "在Ubuntu/Debian系统上使用apt安装docker-compose..."
            apt-get update
            apt-get install -y docker-compose
            download_success=true
        fi
    fi
    
    # 如果成功下载了二进制文件，设置权限
    if [ "$download_success" = true ] && [ -f "/usr/local/bin/docker-compose" ]; then
        # 添加执行权限
        chmod +x /usr/local/bin/docker-compose
        
        # 创建软链接到/usr/bin/
        if [ ! -f /usr/bin/docker-compose ]; then
            ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        fi
    fi
    
    # 最终验证安装
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        local installed_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
        log_success "Docker Compose安装成功 (版本: $installed_version)"
    else
        log_error "Docker Compose安装失败，请手动安装"
        log_info "手动安装命令:"
        log_info "sudo curl -L https://get.daocloud.io/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose"
        log_info "sudo chmod +x /usr/local/bin/docker-compose"
        return 1
    fi
    
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
    
    # 安装Docker
    if ! install_docker; then
        log_error "Docker安装失败，退出脚本"
        exit 1
    fi
    
    # 安装Docker Compose
    if ! install_docker_compose; then
        log_error "Docker Compose安装失败，但继续其他步骤"
        log_warning "您可能需要手动安装Docker Compose"
    fi
    
    configure_firewall
    create_app_directory
    configure_system_optimization
    install_monitoring
    
    log_success "服务器环境初始化完成！"
    
    # 最终检查
    log_info "最终检查安装状态..."
    if command -v docker &> /dev/null; then
        log_success "✓ Docker: $(docker --version)"
    else
        log_error "✗ Docker: 未安装或不可用"
    fi
    
    if command -v docker-compose &> /dev/null; then
        log_success "✓ Docker Compose: $(docker-compose --version)"
    else
        log_warning "✗ Docker Compose: 未安装或不可用"
        log_info "您可以手动运行以下命令安装:"
        log_info "  curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        log_info "  chmod +x /usr/local/bin/docker-compose"
    fi
    
    log_info "请重新登录以使用户组更改生效"
    log_info "然后您可以部署应用了"
}

# 执行主函数
main "$@"