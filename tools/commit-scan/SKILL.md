---
name: commit-scan
description: 提交前安全扫描工具。用于扫描代码库中的敏感信息（内网链接、硬编码密码、内部IP），支持自动修复。当用户需要提交代码、git commit、git push、创建PR、发布前检查、安全审计、检查敏感信息时使用此技能。
---

# 概述

本技能用于项目提交前的安全检查，**扫描并自动修复**以下敏感内容：

| 检查类型 | 说明 | 修复方式 |
|---------|------|---------|
| 华为内网链接 | wiki.huawei.com 等 | 移除或替换 |
| 硬编码密码 | password, api_key 等 | 使用环境变量 |
| 内部 IP | 100.64.x.x 等 | 替换为占位符 |
| 个人信息 | 工号、邮箱等 | 完全移除 |

**使用场景**：
- 提交代码前 (`git commit`)
- 推送代码前 (`git push`)
- 创建 PR 前
- 开源发布前
- 定期安全审计

---

# 快速使用

## 一键扫描

```bash
bash tools/commit-scan/scripts/scan_and_fix.sh skills/
```

## 扫描并自动修复

```bash
bash tools/commit-scan/scripts/scan_and_fix.sh skills/ fix
```

---

# Git Hook 集成（可选）

创建 pre-commit hook：

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
bash tools/commit-scan/scripts/scan_and_fix.sh skills/
EOF
chmod +x .git/hooks/pre-commit
```

---

# 检查规则

## 1. 禁止包含华为内网链接

以下链接必须在提交前移除：

- `wiki.huawei.com` - 内部 Wiki
- `3ms.huawei.com` - 知识社区
- `jx.huawei.com` - 社区帖子
- `hub.openlab-sh.sd.huawei.com` - 内部 Harbor
- `proxyhk.huawei.com` - 代理服务器
- `mirrors.tools.huawei.com` - 镜像源
- `w3.huawei.com` - 内部门户

## 2. 禁止包含敏感信息

### 2.1 密码和密钥

- 硬编码密码：`password`, `passwd`, `pwd`
- API 密钥：`api_key`, `apikey`, `token`, `secret`
- 访问凭证：`access_key`, `private_key`, `credential`

### 2.2 内部 IP 地址

- 华为内部 IP 段：`100.64.0.0/10`（如 `100.100.x.x`）
- 真实服务器 IP：`192.168.x.x`, `10.x.x.x` 等

**示例 IP 除外**：`0.0.0.0`, `127.0.0.1`, `10.0.0.10`, `192.168.1.1`

### 2.3 个人信息

- 员工工号
- 内部邮箱地址
- 手机号码

---

# 处理方式

| 敏感类型 | 处理方式 |
|---------|---------|
| 内网链接 | 移除或替换为公开文档链接 |
| 硬编码密码 | 使用环境变量或配置文件 |
| 内部 IP | 替换为 `<YOUR_SERVER_IP>` 等占位符 |
| 个人信息 | 完全移除 |

---

# 相关资源

- [CLAUDE.md](../../CLAUDE.md) - 项目规范
- [scripts/scan_and_fix.sh](scripts/scan_and_fix.sh) - 扫描修复脚本