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

# 启动应用
echo "🚀 启动Spring Boot应用..."
java -jar target/springmvc-demo-1.0.0.jar
