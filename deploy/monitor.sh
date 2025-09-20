#!/bin/bash

# 自动监控和重启脚本
# 可以通过crontab定时执行

PROJECT_NAME="springmvc-demo"
LOG_FILE="/var/log/${PROJECT_NAME}-monitor.log"
HEALTH_URL="http://localhost:8080/api/health"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# 检查应用健康状态
check_health() {
    if curl -f -s $HEALTH_URL > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 重启应用
restart_app() {
    log "应用健康检查失败，开始重启..."
    
    cd /opt/springmvc-demo
    
    # 重启容器
    docker-compose restart springmvc-app
    
    # 等待启动
    sleep 30
    
    # 再次检查
    if check_health; then
        log "应用重启成功"
    else
        log "应用重启失败，需要人工介入"
        # 可以在这里添加通知逻辑，比如发送邮件或钉钉消息
    fi
}

# 主逻辑
main() {
    if ! check_health; then
        restart_app
    else
        log "应用运行正常"
    fi
}

# 执行
main