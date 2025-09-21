#!/bin/bash

# 测试Docker构建脚本
# 用于验证Dockerfile.aliyun-stable是否可以正常构建

set -e

echo "🧪 测试Docker构建..."

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 当前目录: $(pwd)"
echo "📋 检查文件..."

# 检查必要文件
if [ ! -f "Dockerfile.aliyun-stable" ]; then
    echo "❌ Dockerfile.aliyun-stable 不存在"
    exit 1
fi

if [ ! -f "pom.xml" ]; then
    echo "❌ pom.xml 不存在"
    exit 1
fi

if [ ! -d "src" ]; then
    echo "❌ src 目录不存在"
    exit 1
fi

echo "✅ 所有必要文件都存在"

# 检查Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行"
    exit 1
fi

echo "✅ Docker运行正常"

# 尝试构建
echo "🚀 开始构建测试..."
docker build -f Dockerfile.aliyun-stable -t springmvc-demo:test .

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo "🧹 清理测试镜像..."
    docker rmi springmvc-demo:test
    echo "🎉 测试完成！"
else
    echo "❌ 构建失败"
    exit 1
fi
