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

## 项目结构

```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── example/
│   │           └── springmvc/
│   │               ├── SpringMvcApplication.java     # 启动类
│   │               ├── config/                       # 配置类
│   │               │   ├── WebConfig.java           # Web配置
│   │               │   ├── DataSourceConfig.java    # 数据源配置
│   │               │   ├── RedisConfig.java         # Redis配置
│   │               │   └── RabbitMQConfig.java      # 消息队列配置
│   │               ├── controller/                   # 控制层
│   │               │   ├── UserController.java      # 用户控制器
│   │               │   └── HealthController.java    # 健康检查控制器
│   │               ├── service/                      # 逻辑层
│   │               │   ├── UserService.java         # 用户服务接口
│   │               │   └── impl/
│   │               │       └── UserServiceImpl.java # 用户服务实现
│   │               ├── repository/                   # 数据层
│   │               │   └── UserRepository.java      # 用户数据访问层
│   │               ├── entity/                       # 实体类
│   │               │   └── User.java                # 用户实体
│   │               ├── dto/                          # 数据传输对象
│   │               │   ├── UserCreateRequest.java   # 用户创建请求
│   │               │   ├── UserUpdateRequest.java   # 用户更新请求
│   │               │   └── UserResponse.java        # 用户响应
│   │               └── common/                       # 公共组件
│   │                   ├── exception/               # 异常处理
│   │                   │   ├── BusinessException.java
│   │                   │   ├── ResourceNotFoundException.java
│   │                   │   ├── ResourceExistsException.java
│   │                   │   └── GlobalExceptionHandler.java
│   │                   ├── response/                # 响应封装
│   │                   │   ├── ApiResponse.java     # 统一响应格式
│   │                   │   └── PageResponse.java    # 分页响应格式
│   │                   └── utils/                   # 工具类
│   │                       ├── BeanUtil.java        # Bean工具类
│   │                       └── PasswordUtil.java    # 密码工具类
│   └── resources/
│       ├── application.yml                          # 主配置文件
│       ├── application-dev.yml                      # 开发环境配置
│       ├── application-prod.yml                     # 生产环境配置
│       └── static/                                  # 静态资源
└── test/
    └── java/                                        # 测试代码
```

## 技术栈

- **Spring Boot 2.7.16**: 基础框架
- **Spring MVC**: Web框架
- **Spring Data JPA**: 数据访问层
- **MySQL**: 关系型数据库
- **Redis**: 缓存中间件
- **RabbitMQ**: 消息队列
- **Druid**: 数据库连接池
- **Lombok**: 简化代码
- **Jackson**: JSON处理
- **Validation**: 参数校验

## 快速开始

### 环境要求

- JDK 8+
- Maven 3.6+
- MySQL 5.7+
- Redis 6.0+
- RabbitMQ 3.8+

### 数据库初始化

1. 创建数据库：
```sql
CREATE DATABASE springmvc_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. 应用会自动创建表结构（通过JPA的DDL自动生成）

### 配置文件

修改 `src/main/resources/application-dev.yml` 中的数据库、Redis、RabbitMQ连接信息：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/springmvc_demo
    username: your_username
    password: your_password
  redis:
    host: localhost
    port: 6379
    password: your_redis_password
  rabbitmq:
    host: localhost
    port: 5672
    username: your_username
    password: your_password
```

### 启动应用

```bash
mvn spring-boot:run
```

或者：

```bash
mvn clean package
java -jar target/springmvc-demo-1.0.0.jar
```

### 验证启动

访问健康检查接口：
```
GET http://localhost:8080/api/health
```

## API接口

### 用户管理接口

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/users` | 创建用户 |
| GET | `/api/users/{id}` | 根据ID获取用户 |
| GET | `/api/users/username/{username}` | 根据用户名获取用户 |
| PUT | `/api/users/{id}` | 更新用户信息 |
| DELETE | `/api/users/{id}` | 删除用户 |
| GET | `/api/users` | 分页获取用户列表 |
| GET | `/api/users/all` | 获取所有用户 |
| GET | `/api/users/status/{status}` | 根据状态获取用户 |
| GET | `/api/users/search` | 搜索用户 |
| GET | `/api/users/check/username` | 检查用户名是否存在 |
| GET | `/api/users/check/email` | 检查邮箱是否存在 |
| POST | `/api/users/{id}/enable` | 启用用户 |
| POST | `/api/users/{id}/disable` | 禁用用户 |

### 请求示例

创建用户：
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "123456",
    "realName": "测试用户",
    "phone": "13888888888"
  }'
```

## 中间件扩展

### Redis使用示例

```java
@Autowired
private RedisTemplate<String, Object> redisTemplate;

// 设置缓存
redisTemplate.opsForValue().set("key", "value", 30, TimeUnit.MINUTES);

// 获取缓存
Object value = redisTemplate.opsForValue().get("key");
```

### RabbitMQ使用示例

发送消息：
```java
@Autowired
private RabbitTemplate rabbitTemplate;

// 发送消息
rabbitTemplate.convertAndSend(RabbitMQConfig.DEMO_EXCHANGE, 
                             RabbitMQConfig.DEMO_ROUTING_KEY, 
                             message);
```

接收消息：
```java
@RabbitListener(queues = RabbitMQConfig.DEMO_QUEUE)
public void handleMessage(String message) {
    // 处理消息
}
```

## 扩展指南

### 添加新的实体

1. 在 `entity` 包下创建实体类
2. 在 `repository` 包下创建Repository接口
3. 在 `dto` 包下创建相关的DTO类
4. 在 `service` 包下创建Service接口和实现类
5. 在 `controller` 包下创建Controller类

### 添加新的中间件

1. 在 `pom.xml` 中添加相关依赖
2. 在 `config` 包下创建配置类
3. 在 `application.yml` 中添加配置项

## 注意事项

1. 密码会自动进行SHA-256加密存储
2. 所有接口都有统一的异常处理和响应格式
3. 支持分页查询和关键字搜索
4. 数据库表会自动创建，无需手动建表
5. 开发环境和生产环境配置分离

## 开发规范

1. **分层架构**: 严格按照Controller -> Service -> Repository的调用顺序
2. **异常处理**: 使用统一的异常处理机制
3. **响应格式**: 所有接口返回统一的响应格式
4. **参数校验**: 使用注解进行参数校验
5. **日志记录**: 关键操作需要记录日志
6. **事务管理**: 写操作需要添加事务注解