#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：ModelScope 下载前检查环境

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
echo "  ModelScope 下载环境检查"
echo "========================================"
echo ""

# 获取版本信息
PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}' || echo "未安装")

# 执行检查
echo "--- 核心组件检查 ---"
RESULTS=0

check_version "Python" "3\.[8-9]\.[0-9]+" "" "" || RESULTS=1

echo ""
echo "--- 可选组件检查 ---"

check_version_warn "modelscope" "[0-9]+\.[0-9]+\.[0-9]+" "pip show modelscope 2>/dev/null | grep Version | awk '{print \$2}'" "请安装 ModelScope：pip install modelscope"

check_version_warn "pip" "2[0-9]+\.[0-9]+\.[0-9]+" "pip --version 2>/dev/null | awk '{print \$2}'" "pip 20.0+ 推荐用于下载优化"

check_version_warn "Git" "[0-9]+\.[0-9]+\.[0-9]+" "git --version 2>/dev/null | awk '{print \$3}'" "Git 用于版本 integrity check"

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，可以开始下载${NC}"
    echo ""
    echo "下一步："
    echo "  1. 使用 scripts/run_ms_model_download.sh 下载模型"
    echo "  2. 使用 scripts/run_ms_datasets_download.sh 下载数据集"
    echo "  3. 使用 scripts/run_check_sha.sh 验证完整性"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 环境检查失败${NC}"
    echo ""
    echo "请解决以下问题："
    echo "  1. 安装或升级 Python 3.8+"
    echo "  2. 安装 ModelScope：pip install modelscope"
    echo "  3. 重新运行本检查脚本"
    echo ""
    exit 1
fi