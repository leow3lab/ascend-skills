---
name: evalscope-perf-acc
description: 综合性大模型评估框架，支持准确性和性能评测。当用户需要评估模型代码生成能力、测试推理服务性能或运行自定义数据集测试时使用。
---

# 概述

EvalScope 是一个综合性的大模型评估框架，支持通过 OpenAI API 或直接推理对模型进行多维度评估。

## 核心能力

| 评估类型 | 功能说明 | 适用场景 |
|----------|---------|---------|
| **准确性评估** | 使用标准数据集评估模型代码生成和推理能力 | 模型对比、基准测试、质量验证 |
| **性能压测** | 测试模型的吞吐量、延迟等性能指标 | 容量规划、性能优化、压力测试 |
| **自定义数据集测试** | 使用自定义数据集进行性能测试 | 业务场景验证、特定场景性能评估 |

## 目录结构

```
evalscope-perf-acc/
├── scripts/              # 评估脚本
│   ├── run_eval_acc.sh          # 准确性评估脚本
│   ├── run_eval_perf.sh         # 性能压测脚本
│   ├── run_eval_acc_simple.sh   # 简化版准确性评估
│   ├── run_eval_perf_real.sh    # 自定义数据集性能测试
│   └── run_build_docker.sh     # Docker 容器构建脚本
├── assets/              # 资源文件
│   └── aime2025.txt            # AIME 2025 自定义数据集
├── reference/           # 参考资料
│   ├── README.md              # 官方文档和资料链接
│   └── WIKI.md              # 扩展资料链接
└── SKILL.md            # 本文档
```

# 前置条件

| 环境类型 | 版本要求 | 说明 |
|----------|---------|------|
| vLLM 推理服务 | 已部署 | OpenAI API 兼容接口 |
| Python | 3.8+ | 裸机部署需要 |
| Docker | 20.10+ | 推荐使用，简化环境配置 |
| evalscope | 最新版 | `pip install 'evalscope[perf,app]'` |

# 快速开始

## 部署方式对比

| 部署方式 | 优点 | 缺点 | 推荐场景 |
|----------|------|------|----------|
| **Docker** | 环境一致、配置简单、易于迁移 | 需要 Docker 环境 | 生产环境、多台服务器部署 |
| **裸机** | 无 Docker 依赖、直接访问系统资源 | 需要手动配置依赖 | 单机测试、开发调试 |

## 使用 Docker 部署（推荐）

### 1. 加载镜像

```bash
# 根据实际环境修改镜像路径
docker load -i <镜像路径>/evalscope-arc-bench-<版本>.tar
```

### 2. 配置并启动容器

首次使用前，请修改 `scripts/run_build_docker.sh` 中的配置参数：
- `container_name` - 容器名称
- `image_name` - 镜像名称和版本
- `code_path` - 共享存储路径

```bash
# 启动容器
scripts/run_build_docker.sh
```

### 3. 调整脚本配置

编辑 `scripts/run_eval_acc.sh` 或 `scripts/run_eval_perf.sh`，修改以下参数：
- `CONFIG` 数组 - 设置 API 服务地址和模型名称
- `TOKENIZER_BASE_PATH` - 设置模型基础路径

### 4. 执行评估

```bash
# 准确性评估
scripts/run_eval_acc.sh

# 性能压测
scripts/run_eval_perf.sh
```

## 裸机部署

### 1. 安装依赖

```bash
pip install 'evalscope[perf,app]'
pip install 'swanlab[dashboard]'
```

### 2. 配置脚本

编辑 `scripts/run_eval_acc.sh` 或 `scripts/run_eval_perf.sh`，修改配置参数。

### 3. 执行评估

```bash
# 准确性评估
scripts/run_eval_acc.sh

# 性能压测
scripts/run_eval_perf.sh
```

# 脚本功能详解

## run_eval_acc.sh - 准确性评估

### 功能说明

执行模型的准确性评估，使用标准数据集（HumanEval、MBPP 等）评估模型代码生成和推理能力，输出准确率、Pass@1 等指标。

### 配置方法

直接编辑脚本中的配置变量：

```bash
# API 服务配置
CONFIG=(
    "http://<API_URL>/v1|<模型名称>"
)

# 模型基础路径
TOKENIZER_BASE_PATH=/nfs/shared/models/huggingface
```

### 关键参数说明

