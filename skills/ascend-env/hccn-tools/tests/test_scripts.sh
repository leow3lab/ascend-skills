#!/bin/bash
# test_scripts.sh - 脚本可执行性测试
# 规则 9：行为回归测试 - 脚本执行验证

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"
SKILL_NAME="hccn-tools"

echo "=== $SKILL_NAME 脚本测试 ==="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试 1：脚本文件存在性
echo "测试 1: 检查脚本文件存在"
for script in build_ranktable.sh diagnose_hccn.sh set_ssh_authority.sh; do
    script_path="$SCRIPT_DIR/$script"
    if [ -f "$script_path" ]; then
        echo -e "  ${GREEN}✓${NC} $script 存在"
    else
        echo -e "  ${RED}✗${NC} $script 不存在"
        exit 1
    fi
done
echo ""

# 测试 2：脚本可执行权限
echo "测试 2: 检查脚本可执行权限"
for script in build_ranktable.sh diagnose_hccn.sh set_ssh_authority.sh; do
    script_path="$SCRIPT_DIR/$script"
    if [ -x "$script_path" ]; then
        echo -e "  ${GREEN}✓${NC} $script 可执行"
    else
        echo -e "  ${YELLOW}⚠${NC} $script 不可执行，尝试添加权限..."
        chmod +x "$script_path"
        if [ -x "$script_path" ]; then
            echo -e "  ${GREEN}✓${NC} 已添加执行权限"
        else
            echo -e "  ${RED}✗${NC} 无法添加执行权限"
            exit 1
        fi
    fi
done
echo ""

# 测试 3：脚本 --help 参数测试
echo "测试 3: 测试脚本 --help 参数"
for script in build_ranktable.sh diagnose_hccn.sh set_ssh_authority.sh; do
    script_path="$SCRIPT_DIR/$script"
    echo "  测试 $script --help..."

    if "$script_path" --help > /dev/null 2>&1; then
        echo -e "    ${GREEN}✓${NC} 支持 --help 参数"
    else
        echo -e "    ${YELLOW}⚠${NC} 不支持 --help 参数，直接运行可能有副作用"
    fi
done
echo ""

# 测试 4：脚本无硬编码检查
echo "测试 4: 检查脚本是否无硬编码敏感值"
for script in build_ranktable.sh diagnose_hccn.sh set_ssh_authority.sh; do
    script_path="$SCRIPT_DIR/$script"
    echo "  检查 $script..."

    # 检查是否硬编码了 IP 地址
    if grep -qE "192\.168\.|10\.0\.|127\.0\.0\.1" "$script_path" 2>/dev/null; then
        echo -e "    ${YELLOW}⚠${NC} 发现疑似硬编码的 IP 地址"
    else
        echo -e "    ${GREEN}✓${NC} 无硬编码 IP 地址"
    fi

    # 检查是否硬编码了端口号
    if grep -qE "8000|=8000" "$script_path" 2>/dev/null | grep -v "#"; then
        echo -e "    ${YELLOW}⚠${NC} 发现疑似硬编码的端口号"
    else
        echo -e "    ${GREEN}✓${NC} 配置通过参数传递"
    fi
done
echo ""

# 测试 5：脚本 shebang 规范性
echo "测试 5: 检查脚本 shebang 规范性"
for script in build_ranktable.sh diagnose_hccn.sh set_ssh_authority.sh; do
    script_path="$SCRIPT_DIR/$script"
    first_line=$(head -n 1 "$script_path")

    if [[ "$first_line" == "#!/bin/bash" ]] || [[ "$first_line" == "#!/usr/bin/env bash" ]]; then
        echo -e "  ${GREEN}✓${NC} $script shebang 规范: $first_line"
    else
        echo -e "  ${YELLOW}⚠${NC} $script shebang 非标准: $first_line"
    fi
done
echo ""

echo "=== 脚本测试完成 ==="