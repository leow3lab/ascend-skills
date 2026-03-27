#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：部署前检查各组件版本一致性

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
echo " Ascend Skills 环境对齐检查"
echo "========================================"
echo ""

# 获取版本信息
DRIVER_VERSION=$(npu-smi info 2>/dev/null | grep "Version" | awk '{print $2}' || echo "未安装")
[ -n "$DRIVER_VERSION" ] && [ "$DRIVER_VERSION" != "未安装" ] || DRIVER_VERSION="未安装"

CANN_VERSION=$(cat /usr/local/Ascend/ascend-toolkit/latest/version.info 2>/dev/null || echo "未安装")

PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}' || echo "未安装")

DOCKER_VERSION=$(docker --version 2>/dev/null | grep Version | awk '{for(i=1;i<=NF;i++){if($i=="Version"){print $(i+1);exit}}}' || echo "未安装")

# 执行检查
echo "--- 核心组件检查 ---"
RESULTS=0

check_version "Ascend 驱动" "23\.0\.[0-9]+" "" "$DRIVER_VERSION" || RESULTS=1
check_version "CANN" "8\.0\.[RC1-9x]+" "" "$CANN_VERSION" || RESULTS=1
check_version "Python" "3\.10\.[0-9]+" "" "$PYTHON_VERSION" || RESULTS=1
check_version "Docker" "20\.[0-9]+\.[0-9]+" "" "$DOCKER_VERSION" || RESULTS=1

echo ""
echo "--- 可选组件检查 ---"

check_version_warn "vLLM-Ascend" "v0\.1\.[0-9]+" "pip show vllm-ascend 2>/dev/null | grep Version" "not installed | awk '{print \$2}'" "vLLM 需要版本 v0.1.x，请根据需要安装"

check_version_warn "torch-npu" "2\.[0-9]+\.[0-9]+" "python -c \"import torch_npu; print(torch_npu.__version__)\" 2>/dev/null" "torch-npu 需要版本 2.1.0+，请根据需要安装"

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，所有版本兼容${NC}"
    echo ""
    echo "下一步："
    echo "  1. 参考 deployment-procedure.md 执行部署流程"
    echo "  2. 使用 scripts/ 中的脚本创建容器和启动服务"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 环境检查失败${NC}"
    echo ""
    echo "请解决以下问题："
    echo "  1. 升级或安装缺失的组件"
    echo "  2. 参考 VERSION_MATRIX.md 查找兼容版本组合"
    echo "  3. 重新运行本检查脚本"
    echo ""
    exit 1
fi