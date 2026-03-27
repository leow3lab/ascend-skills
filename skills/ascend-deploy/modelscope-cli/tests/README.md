# modelscope-cli 测试框架

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

**目的**：验证 `scripts/` 下的脚本是否能正常运行

**测试脚本列表**：`ms_loop.sh`, `run_check_sha.sh`, `run_ms_datasets_download.sh`, `run_ms_model_download.sh`, `run_report_param.sh`

**测试维度**：
- [x] 脚本文件存在性
- [x] 脚本可执行权限
- [x] `--help` 参数支持
- [x] 无硬编码敏感值
- [x] shebang 规范性

**执行方式**：`bash tests/test_scripts.sh`

---

### 2. 环境对齐检查 (`check_env.sh`)

**检查项**：
- [x] Python 3.8+（必需）
- [x] modelscope（可选，推荐）
- [x] pip 20.0+（可选）
- [x] Git（可选，用于 integrity check）

**执行方式**：`bash tests/check_env.sh`

---

## 测试覆盖率

| 测试类型 | 覆盖率 | 状态 |
|---------|---------|------|
| 脚本可执行性 | 100% | ✅ |
| 环境对齐检查 | 100% | ✅ |

---

**维护者**：Ascend Team
**最后更新**：2026-03-12