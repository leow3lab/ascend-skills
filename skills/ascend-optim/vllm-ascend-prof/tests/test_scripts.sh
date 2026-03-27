#!/bin/bash
# test_scripts.sh - 脚本可执行性测试
# 规则 9：行为回归测试 - 脚本执行验证

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"
SKILL_NAME="vllm-ascend-prof"

echo "=== $SKILL_NAME 脚本测试 ==="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试 1：脚本文件存在性
echo "测试 1: 检查脚本文件存在"
for script in curl_vllm_ascend_prof.sh parser.py; do
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

# Bash 脚本需要可执行
for script in curl_vllm_ascend_prof.sh; do
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

# Python 脚本只需要读取权限
PYPARSER_PATH="$SCRIPT_DIR/parser.py"
if [ -r "$PYPARSER_PATH" ]; then
    echo -e "  ${GREEN}✓${NC} parser.py 可读 (Python 脚本，无需可执行权限)"
else
    echo -e "  ${RED}✗${NC} parser.py 不可读"
    exit 1
fi
echo ""

# 测试 3：脚本 --help 参数测试
echo "测试 3: 测试脚本 --help 参数"
echo "  测试 curl_vllm_ascend_prof.sh --help..."

if "$SCRIPT_DIR/curl_vllm_ascend_prof.sh" --help > /dev/null 2>&1; then
    echo -e "    ${GREEN}✓${NC} 支持 --help 参数"
else
    echo -e "    ${YELLOW}⚠${NC} 不支持 --help 参数，直接运行可能有副作用"
fi
echo ""

# 测试 4：脚本无硬编码检查
echo "测试 4: 检查脚本是否无硬编码敏感值"
echo "  检查 curl_vllm_ascend_prof.sh..."

# 检查是否硬编码了 IP 地址
if grep -qE "192\.168\.|10\.0\.|127\.0\.0\.1" "$SCRIPT_DIR/curl_vllm_ascend_prof.sh" 2>/dev/null; then
    echo -e "    ${YELLOW}⚠${NC} 发现疑似硬编码的 IP 地址"
else
    echo -e "    ${GREEN}✓${NC} 无硬编码 IP 地址"
fi

# 检查是否硬编码了端口号
if grep -qE "8000|=8000" "$SCRIPT_DIR/curl_vllm_ascend_prof.sh" 2>/dev/null | grep -v "#"; then
    echo -e "    ${YELLOW}⚠${NC} 发现疑似硬编码的端口号"
else
    echo -e "    ${GREEN}✓${NC} 配置通过参数传递"
fi
echo ""

# 测试 5：脚本 shebang 规范性
echo "测试 5: 检查脚本 shebang 规范性"
echo "  检查 curl_vllm_ascend_prof.sh..."
first_line=$(head -n 1 "$SCRIPT_DIR/curl_vllm_ascend_prof.sh")

if [[ "$first_line" == "#!/bin/bash" ]] || [[ "$first_line" == "#!/usr/bin/env bash" ]]; then
    echo -e "  ${GREEN}✓${NC} shebang 规范: $first_line"
else
    echo -e "  ${YELLOW}⚠${NC} shebang 非标准: $first_line"
fi
echo ""

# 测试 6：Python 脚本语法检查
echo "测试 6: 检查 Python 脚本语法"
if python3 -m py_compile "$PYPARSER_PATH" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} parser.py 语法正确"
else
    echo -e "  ${RED}✗${NC} parser.py 语法错误"
    exit 1
fi
echo ""

echo "=== 脚本测试完成 ==="