# Ascend Skills Plugin - 安装指南

## 插件信息

- **名称**: ascend-skills
- **版本**: 1.0.0
- **描述**: 华为昇腾（Ascend）NPU 技能集合，包含 9 个职业技能
- **技能数量**: 9 个

## 安装方法

### 方法 1: 通过 Claude Code 命令安装（推荐）

在 Claude Code 会话中执行：

```
/plugin install https://github.com/leow3lab/awesome-ascend-skills.git
```

### 方法 2: 手动安装

1. 克隆仓库：
```bash
git clone https://github.com/leow3lab/awesome-ascend-skills.git
cd ascend-skills
```

2. 复制到 Claude Code 插件目录：
```bash
# 确保插件目录存在
mkdir -p ~/.claude/plugins/marketplaces/ascend-skills

# 复制到插件目录
cp -r . ~/.claude/plugins/marketplaces/ascend-skills/
```

3. 重启 Claude Code

## 验证安装

安装完成后，在 Claude Code 中可以：

1. 查看已安装的插件：
```
/plugin list
```

2. 测试技能触发（任选一个）：
- 输入："我需要监控 vLLM 在 Ascend NPU 上的性能"
- 应该自动触发 `vllm-ascend-prof` 技能

## 包含的技能

### ascend-deploy (部署相关 - 4个)

1. **aisbench-perf-acc** - vLLM 模型精度和性能评测
2. **evalscope-perf-acc** - 大模型评估框架 EvalScope
3. **modelscope-cli** - ModelScope 模型下载
4. **vllm-ascend-deploy** - vLLM 部署工具

### ascend-env (环境配置 - 4个)

5. **docker-env** - Docker NPU 环境配置
6. **hccn-tools** - HCCN 网络配置和诊断
7. **hccl-bench** - HCCL 集群通信性能测试
8. **mirror-proxy** - 国内镜像源和代理配置

### ascend-optim (性能优化 - 1个)

9. **vllm-ascend-prof** - vLLM 性能分析和监控

## 卸载

```
/plugin uninstall ascend-skills
```

## 故障排查

### 技能未自动触发

1. 检查插件是否正确安装：
```bash
ls ~/.claude/plugins/marketplaces/ascend-skills/skills/
```
应该看到 9 个技能目录。

2. 重启 Claude Code

3. 检查技能描述是否优化：
- 打开任一技能的 `SKILL.md` 文件
- 确认 `description` 字段包含具体的触发场景

### 插件安装失败

1. 检查网络连接和仓库地址
2. 确保 Claude Code 版本支持 `/plugin` 命令
3. 检查磁盘空间是否充足

## 更新

```
/plugin update ascend-skills
```

或重新安装：
```
/plugin uninstall ascend-skills
/plugin install https://github.com/leow3lab/awesome-ascend-skills.git
```

## 反馈

如有问题，请联系：
- **项目仓库**: https://github.com/leow3lab/awesome-ascend-skills.git
- **问题反馈**: 提交 Issue 到项目仓库