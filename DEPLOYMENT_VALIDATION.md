# 部署脚本验证指南

本文档详细介绍如何验证生成的部署脚本是否正常工作。

## 🎯 验证目标

确保部署脚本能够：
- 正确构建和部署应用
- 处理各种环境配置
- 提供错误恢复能力
- 满足生产环境要求

## 🛠️ 验证工具

项目提供了自动化验证工具：`deploy/validate-deployment.sh`

### 快速验证
```bash
# 运行完整验证
cd /path/to/your/project
./deploy/validate-deployment.sh

# 显示详细输出
./deploy/validate-deployment.sh -v

# 查看帮助
./deploy/validate-deployment.sh -h
```

## 📋 验证检查清单

### 1. 脚本语法验证

**检查项目：**
- [ ] 所有shell脚本语法正确
- [ ] 脚本具有适当的权限
- [ ] 脚本头部包含正确的shebang

**手动验证：**
```bash
# 检查语法
bash -n deploy/deploy.sh
bash -n deploy/deploy-light.sh
bash -n deploy/init-server.sh
bash -n deploy/monitor.sh

# 检查权限
ls -la deploy/*.sh
```

### 2. Docker配置验证

**检查项目：**
- [ ] Dockerfile语法正确
- [ ] Docker Compose文件配置有效
- [ ] 镜像构建测试通过
- [ ] 端口配置无冲突

**手动验证：**
```bash
# 验证Dockerfile
docker build --dry-run .

# 验证Docker Compose
docker-compose config
docker-compose -f docker-compose-light.yml config
docker-compose -f docker-compose-cloud.yml config

# 测试镜像构建
docker build -t test-build .
docker rmi test-build
```

### 3. 环境配置验证

**检查项目：**
- [ ] 环境变量模板完整
- [ ] 必需变量已定义
- [ ] 默认值合理
- [ ] 密码强度要求

**手动验证：**
```bash
# 检查环境变量模板
cat .env.example

# 验证必需变量
grep -E "^(DB_|REDIS_|RABBITMQ_|SILICONFLOW_)" .env.example
```

### 4. 应用配置验证

**检查项目：**
- [ ] Spring配置文件语法正确
- [ ] 不同环境配置完整
- [ ] 数据库连接配置正确
- [ ] 日志配置合理

**手动验证：**
```bash
# 检查YAML语法（需要Python）
python3 -c "
import yaml
with open('src/main/resources/application.yml') as f:
    yaml.safe_load(f)
print('✅ YAML语法正确')
"
```

### 5. 系统资源验证

**检查项目：**
- [ ] 内存需求满足
- [ ] 磁盘空间充足
- [ ] 网络端口可用
- [ ] 依赖服务可访问

**手动验证：**
```bash
# 检查内存
free -h

# 检查磁盘空间
df -h

# 检查端口占用
netstat -tlnp | grep -E ":(8080|3306|6379|5672|80) "

# 检查Docker服务
docker info
```

## 🧪 分步验证流程

### 步骤1：语法预检查
```bash
# 运行语法检查
find deploy/ -name "*.sh" -exec bash -n {} \;

# 检查关键文件
ls -la deploy/
ls -la docker/
ls -la src/main/resources/
```

### 步骤2：依赖环境检查
```bash
# 检查Docker
docker --version
docker-compose --version

# 检查系统资源
echo "内存: $(free -h | awk 'NR==2{print $2}')"
echo "CPU: $(nproc)核"
echo "磁盘: $(df -h . | awk 'NR==2{print $4}')"
```

### 步骤3：配置文件验证
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑必要配置
vim .env

# 验证配置
docker-compose config > /dev/null && echo "✅ 配置正确"
```

### 步骤4：构建测试
```bash
# 测试镜像构建
docker build -t validation-test .

# 测试容器启动
docker run --rm -d --name test-container validation-test

# 检查容器状态
docker ps | grep test-container

# 清理测试容器
docker stop test-container
docker rmi validation-test
```

### 步骤5：部署干运行
```bash
# 使用轻量化模式测试
./deploy/deploy-light.sh

# 检查服务状态
docker-compose ps

# 健康检查
curl -f http://localhost:8080/api/health

# 清理测试环境
docker-compose down
```

## 🔍 常见问题诊断

### 问题1：脚本权限错误
```bash
# 症状
-bash: ./deploy.sh: Permission denied

# 解决
chmod +x deploy/*.sh
```

### 问题2：Docker镜像构建失败
```bash
# 检查原因
docker build . 2>&1 | grep -i error

# 常见解决方案
# 1. 检查Dockerfile语法
# 2. 确认基础镜像可用
# 3. 检查网络连接
# 4. 清理Docker缓存
docker system prune -f
```

### 问题3：端口冲突
```bash
# 检查端口占用
netstat -tlnp | grep :8080

# 解决方案
# 1. 停止占用端口的进程
# 2. 修改docker-compose.yml中的端口映射
# 3. 使用不同的端口
```

### 问题4：内存不足
```bash
# 检查内存使用
free -h
docker stats

# 解决方案
# 1. 使用轻量化部署模式
# 2. 调整JVM内存参数
# 3. 优化Docker Compose配置
```

### 问题5：环境变量缺失
```bash
# 检查缺失的变量
docker-compose config 2>&1 | grep -i "variable"

# 解决方案
# 1. 检查.env文件
# 2. 补充缺失的环境变量
# 3. 使用默认值
```

## 🎯 生产环境验证

### 安全性检查
- [ ] 移除默认密码
- [ ] 配置SSL证书
- [ ] 限制管理端口访问
- [ ] 启用防火墙规则

### 性能验证
- [ ] 压力测试通过
- [ ] 内存使用在合理范围
- [ ] 响应时间满足要求
- [ ] 数据库连接池配置合理

### 监控验证
- [ ] 健康检查正常
- [ ] 日志输出正常
- [ ] 监控脚本工作
- [ ] 告警机制有效

## 📊 验证报告示例

```
========== 部署脚本验证报告 ==========
验证时间: 2024-01-20 10:30:00

✅ 脚本语法检查: 通过
✅ Docker配置验证: 通过
✅ 环境变量检查: 通过
✅ 应用配置验证: 通过
⚠️  端口配置检查: 端口8080已占用
✅ 系统资源检查: 通过
✅ 构建测试: 通过
✅ 监控脚本验证: 通过
✅ Nginx配置验证: 通过

成功项目: 8
警告项目: 1
错误项目: 0

✅ 部署脚本验证通过，可以安全部署！
```

## 🚀 自动化验证集成

### CI/CD集成
```yaml
# .github/workflows/validate-deployment.yml
name: Validate Deployment Scripts
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate Deployment
        run: ./deploy/validate-deployment.sh
```

### 定期验证
```bash
# 添加到crontab
0 2 * * 0 /opt/springmvc-demo/deploy/validate-deployment.sh > /var/log/validation.log 2>&1
```

## 📝 最佳实践

1. **验证频率**
   - 每次修改部署脚本后验证
   - 部署前必须验证
   - 定期进行完整验证

2. **验证环境**
   - 在测试环境充分验证
   - 与生产环境尽可能相似
   - 考虑不同的资源配置

3. **问题处理**
   - 记录所有验证结果
   - 建立问题处理流程
   - 持续改进验证工具

4. **团队协作**
   - 验证结果共享
   - 建立验证标准
   - 培训团队成员

---

使用这个验证指南，你可以确保部署脚本在各种环境下都能正常工作！