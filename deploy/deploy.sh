#!/bin/bash

# 阿里云稳定版部署脚本
# 使用系统Maven，避免Maven Wrapper网络问题

set -e

echo "🚀 开始阿里云稳定版部署..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 检查docker-compose是否可用
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ docker-compose未安装，请先安装docker-compose"
    exit 1
fi

# 设置环境变量
export COMPOSE_PROJECT_NAME=springmvc-demo
export DOCKER_BUILDKIT=1

echo "📦 构建Docker镜像（使用稳定版Dockerfile）..."
docker build -f Dockerfile.aliyun-stable -t springmvc-demo:aliyun-stable .

if [ $? -ne 0 ]; then
    echo "❌ Docker镜像构建失败"
    exit 1
fi

echo "✅ Docker镜像构建成功"

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose -f docker-compose.yml down 2>/dev/null || true

# 启动服务
echo "🚀 启动服务..."
docker-compose -f docker-compose.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.yml ps

# 检查应用健康状态
echo "🏥 检查应用健康状态..."
for i in {1..30}; do
    if curl -f http://localhost:8080/api/health > /dev/null 2>&1; then
        echo "✅ 应用启动成功！"
        echo "🌐 访问地址: http://localhost:8080"
        echo "📊 健康检查: http://localhost:8080/api/health"
        break
    else
        echo "⏳ 等待应用启动... ($i/30)"
        sleep 2
    fi
done

# 显示日志
echo "📋 显示应用日志..."
docker-compose -f docker-compose.yml logs --tail=20

echo "🎉 部署完成！"
