#!/bin/bash

# 快速清理脚本 - 一键清理并重新部署
# 用于代码修改后的快速重新部署

set -e

echo "🚀 快速清理并重新部署..."

# 停止并删除所有容器
echo "🛑 停止并删除容器..."
docker compose down --rmi all --volumes --remove-orphans 2>/dev/null || true

# 删除项目相关镜像
echo "🗑️ 删除项目镜像..."
docker rmi -f springmvc-demo-springmvc-app 2>/dev/null || true
docker rmi -f springmvc-demo:aliyun-stable 2>/dev/null || true

# 清理构建缓存
echo "🧹 清理构建缓存..."
docker builder prune -f

# 重新构建并启动
echo "🔨 重新构建并启动..."
docker compose up --build -d

echo "✅ 快速清理部署完成！"
echo "🌐 访问地址: http://localhost:8080"
echo "🏥 健康检查: http://localhost:8080/api/health"
