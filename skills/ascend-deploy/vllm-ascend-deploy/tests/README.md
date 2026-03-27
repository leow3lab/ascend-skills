# vllm-ascend-deploy 测试框架

**目的**：遵循 RULE.md 规则 9（行为回归测试），确保 Skill 的逻辑、数据、行为在版本迭代中保持一致。

---

## 测试目录结构

```
tests/
├── README.md                    # 本文档
├── test_scripts.sh              # 脚本可执行性测试
├── test_consistency.md          # 知识一致性测试用例
├── test_trigger.md             # 触发场景测试用例
└── check_env.sh               # 环境对齐检查脚本
```

---

## 测试类型

### 1. 脚本执行测试 (`test_scripts.sh`)

**目的**：验证 `scripts/` 下的脚本是否能正常运行

**测试维度**：
- [x] 脚本文件存在性
- [x] 脚本可执行权限
- [x] `--help` 参数支持
- [x] 参数验证（dry-run 模式）
- [x] 无硬编码敏感值（IP、端口、密码等）
- [x] shebang 规范性（`#!/bin/bash` 或 `#!/usr/bin/env bash`）

**执行方式**：
```bash
cd skills/ascend-deploy/vllm-ascend-deploy
bash tests/test_scripts.sh
```

---

### 2. 知识一致性测试 (`test_consistency.md`)

**目的**：验证 `references/` 中的版本信息与文档内容一致

**测试维度**：
- [x] Frontmatter 完整性（版本号、验证日期、风险提示）
- [x] 版本格式是否为区间形式（如 `8.0.RC1 - 8.0.x`）
- [x] 文档中的版本号与 Frontmatter 声明一致
- [x] SKILL.md 引用的 references 文档存在且路径正确
- [x] 镜像标签、命令参数等项目在文档各处一致

**执行方式**：
```bash
# 手动检查各个测试用例（参见 test_consistency.md 中的详细说明）
# 或运行自动化脚本（如文档中提供的 test_consistency.sh）
```

---

### 3. 触发场景测试 (`test_trigger.md`)

**目的**：验证 Skill 在不同用户意图下能否正确触发

**测试维度**：
- [ ] 明确场景触发（用户明确说"部署 vLLM"）
- [ ] 隐含场景触发（用户说"启动模型服务"）
- [ ] 歧义场景判别（用户说"运行容器" - 可能是部署类，也可能是环境类）
- [ ] 负面判别（不应触发本 Skill 的场景）

**测试用例示例**：

| 用户输入 | 预期触发 Skill | 优先级 |
|---------|----------------|--------|
| "帮我部署 Qwen3.5 模型到 NPU 服务器" | vllm-ascend-deploy | 高 |
| "在 Ascend 服务器上启动推理服务" | vllm-ascend-deploy | 高 |
| "创建 Docker 容器运行 vLLM" | vllm-ascend-deploy | 中 |
| "检查 NPU 状态" | vllm-ascend-prof（优化类） | - |
| "配置 APT 镜像源" | mirror-proxy（环境类） | - |

---

### 4. 环境对齐检查 (`check_env.sh`)

**目的**：验证本地环境与 Skill 要求的版本匹配

**检查项**：
- [ ] Ascend 驱动版本（23.0.3 - 23.0.x）
- [ ] CANN 版本（8.0.RC1 - 8.0.x）
- [ ] Python 版本（3.10.x）
- [ ] Docker 版本（20.10+）
- [ ] vLLM-Ascend 版本（v0.1.x）

**执行方式**：
```bash
cd skills/ascend-deploy/vllm-ascend-deploy
bash tests/check_env.sh
```

**预期输出**：
```
=== Ascend Skills 环境版本对齐检查 ===

检查 Ascend 驱动... ✓ 23.0.3
检查 CANN... ✓ 8.0.RC1
检查 Python... ✓ 3.10.12
检查 Docker... ✓ 20.10.7

✓ 环境检查通过，所有版本兼容
```

---

## 测试执行流程

### 开发阶段（每次修改后）

1. **脚本测试**：确保修改的脚本语法正确、可执行
   ```bash
   bash tests/test_scripts.sh
   ```

2. **一致性测试**：确保引用的文档存在且版本信息一致
   ```bash
   # 检查 test_consistency.md 中的用例
   ```

3. **执行测试**：在新环境中运行脚本验证功能
   ```bash
   bash scripts/create_container.sh --help
   # 或使用 --dry-run 模式（如果支持）
   ```

---

### 提交前（Pre-commit）

1. **所有测试通过**
   ```bash
   bash tests/test_scripts.sh && bash tests/check_env.sh
   ```

2. **更新验证日期**：如果修改了 `references/` 中的内容，更新 `last_verified` 日期

3. **提交信息规范**：包含测试通过说明
   ```
   feat: vllm-ascend-deploy 优化容器创建脚本

   - 添加 --dry-run 参数支持
   - 优化 NPU 设备检测逻辑
   - 测试通过：test_scripts.sh ✓
   - 环境检查通过：check_env.sh ✓
   ```

---

### 版本发布前（Release）

1. **全量回归测试**：在目标环境的多个版本组合下测试
   - CANN 8.0.RC1 + Driver 23.0.3
   - CANN 8.0.RC2 + Driver 23.0.4
   - 检查测试用例中的所有场景

2. **触发准确性评估**：通过 Claude Code 实际对话测试，统计触发准确率
   - 准确率 = 正确触发次数 / (正确触发次数 + 误触发次数 + 漏触发次数)

3. **文档更新**：确保 `VERSION_MATRIX.md`、`RULE.md` 版本号同步更新

---

## 测试覆盖率目标

| 测试类型 | 覆盖率目标 | 当前状态 |
|---------|------------|---------|
| 脚本可执行性 | 100% | ✅ 完成 |
| 知识一致性（Frontmatter） | 100% | ✅ 完成 |
| 知识一致性（文档内容） | 80% | ⚠️ 部分手动 |
| 触发场景测试 | 80% | 📝 待实现 |
| 环境对齐检查 | 100% | ⏳ 待添加 |

---

## 持续集成（CI/CD）

### GitHub Actions 示例配置

```yaml
name: Skill Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ubuntu-20.04-cann8.0
    steps:
      - uses: actions/checkout@v3

      - name: Run script tests
        run: |
          cd skills/ascend-deploy/vllm-ascend-deploy
          bash tests/test_scripts.sh

      - name: Check consistency
        run: |
          cd skills/ascend-deploy/vllm-ascend-deploy
          bash tests/test_consistency.sh

      - name: Environment check
        run: |
          cd skills/ascend-deploy/vllm-ascend-deploy
          bash tests/check_env.sh
```

---

## 测试失败处理

### 常见失败原因

1. **脚本不可执行**：`chmod +x` 添加权限
2. **版本不匹配**：参考 `VERSION_MATRIX.md` 查找兼容版本
3. **Frontmatter 缺失**：按格式补充版本信息
4. **死链**：检查 `SKILL.md` 中的引用路径

### 回归流程

1. 识别失败类型
2. 在目标环境复现问题
3. 修复并验证
4. 更新测试用例（如发现新问题场景）
5. 重新运行所有测试

---

**维护者**：Ascend Team
**文档版本**：v1.0
**最后更新**：2026-03-12