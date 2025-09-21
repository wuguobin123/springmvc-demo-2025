#!/bin/bash

# 阿里云Docker环境配置脚本
# 用于解决Docker镜像拉取失败问题

echo "=== 阿里云Docker环境配置 ==="

# 1. 配置Docker镜像源
echo "1. 配置Docker镜像源..."
sudo mkdir -p /etc/docker

# 检查docker-daemon.json是否存在
if [ ! -f "docker-daemon.json" ]; then
    echo "❌ docker-daemon.json 文件不存在！"
    echo "📁 当前目录: $(pwd)"
    echo "📋 目录内容:"
    ls -la
    exit 1
fi

# 备份现有配置（如果存在）
if [ -f "/etc/docker/daemon.json" ]; then
    echo "📋 备份现有Docker配置..."
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
fi

# 应用新配置
sudo cp docker-daemon.json /etc/docker/daemon.json
echo "✅ Docker镜像源配置已更新"

# 2. 重启Docker服务
echo "2. 重启Docker服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 等待Docker服务完全启动
echo "⏳ 等待Docker服务启动..."
sleep 5

# 3. 验证Docker配置
echo "3. 验证Docker配置..."
echo "🔍 检查Docker服务状态..."
if ! systemctl is-active --quiet docker; then
    echo "❌ Docker服务未运行，尝试启动..."
    sudo systemctl start docker
fi

echo "🔍 检查镜像加速器配置..."
docker info | grep -A 10 "Registry Mirrors" || echo "⚠️ 无法获取Registry Mirrors信息"

echo "🔍 检查Docker版本..."
docker --version

# 4. 清理Docker缓存（可选）
echo "4. 清理Docker缓存..."
docker system prune -f

# 5. 测试拉取Redis镜像
echo "5. 测试拉取Redis镜像..."
if ! docker image inspect registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine > /dev/null 2>&1; then
    echo "📥 拉取Redis镜像..."
    docker pull registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine
else
    echo "✅ Redis镜像已存在，跳过拉取"
fi

echo "=== 配置完成 ==="
echo "现在可以运行: ./deploy/deploy.sh"
