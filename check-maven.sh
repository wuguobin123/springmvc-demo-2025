#!/bin/bash

# 检查Docker容器中Maven安装状态的脚本

echo "🔍 检查Docker容器中的Maven安装状态"
echo "===================================="

# 1. 检查容器是否运行
CONTAINER_NAME="springmvc-demo-minimal"
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ 容器 $CONTAINER_NAME 正在运行"
    
    # 2. 检查Maven版本
    echo "📦 检查Maven版本..."
    docker exec $CONTAINER_NAME mvn --version 2>/dev/null && echo "✅ Maven已安装" || echo "❌ Maven未安装"
    
    # 3. 检查Maven路径
    echo "📍 检查Maven安装路径..."
    docker exec $CONTAINER_NAME which mvn 2>/dev/null && echo "✅ 找到Maven路径" || echo "❌ 未找到Maven"
    
    # 4. 检查Maven配置
    echo "⚙️  检查Maven配置..."
    docker exec $CONTAINER_NAME cat ~/.m2/settings.xml 2>/dev/null | head -5 && echo "✅ Maven配置存在" || echo "❌ Maven配置不存在"
    
else
    echo "❌ 容器 $CONTAINER_NAME 未运行"
    echo "尝试启动容器..."
    docker compose -f docker-compose-minimal.yml up -d springmvc-app
    
    echo "等待容器启动..."
    sleep 10
    
    # 重新检查
    if docker ps | grep -q $CONTAINER_NAME; then
        echo "✅ 容器启动成功，重新检查Maven..."
        docker exec $CONTAINER_NAME mvn --version 2>/dev/null && echo "✅ Maven已安装" || echo "❌ Maven未安装"
    else
        echo "❌ 容器启动失败"
    fi
fi

echo ""
echo "📋 其他检查方法："
echo "1. 手动进入容器: docker exec -it $CONTAINER_NAME bash"
echo "2. 在容器内运行: mvn --version"
echo "3. 检查构建日志: docker compose -f docker-compose-minimal.yml logs springmvc-app"