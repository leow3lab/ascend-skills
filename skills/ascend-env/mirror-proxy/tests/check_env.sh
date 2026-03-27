#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：镜像源配置前检查

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

echo "========================================"
echo "  镜像源配置环境检查"
echo "========================================"
echo ""

echo "--- 包管理器检查 ---"
RESULTS=0

# 检查 APT (Debian/Ubuntu)
echo -n "检查 APT 包管理器... "
if command -v apt-get > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已安装（用于配置 APT 镜像源）"
else
    echo -e "${YELLOW}⚠${NC} 未安装（非 Debian/Ubuntu 系统，跳过 APT 配置）"
fi

# 检查 pip
echo -n "检查 pip ... "
if command -v pip3 > /dev/null 2>&1; then
    PIP_VERSION=$(pip3 --version 2>/dev/null | awk '{print $2}' || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $PIP_VERSION)"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，pip 镜像配置需要）"
fi

# 检查 npm
echo -n "检查 npm ... "
if command -v npm > /dev/null 2>&1; then
    NPM_VERSION=$(npm --version 2>/dev/null || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $NPM_VERSION)"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，npm 镜像配置需要）"
fi

echo ""
echo "--- 可选组件检查 ---"

# 检查 Docker
echo -n "检查 Docker ... "
if command -v docker > /dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | grep Version | awk '{for(i=1;i<=NF;i++){if($i=="Version"){print $(i+1);exit}}}' || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $DOCKER_VERSION，用于配置 Docker 代理)"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，Docker 代理配置需要）"
fi

# 检查 Git
echo -n "检查 Git ... "
if command -v git > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已安装（用于配置 Git 代理）"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，Git 代理配置需要）"
fi

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，可以进行镜像源配置${NC}"
    echo ""
    echo "下一步："
    echo "  1. 使用 scripts/run_set_pip_mirror.sh 配置 pip 镜像"
    echo "  2. 使用 scripts/run_set_npm_mirror.sh 配置 npm 镜像"
    echo "  3. 使用 scripts/run_set_apt_mirror.sh 配置 APT 镜像"
    echo "  4. 使用 scripts/run_set_proxy.sh 配置代理"
    echo "  5. 使用 scripts/run_set_docker_mirror.sh 配置 Docker 代理"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠${NC} 环境检查完成，部分组件缺失（均为可选）"
    echo ""
    echo "根据需要安装缺失组件："
    echo "  1. APT 镜像：apt-get install -y apt-transport-https"
    echo "  2. pip：apt-get install -y python3-pip"
    echo "  3. Docker：curl -fsSL https://get.docker.com | sh"
    echo "  4. Git：apt-get install -y git"
    echo ""
    exit 0
fi