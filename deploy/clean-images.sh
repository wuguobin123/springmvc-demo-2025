#!/bin/bash

# 清理Docker镜像脚本
# 用于删除项目相关的缓存镜像，方便重新构建

set -e

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 切换到项目根目录
cd "$PROJECT_DIR"

echo "🧹 开始清理Docker镜像缓存..."
echo "📁 项目目录: $PROJECT_DIR"

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 停止所有相关容器
echo "🛑 停止所有相关容器..."
docker compose down 2>/dev/null || true

# 删除所有相关容器（包括停止的）
echo "🗑️ 删除所有相关容器..."
docker compose rm -f 2>/dev/null || true

# 定义要删除的镜像列表
IMAGES=(
    "springmvc-demo-springmvc-app"
    "springmvc-demo:aliyun-stable"
    "springmvc-demo-springmvc-demo"
)

# 删除项目相关镜像
echo "🗑️ 删除项目相关镜像..."
for image in "${IMAGES[@]}"; do
    if docker image inspect "$image" > /dev/null 2>&1; then
        echo "🗑️ 删除镜像: $image"
        docker rmi -f "$image" 2>/dev/null || echo "⚠️ 无法删除镜像: $image"
    else
        echo "ℹ️ 镜像不存在，跳过: $image"
    fi
done

# 删除所有悬空镜像（dangling images）
echo "🗑️ 删除悬空镜像..."
dangling_images=$(docker images -f "dangling=true" -q)
if [ -n "$dangling_images" ]; then
    echo "🗑️ 删除悬空镜像: $dangling_images"
    docker rmi -f $dangling_images 2>/dev/null || true
else
    echo "ℹ️ 没有悬空镜像"
fi

# 删除未使用的镜像（可选，谨慎使用）
read -p "🤔 是否删除所有未使用的镜像？这可能会删除其他项目的镜像 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️ 删除所有未使用的镜像..."
    docker image prune -a -f
else
    echo "ℹ️ 跳过删除未使用的镜像"
fi

# 清理构建缓存
echo "🗑️ 清理Docker构建缓存..."
docker builder prune -f

# 显示清理结果
echo "📊 清理完成，当前镜像列表:"
docker images | grep -E "(springmvc|REPOSITORY)" || echo "ℹ️ 没有找到项目相关镜像"

echo "✅ 镜像清理完成！"
echo "💡 现在可以运行 ./deploy/deploy.sh 重新构建和部署"
