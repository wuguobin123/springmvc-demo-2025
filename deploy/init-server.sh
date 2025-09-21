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

# 检测系统类型
detect_system() {
    if [ -f /etc/alinux-release ]; then
        # 阿里云Linux
        ALINUX_VERSION=$(grep 'Alibaba Cloud Linux' /etc/alinux-release | grep -oE '[0-9]+' | head -n1)
        if [ "$ALINUX_VERSION" = "3" ]; then
            SYSTEM_TYPE="alinux3"
            log_info "检测到Alibaba Cloud Linux 3系统"
        else
            SYSTEM_TYPE="alinux2"
            log_info "检测到Alibaba Cloud Linux 2系统"
        fi
    elif grep -q "Alibaba Cloud Linux" /etc/os-release 2>/dev/null; then
        if grep -q "Alibaba Cloud Linux 3" /etc/os-release; then
            SYSTEM_TYPE="alinux3"
            log_info "检测到Alibaba Cloud Linux 3系统"
        else
            SYSTEM_TYPE="alinux2"
            log_info "检测到Alibaba Cloud Linux 2系统"
        fi
    elif [ -f /etc/anolis-release ]; then
        SYSTEM_TYPE="anolis"
        log_info "检测到Anolis OS系统"
    elif [ -f /etc/redhat-release ] && grep -q "Red Hat" /etc/redhat-release; then
        SYSTEM_TYPE="rhel"
        log_info "检测到Red Hat Enterprise Linux系统"
    elif [ -f /etc/fedora-release ]; then
        SYSTEM_TYPE="fedora"
        log_info "检测到Fedora系统"
    elif [ -f /etc/centos-release ]; then
        SYSTEM_TYPE="centos"
        log_info "检测到CentOS系统"
    elif [ -f /etc/debian_version ]; then
        if grep -q "Ubuntu" /etc/os-release; then
            SYSTEM_TYPE="ubuntu"
            log_info "检测到Ubuntu系统"
        else
            SYSTEM_TYPE="debian"
            log_info "检测到Debian系统"
        fi
    else
        log_error "不支持的操作系统"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_info "更新系统软件包..."
    
    case $SYSTEM_TYPE in
        alinux3)
            dnf update -y
            dnf install -y curl wget git vim dnf-utils ca-certificates
            ;;
        alinux2|centos|rhel|anolis)
            yum update -y
            yum install -y curl wget git vim yum-utils ca-certificates
            ;;
        fedora)
            dnf update -y
            dnf install -y curl wget git vim dnf-utils ca-certificates
            ;;
        ubuntu|debian)
            apt-get update
            apt-get upgrade -y
            apt-get install -y curl wget git vim ca-certificates gnupg lsb-release apt-transport-https software-properties-common
            ;;
        *)
            log_error "不支持的系统类型: $SYSTEM_TYPE"
            exit 1
            ;;
    esac
    
    log_success "系统更新完成"
}

