# SpringMVC 最小化部署指南

## 🎯 当前配置
- ✅ Spring Boot 应用（AI服务调用）
- ✅ H2 内存数据库（开发环境）
- ✅ SiliconFlow AI 集成
- ❌ MySQL（已禁用，后续接入阿里云RDS）
- ❌ Redis（已禁用，后续接入阿里云Redis）
- ❌ RabbitMQ（已禁用，后续根据需要接入）

## 🚀 快速启动

### 方式1：Docker 部署（推荐）
```bash
# 1. 确保API密钥已配置
cat .env

# 2. 启动应用（仅SpringBoot）
./deploy/deploy-minimal.sh start

# 3. 启动应用（包含Nginx代理）
./deploy/deploy-minimal.sh start-nginx

# 4. 验证服务
curl http://localhost:8080/api/health
# 或
curl http://localhost/api/health  # 使用Nginx时
```

### 方式2：直接运行
```bash
# 1. 确保Java环境
java -version

# 2. 设置环境变量
export SILICONFLOW_API_KEY=your-api-key

# 3. 启动应用
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

## 📱 API 接口

### 健康检查
```bash
GET /api/health
```

### AI聊天接口
```bash
POST /api/ai/chat
Content-Type: application/json

{
  "message": "你好，世界！"
}
```

### 用户管理接口
```bash
# 获取用户列表
GET /api/users

# 创建用户
POST /api/users
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "realName": "测试用户",
  "phone": "13800138000",
  "password": "123456"
}
```

## 🔧 管理命令

```bash
# 查看服务状态
./deploy/deploy-minimal.sh status

# 查看应用日志
./deploy/deploy-minimal.sh logs

# 重启服务
./deploy/deploy-minimal.sh restart

# 停止服务
./deploy/deploy-minimal.sh stop
```

## 🌐 访问地址

- **应用直接访问**: http://localhost:8080/api/
- **Nginx代理访问**: http://localhost/api/
- **健康检查**: http://localhost:8080/api/health

## 📦 项目结构

```
├── src/main/java/com/example/springmvc/
│   ├── controller/          # 控制层
│   │   ├── AiChatController.java    # AI聊天接口
│   │   ├── UserController.java      # 用户管理接口
│   │   └── HealthController.java    # 健康检查接口
│   ├── service/             # 服务层
│   │   ├── AiChatService.java       # AI服务
│   │   └── UserService.java         # 用户服务
│   ├── entity/              # 实体层
│   │   └── User.java                # 用户实体
│   └── config/              # 配置层
│       ├── AiConfig.java            # AI配置（启用）
│       ├── RedisConfig.java         # Redis配置（禁用）
│       └── RabbitMQConfig.java      # RabbitMQ配置（禁用）
├── docker-compose-minimal.yml      # 最小化Docker配置
├── deploy/deploy-minimal.sh         # 最小化部署脚本
└── .env                            # 环境变量配置
```

## 🔄 后续扩展

### 接入阿里云数据库时：
1. 修改 `.env` 文件，取消数据库配置注释
2. 修改 `application.yml` 中数据源配置
3. 切换到 `prod` 环境配置

### 接入Redis缓存时：
1. 修改 `.env` 文件，取消Redis配置注释
2. 修改 `application.yml` 中Redis配置
3. Redis配置类会自动加载

### 接入消息队列时：
1. 修改 `.env` 文件，取消RabbitMQ配置注释
2. 修改 `application.yml` 中RabbitMQ配置
3. RabbitMQ配置类会自动加载

## 🚨 故障排除

### 应用启动失败
```bash
# 查看详细日志
docker compose -f docker-compose-minimal.yml logs springmvc-app

# 检查环境变量
cat .env

# 检查端口占用
netstat -tlnp | grep 8080
```

### API调用失败
1. 检查SILICONFLOW_API_KEY是否正确配置
2. 检查网络连接
3. 查看应用日志

---

**注意**: 当前配置为最小化版本，专注于AI服务调用。后续根据需要逐步接入阿里云服务。