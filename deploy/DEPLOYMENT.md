# 阿里云服务器部署指南

## 部署前准备

### 1. 服务器环境初始化

在阿里云ECS服务器上运行以下命令初始化环境：

```bash
# 下载并运行服务器初始化脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/javaweb/main/deploy/init-server.sh -o init-server.sh
chmod +x init-server.sh
sudo ./init-server.sh
```

或者手动上传 `init-server.sh` 脚本到服务器并运行：

```bash
sudo ./deploy/init-server.sh
```

### 2. 配置环境变量

复制环境变量配置文件：

```bash
cp env.example .env
```

编辑 `.env` 文件，填入实际的配置值：

```bash
vi .env
```

**重要配置项：**
- `SILICONFLOW_API_KEY`: SiliconFlow AI API密钥（必填）
- `DB_PASSWORD`: 数据库密码
- `MYSQL_ROOT_PASSWORD`: MySQL root密码
- `REDIS_PASSWORD`: Redis密码
- `RABBITMQ_PASSWORD`: RabbitMQ密码

## 部署步骤

### 1. 上传项目文件

将项目文件上传到服务器的 `/opt/springmvc-demo` 目录：

```bash
# 创建目录
sudo mkdir -p /opt/springmvc-demo
sudo chown -R $USER:$USER /opt/springmvc-demo

# 上传项目文件（使用scp或其他方式）
scp -r ./* user@your-server:/opt/springmvc-demo/
```

### 2. 运行部署脚本

```bash
cd /opt/springmvc-demo
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

### 3. 验证部署

部署完成后，可以通过以下方式验证：

```bash
# 检查容器状态
docker compose ps

# 检查应用健康状态
curl http://localhost:8080/api/health

# 查看应用日志
docker compose logs -f springmvc-app
```

## 访问地址

- **应用主页**: http://your-server-ip:8080
- **健康检查**: http://your-server-ip:8080/api/health
- **RabbitMQ管理界面**: http://your-server-ip:15672 (admin/admin123)

## 监控和维护

### 1. 设置自动监控

添加监控脚本到crontab：

```bash
# 编辑crontab
crontab -e

# 添加以下行（每5分钟检查一次）
*/5 * * * * /opt/springmvc-demo/deploy/monitor.sh
```

### 2. 查看日志

```bash
# 应用日志
docker compose logs -f springmvc-app

# 系统监控日志
tail -f /var/log/springmvc-demo-monitor.log
```

### 3. 常用运维命令

```bash
# 重启应用
docker compose restart springmvc-app

# 重启所有服务
docker compose restart

# 查看资源使用情况
docker stats

# 备份数据库
docker exec mysql-db mysqldump -u root -p springmvc_demo > backup_$(date +%Y%m%d).sql
```

## 防火墙配置

如果使用阿里云安全组，请确保开放以下端口：

- 80/tcp (HTTP)
- 443/tcp (HTTPS，如果配置SSL)
- 8080/tcp (应用端口)
- 3306/tcp (MySQL，可选，仅在需要外部连接时)
- 6379/tcp (Redis，可选，仅在需要外部连接时)
- 15672/tcp (RabbitMQ管理界面)

## SSE服务配置

为了确保SSE（Server-Sent Events）服务正常工作，需要进行以下配置：

### 1. Nginx配置

在Nginx配置文件中，需要为SSE端点添加特殊配置：

```nginx
# SSE流式输出配置
location /api/ai/stream {
    proxy_pass http://springmvc_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Accept text/event-stream;
    proxy_set_header X-Accel-Buffering no;
    
    # SSE特定配置
    proxy_http_version 1.1;
    proxy_set_header Connection '';
    
    # 关闭缓冲以支持流式传输
    proxy_buffering off;
    
    # 设置超时时间以维持长连接
    proxy_connect_timeout 1s;
    proxy_send_timeout 10s;
    proxy_read_timeout 3600s;
}
```

### 2. MCP SSE服务配置

项目还包含MCP SSE服务，需要为以下端点配置特殊处理：

```nginx
# MCP SSE端点配置
location /api/mcp/sse {
    proxy_pass http://springmvc_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Accept text/event-stream;
    proxy_set_header X-Accel-Buffering no;
    
    # SSE特定配置
    proxy_http_version 1.1;
    proxy_set_header Connection '';
    
    # 关闭缓冲以支持流式传输
    proxy_buffering off;
    
    # 设置超时时间以维持长连接
    proxy_connect_timeout 1s;
    proxy_send_timeout 10s;
    proxy_read_timeout 86400s;

# MCP消息端点配置
location /api/mcp/message {
    proxy_pass http://springmvc_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Accept text/event-stream;
    proxy_set_header X-Accel-Buffering no;
    
    # SSE特定配置
    proxy_http_version 1.1;
    proxy_set_header Connection '';
    
    # 关闭缓冲以支持流式传输
    proxy_buffering off;
    
    # 设置超时时间以维持长连接
    proxy_connect_timeout 1s;
    proxy_send_timeout 10s;
    proxy_read_timeout 86400s;
}
```

关键配置说明：
- `proxy_buffering off` - 关闭代理缓冲，确保数据实时传输
- `proxy_http_version 1.1` - 使用HTTP/1.1以支持长连接
- `proxy_set_header Connection ''` - 清除连接头以保持长连接
- `proxy_read_timeout 86400s` - 设置长超时时间以维持长连接（24小时）

### 3. 阿里云安全组配置

确保阿里云安全组规则允许以下端口的访问：
- 入方向：80端口（HTTP）
- 入方向：443端口（如果启用HTTPS）

## 故障排除

### 1. 容器启动失败

```bash
# 查看详细错误信息
docker compose logs springmvc-app

# 检查容器状态
docker compose ps -a
```

### 2. 数据库连接失败

```bash
# 检查MySQL容器
docker compose logs mysql

# 测试数据库连接
docker exec -it mysql-db mysql -u springmvc_user -p springmvc_demo
```

### 3. 应用健康检查失败

```bash
# 检查应用日志
docker compose logs -f springmvc-app

# 手动测试健康检查端点
curl -v http://localhost:8080/api/health
```

## 更新部署

```bash
# 拉取最新代码
git pull

# 重新构建并部署
./deploy/deploy.sh
```

## 安全建议

1. 修改默认密码（数据库、Redis、RabbitMQ）
2. 配置SSL证书（生产环境）
3. 限制数据库端口的外部访问
4. 定期备份数据
5. 监控系统资源使用情况
6. 配置日志轮转避免磁盘空间不足