| 参数 | 说明 | 示例值 |
|------|------|--------|
| `CONFIG` | API 服务地址和模型名称 | `"http://<YOUR_SERVER_IP>:8088/v1\|Qwen/Qwen3-Coder-30B-Instruct"` |
| `TOKENIZER_BASE_PATH` | 模型存储基础路径 | `/nfs/shared/models/huggingface` |
| `--datasets` | 评估数据集 | `humaneval tool_bench aime25 live_code_bench` |
| `--eval-batch-size` | 批处理大小 | `16` |
| `--ignore-errors` | 忽略错误继续执行 | 无值 |

### 支持的数据集

- `humaneval` - Python 代码生成评估基准
- `mbpp` - 基础 Python 编程问题
- `scicode` - 科学计算代码生成评估
- `live_code_bench` - 实时代码生成
- `tool_bench` - 工具使用评估

### 配置调优建议

- **首次测试**：使用 `humaneval` 单个数据集，快速验证环境配置
- **生产评估**：根据模型类型选择合适的数据集组合
- **调优参数**：根据服务器资源调整 `--eval-batch-size`，过大可能导致内存不足

### 输出结果

评估结果保存在 `acc_outputs/` 目录，包含：
- `eval.log` - 评估日志
- `summary.json` - 评估结果汇总
- 可视化报告（如需要，使用 `evalscope app` 查看）

---

## run_eval_perf.sh - 性能压测

### 功能说明

执行模型性能压测，测试不同并发场景下的吞吐量（tokens/s）、延迟（ms）等性能指标，帮助评估模型的服务能力。

### 配置方法

```bash
# 配置格式：API_URL | 模型名称 | Prompt长度 | MaxTokens
CONFIG=(
    "http://<API_URL>/v1|<模型名称>|<PROMPT_LENGTH>|<MAX_TOKENS>"
)

# 模型基础路径
TOKENIZER_BASE_PATH=/nfs/shared/models/huggingface
```

### 关键参数说明

| 参数 | 说明 | 示例值 | 调优建议 |
|------|------|--------|-----------|
| `PROMPT_LENGTH` | Prompt 文本长度 | `4096`, `16384` | 根据实际场景选择 |
| `MAX_TOKENS` | 最大生成 token 数 | `1024`, `2048` | 根据输出需求调整 |
| `--parallel` | 并发数列表 | `10 30 50` | 测试不同并发下性能 |
| `--number` | 每个并发的请求数 | `30 50 100` | 与 `--parallel` 对应 |
| `--dataset` | 数据集类型 | `random` | 使用随机数据模拟场景 |

### 推荐测试场景

| 场景 | Prompt Length | Max Tokens | 适用场景 |
|------|---------------|------------|----------|
| 短文本 | 4096 | 1024 | 代码补全、问答 |
| 中等文本 | 16384 | 2048 | 代码生成、长文本生成 |
| 长文本 | 32768 | 4096 | 文档生成、多轮对话 |

### 配置调优建议

- **资源充足**：增大 `--parallel` 和 `--number`，测试极限性能
- **资源受限**：减小并发数，避免 OOM 错误
- **业务场景匹配**：根据实际业务调整 `PROMPT_LENGTH` 和 `MAX_TOKENS`

### 输出结果

性能指标保存在 `perf_outputs/` 目录，包含：
- `perf.log` - 性能测试日志
- `summary.json` - 性能结果汇总（吞吐量、延迟等）

---

## run_eval_acc_simple.sh - 简化版准确性评估

### 功能说明

提供了一组预配置的准确性评估参数，适合快速验证环境配置或进行初步测试。

### 使用方法

```bash
# 直接执行，无需修改配置
scripts/run_eval_acc_simple.sh
```

### 注意事项

- 脚本中的配置为示例值，生产环境请根据需求修改参数
- 适合在测试环境或首次部署时使用

---

## run_eval_perf_real.sh - 自定义数据集性能测试

### 功能说明

使用自定义数据集（如 AIME 数学竞赛题、企业内部问题集）进行性能测试，验证模型在特定业务场景下的性能表现。

> ⚠️ **重要限制**：此脚本仅用于性能测试，不支持准确性评测。

### 配置方法

```bash
# 配置格式：API_URL | 模型名称
CONFIG=(
    "http://<API_URL>/v1|<模型名称>"
)

# 修改数据集路径
--dataset-path ./assets/<你的数据集>.txt
```

### 自定义数据集格式

每行一个问题或文本内容，例如：

