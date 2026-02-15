#!/bin/bash

mkdir -p config/{workspace,pairing,extensions,skills}

# 生成设备令牌
DEVICE_TOKEN=$(openssl rand -hex 32)
echo "{\"token\":\"$DEVICE_TOKEN\",\"createdAt\":\"$(date -Iseconds)\"}" > config/pairing/device.json

echo "✅ 初始化完成"
echo "请设置环境变量：export QVERIS_API_KEY=your-api-key"
echo "然后运行：docker-compose up -d"