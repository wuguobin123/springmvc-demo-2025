#!/bin/bash

# 阿里云快速部署脚本 - 本地构建版本
# 使用说明：./deploy-aliyun-fast.sh [服务器IP] [用户名]

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

# 参数检查
if [ $# -lt 2 ]; then
    log_error "使用方法: $0 <服务器IP> <用户名> [端口]"
    log_info "示例: $0 47.xxx.xxx.xxx root"
    log_info "示例: $0 47.xxx.xxx.xxx root 22"
    exit 1
fi

SERVER_IP="$1"
USERNAME="$2"
SSH_PORT="${3:-22}"

# 检查必要工具
check_requirements() {
    log_info "检查必要工具..."
    
    if ! command -v mvn &> /dev/null && ! [ -x "./mvnw" ]; then
        log_error "Maven或mvnw不可用，请确保已安装Maven或项目中存在mvnw"
        exit 1
    fi
    
    if ! command -v rsync &> /dev/null; then
        log_warning "rsync不可用，将使用scp传输文件（较慢）"
        USE_RSYNC=false
    else
        USE_RSYNC=true
    fi
    
    log_success "工具检查完成"
}

# 本地构建
build_locally() {
    log_info "开始本地构建..."
    
    # 使用mvnw如果存在，否则使用mvn
    if [ -x "./mvnw" ]; then
        MAVEN_CMD="./mvnw"
    else
        MAVEN_CMD="mvn"
    fi
    
    # 清理并构建
    $MAVEN_CMD clean package -DskipTests -q
    
    if [ ! -f "target/springmvc-demo-1.0.0.jar" ]; then
        log_error "构建失败，jar文件不存在"
        exit 1
    fi
    
    log_success "本地构建完成"
}

# 准备部署文件
prepare_deployment() {
    log_info "准备部署文件..."
    
    # 创建临时部署目录
    DEPLOY_DIR="/tmp/springmvc-deploy-$(date +%s)"
    mkdir -p "$DEPLOY_DIR"
    
    # 复制jar文件
    cp target/springmvc-demo-1.0.0.jar "$DEPLOY_DIR/"
    
    # 创建优化的Dockerfile
    cat > "$DEPLOY_DIR/Dockerfile" << 'EOF'
# 阿里云快速部署专用Dockerfile
FROM registry.cn-hangzhou.aliyuncs.com/library/openjdk:17-jre-slim

WORKDIR /app

# 设置环境变量
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
ENV PROFILE=dev

# 替换为阿里云源（加速）
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# 只安装curl
RUN apt-get update && apt-get install -y curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 复制jar文件
COPY springmvc-demo-1.0.0.jar app.jar

# 创建非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser && \
    chown appuser:appuser app.jar

# 切换用户
USER appuser

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

# 启动应用
CMD java $JAVA_OPTS -Dspring.profiles.active=$PROFILE -jar app.jar
EOF
    
    # 复制docker-compose配置
    cat > "$DEPLOY_DIR/docker-compose.yml" << 'EOF'
services:
  springmvc-app:
    build: .
    container_name: springmvc-demo-fast
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - SILICONFLOW_API_KEY=${SILICONFLOW_API_KEY}
      - AI_BASE_URL=https://api.siliconflow.cn/v1
      - AI_MODEL=Qwen/QwQ-32B
      - AI_TEMPERATURE=0.7
      - JAVA_OPTS=-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    mem_limit: 600m
    memswap_limit: 600m
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      timeout: 10s
      interval: 30s
      retries: 3
      start_period: 60s
EOF
    
    # 创建环境变量文件模板
    cat > "$DEPLOY_DIR/.env.example" << 'EOF'
# AI服务配置
SILICONFLOW_API_KEY=your_api_key_here

# 其他配置
COMPOSE_PROJECT_NAME=springmvc-demo
EOF
    
    log_success "部署文件准备完成: $DEPLOY_DIR"
}

# 传输文件到服务器
transfer_files() {
    log_info "传输文件到服务器..."
    
    # 检查SSH连接
    if ! ssh -p "$SSH_PORT" -o ConnectTimeout=10 "$USERNAME@$SERVER_IP" "echo 'SSH连接测试成功'" >/dev/null 2>&1; then
        log_error "无法连接到服务器 $USERNAME@$SERVER_IP:$SSH_PORT"
        exit 1
    fi
    
    # 在服务器上创建目录
    ssh -p "$SSH_PORT" "$USERNAME@$SERVER_IP" "mkdir -p /opt/springmvc-demo"
    
    # 传输文件
    if [ "$USE_RSYNC" = true ]; then
        rsync -avz -e "ssh -p $SSH_PORT" "$DEPLOY_DIR/" "$USERNAME@$SERVER_IP:/opt/springmvc-demo/"
    else
        scp -P "$SSH_PORT" -r "$DEPLOY_DIR/"* "$USERNAME@$SERVER_IP:/opt/springmvc-demo/"
    fi
    
    log_success "文件传输完成"
}

# 远程部署
deploy_remote() {
    log_info "在服务器上部署应用..."
    
    ssh -p "$SSH_PORT" "$USERNAME@$SERVER_IP" << 'EOF'
        cd /opt/springmvc-demo
        
        # 停止现有容器
        docker compose down 2>/dev/null || true
        
        # 清理旧镜像
        docker images | grep springmvc-demo | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
        
        # 检查环境变量文件
        if [ ! -f .env ]; then
            echo "创建.env文件..."
            cp .env.example .env
            echo "请编辑.env文件设置API密钥: vi .env"
        fi
        
        # 构建和启动
        echo "开始构建Docker镜像..."
        docker compose build --no-cache
        
        echo "启动应用..."
        docker compose up -d
        
        echo "检查容器状态..."
        sleep 10
        docker compose ps
        
        echo "检查应用健康状态..."
        for i in {1..30}; do
            if curl -f http://localhost:8080/api/health >/dev/null 2>&1; then
                echo "✅ 应用启动成功！"
                break
            fi
            echo "等待应用启动... ($i/30)"
            sleep 2
        done
        
        echo "部署完成！"
        echo "访问地址: http://$(curl -s ifconfig.me):8080"
EOF
    
    log_success "远程部署完成"
}

# 清理临时文件
cleanup() {
    if [ -n "$DEPLOY_DIR" ] && [ -d "$DEPLOY_DIR" ]; then
        rm -rf "$DEPLOY_DIR"
        log_info "清理临时文件完成"
    fi
}

# 主函数
main() {
    log_info "开始阿里云快速部署..."
    log_info "目标服务器: $USERNAME@$SERVER_IP:$SSH_PORT"
    
    # 设置清理函数
    trap cleanup EXIT
    
    # 检查环境
    check_requirements
    
    # 本地构建
    build_locally
    
    # 准备部署文件
    prepare_deployment
    
    # 传输文件
    transfer_files
    
    # 远程部署
    deploy_remote
    
    log_success "部署完成！"
    log_info "应用将在几分钟内可用"
    log_info "访问地址: http://$SERVER_IP:8080"
    log_info "健康检查: http://$SERVER_IP:8080/api/health"
    
    log_warning "注意: 请确保在服务器上设置正确的SILICONFLOW_API_KEY"
    log_info "编辑命令: ssh -p $SSH_PORT $USERNAME@$SERVER_IP 'cd /opt/springmvc-demo && vi .env'"
}

# 执行主函数
main "$@"