```
Find the sum of all integer bases b>9 for which 17_b is a divisor of 97_b.

On triangle ABC points A,D,E, and B lie that order on side AB with AD=4, DE=16, and EB=8.
```

### 适用场景

- 实际业务场景的性能验证
- 特定长度的文本性能测试
- 压力测试和稳定性评估
- 并发处理能力验证

### 输出结果

结果保存在 `custom_perf_outputs/` 目录

---

## run_build_docker.sh - Docker 容器启动

### 功能说明

启动 evalscope Docker 容器。

### 配置方法

编辑脚本中的配置参数：

```bash
# 容器配置
container_name=evalscope-benchmark-cli
image_name=evalscope-arc-bench:20260121
code_path=<你的共享存储路径>
workdir=${code_path}/nfs/data/agent/evalscope-benchmark
```

### 输出结果

容器启动成功后，会自动进入容器内的 bash shell。

---

# 环境配置

> 💡 **重要提示**：本 skill 中的所有配置参数为示例值，请根据实际场景和需求灵活调整。

## 核心配置参数

### 1. Docker 镜像路径

```bash
docker load -i <你的镜像路径>/evalscope-arc-bench-<版本>.tar
```

### 2. 模型存储路径

编辑脚本中的 `TOKENIZER_BASE_PATH` 变量：

```bash
TOKENIZER_BASE_PATH=/nfs/shared/models/huggingface
```

### 3. API 服务地址

编辑脚本 `CONFIG` 数组中的配置：

```bash
# 格式："http://<服务器IP>:<端口>/v1|<模型名称>"
"http://<YOUR_SERVER_IP>:8088/v1|Qwen/Qwen3-Coder-30B-Instruct"
```

### 4. 共享存储路径

编辑 `run_build_docker.sh` 中的 `code_path` 参数：

```bash
code_path=<你的共享存储路径>
```

### 5. 代理配置（可选）

如果需要使用代理下载数据集：

**下载数据集时**（由脚本自动处理）：
```bash
source /opt/tools/proxy.sh
```

**评估执行前**（脚本会自动清除代理）：
```bash
unset https_proxy http_proxy no_proxy
```

---

# 输出结果

## 结果目录结构

```
evalscope-perf-acc/
├── acc_outputs/              # 准确性评估结果
│   └── <模型名>_<时间戳>/
│       ├── eval.log         # 评估日志
│       └── summary.json    # 评估结果汇总
├── perf_outputs/             # 性能压测结果
│   └── <模型名>-<时间戳>/
│       ├── perf.log         # 性能测试日志
│       └── summary.json    # 性能指标汇总
└── custom_perf_outputs/      # 自定义数据集性能测试结果
    └── <模型名>-<时间戳>/
        └── summary.json    # 测试结果汇总
```

## 准确性评估结果解读

主要评估指标（以 HumanEval 为例）：

| 指标 | 说明 | 含义 |
|--------|------|------|
| **Pass@1** | 第一次尝试通过率 | 入库即正确的概率 |
| **Pass@10** | 10 次尝试中至少一次通过 | 有多次尝试机会时的成功率 |
| **Mean Pass@k** | 平均通过率 | 综合评估模型能力 |

参考基准（仅供参考，实际结果因模型和配置而异）：
- Qwen3-Coder-30B: HumanEval Pass@1 ~60-65%
- Qwen3-Next-80B: HumanEval Pass@1 ~55-60%

## 性能测试结果解读

主要性能指标：

| 指标 | 说明 | 优化目标 |
|--------|------|----------|
| **Throughput** | 吞吐量（tokens/s） | 越高越好 |
| **TTFT** | Time to First Token | 首字延迟，越低越好 |
| **Latency** | 响应延迟 | 越低越好 |

## 查看结果

### 查看日志

```bash
# 准确性评估日志
tail -f ./acc_outputs/<模型名>_<时间戳>/eval.log

# 性能测试日志
tail -f ./perf_outputs/<模型名>-<时间戳>/perf.log
```

### 使用 Dashboard 查看评估结果

```bash
# 启动评估结果可视化界面
evalscope app --outputs ./outputs --server-name 0.0.0.0 --server-port 8887
```

访问 `http://<服务器IP>:8887` 查看可视化结果。

---

# 自定义数据集性能测试

> ⚠️ **重要说明**：
> - 自定义数据集**仅支持性能测试**（吞吐量、延迟等指标）
> - 自定义数据集**不支持准确性评测**（准确率、Pass@1 等指标）
> - 如需进行准确性评测，请使用 `run_eval_acc.sh` 配合内置标准数据集（humaneval、mbpp 等）

