#!/bin/bash

# 阿里云稳定版部署脚本
# 使用系统Maven，避免Maven Wrapper网络问题

set -e

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 切换到项目根目录
cd "$PROJECT_DIR"

echo "🚀 开始阿里云稳定版部署..."
echo "📁 项目目录: $PROJECT_DIR"

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 检查docker compose是否可用
if ! docker compose version > /dev/null 2>&1; then
    echo "❌ docker compose未安装，请先安装docker compose插件"
    exit 1
fi

# 预拉取必要的镜像（避免网络超时问题）
echo "📥 检查并预拉取必要的Docker镜像..."

# 检查并拉取MySQL镜像
echo "🔍 检查MySQL镜像..."
if ! docker image inspect him7zrbc.mirror.aliyuncs.com/library/mysql:8.0 > /dev/null 2>&1; then
    echo "📥 拉取MySQL镜像..."
    docker pull him7zrbc.mirror.aliyuncs.com/library/mysql:8.0 || {
        echo "⚠️ MySQL镜像拉取失败，尝试使用官方镜像..."
        docker pull mysql:8.0
    }
else
    echo "✅ MySQL镜像已存在，跳过拉取"
fi

# 检查并拉取Redis镜像
echo "🔍 检查Redis镜像..."
if ! docker image inspect him7zrbc.mirror.aliyuncs.com/library/redis:alpine > /dev/null 2>&1; then
    echo "📥 拉取Redis镜像..."
    docker pull him7zrbc.mirror.aliyuncs.com/library/redis:alpine || {
        echo "⚠️ Redis镜像拉取失败，尝试使用官方镜像..."
        docker pull redis:alpine
    }
else
    echo "✅ Redis镜像已存在，跳过拉取"
fi

# 检查并拉取RabbitMQ镜像
echo "🔍 检查RabbitMQ镜像..."
if ! docker image inspect him7zrbc.mirror.aliyuncs.com/library/rabbitmq:3.8-management > /dev/null 2>&1; then
    echo "📥 拉取RabbitMQ镜像..."
    docker pull him7zrbc.mirror.aliyuncs.com/library/rabbitmq:3.8-management || {
        echo "⚠️ RabbitMQ镜像拉取失败，尝试使用官方镜像..."
        docker pull rabbitmq:3.8-management
    }
else
    echo "✅ RabbitMQ镜像已存在，跳过拉取"
fi

# 检查并拉取Nginx镜像
echo "🔍 检查Nginx镜像..."
if ! docker image inspect him7zrbc.mirror.aliyuncs.com/library/nginx:1.21-alpine > /dev/null 2>&1; then
    echo "📥 拉取Nginx镜像..."
    docker pull him7zrbc.mirror.aliyuncs.com/library/nginx:1.21-alpine || {
        echo "⚠️ Nginx镜像拉取失败，尝试使用官方镜像..."
        docker pull nginx:1.21-alpine
    }
else
    echo "✅ Nginx镜像已存在，跳过拉取"
fi

echo "✅ 镜像检查完成"

# 设置环境变量
export COMPOSE_PROJECT_NAME=springmvc-demo
export DOCKER_BUILDKIT=1

echo "📦 构建Docker镜像（使用稳定版Dockerfile）..."
echo "🔍 检查Dockerfile是否存在..."
if [ ! -f "Dockerfile.aliyun-stable" ]; then
    echo "❌ Dockerfile.aliyun-stable 文件不存在！"
    echo "📁 当前目录: $(pwd)"
    echo "📋 目录内容:"
    ls -la
    exit 1
fi

echo "✅ Dockerfile.aliyun-stable 文件存在，开始构建..."
docker build -f Dockerfile.aliyun-stable -t springmvc-demo:aliyun-stable .

if [ $? -ne 0 ]; then
    echo "❌ Docker镜像构建失败"
    exit 1
fi

echo "✅ Docker镜像构建成功"

# 停止现有容器
echo "🛑 停止现有容器..."
docker compose -f docker-compose.yml down 2>/dev/null || true

# 启动服务
echo "🚀 启动服务..."
docker compose -f docker-compose.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker compose -f docker-compose.yml ps

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
docker compose -f docker-compose.yml logs --tail=20

echo "🎉 部署完成！"
