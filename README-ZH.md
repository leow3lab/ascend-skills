# Ascend Deploy Skills

<p align="center">
  <img src="./asserts/panic.png" alt="Ascend Deploy Skills" width="200">
</p>

专注于 **LLM 部署技能** 的技能集合，面向华为昇腾（Ascend）NPU。

支持 Claude Code、OpenClaw、OpenCode 等 AI 编程助手。

**当前版本：v0.1.0** | [更新日志](./CHANGELOG.md)

## 部署工作流

<p align="center">
  <img src="./asserts/flow.png" alt="部署流程" width="600">
</p>

## 安装

克隆仓库并让 AI 助手安装：

```bash
git clone https://github.com/leow3lab/ascend-skills.git

请帮我安装刚才克隆的 ascend-skills 仓库中的技能
```

## 更新

- **v0.1.0** (2026-03-27) - 初始公开发布，包含 9 个 Ascend NPU 部署技能

## 技能概览

### 模型部署 (ascend-deploy)

| 技能 | 说明 |
|------|------|
| **vllm-ascend-deploy** | 在 Ascend NPU 上部署 LLM 模型 |
| **aisbench-perf-acc** | vLLM 模型精度和性能评测 |
| **evalscope-perf-acc** | 综合性大模型评估框架 EvalScope |
| **modelscope-cli** | ModelScope 模型下载工具 |

### 环境配置 (ascend-env)

| 技能 | 说明 |
|------|------|
| **docker-env** | Docker 容器中 Ascend NPU 环境配置 |
| **hccn-tools** | HCCN 网络配置和诊断 |
| **hccl-bench** | HCCL 集群通信性能基准测试 |
| **mirror-proxy** | 镜像源和代理配置工具 |

### 性能优化 (ascend-optim)

| 技能 | 说明 |
|------|------|
| **vllm-ascend-prof** | vLLM 在 Ascend NPU 上的性能分析 |

## 使用示例

安装后，技能会自动根据您的需求触发：

- 部署 vLLM 模型 → `vllm-ascend-deploy` 自动触发
- 检查 NPU 性能 → `vllm-ascend-prof` 自动触发
- 运行模型基准测试 → `aisbench-perf-acc` 自动触发
- 配置 NPU 环境 → `hccn-tools`、`docker-env` 等自动触发

## 学习资源

我们在 [docs](./docs/) 目录中分享了开发经验和最佳实践：

- [Skills 开发经验分享](./docs/awesome-skills-experience.md) - 开发过程中的经验总结

## 内部工具

`tools/` 目录包含内部开发工具（不随插件安装）：

- **commit-scan** - 提交前安全扫描工具

## 参考资料

### 官方资源

- [昇腾社区](https://www.hiascend.com) - 华为 Ascend 开发者社区
- [CANN 文档中心](https://www.hiascend.com/document) - CANN 框架官方文档
- [昇腾镜像仓库](https://www.hiascend.com/developer/ascendhub) - 官方 Docker 镜像
- [Ascend 开源项目](https://gitcode.com/Ascend) - Ascend 开源项目集合

### 社区资源

- [Awesome Ascend Skills](https://github.com/ascend-ai-coding/awesome-ascend-skills) - Ascend 技能和资源精选列表
- [ClawHub](https://clawhub.com) - Ascend 开发者社区和资源
- [Skills.sh](https://skills.sh) - 技能文档和教程

## 仓库

https://github.com/leow3lab/ascend-skills

## 许可证

MIT License