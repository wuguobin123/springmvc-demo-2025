#!/bin/bash

# 加载.env文件
if [ -f .env ]; then
    echo "🔧 加载.env文件..."
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ .env文件加载成功"
    echo "🔍 SILICONFLOW_API_KEY: ${SILICONFLOW_API_KEY:+已设置}"
else
    echo "⚠️ .env文件不存在"
fi

# 构建并启动应用
JAR=$(ls -1 target/*.jar 2>/dev/null | grep -v 'original' | head -n 1)

if [ ! -f "$JAR" ]; then
    echo "🔨 未找到可执行jar，开始构建..."
    ./mvnw -q -DskipTests package || { echo "❌ 构建失败"; exit 1; }
    JAR=$(ls -1 target/*.jar 2>/dev/null | grep -v 'original' | head -n 1)
fi

if [ -z "$JAR" ]; then
    echo "❌ 未找到可执行jar，请检查构建输出"
    exit 1
fi

PORT=${PORT:-8080}
echo "🚀 启动Spring Boot应用: $JAR 于端口 $PORT"
exec env PORT="$PORT" java -jar "$JAR"