## 自定义数据集格式

1. 在 `assets/` 目录下创建文本文件（如 `my_dataset.txt`）
2. 每行一个问题或文本内容
3. 使用 `run_eval_perf_real.sh` 脚本，修改数据集路径：

```bash
--dataset-path ./assets/my_dataset.txt
```

## 数据集示例

### AIME 2025 数学竞赛题（`assets/aime2025.txt`）

```
Find the sum of all integer bases b>9 for which 17_b is a divisor of 97_b.

On triangle ABC points A,D,E, and B lie that order on side AB with AD=4, DE=16, and EB=8.
...
```

### 企业内部示例

```
如何申请服务器资源？
请解释什么是容器化部署？
公司的数据安全政策是什么？
...
```

## 自定义数据集使用场景

| 场景 | 说明 | 性能测试意义 |
|------|------|--------------|
| **实际业务场景验证** | 使用真实业务问题测试 | 验证模型在真实场景下的性能表现 |
| **特定长度文本测试** | 验证不同长度的输入处理能力 | 评估长文本处理性能和内存使用 |
| **压力测试** | 大量并发请求测试 | 验证模型在高负载下的稳定性 |
| **并发能力验证** | 多用户同时访问场景 | 测试模型的并发处理能力 |

---

# 支持的准确性评测数据集

## 数据集说明

以下数据集用于**准确性评估**，与性能测试功能（`run_eval_perf.sh`）完全不同。

## 数据集列表

| 数据集 | 类型 | 说明 | 推荐模型 |
|--------|------|------|----------|
| `humaneval` | 代码生成 | Python 代码生成评估基准 | 所有代码模型 |
| `mbpp` | 代码生成 | 基础 Python 编程问题，样本量适中 | Qwen-Coder, CodeLlama |
| `scicode` | 代码生成 | 科学计算代码生成评估 | 科学计算相关模型 |
| `live_code_bench` | 代码生成 | 实时代码生成和调试能力 | 代码工具类模型 |
| `tool_bench` | 工具使用 | 工具和函数调用能力评估 | Agent 相关模型 |
| `aime25` | 数学推理 | AIME 2025 数学竞赛题 | 数学推理能力强模型 |
| `general_fc` | 通用能力 | 通用任务评估 | 通用大模型 |

## 数据集选择建议

### 代码生成模型（如 Qwen-Coder）

推荐数据集组合：
- `humaneval` - 标准代码生成基准
- `mbpp` - 基础编程能力
- `live_code_bench` - 实时编码能力

### 通用大模型（如 Qwen-Next）

推荐数据集组合：
- `humaneval` - 代码能力验证
- `tool_bench` - 工具使用能力
- `general_fc` - 通用任务评估

### 数学推理模型

推荐数据集组合：
- `aime25` - 高难度数学问题
- `humaneval` - 代码中的数学逻辑

> **注意**：以上数据集通过 `run_eval_acc.sh` 使用，用于获取模型的准确率指标。如需性能测试，请使用 `run_eval_perf.sh`。

---

# 常见问题排查

## 问题 1：数据集下载失败

**症状**：首次运行时报错无法下载或加载数据集

**可能原因**：
- 网络连接问题或代理配置错误
- ModelScope 服务访问受限

**解决方法**：

```bash
# 1. 检查网络连接
ping modelscope.cn

# 2. 配置代理（如需要）
export https_proxy=http://proxy:port
export http_proxy=http://proxy:port

# 3. 使用本地数据集（如已下载）
# 将数据集放置在 evalscope 支持的缓存目录
```

---

## 问题 2：Tokenizer 路径错误

**症状**：报错 `tokenizer.json not found` 或 `No such file or directory`

**可能原因**：
- `TOKENIZER_BASE_PATH` 配置错误
- 模型名称不匹配
- tokenizer 文件未完整下载

**解决方法**：

```bash
# 1. 验证路径配置
echo $TOKENIZER_BASE_PATH

# 2. 检查 tokenizer 文件是否存在
ls -la ${TOKENIZER_BASE_PATH}/${MODEL_NAME}/tokenizer.json

# 3. 列出可用的模型目录
ls ${TOKENIZER_BASE_PATH}

# 4. 确认模型名称是否正确
# 注意：模型名称中的 / 需要与目录结构匹配
```

---

