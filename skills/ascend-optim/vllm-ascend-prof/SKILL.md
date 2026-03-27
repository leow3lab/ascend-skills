---
name: vllm-ascend-prof
description: vLLM 在 Ascend NPU 上的推理性能分析工具。用于分析推理服务性能、监控 NPU 状态、排查性能瓶颈、诊断算子性能问题。
---

# 概述

本技能提供 vLLM-Ascend 推理服务的性能分析能力，支持 NPU 状态监控、性能指标采集和性能问题诊断。

**使用场景**：
- 监控 NPU 使用情况
- 分析性能指标（TTFT、TPOT、吞吐量）
- 诊断性能瓶颈
- 分析算子性能，识别优化空间

**前置条件**：已部署 vLLM-Ascend 推理服务，拥有 NPU 访问权限

---

# 核心概念

## LLM 推理阶段

| 阶段 | 说明 | 关键指标 | 阈值 |
|------|------|----------|------|
| **Prefill** | 生成首个 token | TTFT | 与输入长度相关 |
| **Decode** | 持续生成 token | TPOT | < 50ms |

**吞吐量**：TPS = BatchSize / TPOT(s)

## LLM 层结构

```
Layer = Attention + FFN

Attention: rope → rmsnorm → Matmul(QKV) → [Attention] → Matmul(output) → add
MoE FFN:  Gating(Matmul+Topk+softmax) → Routing(+通信) → Gmm + swiglu + Gmm
```

## NPU 流水线

| 流水线 | 说明 | Bound 判断 |
|--------|------|------------|
| **mac** | 矩阵计算 | 性能合格，无需继续分析 |
| **vec** | 向量计算 | 大概率合格 |
| **mte2** | 数据搬入 | **重点分析**，计算实际带宽 |
| **fixpipe** | Cube 结果搬出 | 确认 unit_flag 开启情况 |
| **scalar** | 指令发射 | 不直接反映问题 |

**利用率判断**：算子耗时 > 50μs 时，应在某流水线达到 80%+ 利用率

---

# 快速开始

## 1. 监控 NPU 状态

```bash
npu-smi info
watch -n 1 npu-smi info
```

## 2. 采集性能数据

```bash
bash scripts/curl_vllm_ascend_prof.sh
```

## 3. 性能指标解读

| 指标 | 说明 | 优秀范围 |
|------|------|----------|
| TTFT | 首 token 延迟 | < 100ms |
| TPOT | 每 token 延迟 | < 50ms |
| Throughput | 吞吐量 | > 100 tps |
| NPU Utilization | NPU 利用率 | > 80% |

---

# Profiling 分析方法

## 一、准备工作

### 原则
- Profiling 必须开启 **level1**，否则算子关键信息缺失
- PD 混布节点的 Profiling 会把两个阶段算子杂糅，需手动区分

### 典型现象
- op_summary 中缺少流水线利用率信息
- Prefill 和 Decode 算子混在一起

### 关键文件

| 文件 | 用途 |
|------|------|
| `msprof_xxx.json` | 模型级打点图，确认 host bound |
| `op_statistic` | 算子调用统计，确认 TOPN |
| `op_summary` | **最关键**，算子详情分析 |

### 优化思路
```bash
export ASCEND_PROFILER_LEVEL=1
```
- PD 分离部署场景分别采集
- 通过 shape 区分：Prefill 高维为 in_seqlen，Decode 为 batch*MTP

---

## 二、Host Bound 诊断

### 原则
- CPU 任务量应 **小于** NPU，形成 device bound
- NPU 核心 stream 连续 = device bound，有空隙 = host bound

### 典型现象
- NPU stream 出现明显空隙
- Host2Device 同步连线不歪（set 早于 wait）

### 优化思路

| 现象 | 解决方案 |
|------|----------|
| CPU 耗时 > Device 耗时 | 交由算子团队优化 |
| 首次调用耗时高 | 预热、算子缓存 |
| 整体下发开销大 | 算子融合减少调用次数 |

---

## 三、算子性能诊断

### 原则
- 算子耗时 > 50μs 时，应在某流水线形成 **80%+ 利用率** 的 bound
- 流水线利用率高 ≠ 效率高，需结合实际带宽/算力判断

### 典型现象

| 流水线 | Bound 判断 | 进一步分析 |
|--------|------------|------------|
| **mac** | 性能合格 | MFU ≈ mac_ratio |
| **vec** | 大概率合格 | 可检查 API 冗余 |
| **mte2** | **需重点分析** | 计算实际带宽 |
| **fixpipe** | 检查 unit_flag | 开启后参考意义不大 |

### 优化思路

**MFU 计算**：
```
MFU = (M * K * N * 2 / task_duration) / 理论算力
# bf16 理论算力: 294 TFlops
```

