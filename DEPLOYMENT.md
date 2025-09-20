# SpringMVC Demo 阿里云部署指南

本文档详细介绍如何将SpringMVC Demo项目部署到阿里云ECS服务器上。

## 📋 部署架构

```
用户请求 → 阿里云SLB → Nginx → Spring Boot应用
                            ↓
                      MySQL + Redis + RabbitMQ
```

## 🛠️ 准备工作

### 1. 阿里云资源准备

#### ECS实例
- **规格推荐**: ecs.c6.large (2核4G) 或更高
- **操作系统**: CentOS 7.x / Ubuntu 18.04+
- **磁盘**: 系统盘40GB + 数据盘100GB
- **网络**: 专有网络VPC，分配公网IP

#### 安全组配置
开放以下端口：
- 22 (SSH)
- 80 (HTTP)
- 8080 (应用端口)
- 3306 (MySQL，可选)
- 6379 (Redis，可选)
- 5672, 15672 (RabbitMQ，可选)

#### 可选云服务
- **RDS MySQL**: 生产环境推荐使用云数据库
- **Redis实例**: 推荐使用云Redis
- **SLB负载均衡**: 高可用部署时使用
- **ACR容器镜像服务**: 存储Docker镜像

### 2. 本地环境准备

确保本地已安装：
- Docker 20.10+
- Docker Compose 2.0+
- Git

## 🚀 部署步骤

### 第一步：服务器环境初始化

1. 连接到ECS服务器：
```bash
ssh root@your-server-ip
```

2. 下载并运行初始化脚本：
```bash
wget https://raw.githubusercontent.com/your-repo/springmvc-demo/main/deploy/init-server.sh
chmod +x init-server.sh
./init-server.sh
```

3. 重新登录使用户组更改生效：
```bash
exit
ssh root@your-server-ip
```

### 第二步：项目代码部署

1. 克隆项目到服务器：
```bash
cd /opt
git clone https://github.com/your-repo/springmvc-demo.git
cd springmvc-demo
```

2. 配置环境变量：
```bash
cp .env.example .env
vim .env
```

配置示例：
```bash
# 数据库配置
DB_HOST=mysql
DB_PORT=3306
DB_NAME=springmvc_demo
DB_USERNAME=springmvc_user
DB_PASSWORD=YourStrongPassword123

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=YourRedisPassword123

# RabbitMQ配置
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USERNAME=admin
RABBITMQ_PASSWORD=YourRabbitMQPassword123

# AI服务配置
SILICONFLOW_API_KEY=your-actual-api-key

# 阿里云容器镜像服务（可选）
ALIYUN_DOCKER_USERNAME=your-username
ALIYUN_DOCKER_PASSWORD=your-password
```

### 第三步：构建和部署

1. 使用部署脚本：
```bash
cd /opt/springmvc-demo
./deploy/deploy.sh deploy prod v1.0.0
```

2. 或者手动部署：
```bash
# 构建镜像
docker build -t springmvc-demo:latest .

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps
```

### 第四步：验证部署

1. 检查服务状态：
```bash
docker-compose ps
```

2. 查看应用日志：
```bash
docker-compose logs -f springmvc-app
```

3. 健康检查：
```bash
curl http://localhost:8080/api/health
```

4. 测试API：
```bash
# 创建用户
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "realName": "测试用户",
    "phone": "13800138000",
    "password": "123456"
  }'

# 获取用户列表
curl http://localhost:8080/api/users
```

## 🔧 生产环境优化

### 1. 使用云数据库

#### 云数据库RDS配置
```yaml
# docker-compose.yml 中移除 mysql 服务
# .env 文件中配置RDS连接信息
DB_HOST=rm-xxxxx.mysql.rds.aliyuncs.com
DB_PORT=3306
DB_NAME=springmvc_demo
DB_USERNAME=your_rds_username
DB_PASSWORD=your_rds_password
```

