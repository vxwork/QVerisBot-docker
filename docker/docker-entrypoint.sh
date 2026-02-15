#!/bin/bash
set -e

# 检查必要的配置
if [ ! -f /root/.openclaw/openclaw.json ]; then
    echo "⚠️ 配置文件不存在，首次启动需要初始化配置..."
    # 创建默认配置目录
    mkdir -p /root/.openclaw/workspace
    mkdir -p /root/.openclaw/pairing
    
    # 生成设备令牌
    DEVICE_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n')
    echo "{\"token\":\"$DEVICE_TOKEN\",\"createdAt\":\"$(date -Iseconds)\"}" > /root/.openclaw/pairing/device.json
    
    echo "✅ 已生成设备令牌"
fi

# 如果命令是 gateway，则启动
if [ "$1" = "gateway" ]; then
    echo "🚀 启动 QVerisBot Gateway..."
    exec node dist/entry.js gateway run --bind loopback --verbose
fi

# 其他命令直接执行
exec "$@"