## 问题 3：内存不足 (OOM)

**症状**：评估过程中报错 `Out of Memory` 或 GPU/CPU 内存溢出

**可能原因**：
- 并发数过高
- Prompt 长度或 Max Tokens 设置过大
- 模型本身占用内存较大

**解决方法**：

```bash
# 1. 减小并发数
# 修改 run_eval_perf.sh 中的 --parallel 参数
--parallel 5 10 20

# 2. 减小 token 数量
--max-tokens 1024
--min-prompt-length 8192
--max-prompt-length 8192

# 3. 监控资源使用
# GPU
watch -n 1 "nvidia-smi"

# CPU
watch -n 1 "free -h && top -n 1"
```

---

## 问题 4：API 连接失败

**症状**：报错 `Connection refused` 或 `API request failed`

**可能原因**：
- vLLM 推理服务未启动
- API 地址或端口配置错误
- 网络连接问题
- 防火墙阻止访问

**解决方法**：

```bash
# 1. 检查 vLLM 服务状态
ssh root@<vLLM服务器IP> "docker ps | grep vllm"

# 2. 测试 API 连通性
curl -s http://<API_URL>/v1/models
curl -s http://<API_URL>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"<模型名>","messages":[{"role":"user","content":"hello"}],"max_tokens":10}'

# 3. 检查端口监听状态
ss -tlnp | grep <端口>

# 4. 检查网络连通性
telnet <服务器IP> <端口>
ping <服务器IP>
```

---

## 问题 5：评估结果异常（准确率过低）

**症状**：准确率异常低（如 0% 或远低于预期）

**可能原因**：
- API 服务返回异常
- 模型名称配置错误
- 数据集下载或加载失败
- 代理设置导致 API 请求失败

**解决方法**：

```bash
# 1. 测试 API 正常返回
curl -s http://<API_URL>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"<模型名>","messages":[{"role":"user","content":"写一个Python函数"}],"max_tokens":50}'

# 2. 检查评估日志中的错误
tail -f ./acc_outputs/*/eval.log | grep -i error
tail -f ./perf_outputs/*/perf.log | grep -i error

# 3. 验证模型名称是否与 API 服务匹配
# 获取 API 支持的模型列表
curl -s http://<API_URL>/v1/models | jq

# 4. 确认数据集加载成功
# 检查日志中是否有数据集加载信息
grep -i "dataset" ./acc_outputs/*/eval.log
```

---

## 问题 6：Docker 容器启动失败

**症状**：`docker run` 命令报错

**可能原因**：
- 镜像未加载或不存在
- 卷挂载路径不存在
- 端口已被占用

**解决方法**：

```bash
# 1. 检查镜像是否存在
docker images | grep evalscope

# 2. 检查挂载路径是否存在
ls -la /nfs2

# 3. 检查端口占用
ss -tlnp | grep 8080

# 4. 查看详细的错误信息
docker run --rm --name test-debug <镜像名> /bin/bash
```

---

## 问题 7：代理相关问题

**症状**：数据集下载失败，但 API 调用也无法正常工作

**可能原因**：
- 代理配置在数据集下载后未清除
- 代理配置导致 API 请求失败

**解决方法**：

```bash
# 1. 检查当前代理设置
env | grep proxy

# 2. 清除代理（评估前需要）
unset https_proxy http_proxy no_proxy

# 3. 验证 API 连接
curl -v http://<API_URL>/v1/models

# 4. 如需再次下载数据集，重新配置代理
source /opt/tools/proxy.sh
# 下载完成后，再次清除代理
```

---

# 参考资料

- `reference/README.md` - 官方文档和资料链接
- `reference/WIKI.md` - 扩展资料链接
- [EvalScope 官方文档](https://evalscope.readthedocs.io/)
- [EvalScope GitHub](https://github.com/modelscope/evalscope)
- [EvalScope 性能压测指南](https://evalscope.readthedocs.io/zh-CN/latest/perf)
- [EvalScope 支持的数据集](https://evalscope.readthedocs.io/zh-CN/latest/datasets)

## 常用命令参考

### Docker 操作
```bash
docker ps              # 查看运行中的容器
docker logs -f <容器名>  # 查看容器日志
docker exec -it <容器名> /bin/bash  # 进入容器
```

### 常用 evalscope 命令
```bash
evalscope eval ...      # 准确性评估
evalscope perf ...      # 性能压测
evalscope app ...       # 启动可视化界面
```