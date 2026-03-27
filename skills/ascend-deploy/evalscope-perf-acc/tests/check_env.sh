#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：EvalScope 评估前检查组件版本一致性

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
echo "  EvalScope 评估环境检查"
echo "========================================"
echo ""

# 获取版本信息
PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}' || echo "未安装")
DOCKER_VERSION=$(docker --version 2>/dev/null | grep Version | awk '{for(i=1;i<=NF;i++){if($i=="Version"){print $(i+1);exit}}}' || echo "未安装")

# 执行检查
echo "--- 核心组件检查 ---"
RESULTS=0

check_version "Python" "3\.[8-9]\.[0-9]+" "" "" || RESULTS=1

# Docker 是必需的（EvalScope 容器化部署）
if [ "$DOCKER_VERSION" = "未安装" ]; then
    echo -e "${RED}✗${NC} Docker 未安装 - EvalScope 评估需要 Docker 环境"
    echo -e "  ${YELLOW}安装命令: curl -fsSL https://get.docker.com | sh${NC}"
    RESULTS=1
else
    check_version "Docker" "2[0-9]+\.[0-9]+\.[0-9]+" "" "" || RESULTS=1
fi

echo ""
echo "--- 可选组件检查 ---"

check_version_warn "evalscope" "[0-9]+\.[0-9]+\.[0-9]+" "pip show evalscope 2>/dev/null | grep Version | awk '{print \$2}'" "请安装最新版 evalscope：pip install 'evalscope[perf,app]'"

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，所有版本兼容${NC}"
    echo ""
    echo "下一步："
    echo "  1. 使用 scripts/run_build_docker.sh 构建评估容器"
    echo "  2. 使用 scripts/run_eval_acc.sh 运行精度评估"
    echo "  3. 使用 scripts/run_eval_perf.sh 运行性能测试"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 环境检查失败${NC}"
    echo ""
    echo "请解决以下问题："
    echo "  1. 安装或升级 Docker（必需）"
    echo "  2. 升级或安装缺失的组件"
    echo "  3. 参考 VERSION_MATRIX.md 查找兼容版本组合"
    echo "  4. 重新运行本检查脚本"
    echo ""
    exit 1
fi