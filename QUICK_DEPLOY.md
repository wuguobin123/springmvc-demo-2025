# SpringMVC Demo 快速部署指南

如果你想快速部署到阿里云，请按照以下步骤操作：

## 🚀 快速开始

### 1. 准备阿里云ECS
- 购买一台ECS实例（推荐2核4G配置）
- 配置安全组开放端口：22, 80, 8080
- 记录公网IP地址

### 2. 初始化服务器
```bash
# SSH连接到服务器
ssh root@your-server-ip

# 下载并执行初始化脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/springmvc-demo/main/deploy/init-server.sh | bash

# 重新登录
exit && ssh root@your-server-ip
```

### 3. 部署应用
```bash
# 克隆项目
git clone https://github.com/your-repo/springmvc-demo.git /opt/springmvc-demo
cd /opt/springmvc-demo

# 配置环境变量
cp .env.example .env
# 编辑.env文件，至少修改数据库密码和API密钥

# 一键部署
./deploy/deploy.sh deploy prod latest
```

### 4. 验证部署
```bash
# 检查应用状态
curl http://localhost:8080/api/health

# 如果返回 {"status":"UP"} 则部署成功
```

### 5. 访问应用
在浏览器中访问：`http://your-server-ip/api/health`

## 🔧 环境变量配置

最少需要配置的环境变量：
```bash
# .env文件
DB_PASSWORD=YourStrongPassword123
REDIS_PASSWORD=YourRedisPassword123  
RABBITMQ_PASSWORD=YourRabbitMQPassword123
SILICONFLOW_API_KEY=your-actual-api-key
```

## 📋 常用命令

```bash
# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f springmvc-app

# 重启应用
docker-compose restart springmvc-app

# 停止应用
docker-compose down

# 完全重新部署
./deploy/deploy.sh deploy prod latest
```

## 🚨 问题排查

如果部署失败，请检查：
1. 服务器内存是否足够（至少2GB）
2. 端口是否被占用
3. Docker服务是否正常运行
4. 环境变量是否正确配置

查看详细日志：
```bash
docker-compose logs springmvc-app
```

---

详细部署文档请参考：[DEPLOYMENT.md](DEPLOYMENT.md)