#!/bin/bash

# 阿里云服务器Maven Wrapper问题一键修复脚本
# 解决 maven-wrapper.properties 不存在的问题

set -e

echo "🔧 阿里云服务器Docker构建问题修复"
echo "======================================="

# 1. 停止当前构建
echo "1. 停止当前容器..."
docker compose -f docker-compose-minimal.yml down 2>/dev/null || true

# 2. 清理问题镜像
echo "2. 清理构建缓存..."
docker system prune -f
docker builder prune -f

# 3. 配置Docker镜像加速器
echo "3. 配置Docker镜像加速器..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://mirrors.aliyun.com",
    "https://dockerproxy.com",
    "https://mirror.baidubce.com"
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

# 4. 重启Docker
echo "4. 重启Docker服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 5. 等待Docker重启
sleep 5

# 6. 验证Docker配置
echo "5. 验证Docker配置..."
if docker info | grep -q "mirrors.aliyun.com"; then
    echo "✅ Docker镜像源配置成功"
else
    echo "⚠️  Docker镜像源配置可能未生效"
fi

# 7. 使用修复后的配置启动
echo "6. 使用修复配置重新构建..."
docker compose -f docker-compose-minimal.yml build --no-cache springmvc-app

echo "7. 启动应用..."
docker compose -f docker-compose-minimal.yml up -d springmvc-app

# 8. 检查启动状态
echo "8. 检查应用状态..."
sleep 10

for i in {1..30}; do
    if curl -f http://localhost:8080/api/health >/dev/null 2>&1; then
        echo "✅ 应用启动成功！"
        PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
        echo "🎉 部署完成！"
        echo "访问地址: http://$PUBLIC_IP:8080"
        echo "健康检查: http://$PUBLIC_IP:8080/api/health"
        exit 0
    fi
    echo "等待应用启动... ($i/30)"
    sleep 2
done

echo "❌ 应用启动超时，查看日志："
docker compose -f docker-compose-minimal.yml logs springmvc-app

echo ""
echo "📋 手动调试命令："
echo "docker compose -f docker-compose-minimal.yml ps"
echo "docker compose -f docker-compose-minimal.yml logs springmvc-app"