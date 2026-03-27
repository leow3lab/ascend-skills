# hccn-tools 测试框架

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

**测试脚本列表**：`build_ranktable.sh`, `diagnose_hccn.sh`, `set_ssh_authority.sh`

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
- [x] NPU 驱动（必需）
- [x] hccn_tool（必需）
- [x] NPU 网络设备
- [x] SSH 服务（可选，多节点需要）
- [x] mpirun（可选，多节点测试需要）

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