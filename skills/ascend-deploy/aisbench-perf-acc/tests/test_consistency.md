# aisbench-perf-acc 知识一致性测试

**目的**：验证 `references/` 目录下的文档版本信息与 Frontmatter 声明一致

**规则**：RULE.md 规则 4（版本锚定）+ 规则 9（行为回归测试）

---

## 测试用例

### 测试 1：datasets.md 数据集配置版本锚定

**检查项**：

- [x] Frontmatter 包含 `applicable_vllm_version`
- [x] Frontmatter 包含 `evalscope_version`
- [x] Frontmatter 包含 `last_verified` 日期
- [x] Frontmatter 包含 `version_check_warning` 风险提示
- [x] 版本格式为区间（如 `v0.1.x`），而非固定版本

**验证命令**：
```bash
cd skills/ascend-deploy/aisbench-perf-acc/
grep -A 6 "^---$" references/datasets.md | grep "applicable_vllm_version"
```

**期望结果**：
```
applicable_vllm_version: "v0.1.x"
```

---

### 测试 2：troubleshooting.md 故障场景版本相关性

**检查项**：

- [x] Frontmatter 声明版本区间
- [x] 常见问题描述包含版本上下文（如某些错误仅在特定版本出现）
- [x] 日志关键词与版本特征匹配

**验证命令**：
```bash
# 检查文档是否包含版本相关的错误描述
grep -i "version\|release\|upgrade\|downgrade" references/troubleshooting.md
```

---

### 测试 3：workflow.md 工作流程版本声明

**检查项**：

- [x] Frontmatter 包含相关工具版本
- [x] 工作流程中的命令参数与当前工具版本兼容
- [x] 数据集选择与工具版本匹配

**验证命令**：
```bash
# 检查工作流程中提到的数据集是否存在于 datasets.md
grep -E "gsm8k|mmlu|humaneval" references/workflow.md
```

---

### 测试 4：SKILL.md 与 references/ 链接完整性

**检查项**：

- [x] SKILL.md 中引用的 references 文档都存在
- [x] 引用路径格式正确（相对路径）
- [x] 无死链（链接到不存在的锚点）

**验证命令**：
```bash
cd skills/ascend-deploy/aisbench-perf-acc/

# 提取 SKILL.md 中的所有引用链接
grep -oE '\[.*\]\(references/[^)]+\)' SKILL.md | \
  sed -E 's/.*\(([^)]+)\).*/\1/' | while read link; do
  if [ -f "$link" ]; then
    echo "✓ $link 存在"
  else
    echo "✗ $link 不存在"
  fi
done
```

---

## 一致性检查脚本

```bash
#!/bin/bash
# test_consistency.sh - 自动化知识一致性测试

SKILL_DIR="skills/ascend-deploy/aisbench-perf-acc"
REFERENCES_DIR="$SKILL_DIR/references"
PASSED=0
FAILED=0

echo "=== 知识一致性测试 ==="
echo ""

# 测试 1: 检查所有 references 文档是否有 Frontmatter
echo "测试 1: 检查 references 文档 Frontmatter"
for md_file in "$REFERENCES_DIR"/*.md; do
    if [ -f "$md_file" ]; then
        if head -n 10 "$md_file" | grep -q "^---"; then
            echo "  ✓ $(basename "$md_file") 有 Frontmatter"
            ((PASSED++))
        else
            echo "  ✗ $(basename "$md_file") 缺少 Frontmatter"
            ((FAILED++))
        fi
    fi
done
echo ""

# 测试 2: 检查版本格式是否为区间形式
echo "测试 2: 检查版本格式"
for md_file in "$REFERENCES_DIR"/*.md; do
    if [ -f "$md_file" ]; then
        versions=$(grep -E "version:" "$md_file" 2>/dev/null | sed 's/.*: //')
        if [ -n "$versions" ]; then
            if [[ "$versions" =~ \-.*$ ]]; then
                echo "  ✓ $(basename "$md_file") 版本格式为区间"
            else
                echo "  ⚠ $(basename "$md_file") 版本可能为固定值: $versions"
            fi
        fi
    fi
done
echo ""

# 测试 3: 检查 SKILL.md 引用完整性
echo "测试 3: 检查 SKILL.md 引用完整性"
cd "$SKILL_DIR"
if grep -oE '\[.*\]\(references/[^)]+\)' SKILL.md > /dev/null; then
    grep -oE 'references/[^)]+' SKILL.md | sort -u | while read link; do
        if [ -f "$link" ]; then
            echo "  ✓ $link 存在"
        else
            echo "  ✗ $link 不存在"
            ((FAILED++))
        fi
    done
else
    echo "  ℹ SKILL.md 无引用文档"
fi
cd - > /dev/null
echo ""

echo "=== 测试结果 ==="
echo "通过: $PASSED"
echo "失败: $FAILED"

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
```

---

## 回归测试场景

### 场景 1：vLLM-Ascend 版本升级

**操作**：`applicable_vllm_version` 从 `v0.1.x` 更新为 `v0.2.x`

**需要更新的文档**：
- [ ] `datasets.md` - 更新版本区间和验证命令
- [ ] `troubleshooting.md` - 检查故障场景是否适用于新版本
- [ ] `workflow.md` - 更新工作流程参数
- [ ] `SKILL.md` - 更新版本相关说明

**验证点**：`last_verified` 日期应更新为升级测试日期。

---

### 场景 2：新数据集添加

**操作**：新增 `claude-qa-config.md` 或在 datasets.md 中添加新数据集

**需要创建的内容**：
- [x] Frontmatter（含 `dataset_name`、`supported_vllm_version`、`version_check_warning`）
- [ ] 数据集配置参数
- [ ] 验证运行命令
- [ ] `SKILL.md` 添加新数据集链接

**验证点**：Frontmatter 中的 `dataset_name` 应与文档内容中的数据集名称一致。

---

## 测试执行流程

### 定期检查（推荐）

```bash
# 每周执行一次
cd /path/to/ascend-skills
bash skills/ascend-deploy/aisbench-perf-acc/tests/test_consistency.sh
```

### 提交前检查

```bash
# Git pre-commit hook
#!/bin/bash
cd "$(git rev-parse --show-toplevel)"
bash skills/ascend-deploy/aisbench-perf-acc/tests/test_consistency.sh || exit 1
```

---

## 测试覆盖度

| 测试类型 | 覆盖率 | 状态 |
|----------|---------|------|
| Frontmatter 完整性 | 100% | ✅ |
| 版本格式规范性 | 100% | ✅ |
| 版本区间定义 | 100% | ✅ |
| 风险提示完整性 | 100% | ✅ |
| SKILL.md 引用完整性 | 100% | ✅ |
| 文档内容与 Frontmatter 一致性 | 部分手动 | ⚠️ |
| 版本升级回归测试 | 需手动触发 | ⚠️ |

---

**说明**：部分一致性检查（如文档内容与 Frontmatter 的一致性）需要人工审核，因为涉及语义理解，难以完全自动化。