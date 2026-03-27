---
applicable_aisbench_version: "v0.2.0 - v0.3.x"
last_verified: 2026-03-12
version_check_warning: 数据集配置在 AISBench v0.2.x 版本中验证。更高版本可能有配置文件路径变化，使用前请确认兼容性。
---

# AISBench 数据集配置参考

本文档列出 AISBench 镜像中所有可用的数据集及其配置文件。

---

## 数学推理

### GSM8K
**配置目录：** `gsm8k`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `gsm8k_gen.py` | - | - | 基础生成配置 |
| `gsm8k_gen_4_shot_cot_chat_prompt.py` | 4-shot | ✅ | **推荐**：对话模型，4-shot 示例 |
| `gsm8k_gen_0_shot_cot_chat_prompt.py` | 0-shot | ✅ | 快速测试，对话模型 |
| `gsm8k_gen_0_shot_cot_str.py` | 0-shot | ✅ | 字符串格式，快速测试 |
| `gsm8k_gen_0_shot_cot_str_perf.py` | 0-shot | ✅ | **性能测试专用** |
| `gsm8k_gen_0_shot_noncot_chat_prompt.py` | 0-shot | ❌ | 简单问答，无需推理 |
| `gsm8k_gen_4_shot_cot_str.py` | 4-shot | ✅ | 字符串格式，4-shot 示例 |

### AIME2025
**配置目录：** `aime2025`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `aime2025_gen.py` | - | - | 基础生成配置 |
| `aime2025_gen_0_shot_chat_prompt.py` | 0-shot | ✅ | **推荐**：对话模型，带思维链 |

### MATH
**配置目录：** `math`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `math500_gen_0_shot_cot_chat_prompt.py` | 0-shot | ✅ | MATH500 子集，对话模型 |
| `math_prm800k_500_0shot_cot_gen.py` | 0-shot | ✅ | **推荐**：PRM800K 精选 500 题 |
| `math_prm800k_500_5shot_cot_gen.py` | 5-shot | ✅ | PRM800K 精选 500 题，5-shot |

---

## 多学科理解

### MMLU
**配置目录：** `mmlu`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `mmlu_gen.py` | - | - | 基础生成配置 |
| `mmlu_gen_0_shot_cot_chat_prompt.py` | 0-shot | ✅ | **推荐**：对话模型，带思维链 |
| `mmlu_gen_5_shot_chat_prompt.py` | 5-shot | ✅ | **推荐**：对话模型，5-shot 示例 |
| `mmlu_gen_5_shot_str.py` | 5-shot | ✅ | 字符串格式，5-shot 示例 |
| `mmlu_ppl_0_shot_str.py` | 0-shot | - | PPL 评估，字符串格式 |

### C-MMLU（中文）
**配置目录：** `cmmlu`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `cmmlu_gen_0_shot_cot_chat_prompt.py` | 0-shot | ✅ | **推荐**：对话模型，带思维链 |
| `cmmlu_gen_5_shot_cot_chat_prompt.py` | 5-shot | ✅ | 对话模型，5-shot 示例 |
| `cmmlu_ppl_0_shot_cot_chat_prompt.py` | 0-shot | - | PPL 评估，对话模型 |

### C-Eval（中文）
**配置目录：** `ceval`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `ceval_gen.py` | - | - | 基础生成配置 |
| `ceval_gen_0_shot_cot_chat_prompt.py` | 0-shot | ✅ | **推荐**：对话模型，带思维链 |
| `ceval_gen_0_shot_noncot_chat_prompt.py` | 0-shot | ❌ | 对话模型，不带思维链 |
| `ceval_gen_0_shot_str.py` | 0-shot | ✅ | 字符串格式，通用模型 |
| `ceval_gen_0_shot_str_perf.py` | 0-shot | ✅ | **性能测试专用** |
| `ceval_gen_5_shot_str.py` | 5-shot | ✅ | 字符串格式，5-shot 示例 |
| `ceval_ppl_0_shot_str.py` | 0-shot | - | PPL 评估，字符串格式 |

---

## 代码生成

### HumanEval
**配置目录：** `humaneval`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `humaneval_gen_0_shot.py` | 0-shot | - | **推荐**：代码生成标准测试 |
| `humaneval_gen_0_shot_perf.py` | 0-shot | - | **性能测试专用** |

---

## 多任务/科学

### BBH
**配置目录：** `bbh`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `bbh_gen.py` | - | - | 基础生成配置 |
| `bbh_gen_3_shot_cot_chat.py` | 3-shot | ✅ | **推荐**：对话模型，3-shot |

### GPQA
**配置目录：** `gpqa`

| 配置文件 | Shot | CoT | 适用场景 |
|-----------|------|-----|----------|
| `gpqa_gen.py` | - | - | 基础生成配置 |
| `gpqa_gen_0_shot_cot_chat_prompt.py` | 0-shot | ✅ | **推荐**：对话模型，带思维链 |
| `gpqa_gen_0_shot_str.py` | 0-shot | ✅ | 字符串格式，通用模型 |
| `gpqa_ppl_0_shot_str.py` | 0-shot | - | PPL 评估，字符串格式 |

---

## 性能测试

### Synthetic
**配置目录：** `synthetic`

| 配置文件 | 适用场景 |
|-----------|----------|
| `synthetic_gen.py` | **推荐**：基础生成配置 |
| `synthetic_gen_string.py` | 字符串生成 |
| `synthetic_gen_tokenid.py` | Token ID 生成 |