#### 云Redis配置
```yaml
# docker-compose.yml 中移除 redis 服务  
# .env 文件中配置云Redis信息
REDIS_HOST=r-xxxxx.redis.rds.aliyuncs.com
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
```

### 2. 负载均衡配置

如果使用多台ECS实例，配置SLB：

1. 创建SLB实例
2. 配置监听器：
   - 前端端口：80
   - 后端端口：80
   - 健康检查：HTTP /api/health
3. 添加后端服务器

### 3. SSL证书配置

```nginx
# docker/nginx/nginx.conf
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    location / {
        proxy_pass http://springmvc_backend;
        # ... 其他配置
    }
}

server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

## 📊 监控和维护

### 1. 应用监控

配置自动监控脚本：
```bash
# 添加到crontab
crontab -e

# 每5分钟检查一次
*/5 * * * * /opt/springmvc-demo/deploy/monitor.sh
```

### 2. 日志管理

查看各服务日志：
```bash
# 应用日志
docker-compose logs -f springmvc-app

# Nginx日志
docker-compose logs -f nginx

# 数据库日志（如果使用Docker）
docker-compose logs -f mysql
```

### 3. 数据备份

MySQL数据备份：
```bash
# 创建备份脚本
cat > /opt/backup-mysql.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec mysql mysqldump -u root -p$MYSQL_ROOT_PASSWORD springmvc_demo > /opt/backup/mysql_backup_$DATE.sql
# 保留最近7天的备份
find /opt/backup -name "mysql_backup_*.sql" -mtime +7 -delete
EOF

chmod +x /opt/backup-mysql.sh

# 添加到crontab，每天凌晨2点备份
0 2 * * * /opt/backup-mysql.sh
```

## 🔒 安全配置

### 1. 防火墙配置

```bash
# CentOS/RHEL
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# Ubuntu
ufw allow 80/tcp
ufw allow 8080/tcp
```

### 2. 应用安全

在 `application-prod.yml` 中配置：
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info  # 仅暴露必要的端点
  endpoint:
    health:
      show-details: never   # 不显示详细信息
```

## 🚨 故障排除

### 常见问题

1. **应用无法启动**
   ```bash
   # 查看详细日志
   docker-compose logs springmvc-app
   
   # 检查端口占用
   netstat -tlnp | grep 8080
   ```

2. **数据库连接失败**
   ```bash
   # 检查数据库容器状态
   docker-compose ps mysql
   
   # 测试数据库连接
   docker exec -it mysql mysql -u root -p
   ```

3. **内存不足**
   ```bash
   # 查看内存使用
   free -h
   
   # 调整JVM参数
   export JAVA_OPTS="-Xms256m -Xmx512m"
   ```

### 回滚操作

如果部署出现问题，可以快速回滚：
```bash
./deploy/deploy.sh rollback
```

## 📈 性能优化

### 1. JVM调优

在Dockerfile中配置：
```dockerfile
ENV JAVA_OPTS="-server -Xms1g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### 2. 数据库优化

MySQL配置调优：
```sql
-- 在MySQL中执行
SET GLOBAL innodb_buffer_pool_size = 1073741824;  -- 1GB
SET GLOBAL max_connections = 500;
```

### 3. Redis优化

Redis内存优化：
```redis
# redis.conf
maxmemory 512mb
maxmemory-policy allkeys-lru
```

## 🔄 更新部署

### 滚动更新

```bash
# 拉取最新代码
git pull origin main

# 重新构建和部署
./deploy/deploy.sh deploy prod v1.1.0

# 验证更新
curl http://localhost:8080/api/health
```

### 蓝绿部署

对于零停机部署，可以使用蓝绿部署策略：

1. 准备新的容器
2. 更新Nginx配置切换流量
3. 停止旧容器

## 📞 联系支持

如果在部署过程中遇到问题，请：

1. 查看日志文件
2. 检查环境配置
3. 参考故障排除章节
4. 联系技术支持

---

**注意**: 请根据实际情况调整配置参数，确保生产环境的安全性和稳定性。