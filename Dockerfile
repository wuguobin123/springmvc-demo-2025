# 使用官方OpenJDK 17镜像作为基础镜像
FROM openjdk:17-jdk-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"
ENV PROFILE=prod

# 安装必要的系统工具
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制Maven构建文件
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .

# 下载依赖（利用Docker缓存）
RUN ./mvnw dependency:go-offline -B

# 复制源代码
COPY src src

# 构建应用
RUN ./mvnw clean package -DskipTests

# 创建非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

# 创建日志目录
RUN mkdir -p /var/log/springmvc-demo && chown -R appuser:appuser /var/log/springmvc-demo

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

# 启动应用
CMD java $JAVA_OPTS -Dspring.profiles.active=$PROFILE -jar target/springmvc-demo-1.0.0.jar