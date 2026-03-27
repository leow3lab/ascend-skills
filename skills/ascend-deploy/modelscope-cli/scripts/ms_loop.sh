#!/bin/bash

# ModelScope 循环重试脚本
# 用于网络不稳定时自动重试下载任务

set -e

SCRIPT=$1

# 检查参数
if [ -z "$SCRIPT" ]; then
    echo "用法: $0 <脚本路径>"
    echo "示例: $0 scripts/run_ms_model_download.sh"
    exit 1
fi

# 检查脚本文件是否存在
if [ ! -f "$SCRIPT" ]; then
    echo "错误: 脚本文件不存在: $SCRIPT"
    exit 1
fi

RETRY_COUNT=0

while true; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "========================================"
    echo "第 ${RETRY_COUNT} 次尝试执行: $SCRIPT"
    echo "========================================"

    set +e  # 允许命令失败
    bash ${SCRIPT}
    EXIT_CODE=$?
    set -e

    if [ $EXIT_CODE -eq 0 ]; then
        echo "========================================"
        echo "✅ 执行成功！共尝试 ${RETRY_COUNT} 次"
        echo "========================================"
        break  # 成功时退出循环
    else
        echo "⚠️ 执行失败，退出码: $EXIT_CODE"
        echo "等待 5 秒后重试..."
        sleep 5  # 失败后等待 5 秒再重试
    fi
done