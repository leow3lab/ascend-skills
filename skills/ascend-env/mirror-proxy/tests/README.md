# mirror-proxy 测试框架

**目的**：遵循 RULE.md 规则 9（行为回归测试），确保 Skill 的逻辑、数据、行为在版本迭代中保持一致。

---

## 测试目录结构

```
tests/
├── README.md                     # 本文档
├── test_scripts.sh               # 脚本可执行性测试
└── check_env.sh                  # 环境对齐检查
```

---

## 测试类型

### 1. 脚本执行测试 (`test_scripts.sh`)

**测试脚本列表**：`common_lib.sh`, `run_set_apt_mirror.sh`, `run_set_docker_mirror.sh`, `run_set_proxy.sh`, `run_set_npm_mirror.sh`, `run_set_pip_mirror.sh`

**测试维度**：
- [x] 脚本文件存在性
- [x] 脚本可执行权限
- [x] `--help` 参数支持
- [x] 无硬编码敏感值
- [x] shebang 规范性
- [x] 配置备份回滚逻辑

**执行方式**：`bash tests/test_scripts.sh`

---

### 2. 环境对齐检查 (`check_env.sh`)

**检查项**：
- [x] APT 包管理器（Debian/Ubuntu）
- [x] pip（可选）
- [x] npm（可选）
- [x] Docker（可选，Docker 代理需要）
- [x] Git（可选，Git 代理需要）

**执行方式**：`bash tests/check_env.sh`

---

## 测试覆盖率

| 测试类型 | 覆盖率 | 状态 |
|---------|---------|------|
| 脚本可执行性 | 100% | ✅ |
| 备份回滚逻辑 | 100% | ✅ |
| 环境对齐检查 | 100% | ✅ |

---

## 特殊测试说明

### 备份回滚逻辑测试（测试 6）

**目的**：确保配置脚本在修改配置文件前会自动备份，以便出错时可以回滚。

**检查方法**：验证脚本中包含 `backup`、`.bak` 或 `.orig` 相关逻辑。

**涉及的脚本**：
- `run_set_apt_mirror.sh` - 备份 `/etc/apt/sources.list`
- `run_set_pip_mirror.sh` - 备份 `~/.pip/pip.conf`
- `run_set_docker_mirror.sh` - 备份 `/etc/docker/daemon.json`

---

**维护者**：Ascend Team
**最后更新**：2026-03-27