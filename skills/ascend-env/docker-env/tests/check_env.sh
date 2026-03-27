#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：Docker NPU 容器环境检查

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
echo "  Docker NPU 容器环境检查"
echo "========================================"
echo ""

# 获取版本信息
DOCKER_VERSION=$(docker --version 2>/dev/null | grep Version | awk '{for(i=1;i<=NF;i++){if($i=="Version"){print $(i+1);exit}}}' || echo "未安装")

# 执行检查
echo "--- 核心组件检查 ---"
RESULTS=0

# Docker 是必需的
if [ "$DOCKER_VERSION" = "未安装" ]; then
    echo -e "${RED}✗${NC} Docker 未安装 - NPU 容器需要 Docker 环境"
    echo -e "  ${YELLOW}安装命令: curl -fsSL https://get.docker.com | sh${NC}"
    RESULTS=1
else
    check_version "Docker" "2[0-9]+\.[0-9]+\.[0-9]+" "" "" || RESULTS=1
fi

echo ""
echo "--- NPU 环境检查 ---"

# 检查 NPU 驱动
echo -n "检查 NPU 驱动... "
if npu-smi info > /dev/null 2>&1; then
    DRIVER_VERSION=$(npu-smi info 2>/dev/null | grep "Version" | awk '{print $2}' || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $DRIVER_VERSION)"
else
    echo -e "${RED}✗${NC} 未安装"
    echo -e "  ${YELLOW}NPU 驱动是容器内访问 NPU 的必需组件${NC}"
    RESULTS=1
fi

# 检查 CANN
echo -n "检查 CANN ... "
if [ -d "/usr/local/Ascend/ascend-toolkit/latest" ]; then
    CANN_VERSION=$(cat /usr/local/Ascend/ascend-toolkit/latest/version.info 2>/dev/null || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $CANN_VERSION)"
else
    echo -e "${RED}✗${NC} 未安装"
    echo -e "  ${YELLOW}CANN 是容器运行模型推理的必需组件${NC}"
    RESULTS=1
fi

# 检查 NPU 设备
echo -n "检查 NPU 设备文件... "
if ls /dev/davinci* > /dev/null 2>&1; then
    NPU_COUNT=$(ls /dev/davinci* 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} 检测到 $NPU_COUNT 个 NPU 设备 (/dev/davinci0-$((NPU_COUNT-1)))"
else
    echo -e "${RED}✗${NC} 未检测到 NPU 设备文件"
    echo -e "  ${YELLOW}容器需要映射 /dev/davinci* 设备${NC}"
    RESULTS=1
fi

echo ""
echo "--- 可选组件检查 ---"

# 检查 Docker Compose
echo -n "检查 Docker Compose ... "
if docker compose version > /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $COMPOSE_VERSION)"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，用于多容器编排）"
    echo -e "  ${NC}安装命令: scripts/run_install_compose.sh${NC}"
fi

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，可以启动 NPU Docker 容器${NC}"
    echo ""
    echo "下一步："
    echo "  1. 使用 scripts/run_build_npu_docker_container.sh 启动 NPU 容器"
    echo "  2. 使用 sudo bash scripts/run_install_compose.sh 安装 Docker Compose（可选）"
    echo "  3. 容器内运行: npu-smi info 验证 NPU 访问"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 环境检查失败${NC}"
    echo ""
    echo "请解决以下问题："
    echo "  1. 安装 Docker（必需）"
    echo "  2. 安装 NPU 驱动和 CANN（必需）"
    echo "  3. 确保 NPU 设备文件存在（/dev/davinci*）"
    echo "  4. 重新运行本检查脚本"
    echo ""
    exit 1
fi