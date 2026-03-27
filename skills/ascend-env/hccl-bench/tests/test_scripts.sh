#!/bin/bash
# test_scripts.sh - 脚本可执行性测试
# 规则 9：行为回归测试 - 脚本执行验证
# 注意：hccl-bench 脚本尚未实现，此测试为占位

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"
SKILL_NAME="hccl-bench"

echo "=== $SKILL_NAME 脚本测试 ==="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试 1：脚本文件存在性
echo "测试 1: 检查脚本文件存在"
# hccl-bench 当前只有 TODO.md，没有实际脚本
echo -e "  ${YELLOW}ℹ${NC} hccl-bench 脚本尚未实现（参见 scripts/TODO.md）"
echo ""

# 测试 2：TODO 文件存在性
echo "测试 2: 检查 TODO 文档存在"
if [ -f "$SCRIPT_DIR/TODO.md" ]; then
    echo -e "  ${GREEN}✓${NC} TODO.md 存在"
else
    echo -e "  ${RED}✗${NC} TODO.md 不存在"
    exit 1
fi
echo ""

# 测试 3：TODO 非空
echo "测试 3: 检查 TODO 内容"
if [ -s "$SCRIPT_DIR/TODO.md" ]; then
    echo -e "  ${GREEN}✓${NC} TODO.md 包含内容规划"
    TODO_LINES=$(wc -l < "$SCRIPT_DIR/TODO.md")
    echo -e "  ${NC}  包含 $TODO_LINES 行规划内容"
else
    echo -e "  ${YELLOW}⚠${NC} TODO.md 为空，需要添加内容"
fi
echo ""

echo "=== 脚本测试完成 ==="
echo ""
echo -e "${YELLOW}⚠${NC} 注意：HCCL 基准测试脚本尚未实现，等待开发完成后更新测试用例"