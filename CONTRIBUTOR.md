

# 🚀 贡献指南 (Contributing Guide)

感谢您关注 `ascend-skills`！无论是脚本优化、文档纠错还是新技能沉淀，您的每一份贡献都在帮助昇腾开发者社区构建更强大的工具库。

---

## 💡 我们可以一起做什么？

为了保持项目高质量迭代，我们欢迎以下类型的贡献：

* **文档精进**：修正描述偏差、补充实测案例或最佳实践。
* **新技能 (Skills) 沉淀**：将常用的部署、压测、调优脚本模块化。
* **实战反馈**：分享在 Ascend 硬件上遇到的“坑”与解决方案。
* **工具链优化**：改进现有脚本的鲁棒性或自动化程度。

---

## 🛠️ 参与贡献的流程

### 1. 核心原则：单一职责 (Atomic PR)

**每一笔 Pull Request (PR) 必须只包含一个独立的技能或功能修复。**

> **Why?** 这样可以极大提高 Code Review 效率，确保自动化校验精准触发，并支持单点回滚。

### 2. 分支管理规范

请勿直接提交到 `main` 分支。请遵循以下工作流：

1. **Sync**: 确保您的本地 `main` 分支是最新的。
2. **Branch**: 创建以功能为命名的特性分支。
```bash
git checkout -b feat/your-skill-name

```


3. **Verify**: 在提交前，请务必在真实环境下完成至少一次完整流程验证。

### 3. 文档与质量标准

每一个 Skill 都是一个自包含的单元，必须包含对应的 Markdown 说明文档。

* **标准模板**：请参考项目中的 `docs/skill-template.md` 文件
* **优秀案例**：参考 `skills/` 目录下已有技能的结构与详略

---

## 🤖 自动化检查 (提交前必做)

为了节省您的开发时间，避免因琐碎的格式问题被 Reviewer 打回，请在提交前运行 `skill-creator` 工具：

| 检查项 | 说明 |
| --- | --- |
| **目录结构** | 校验是否符合 `/skills/category/skill-name` 层级 |
| **MD 规范** | 检查必要标题行（背景、环境、步骤）是否缺失 |
| **脚本执行权限** | 确保 `.sh` 等文件具有可执行属性 |

```bash
# 1. 克隆校验 Skill
git clone https://github.com/leow3lab/awesome-ascend-skills.git

# 2. 运行本地校验
cd skill-creator

# 3. 让你的ClaudeCode 进行检查格式 在你的技能目录下启动 Claude Code ， 输入指令让 AI 替你把关
> "请根据 skill-creator 的规范，检查当前目录下文档的逻辑完整性，并自动修正 Markdown 的格式错误。"
```

---

## ✉️ 提交建议 (Commit Message)

推荐使用 **Conventional Commits** 格式：

* `feat: add new skill for vLLM optimization`
* `docs: fix typo in installation guide`
* `fix: resolve memory leak in profiling script`

