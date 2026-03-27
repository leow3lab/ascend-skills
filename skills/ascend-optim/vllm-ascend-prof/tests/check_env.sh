#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：vLLM 性能分析前检查环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查函数
check_version() {
    local name=$1
    local expected_regex=$2
    local get_version_cmd=$3
    local version_info=$4

    echo -n "检查 $name... "

    # 执行命令获取版本
    if [ -n "$get_version_cmd" ]; then
        actual=$(eval "$get_version_cmd" 2>/dev/null || echo "未安装")
    else
        actual="未安装"
    fi

    # 检查版本是否匹配
    if [ "$actual" = "未安装" ]; then
        echo -e "${RED}✗${NC} 未安装"
        echo -e "  ${YELLOW}安装命令: $version_info${NC}"
        return 1
    fi

    if [[ "$actual" =~ $expected_regex ]]; then
        echo -e "${GREEN}✓${NC} $actual"
        return 0
    else
        echo -e "${RED}✗${NC} $actual"
        echo -e "  ${YELLOW}期望版本区间: $expected_regex${NC}"
        echo -e "  ${YELLOW}当前版本: $actual${NC}"
        return 1
    fi
}

# 警告检查函数
check_version_warn() {
    local name=$1
    local expected_regex=$2
    local get_version_cmd=$3
    local warning_msg=$4

    echo -n "检查 $name... "

    actual=$(eval "$get_version_cmd" 2>/dev/null || echo "未安装")

    if [ "$actual" = "未安装" ]; then
        echo -e "${YELLOW}⚠${NC} 未安装（可选）"
        return 0
    fi

    if [[ "$actual" =~ $expected_regex ]]; then
        echo -e "${GREEN}✓${NC} $actual"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $actual"
        echo -e "  ${NC}注意: $warning_msg${NC}"
        return 0
    fi
}

echo "========================================"
echo "  vLLM 性能分析环境检查"
echo "========================================"
echo ""

# 执行检查
echo "--- 核心组件检查 ---"
RESULTS=0

check_version "Python" "3\.[8-9]\.[0-9]+" "" "" || RESULTS=1

echo ""
echo "--- 可选组件检查 ---"

# 检查 curl（用于调用 vLLM API）
echo -n "检查 curl ... "
if command -v curl > /dev/null 2>&1; then
    CURL_VERSION=$(curl --version 2>/dev/null | head -1 | awk '{print $2}' || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $CURL_VERSION)"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，脚本调用需要）"
    echo -e "  ${NC}安装命令: apt-get install -y curl${NC}"
fi

# 检查 jq（用于解析 JSON 输出）
echo -n "检查 jq ... "
if command -v jq > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已安装（用于解析性能分析 JSON）"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，JSON 解析需要）"
    echo -e "  ${NC}安装命令: apt-get install -y jq${NC}"
fi

echo ""
echo "--- NPU 环境检查 ---"

# 检查 NPU 设备
echo -n "检查 NPU 设备... "
if npu-smi info > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已安装 NPU 驱动"
else
    echo -e "${YELLOW}⚠${NC} NPU 驱动未安装（性能分析需要访问 NPU）"
fi

# 检查 vLLM 服务配置
echo -n "检查 vLLM API 配置... "
if [ -n "$VLLM_API_HOST" ] && [ -n "$VLLM_API_PORT" ]; then
    echo -e "${GREEN}✓${NC} 已配置 (HOST=$VLLM_API_HOST, PORT=$VLLM_API_PORT)"
else
    echo -e "${YELLOW}⚠${NC} 未配置（可通过参数传递或设置环境变量）"
fi

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，可以进行性能分析${NC}"
    echo ""
    echo "下一步："
    echo "  1. 使用 scripts/curl_vllm_ascend_prof.sh 获取性能数据"
    echo "  2. 使用 scripts/parser.py 解析性能指标"
    echo "  3. 参考 reference/README.md 了解性能指标含义"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 环境检查失败${NC}"
    echo ""
    echo "请解决以下问题："
    echo "  1. 安装 Python 3.8+（必需）"
    echo "  2. 安装 curl 和 jq（可选，脚本需要）"
    echo "  3. 确保运行了 vLLM 推理服务"
    echo "  4. 重新运行本检查脚本"
    echo ""
    exit 1
fi