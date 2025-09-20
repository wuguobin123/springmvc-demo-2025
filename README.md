# SpringMVC Demo Project

这是一个基于Spring Boot的标准三层架构SpringMVC项目，严格按照控制层、逻辑层、数据层的结构实现，并为后续接入中间件做好扩展准备。

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