#!/bin/bash
# ============================================
# Ascend Skills 开源前安全检查脚本
# 功能：扫描并自动修复敏感信息
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认扫描目录
SCAN_DIR="${1:-skills/}"
FIX_MODE="${2:-report}"  # report | fix

echo "=========================================="
echo "  Ascend Skills 开源前安全检查"
echo "  扫描目录: ${SCAN_DIR}"
echo "  模式: ${FIX_MODE}"
echo "=========================================="
echo ""

# 统计变量
INTERNAL_LINKS=0
SENSITIVE_IPS=0
HARDCODED_SECRETS=0
FIXED_COUNT=0

# 1. 检查华为内网链接
echo -e "${YELLOW}[1] 检查华为内网链接...${NC}"
LINK_PATTERNS=(
    "wiki\.huawei\.com"
    "3ms\.huawei\.com"
    "jx\.huawei\.com"
    "hub\.openlab-sh\.sd\.huawei\.com"
    "proxyhk\.huawei\.com"
    "mirrors\.tools\.huawei\.com"
    "w3\.huawei\.com"
)

for pattern in "${LINK_PATTERNS[@]}"; do
    FOUND=$(grep -rE "$pattern" "$SCAN_DIR" 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        COUNT=$(echo "$FOUND" | wc -l)
        INTERNAL_LINKS=$((INTERNAL_LINKS + COUNT))
        echo -e "  ${RED}发现 ${COUNT} 处: ${pattern}${NC}"
        echo "$FOUND" | head -5
        echo ""

        if [ "$FIX_MODE" == "fix" ]; then
            echo -e "  ${YELLOW}  → 移除内网链接...${NC}"
            grep -rlE "$pattern" "$SCAN_DIR" 2>/dev/null | while read file; do
                sed -i "s|https\?://${pattern}|<REMOVED_INTERNAL_LINK>|g" "$file"
                FIXED_COUNT=$((FIXED_COUNT + 1))
            done
        fi
    fi
done

# 2. 检查内部 IP
echo -e "${YELLOW}[2] 检查内部 IP 地址...${NC}"
# 华为内部 IP 段 100.64.0.0/10
INTERNAL_IP_PATTERN="100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}"

FOUND_IP=$(grep -rE "$INTERNAL_IP_PATTERN" "$SCAN_DIR" 2>/dev/null || true)
if [ -n "$FOUND_IP" ]; then
    COUNT=$(echo "$FOUND_IP" | wc -l)
    SENSITIVE_IPS=$((SENSITIVE_IPS + COUNT))
    echo -e "  ${RED}发现 ${COUNT} 处内部 IP${NC}"
    echo "$FOUND_IP" | head -5
    echo ""

    if [ "$FIX_MODE" == "fix" ]; then
        echo -e "  ${YELLOW}  → 替换为占位符...${NC}"
        grep -rlE "$INTERNAL_IP_PATTERN" "$SCAN_DIR" 2>/dev/null | while read file; do
            sed -i -E "s/${INTERNAL_IP_PATTERN}/<YOUR_SERVER_IP>/g" "$file"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        done
    fi
fi

# 3. 检查硬编码密码和密钥
echo -e "${YELLOW}[3] 检查硬编码密码和密钥...${NC}"
SECRET_PATTERN="(password|passwd|pwd|api_key|apikey|secret|token|access_key)\s*[=:]\s*['\"][^'\"]{8,}['\"]"

FOUND_SECRETS=$(grep -riE "$SECRET_PATTERN" "$SCAN_DIR" 2>/dev/null || true)
if [ -n "$FOUND_SECRETS" ]; then
    COUNT=$(echo "$FOUND_SECRETS" | wc -l)
    HARDCODED_SECRETS=$((HARDCODED_SECRETS + COUNT))
    echo -e "  ${RED}发现 ${COUNT} 处硬编码凭证${NC}"
    echo "$FOUND_SECRETS" | head -5
    echo ""
fi

# 4. 汇总报告
echo ""
echo "=========================================="
echo "  扫描报告"
echo "=========================================="
echo -e "  内网链接:     ${RED}${INTERNAL_LINKS}${NC} 处"
echo -e "  内部 IP:      ${RED}${SENSITIVE_IPS}${NC} 处"
echo -e "  硬编码凭证:   ${RED}${HARDCODED_SECRETS}${NC} 处"
echo "------------------------------------------"

TOTAL=$((INTERNAL_LINKS + SENSITIVE_IPS + HARDCODED_SECRETS))

if [ "$FIX_MODE" == "fix" ]; then
    echo -e "  已修复:      ${GREEN}${FIXED_COUNT}${NC} 处"
fi

if [ $TOTAL -eq 0 ]; then
    echo -e "  状态:        ${GREEN}✓ 通过安全检查${NC}"
    exit 0
else
    echo -e "  状态:        ${RED}✗ 存在安全风险${NC}"
    echo ""
    echo "  运行 'bash scripts/scan_and_fix.sh skills/ fix' 自动修复"
    exit 1
fi