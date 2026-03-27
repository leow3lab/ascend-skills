# vllm-ascend-prof 测试框架

**目的**：遵循 RULE.md 规则 9（行为回归测试），确保 Skill 的逻辑、数据、行为在版本迭代中保持一致。

---

## 测试目录结构

```
tests/
├── README.md                     # 本文档
├── test_scripts.sh               # 脚本可执行性测试
└── check_env.sh                # 环境对齐检查
```

---

## 测试类型

### 1. 脚本执行测试 (`test_scripts.sh`)

**测试脚本列表**：`curl_vllm_ascend_prof.sh` (bash), `parser.py` (Python)

**测试维度**：
- [x] 脚本文件存在性
- [x] 脚本可执行权限（bash 脚本），Python 脚本可读权限
- [x] `--help` 参数支持
- [x] 无硬编码敏感值
- [x] shebang 规范性
- [x] Python 语法检查（新增）

**执行方式**：`bash tests/test_scripts.sh`

---

### 2. 环境对齐检查 (`check_env.sh`)

**检查项**：
- [x] Python 3.8+（必需）
- [x] curl（可选，API 调用需要）
- [x] jq（可选，JSON 解析需要）
- [x] NPU 设备
- [x] vLLM API 配置（环境变量 VLLM_API_HOST/VLLM_API_PORT）

**执行方式**：`bash tests/check_env.sh`

---

## 测试覆盖率

| 测试类型 | 覆盖率 | 状态 |
|---------|---------|------|
| 脚本可执行性 | 100% | ✅ |
| Python 语法检查 | 100% | ✅ |
| 环境对齐检查 | 100% | ✅ |

---

## 特殊测试说明

### Python 脚本语法检查（测试 6）

**目的**：确保 `parser.py` 语法正确，可以在运行时被 Python 解释器导入。

**检查方法**：使用 `python3 -m py_compile` 编译脚本，无错误表示语法正确。

**注意**：
- Python 脚本不需要可执行权限（`+x`），但需要可读权限（`+r`）
- Bash 脚本必须可执行才能直接运行

---

**维护者**：Ascend Team
**最后更新**：2026-03-12