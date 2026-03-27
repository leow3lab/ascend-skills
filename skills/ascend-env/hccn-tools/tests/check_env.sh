#!/bin/bash
# check_env.sh - 环境版本对齐检查
# 规则 13（环境对齐）和 规则 4（版本锚定）的实现脚本
# 用途：HCCN 网络配置前检查环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  HCCN 网络配置环境检查"
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
    echo -e "  ${YELLOW}NPU 驱动是 HCCN 工具的必需组件${NC}"
    RESULTS=1
fi

# 检查 hccn_tool
echo -n "检查 hccn_tool ... "
if command -v hccn_tool > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已安装"
else
    echo -e "${RED}✗${NC} 未安装"
    echo -e "  ${YELLOW}hccn_tool 用于网络配置和诊断${NC}"
    RESULTS=1
fi

# 检查网络设备
echo -n "检查 NPU 网络设备... "
if ls /dev/davinci* > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已检测到 NPU 设备"
else
    echo -e "${YELLOW}⚠${NC} 未检测到 NPU 设备"
fi

echo ""
echo "--- 可选组件检查 ---"

# 检查 SSH
echo -n "检查 SSH 服务... "
if systemctl status sshd > /dev/null 2>&1 || systemctl status ssh > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已运行（用于多节点 SSH 认证）"
else
    echo -e "${YELLOW}⚠${NC} 未运行（可选，多节点配置需要）"
fi

# 检查 mpirun（多节点测试需要）
echo -n "检查 mpirun ... "
if command -v mpirun > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 已安装（用于多节点 HCCL 测试）"
else
    echo -e "${YELLOW}⚠${NC} 未安装（可选，多节点性能测试需要）"
fi

echo ""
echo "========================================"

if [ $RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过，可以配置 HCCN 网络${NC}"
    echo ""
    echo "下一步："
    echo "  1. 使用 scripts/build_ranktable.sh 生成 Rank Table"
    echo "  2. 使用 scripts/set_ssh_authority.sh 配置 SSH 认证"
    echo "  3. 使用 scripts/diagnose_hccn.sh 诊断网络问题"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 环境检查失败${NC}"
    echo ""
    echo "请解决以下问题："
    echo "  1. 安装 NPU 驱动（必需）"
    echo "  2. 安装 hccn_tool 工具（必需）"
    echo "  3. 重新运行本检查脚本"
    echo ""
    exit 1
fi