# 卸载旧版Docker
uninstall_old_docker() {
    log_info "卸载旧版本Docker..."
    
    case $SYSTEM_TYPE in
        alinux3|fedora)
            # 删除Docker相关源
            rm -f /etc/yum.repos.d/docker*.repo
            # 卸载Docker和相关的软件包
            dnf -y remove docker-ce containerd.io docker-ce-rootless-extras \
                docker-buildx-plugin docker-ce-cli docker-compose-plugin \
                docker docker-client docker-client-latest docker-common \
                docker-latest docker-latest-logrotate docker-logrotate docker-engine
            ;;
        alinux2|centos|rhel|anolis)
            # 删除Docker相关源
            rm -f /etc/yum.repos.d/docker*.repo
            # 卸载Docker和相关的软件包
            yum -y remove docker-ce containerd.io docker-ce-rootless-extras \
                docker-buildx-plugin docker-ce-cli docker-compose-plugin \
                docker docker-client docker-client-latest docker-common \
                docker-latest docker-latest-logrotate docker-logrotate docker-engine
            ;;
        ubuntu|debian)
            # 删除Docker相关源
            rm -f /etc/apt/sources.list.d/*docker*.list
            # 卸载Docker和相关的软件包
            for pkg in docker.io docker-buildx-plugin docker-ce-cli docker-ce-rootless-extras \
                      docker-compose-plugin docker-doc docker-compose podman-docker containerd runc \
                      docker docker-engine docker.io containerd runc; do
                apt-get remove -y $pkg 2>/dev/null || true
            done
            ;;
    esac
    
    # 清理Docker数据目录（可选）
    if [ -d "/var/lib/docker" ]; then
        log_warning "发现Docker数据目录 /var/lib/docker，如需完全清理请手动删除"
    fi
    
    log_success "旧版本Docker卸载完成"
}

# 安装Docker
install_docker() {
    log_info "安装Docker..."
    
    # 检查Docker是否已安装且可用
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        local version=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_warning "Docker已安装 (版本: $version)，跳过安装步骤"
        return
    fi
    
    # 先卸载旧版本
    uninstall_old_docker
    
    # 根据系统类型安装Docker
    case $SYSTEM_TYPE in
        alinux3)
            log_info "在Alibaba Cloud Linux 3上安装Docker..."
            # 添加Docker软件包源
            wget -O /etc/yum.repos.d/docker-ce.repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/centos/docker-ce.repo
            sed -i 's|https://mirrors.aliyun.com|http://mirrors.cloud.aliyuncs.com|g' /etc/yum.repos.d/docker-ce.repo
            # Alibaba Cloud Linux3专用的dnf源兼容插件
            dnf -y install dnf-plugin-releasever-adapter --repo alinux3-plus
            # 安装Docker社区版本，容器运行时containerd.io，以及Docker构建和Compose插件
            dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        alinux2)
            log_info "在Alibaba Cloud Linux 2上安装Docker..."
            # 添加Docker软件包源
            wget -O /etc/yum.repos.d/docker-ce.repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/centos/docker-ce.repo
            sed -i 's|https://mirrors.aliyun.com|http://mirrors.cloud.aliyuncs.com|g' /etc/yum.repos.d/docker-ce.repo
            # 安装Docker
            yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos)
            log_info "在CentOS上安装Docker..."
            yum install -y yum-utils
            yum-config-manager --add-repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/centos/docker-ce.repo
            yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        rhel)
            log_info "在Red Hat Enterprise Linux上安装Docker..."
            # 添加Docker软件包源
            wget -O /etc/yum.repos.d/docker-ce.repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/rhel/docker-ce.repo
            sed -i 's|https://mirrors.aliyun.com|http://mirrors.cloud.aliyuncs.com|g' /etc/yum.repos.d/docker-ce.repo
            yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        fedora)
            log_info "在Fedora上安装Docker..."
            # 添加Docker软件包源
            wget -O /etc/yum.repos.d/docker-ce.repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/fedora/docker-ce.repo
            sed -i 's|https://mirrors.aliyun.com|http://mirrors.cloud.aliyuncs.com|g' /etc/yum.repos.d/docker-ce.repo
            dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        anolis)
            log_info "在Anolis OS上安装Docker..."
            # 添加Docker软件包源
            wget -O /etc/yum.repos.d/docker-ce.repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/centos/docker-ce.repo
            sed -i 's|https://mirrors.aliyun.com|http://mirrors.cloud.aliyuncs.com|g' /etc/yum.repos.d/docker-ce.repo
            yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        ubuntu)
            log_info "在Ubuntu上安装Docker..."
            # 更新包管理工具
            apt-get update
            # 添加Docker软件包源
            curl -fsSL http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu/gpg | apt-key add -
            add-apt-repository -y "deb [arch=$(dpkg --print-architecture)] http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
            # 安装Docker
            apt-get update
            apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        debian)
            log_info "在Debian上安装Docker..."
            # 更新包管理工具
            apt-get update
            # 添加Docker软件包源
            curl -fsSL http://mirrors.cloud.aliyuncs.com/docker-ce/linux/debian/gpg | apt-key add -
            add-apt-repository -y "deb [arch=$(dpkg --print-architecture)] http://mirrors.cloud.aliyuncs.com/docker-ce/linux/debian $(lsb_release -cs) stable"
            # 安装Docker
            apt-get update
            apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            log_error "不支持的系统类型: $SYSTEM_TYPE"
            return 1
            ;;
    esac
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 添加当前用户到docker组
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        log_info "已将用户 $SUDO_USER 添加到docker组"
    else
        usermod -aG docker $USER
        log_info "已将当前用户添加到docker组"
    fi
    
    log_success "Docker安装完成"
}

# 验证Docker Compose插件
verify_docker_compose() {
    log_info "验证Docker Compose插件..."
    
    # 检查Docker Compose插件是否可用
    if docker compose version &> /dev/null; then
        local version=$(docker compose version --short 2>/dev/null || docker compose version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1 | sed 's/v//')
        log_success "Docker Compose插件已安装 (版本: $version)"
        return 0
    fi
    
    # 如果插件不可用，尝试手动安装
    log_warning "Docker Compose插件不可用，尝试手动安装..."
    
    # 检查插件目录是否存在
    if [ ! -d "/usr/local/lib/docker/cli-plugins" ]; then
        mkdir -p /usr/local/lib/docker/cli-plugins
    fi
    
    # 定义Docker Compose版本
    DOCKER_COMPOSE_VERSION="v2.21.0"
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    # 定义多个下载源（优先使用国内镜像）
    declare -a DOWNLOAD_URLS=(
        "https://ghproxy.com/https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
        "https://mirror.ghproxy.com/https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
        "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
    )
    
    # 尝试下载Docker Compose插件
    download_success=false
    for url in "${DOWNLOAD_URLS[@]}"; do
        log_info "尝试从 GitHub 下载Docker Compose插件..."
        
        if curl -L --connect-timeout 10 --max-time 300 --retry 3 --retry-delay 3 \
            "$url" -o /usr/local/lib/docker/cli-plugins/docker-compose; then
            
            # 验证下载的文件
            if [ -s /usr/local/lib/docker/cli-plugins/docker-compose ]; then
                # 设置权限
                chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
                
                # 测试插件是否工作
                if docker compose version &> /dev/null; then
                    local version=$(docker compose version --short 2>/dev/null || echo "unknown")
                    log_success "Docker Compose插件安装成功 (版本: $version)"
                    download_success=true
                    break
                else
                    log_warning "插件下载完成但无法正常工作，尝试下一个源..."
                    rm -f /usr/local/lib/docker/cli-plugins/docker-compose
                fi
            else
                log_warning "下载的文件为空，尝试下一个源..."
                rm -f /usr/local/lib/docker/cli-plugins/docker-compose
            fi
        else
            log_warning "从该源下载失败，尝试下一个源..."
        fi
        
        sleep 2
    done
    
    # 如果插件安装失败，检查是否有独立的docker-compose
    if [ "$download_success" = false ]; then
        log_warning "Docker Compose插件安装失败，检查独立版本..."
        
        if command -v docker-compose &> /dev/null; then
            local version=$(docker-compose --version | awk '{print $3}' | sed 's/,//' | head -n1)
            log_warning "发现独立版本的Docker Compose (版本: $version)"
            log_info "建议使用 'docker compose' 命令替代 'docker-compose'"
            return 0
        else
            log_error "Docker Compose未安装且插件安装失败"
            log_info "您可以手动安装Docker Compose插件:"
            log_info "  mkdir -p /usr/local/lib/docker/cli-plugins"
            log_info "  curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose"
            log_info "  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose"
            return 1
        fi
    fi
    
    return 0
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

# 配置Docker
configure_docker() {
    log_info "配置Docker..."
    
    # 创建Docker配置目录
    mkdir -p /etc/docker
    
    # 配置Docker daemon.json（针对中国用户优化）
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "http://mirrors.cloud.aliyuncs.com",
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
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "0.0.0.0:9323",
  "default-address-pools": [
    {
      "base": "172.30.0.0/16",
      "size": 24
    }
  ]
}
EOF
    
    # 重新加载Docker配置
    systemctl daemon-reload
    systemctl restart docker
    
    # 验证Docker配置
    if docker info >/dev/null 2>&1; then
        log_success "Docker配置完成并验证成功"
    else
        log_warning "Docker配置完成但验证失败，请检查配置"
    fi
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
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.panic_on_oom = 0

# 文件系统优化
fs.file-max = 2097152
fs.nr_open = 2097152
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
    log_info "脚本基于阿里云官方文档优化: https://help.aliyun.com/zh/ecs/use-cases/install-and-use-docker"
    
    # 检查root权限
    check_root
    
    # 检测系统类型
    detect_system
    
    # 更新系统
    update_system
    
    # 安装Docker
    if ! install_docker; then
        log_error "Docker安装失败，退出脚本"
        exit 1
    fi
    
    # 配置Docker
    configure_docker
    
    # 验证Docker Compose插件
    if ! verify_docker_compose; then
        log_warning "Docker Compose插件验证失败，但继续其他步骤"
    fi
    
    # 配置防火墙
    configure_firewall
    
    # 创建应用目录
    create_app_directory
    
    # 配置系统优化
    configure_system_optimization
    
    # 安装监控工具
    install_monitoring
    
    log_success "服务器环境初始化完成！"
    
    # 最终检查
    log_info "\n最终检查安装状态..."
    echo "========================================"
    
    # 检查Docker
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_success "✓ Docker: $docker_version"
        
        # 检查Docker服务状态
        if systemctl is-active --quiet docker; then
            log_success "✓ Docker服务: 运行中"
        else
            log_error "✗ Docker服务: 未运行"
        fi
    else
        log_error "✗ Docker: 未安装或不可用"
    fi
    
    # 检查Docker Compose
    if docker compose version &> /dev/null 2>&1; then
        local compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        log_success "✓ Docker Compose (插件): $compose_version"
    elif command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version | awk '{print $3}' | sed 's/,//' | head -n1)
        log_warning "✓ Docker Compose (独立版本): $compose_version"
        log_info "  建议使用 'docker compose' 命令替代 'docker-compose'"
    else
        log_error "✗ Docker Compose: 未安装或不可用"
        log_info "  您可以手动安装Docker Compose插件:"
        log_info "    mkdir -p /usr/local/lib/docker/cli-plugins"
        log_info "    curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose"
        log_info "    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose"
    fi
    
    # 检查防火墙
    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        log_success "✓ 防火墙: firewalld 运行中"
    elif command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        log_success "✓ 防火墙: ufw 已启用"
    else
        log_warning "! 防火墙: 状态未知或未配置"
    fi
    
    # 检查应用目录
    if [ -d "/opt/springmvc-demo" ]; then
        log_success "✓ 应用目录: /opt/springmvc-demo"
    else
        log_error "✗ 应用目录: 创建失败"
    fi
    
    echo "========================================"
    
    log_info "\n重要提示:"
    log_warning "1. 请重新登录SSH以使用户组更改生效（docker组）"
    log_info "2. 现在您可以部署Spring MVC应用了"
    log_info "3. 使用 'docker compose' 命令管理容器（推荐）"
    log_info "4. 应用部署目录: /opt/springmvc-demo"
    
    if [ -n "$SUDO_USER" ]; then
        log_info "5. 已将用户 $SUDO_USER 添加到docker组"
    fi
    
    log_info "\n快速测试Docker安装:"
    log_info "  docker run --rm hello-world"
    log_info "  docker compose version"
}

# 执行主函数
main "$@"