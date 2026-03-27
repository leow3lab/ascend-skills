#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：HCCL 基准测试前检查环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  HCCL 基准测试环境检查"
echo "========================================"
echo ""

echo "--- 核心组件检查 ---"
RESULTS=0

# 检查 NPU 驱动
echo -n "检查 NPU 驱动... "
if npu-smi info > /dev/null 2>&1; then
    DRIVER_VERSION=$(npu-smi info 2>/dev/null | grep "Version" | awk '{print $2}' || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $DRIVER_VERSION)"
else
    echo -e "${RED}✗${NC} 未安装"
    echo -e "  ${YELLOW}NPU 驱动是 HCCL 测试的必需组件${NC}"
    RESULTS=1
fi

# 检查 CANN
echo -n "检查 CANN ... "
if [ -d "/usr/local/Ascend/ascend-toolkit/latest" ]; then
    CANN_VERSION=$(cat /usr/local/Ascend/ascend-toolkit/latest/version.info 2>/dev/null || echo "未知")
    echo -e "${GREEN}✓${NC} 已安装 (版本: $CANN_VERSION)"
else
    echo -e "${RED}✗${NC} 未安装"
    echo -e "  ${YELLOW}CANN 是 HCCL 测试的必需组件${NC}"
    RESULTS=1
fi

# 检查 NPU 设备数量
echo -n "检查 NPU 设备数量... "
NPU_COUNT=$(ls /dev/davinci* 2>/dev/null | wc -l)
if [ "$NPU_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} 检测到 $NPU_COUNT 个 NPU 设备"
else
    echo -e "${YELLOW}⚠${NC} 未检测到 NPU 设备"
    RESULTS=1
fi

echo ""
echo "--- 可选组件检查 ---"

# 检查 mpirun（多节点测试需要）
echo -n "检查 mpirun ... "
if command -v mpirun > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已安装（用于多节点 HCCL 测试）"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，多节点性能测试需要）"
    echo -e "  ${NC}安装命令: apt install mpich 或 yum install mpich${NC}"
fi

# 检查 hostfile（多节点配置需要）
echo -n "检查 hostfile ... "
if [ -f "/etc/hccl/hostfile" ]; then
    NODE_COUNT=$(wc -l < /etc/hccl/hostfile)
    echo -e "${GREEN}✓${NC} 存在 ($NODE_COUNT 个节点配置)"
else
    echo -e "${YELLOW}⚠${NC} 不存在（可选，多节点配置需要）"
fi

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，可以进行 HCCL 基准测试${NC}"
    echo ""
    echo "下一步（脚本实现后）："
    echo "  1. 配置单节点多卡测试：scripts/execute_hccl_test.sh --mode single-node"
    echo "  2. 配置多节点测试：scripts/execute_hccl_test.sh --mode multi-node"
    echo "  3. 查看测试结果：查看 logs/ 目录下的性能报告"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠${NC} 环境检查部分失败"
    echo ""
    echo "注意事项："
    echo "  1. NPU 驱动和 CANN 是必需的"
    echo "  2. mpirun 和 hostfile 是多节点测试必需的"
    echo "  3. 单节点测试只需 NPU 驱动和 CANN"
    echo ""
    exit 1
fi