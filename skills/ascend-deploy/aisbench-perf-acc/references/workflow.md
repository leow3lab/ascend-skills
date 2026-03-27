---
applicable_aisbench_version: "v0.2.0 - v0.3.x"
last_verified: 2026-03-12
version_check_warning:交互式工作流程依赖 AISBench 的命令行接口和数据集配置路径。版本升级可能涉及参数变更，使用前请确认命令兼容性。
---

# AISBench 交互式工作流程

## 触发条件

当用户表达以下需求时触发本技能：
- "测试我的 vLLM 模型在 XXX 上的表现"
- "跑一下 GSM8K/MMLU/HumanEval 评测"
- "对我的推理服务做压力测试"
- "帮我配置 AISBench 评测"

---

## 完整交互流程

### Step 1: 选择数据集

展示数据集分类表，让用户选择：

```
请选择数据集名称：
- 数学推理：GSM8K, AIME2025, MATH
- 多学科：MMLU, C-MMLU, C-Eval
- 代码生成：HumanEval
- 多任务：BBH, GPQA
- 性能测试：synthetic
```

**默认推荐：**
- 快速验证 → GSM8K
- 完整测试 → MMLU
- 代码能力 → HumanEval
- 压力测试 → synthetic

---

### Step 2: 选择配置文件

根据用户选择的数据集，展示可用配置表。

**示例（GSM8K）：**
```
GSM8K 可用配置：
1. gsm8k_gen_4_shot_cot_chat_prompt.py  【推荐】4-shot CoT，对话格式
2. gsm8k_gen_0_shot_cot_chat_prompt.py   0-shot 快速测试
3. gsm8k_gen_0_shot_cot_str.py           字符串格式
4. gsm8k_gen_0_shot_cot_str_perf.py      性能测试专用
```

**默认选择：** 推荐配置（通常是 4-shot 或 5-shot CoT 对话格式）

---

### Step 3: 确认数据量

```
是否限制测试数据量？(y/n)
> 输入：y
输入测试数据量：
> 输入：10（前 10 条快速验证）
```

**说明：** 不限制则使用数据集全部数据

---

### Step 4: 收集推理服务参数

逐项询问（带默认值）：

| 参数 | 提示 | 默认值 |
|------|------|--------|
| host_ip | 推理服务 IP 地址 | localhost |
| host_port | 推理服务端口 | 8080 |
| api_key | API Key（可选） | (空) |
| max_out_len | 最大输出 token 数 | 512（数学推理 1024） |
| temperature | 温度参数 | 0.01（精度）/ 0.7（创意） |
| batch_size | 并发请求数 | 1 |
| request_rate | 请求频率 | 0（一次性发送） |

---

### Step 5: 探测连通性

**使用脚本（推荐）：**
```bash
./scripts/test_connectivity.sh <host_ip> <host_port> [api_key]
```

**手动测试：**
```bash
curl -s http://<host_ip>:<host_port>/v1/models -H "Authorization: Bearer <api_key>"
```

**预期结果：**
- ✅ 成功：返回 `{"object":"list","data":[...]}`
- ❌ 失败：根据不同错误提示用户排查

---

### Step 6: 展示并确认命令

**使用脚本（推荐）：**
```bash
./scripts/run_benchmark.sh \
  --dataset gsm8k_gen_4_shot_cot_chat_prompt \
  --num-prompts 10 \
  --host-ip <host_ip> \
  --host-port <host_port> \
  --dump-eval-details
```

**手动命令：** 见 [scripts/run_benchmark.sh](../scripts/run_benchmark.sh)

**用户确认后执行**

---

### Step 7: 执行评测

执行命令并等待完成。

**预期输出：**
```
===== 评测结果 =====
dataset: gsm8k
accuracy: 90.00% (9/10)
评测耗时：3 分 30 秒
====================
```

**注意：**
- AISBench 启动需要 20-40 秒 warmup 时间
- 进度条可能在前 30 秒显示 0%，属于正常现象
- 等待超过 2 分钟无进展再排查

---

### Step 8: 保存结果

结果自动保存到：
```
~/aisbench-results/{YYYYMMDD_HHMMSS}_{dataset}/
├── summary/          # 汇总结果（CSV/MD/TXT）
├── predictions/      # 推理结果
├── results/          # 评测分数
├── configs/          # 配置文件
└── README.md         # 测试说明
```

**展示结果摘要：**
```
评测完成！
准确率：90.00% (9/10)
评测耗时：3 分 30 秒
结果已保存到：~/aisbench-results/20260305_161721_gsm8k/
```

---

## 场景化默认值

### 场景 1：快速精度测试
用户说："测一下 GSM8K"

默认配置：
- 数据集：GSM8K
- 配置：`gsm8k_gen_4_shot_cot_chat_prompt.py`
- 数据量：前 10 条
- 模式：精度测试

### 场景 2：完整数据集测试
用户说："完整测试 MMLU"

默认配置：
- 数据集：MMLU
- 配置：`mmlu_gen_5_shot_chat_prompt.py`
- 数据量：全部 5,800 题
- 模式：精度测试
- 自动添加：`--merge-ds`

### 场景 3：性能压力测试
用户说："做个压力测试"

默认配置：
- 数据集：synthetic
- 配置：`synthetic_gen_perf.py`
- 数据量：不限
- 模式：perf（性能测试）
- 压力参数：`request_rate=10`, `batch_size=32`, `duration=60s`

---

## 术语快速参考

| 术语 | 含义 | 推荐值 |
|------|------|--------|
| 0-shot | 无示例，测试真实能力 | 快速验证 |
| N-shot | 提供 N 个示例 | 提升准确率 |
| CoT | 思维链，逐步推理 | 复杂推理任务 |
| chat_prompt | 对话格式 | 对话模型 |
| str | 字符串格式 | 通用模型 |
| perf | 性能测试专用 | 压力测试 |
