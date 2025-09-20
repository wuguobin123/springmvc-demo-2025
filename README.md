# SpringMVC Demo 项目

基于Spring Boot的分层架构Web应用，展示现代Java Web开发的最佳实践。

## 📋 项目简介

这是一个使用Spring Boot 2.7.16构建的企业级Web应用示例，采用经典的分层架构模式，包含用户管理功能，支持RESTful API。

## 🏗️ 技术栈

- **后端框架**: Spring Boot 2.7.16
- **Web框架**: Spring MVC
- **数据访问**: Spring Data JPA + Hibernate
- **数据库**: H2 (开发环境) / MySQL (生产环境)
- **连接池**: Druid
- **缓存**: Redis (可选)
- **消息队列**: RabbitMQ (可选)
- **构建工具**: Maven
- **Java版本**: 17

## 📁 项目结构

```
src/main/java/com/example/springmvc/
├── common/                 # 公共组件
│   ├── exception/         # 异常处理
│   ├── response/          # 统一响应格式
│   └── utils/             # 工具类
├── config/                # 配置类
├── controller/            # 控制器层
├── dto/                   # 数据传输对象
├── entity/                # 实体类
├── repository/            # 数据访问层
├── service/               # 业务逻辑层
└── SpringMvcApplication.java  # 启动类
```

## 🚀 快速开始

### 环境要求

- Java 17+
- Maven 3.6+

### 启动应用

1. 克隆项目
```bash
git clone https://github.com/wuguobin123/springmvc-demo-2025.git
cd springmvc-demo-2025
```

2. 启动应用
```bash
./mvnw spring-boot:run
```

3. 访问应用
- 应用地址: http://localhost:8080/api
- H2控制台: http://localhost:8080/api/h2-console
  - JDBC URL: `jdbc:h2:mem:testdb`
  - 用户名: `sa`
  - 密码: (空)

## 📡 API接口

### 健康检查
```
GET /api/health
```

### 用户管理
```
GET    /api/users           # 获取用户列表（分页）
POST   /api/users           # 创建用户
GET    /api/users/{id}      # 获取用户详情
PUT    /api/users/{id}      # 更新用户
DELETE /api/users/{id}      # 删除用户
```

### 示例请求

创建用户:
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "realName": "测试用户",
    "phone": "13800138000",
    "password": "123456"
  }'
```

## 🔧 配置说明

### 环境配置

- `application.yml`: 主配置文件
- `application-dev.yml`: 开发环境配置
- `application-prod.yml`: 生产环境配置

### 数据库配置

开发环境使用H2内存数据库，生产环境可配置MySQL:

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/springmvc_demo
    username: root
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
```

## 📝 开发特性

- ✅ 统一异常处理
- ✅ 统一响应格式
- ✅ 参数校验
- ✅ 分页查询
- ✅ 密码加密
- ✅ 开发热重载
- ✅ API文档（Swagger可选）
- ✅ 单元测试支持

## 📊 项目状态

- 🟢 **运行状态**: 正常
- 🟢 **构建状态**: 通过
- 🟢 **测试覆盖**: 待完善

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 联系方式

- 项目链接: [https://github.com/wuguobin123/springmvc-demo-2025](https://github.com/wuguobin123/springmvc-demo-2025)
- 问题反馈: [Issues](https://github.com/wuguobin123/springmvc-demo-2025/issues)