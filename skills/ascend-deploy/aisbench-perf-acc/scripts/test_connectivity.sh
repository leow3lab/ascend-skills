#!/bin/bash
# 测试 AISBench 推理服务连通性
# 用法：./test_connectivity.sh <host_ip> <host_port> [api_key]

set -e

HOST_IP="${1:-localhost}"
HOST_PORT="${2:-8080}"
API_KEY="${3:-}"

echo "🔍 测试推理服务连通性..."
echo "   地址：http://${HOST_IP}:${HOST_PORT}/v1/models"

if [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer ${API_KEY}" \
        "http://${HOST_IP}:${HOST_PORT}/v1/models")
else
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        "http://${HOST_IP}:${HOST_PORT}/v1/models")
fi

# 分离响应体和状态码
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n-1)

echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 连接成功！"
    echo ""
    echo "响应摘要:"
    echo "$RESPONSE_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"  模型数：{len(d.get('data',[]))}\")" 2>/dev/null || echo "$RESPONSE_BODY"
    exit 0
elif [ "$HTTP_CODE" = "401" ]; then
    echo "❌ 认证失败：API Key 错误或缺失"
    echo "   状态码：$HTTP_CODE"
    echo "   响应：$RESPONSE_BODY"
    exit 1
elif [ "$HTTP_CODE" = "000" ]; then
    echo "❌ 无法连接到服务"
    echo "   可能原因："
    echo "   - 服务未启动"
    echo "   - IP 地址或端口错误"
    echo "   - 防火墙阻止连接"
    exit 1
else
    echo "⚠️  服务响应异常"
    echo "   状态码：$HTTP_CODE"
    echo "   响应：$RESPONSE_BODY"
    exit 1
fi
