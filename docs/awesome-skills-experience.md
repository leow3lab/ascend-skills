# Ascend Skills 开发经验分享

本文档整理了我们在开发 Claude Code Skills 过程中学习到的经验和最佳实践。

> 最后更新：2026-03-27

---

## 一、理解 Skills 机制

### 官方文档

- [Agent Skills - Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) - Claude Agent Skills 官方概述
- [The Complete Guide to Building Skill for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) - Anthropic 官方 Skill 开发完整指南
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) - Skill 编写最佳实践

### 核心概念

Skills 是 Claude 的能力扩展机制，通过描述触发和指令内容增强 Claude 的特定领域能力。

---

## 二、设计原则

### 设计模式

- [5 Agent Skill design patterns](https://x.com/GoogleCloudTech/status/2033953579824758855) - Google Cloud Tech 分享的 5 种 Agent Skill 设计模式

### 关键原则

1. **用确定性的结构对冲模型生成的不确定性**
2. **三层架构：Entry → Composer → Atomic**
3. **渐进式披露：Metadata → SKILL.md → Bundled Resources**
4. **版本锚定：通过 frontmatter 管理版本依赖**

---

## 三、开发实践

### 参考项目

- [anthropics/skills](https://github.com/anthropics/skills) - Anthropic 官方 Skills 仓库
- [skillmatic-ai/awesome-agent-skills](https://github.com/skillmatic-ai/awesome-agent-skills) - 社区 Skills 精选列表

### 开发技巧

- 保持 SKILL.md 在 500 行以内
- 使用脚本处理确定性任务
- 清晰的触发描述避免误触发
- 版本化引用外部资源

---

## 四、实战经验

### Claude Code 团队经验

- [Lessons from Building Claude Code: How We Use Skills](https://x.com/trq212/status/2033949937936085378) - Claude Code 团队分享 Skills 使用经验

### 我们的踩坑记录

1. **触发描述要具体** - 模糊的描述会导致误触发或不触发
2. **脚本比指令更可靠** - 复杂逻辑用脚本实现，避免指令执行不一致
3. **文档分层管理** - 链接单独放 URL.md，实际内容放 README.md
4. **敏感信息扫描** - 开源前务必检查内部链接、密码、IP 等

---

## 五、持续学习

Skills 开发是一个持续迭代的过程，我们会在后续版本中不断更新本文档。

欢迎在 [Issues](https://github.com/leow3lab/ascend-skills/issues) 中分享你的经验和建议！