**mte2 带宽分析**：
```
实际带宽 = 搬运数据量 / mte2_time
理论带宽 = ~1.3 TB/s (A2/A3)
热数据(L2Cache) = 约 3x 带宽提升
```

**mte2 低效原因**：

| 原因 | 解决方案 |
|------|----------|
| 权重非 NZ 格式 | `VLLM_ASCEND_ENABLE_NZ=1` |
| 尾轴非 512B 对齐 | 调整 shape 或 TP 策略 |
| 尾轴为 16KB 整数倍 | 微调 shape |

---

## 四、Shape 亲和性

### 原则
- 搬运效率：权重 NZ 格式 > 尾轴 512B 对齐
- 负载均衡：并行度应为物理核数整数倍

### 典型现象
- mte2 利用率正常但带宽效率低
- Vector 算子负载不均

### 优化思路

**搬运效率亲和**：

| 条件 | 优先级 |
|------|--------|
| 权重 NZ 格式 | 最优 |
| 尾轴 512B 对齐 + 非 16KB 整数倍 | 近似最优 |

**负载均衡亲和**（物理核数：A2/A3 为 20/24 核，40/48 vector 核）：

| 算子类型 | 分核策略 | 优化建议 |
|----------|----------|----------|
| Vector | 按 batch 维 | batch 数取核数整数倍 |
| Cube | 按 M/N 切分 | Decode M ≤ 128 无损 |
| Attention | batch × kv_head | 注意 head 数配合 |

---

## 五、融合空间分析

### 原则
- **通用原则**：结构在主流模型中广泛应用
- **收益原则**：能显著降低开销或提升效率

### 典型现象
- CPU 下发开销成为瓶颈
- 小 shape 算子头尾开销占比大

### 优化思路

| 类型 | 说明 | 收益判断 |
|------|------|----------|
| **深融合** | 块粒度级联 | 数据量 > 100MB 时提升 L2Cache 命中率 |
| **浅融合** | 整体先产后消 | 小 shape 有收益 |

**CV 融合**：数据量 > 100MB 时深融合提升 L2Cache 命中率

**VV 融合**：UB 驻留，节省搬入/搬出开销

---

## 六、性能预期对比

### 原则
- 计算/访存瓶颈算子可通过算力/带宽折算预期耗时
- NPU Vector 算力和带宽相对薄弱

### 优化思路
```
计算瓶颈耗时 = 计算量 / 理论算力
访存瓶颈耗时 = 数据量 / 理论带宽

NPU 实际表现通常略低于理论折算结果
```

---

# 环境变量配置

## vLLM 性能优化

```bash
# 大并发场景
export VLLM_ASCEND_ENABLE_FLASHCOMM1=1

# 小并发场景
export VLLM_ASCEND_ENABLE_PREFETCH_MLP=1

# TP 场景
export VLLM_ASCEND_ENABLE_MATMUL_ALLREDUCE=1

# DeepSeek W8A8（默认开启）
export VLLM_ASCEND_ENABLE_MLAPO=1

# 权重 NZ 格式
export VLLM_ASCEND_ENABLE_NZ=1
```

## CANN 配置

```bash
# Profiling 采集
export PROFILING_MODE=true
export PROFILING_OPTIONS='{"output":"/tmp/profiling","task_trace":"on"}'

# 并行编译
export TE_PARALLEL_COMPILER=8

# 通信缓冲区
export HCCL_BUFFSIZE=200
```

详见 [CANN-Env.md](reference/CANN-Env.md)

---

# 诊断流程

```
1. 监控基础指标（npu-smi）
   ↓
2. 采集 Profiling 数据（确保 level1）
   ↓
3. Host Bound 诊断（NPU stream 连续性）
   ↓ (device bound)
4. 组网合理性分析（拼接类算子）
   ↓
5. 算子性能初诊（流水线利用率）
   ├─ mac bound → 合格
   ├─ vec bound → 大概率合格
   └─ mte2 bound → 计算带宽分析
   ↓
6. Shape 亲和性调整
   ↓
7. 融合空间分析
   ↓
8. 友商性能对比
```

---

# 参考资源

> **优先查阅官方文档**：以下官方链接会实时更新，保证时效性！
>
> - **环境变量配置**：https://docs.vllm.ai/projects/ascend/en/latest/user_guide/configuration/env_vars.html
> - **特性优化指南**：https://docs.vllm.ai/projects/ascend/en/latest/user_guide/feature_guide/index.html

## 本地参考

- [CANN-Env.md](reference/CANN-Env.md) - CANN 环境变量配置
- [URL.md](reference/URL.md) - 参考链接汇总

# 脚本工具

| 脚本 | 功能 |
|------|------|
| `scripts/curl_vllm_ascend_prof.sh` | 获取推理服务性能数据 |