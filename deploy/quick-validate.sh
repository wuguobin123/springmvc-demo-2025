#!/bin/bash

# 部署脚本快速验证工具
# 专注于验证部署脚本的基本功能和语法

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 部署脚本快速验证"
echo "项目: $(basename "$PROJECT_ROOT")"
echo "时间: $(date)"
echo ""

# 1. 验证脚本文件
log_info "1. 检查部署脚本文件..."
scripts=(
    "deploy.sh:主部署脚本"
    "deploy-light.sh:轻量化部署脚本"
    "deploy-minimal.sh:最小化部署脚本"
    "init-server.sh:服务器初始化脚本"
    "monitor.sh:监控脚本"
)

script_errors=0
for script_info in "${scripts[@]}"; do
    script="${script_info%%:*}"
    desc="${script_info#*:}"
    script_path="$SCRIPT_DIR/$script"
    
    if [ -f "$script_path" ]; then
        if bash -n "$script_path" 2>/dev/null; then
            if [ -x "$script_path" ]; then
                log_success "$desc ✓"
            else
                log_warning "$desc (缺少执行权限)"
            fi
        else
            log_error "$desc (语法错误)"
            ((script_errors++))
        fi
    else
        log_error "$desc (文件不存在)"
        ((script_errors++))
    fi
done

# 2. 验证Docker配置
log_info "2. 检查Docker配置文件..."
config_errors=0

if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    if grep -q "FROM" "$PROJECT_ROOT/Dockerfile"; then
        log_success "Dockerfile ✓"
    else
        log_error "Dockerfile 格式错误"
        ((config_errors++))
    fi
else
    log_error "Dockerfile 不存在"
    ((config_errors++))
fi

compose_files=("docker-compose.yml" "docker-compose-light.yml")
for file in "${compose_files[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        if grep -q "version:" "$PROJECT_ROOT/$file" && grep -q "services:" "$PROJECT_ROOT/$file"; then
            log_success "$file ✓"
        else
            log_error "$file 格式错误"
            ((config_errors++))
        fi
    else
        log_warning "$file 不存在"
    fi
done

# 3. 验证环境配置
log_info "3. 检查环境配置..."
env_errors=0

if [ -f "$PROJECT_ROOT/.env.example" ]; then
    required_vars=("DB_HOST" "DB_PASSWORD" "REDIS_HOST" "SILICONFLOW_API_KEY")
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" "$PROJECT_ROOT/.env.example"; then
            log_success "环境变量 $var ✓"
        else
            log_warning "环境变量 $var 缺失"
        fi
    done
else
    log_error ".env.example 不存在"
    ((env_errors++))
fi

# 4. 验证应用配置
log_info "4. 检查应用配置..."
app_errors=0

app_configs=("application.yml" "application-prod.yml")
for config in "${app_configs[@]}"; do
    config_path="$PROJECT_ROOT/src/main/resources/$config"
    if [ -f "$config_path" ]; then
        if grep -q "spring:" "$config_path"; then
            log_success "$config ✓"
        else
            log_warning "$config 格式可能有问题"
        fi
    else
        log_error "$config 不存在"
        ((app_errors++))
    fi
done

# 5. 验证Maven配置
log_info "5. 检查Maven配置..."
maven_errors=0

if [ -f "$PROJECT_ROOT/pom.xml" ]; then
    if grep -q "<groupId>" "$PROJECT_ROOT/pom.xml" && grep -q "<artifactId>" "$PROJECT_ROOT/pom.xml"; then
        log_success "pom.xml ✓"
    else
        log_error "pom.xml 格式错误"
        ((maven_errors++))
    fi
else
    log_error "pom.xml 不存在"
    ((maven_errors++))
fi

# 6. 验证工具可用性
log_info "6. 检查部署工具..."
tools_warnings=0

tools=("java:Java" "mvn:Maven" "git:Git" "curl:cURL")
for tool_info in "${tools[@]}"; do
    tool="${tool_info%%:*}"
    name="${tool_info#*:}"
    
    if command -v "$tool" &> /dev/null; then
        log_success "$name ✓"
    else
        log_warning "$name 未安装"
        ((tools_warnings++))
    fi
done

# Docker检查（可选）
if command -v docker &> /dev/null; then
    log_success "Docker ✓"
    if docker info &> /dev/null 2>&1; then
        log_success "Docker 服务运行中 ✓"
    else
        log_warning "Docker 服务未运行"
    fi
else
    log_info "Docker 未安装（容器化部署需要）"
fi

# 7. 生成验证结果
echo ""
echo "========== 验证结果 =========="

total_errors=$((script_errors + config_errors + env_errors + app_errors + maven_errors))

if [ $total_errors -eq 0 ]; then
    if [ $tools_warnings -eq 0 ]; then
        echo -e "${GREEN}✅ 所有检查通过！部署脚本完全就绪。${NC}"
        echo ""
        echo "🚀 可以执行的部署命令："
        echo "   ./deploy/deploy.sh deploy prod latest"
        echo "   ./deploy/deploy-light.sh"
        echo "   ./deploy/deploy-minimal.sh"
        exit_code=0
    else
        echo -e "${YELLOW}⚠️  基本检查通过，但建议安装缺失的工具。${NC}"
        echo ""
        echo "🔧 建议安装的工具："
        [ $tools_warnings -gt 0 ] && echo "   - Docker (用于容器化部署)"
        exit_code=0
    fi
else
    echo -e "${RED}❌ 发现 $total_errors 个错误，请修复后重试！${NC}"
    echo ""
    echo "🔧 需要修复的问题："
    [ $script_errors -gt 0 ] && echo "   - 部署脚本问题: $script_errors 个"
    [ $config_errors -gt 0 ] && echo "   - Docker配置问题: $config_errors 个"
    [ $env_errors -gt 0 ] && echo "   - 环境配置问题: $env_errors 个"
    [ $app_errors -gt 0 ] && echo "   - 应用配置问题: $app_errors 个"
    [ $maven_errors -gt 0 ] && echo "   - Maven配置问题: $maven_errors 个"
    exit_code=1
fi

echo ""
echo "📚 详细文档："
echo "   - DEPLOYMENT.md: 完整部署指南"
echo "   - QUICK_DEPLOY.md: 快速部署指南"
echo "   - DEPLOYMENT_VALIDATION.md: 验证详细说明"

exit $exit_code