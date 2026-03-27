---
name: aisbench-perf-acc
description: vLLM 模型在标准数据集上的精度与性能评测工具。当用户需要评估模型准确率、测试推理服务性能或运行基准测试时使用。
---

# AISBench 精度与性能测试

**触发场景：** 用户需要评测 vLLM 模型在标准数据集上的准确率或推理服务性能。

---

## 使用方式

按照 [交互式工作流程](references/workflow.md) 引导用户完成配置：

1. **选择数据集** → GSM8K、MMLU、HumanEval 等
2. **选择配置文件** → shot 数、CoT、请求类型
3. **确认数据量** → 快速验证（10 条）或完整测试
4. **收集服务参数** → host、port、api_key 等
5. **探测连通性** → curl 测试服务是否可访问
6. **确认并执行** → 展示命令，用户确认后执行
7. **保存结果** → `~/aisbench-results/{时间戳}_{数据集}/`

---

## 核心命令

**推荐使用脚本：**

```bash
# 快速测试（GSM8K 前 10 条）
./scripts/run_benchmark.sh --dataset gsm8k_gen_4_shot_cot_chat_prompt --num-prompts 10

# 完整测试（MMLU 全部）
./scripts/run_benchmark.sh --dataset mmlu_gen_5_shot_chat_prompt --merge-ds --dump-eval-details
```

**手动命令模板：** 见 [scripts/run_benchmark.sh](scripts/run_benchmark.sh)

---

## 默认配置建议

| 场景 | 数据集 | 配置文件 | 数据量 |
|------|--------|----------|--------|
| 快速验证 | GSM8K | `gsm8k_gen_4_shot_cot_chat_prompt.py` | 前 10 条 |
| 完整测试 | MMLU | `mmlu_gen_5_shot_chat_prompt.py` | 全部（自动 `--merge-ds`） |
| 代码能力 | HumanEval | `humaneval_gen_0_shot.py` | 全部 164 题 |
| 压力测试 | synthetic | `synthetic_gen_perf.py` | 持续 60 秒 |

---

## 参考资源

- **[workflow.md](references/workflow.md)** — 完整交互式工作流程
- **[datasets.md](references/datasets.md)** — 全部数据集和配置文件列表
- **[troubleshooting.md](references/troubleshooting.md)** — 故障排查指南

## 脚本工具

| 脚本 | 用途 |
|------|------|
| [`scripts/test_connectivity.sh`](scripts/test_connectivity.sh) | 测试推理服务连通性 |
| [`scripts/run_benchmark.sh`](scripts/run_benchmark.sh) | 一键执行评测（推荐） |

---

## 术语解释

| 术语 | 含义 |
|------|------|
| 0-shot / N-shot | 无示例=N-shot，测试真实能力；有示例=N-shot，提升准确率 |
| CoT | 思维链（Chain-of-Thought），要求模型逐步推理 |
| chat_prompt / str | 对话格式（messages 数组）/ 字符串格式 |
| perf | 性能测试专用配置 |

---

## 注意事项

1. **warmup 时间：** AISBench 启动需 20-40 秒初始化，进度条前 30 秒可能显示 0%
2. **流式问题：** 如遇进度卡住，改用 `vllm_api_general_chat.py`（非流式）
3. **调试技巧：** 去掉 `--rm` 参数保留容器，用 `docker exec` 进入查看日志
