# CANN 环境变量配置参考

本文档整理 vLLM-Ascend 性能优化相关的 CANN 环境变量，按"原则、典型现象、优化思路"组织。

---

## 一、Profiling 数据采集

### 原则
- 必须开启 level1 采集，否则算子关键信息缺失
- Profiling 输出路径需有读写权限

### 典型现象
- op_summary 中缺少流水线利用率信息
- 算子详情无法分析

### 优化思路

```bash
# 开启 Profiling
export PROFILING_MODE=true

# Profiling 配置选项
export PROFILING_OPTIONS='{"output":"/tmp/profiling","training_trace":"on","task_trace":"on","aic_metrics":"PipeUtilization"}'

# task_trace 取值说明：
# - on/l1：采集算子下发耗时、执行耗时、基本信息（默认）
# - l0：仅采集算子下发耗时、执行耗时（性能开销小）
# - off：关闭
```

**关键配置项**：

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `task_trace` | 算子耗时采集 | `on` 或 `l1` |
| `training_trace` | 迭代轨迹采集 | `on` |
| `aic_metrics` | AI Core 指标 | `PipeUtilization`（默认） |
| `output` | 输出路径 | 自定义路径 |
| `storage_limit` | 最大存储空间 | `200MB` 以上 |

**aic_metrics 可选值**：
- `PipeUtilization`：计算单元和搬运单元耗时占比（默认）
- `ArithmeticUtilization`：计算类指标占比
- `Memory`：外部内存读写指令占比
- `L2Cache`：L2 Cache 命中/缺失次数

---

## 二、图编译优化

### 原则
- 图编译耗时与模型复杂度正相关，可并行加速
- 编译缓存可复用，减少重复编译开销

### 典型现象
- 首次启动模型编译耗时长
- 多进程场景编译缓存冲突

### 优化思路

```bash
# 并行编译进程数（建议 CPU 核数 * 80% / NPU 数量）
export TE_PARALLEL_COMPILER=8

# 图编译多线程
export MAX_COMPILE_CORE_NUMBER=5
export MULTI_THREAD_COMPILE=1

# 编译缓存配置
export ASCEND_MAX_OP_CACHE_SIZE=500        # 缓存空间上限（MB）
export ASCEND_REMAIN_CACHE_SIZE_RATIO=50   # 清理时保留比例（%）

# 缓存路径
export ASCEND_CACHE_PATH=/path/to/cache    # 共享缓存路径
export ASCEND_WORK_PATH=/path/to/work      # 单机独享路径
```

**缓存优先级**：`op_cache.ini` > `ASCEND_MAX_OP_CACHE_SIZE` > 默认值（500MB）

---

## 三、算子执行优化

### 原则
- 算子缓存可减少 Host 侧调度开销
- 动态 shape 场景需增大缓存条目

### 典型现象
- 动态 shape 场景调度性能下降
- Host 内存占用过高

### 优化思路

```bash
# 算子信息缓存条目数（默认 10000）
export ACLNN_CACHE_LIMIT=10000

# 计算公式：单算子 cache 内存 = ACLNN_CACHE_LIMIT * 线程数 * 2KB
# 融合算子 cache 内存 = ACLNN_CACHE_LIMIT * 20KB
```

**内存估算**：
- 10 线程 + 100000 条目 ≈ 2GB Host 内存

---

## 四、集合通信优化

### 原则
- HCCL 自适应选择算法，一般无需手工配置
- 通信链路选择影响 Server 内通信性能

### 典型现象
- 通信算子成为性能瓶颈
- Server 内通信效率低

### 优化思路

### 4.1 通信算法配置

```bash
# 全局配置
export HCCL_ALGO="level0:NA;level1:NHR"

# 按算子配置
export HCCL_ALGO="allreduce=level0:NA;level1:ring/allgather=level0:NA;level1:H-D_R"
```

**Server 间算法选择**：

| 算法 | 特点 | 适用场景 |
|------|------|----------|
| `ring` | 通信步数多，受拥塞影响小 | Server 少、数据量小 |
| `H-D_R` | 通信步数少，时延低 | Server 数为 2 的幂次 |
| `NHR` | 通信步数少，时延低 | Server 多 |
| `pipeline` | 并发使用 Server 内/间链路 | 数据量大、每机多卡 |
| `pairwise` | 避免一打多 | AlltoAll 大数据量 |

### 4.2 通信链路配置

```bash
# Server 内使用 PCIe 通信
export HCCL_INTRA_PCIE_ENABLE=1

# Server 内使用 RoCE 通信
export HCCL_INTRA_ROCE_ENABLE=1
```

**配置组合**：

| HCCL_INTRA_PCIE_ENABLE | HCCL_INTRA_ROCE_ENABLE | Server 内链路 |
|------------------------|------------------------|---------------|
| 1 | 不配置 | PCIe |
| 0 | 1 | RoCE |
| 不配置 | 不配置 | PCIe（默认） |

### 4.3 通信缓冲区

```bash
# 共享数据缓存区大小（默认 200MB）
export HCCL_BUFFSIZE=200

# 建议计算：ceil(MicrobatchSize * SequenceLength * hiddenSize * sizeof(DataType) / 1024 / 1024)
```

### 4.4 多 QP 通信（RDMA）

```bash
# 两个 rank 间 QP 个数（建议 1-8）
export HCCL_RDMA_QPS_PER_CONNECTION=4

# 每个 QP 分担数据量阈值（默认 512KB）
export HCCL_MULTI_QP_THRESHOLD=512
```

### 4.5 网络配置

```bash
# Host 通信 IP
export HCCL_IF_IP=10.10.10.1

# Host 通信端口范围
export HCCL_HOST_SOCKET_PORT_RANGE="60000-60050"

# NPU 通信端口范围
export HCCL_NPU_SOCKET_PORT_RANGE="61000-61050"

# RDMA 重传超时系数（默认 20）
export HCCL_RDMA_TIMEOUT=20

# RDMA 重传次数（默认 7）
export HCCL_RDMA_RETRY_CNT=7
```

---

## 五、超时与可靠性

### 原则
- 超时时间需根据业务场景调整
- 重执行功能可提升通信稳定性

### 典型现象
- 集合通信初始化超时
- 通信算子执行超时

### 优化思路

```bash
# Socket 建链超时（默认 120s，实际 +20s）
export HCCL_CONNECT_TIMEOUT=200

# 设备间执行同步超时（默认 1836s）
export HCCL_EXEC_TIMEOUT=1800

# 开启通信算子重执行
export HCCL_OP_RETRY_ENABLE="L1:1,L2:1"

# 重执行参数
export HCCL_OP_RETRY_PARAMS="MaxCnt:3,HoldTime:5000,IntervalTime:1000"
```

**重执行参数说明**：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `MaxCnt` | 最大重传次数 | 1 |
| `HoldTime` | 首次重执行等待时间（ms） | 5000 |
| `IntervalTime` | 重执行间隔时间（ms） | 1000 |

---

## 六、日志与调试

### 原则
- 生产环境使用 ERROR 级别
- 调试时可开启 DEBUG 级别（性能有影响）

### 典型现象
- 日志量过大影响性能
- 日志丢失难以定位问题

### 优化思路

```bash
# 日志落盘路径
export ASCEND_PROCESS_LOG_PATH=$HOME/log/

# 日志级别（0=DEBUG, 1=INFO, 2=WARNING, 3=ERROR, 4=NULL）
export ASCEND_GLOBAL_LOG_LEVEL=3

# 模块日志级别
export ASCEND_MODULE_LOG_LEVEL=TBE=0:RUNTIME=0

# 日志不丢失模式
export ASCEND_LOG_SYNC_SAVE=1

# Device 日志回传超时（默认 2000ms）
export ASCEND_LOG_DEVICE_FLUSH_TIMEOUT=5000
```

---

## 七、资源与设备配置

### 原则
- 设备 ID 需与实际物理设备对应
- 可见设备配置可实现不修改代码切换设备

### 典型现象
- 多卡场景设备分配混乱
- 单卡多进程端口冲突

### 优化思路

```bash
# 指定当前进程所用设备
export ASCEND_DEVICE_ID=0

# 指定可见设备（仅使用 1,2,3 号卡）
export ASCEND_RT_VISIBLE_DEVICES=1,2,3

# 自定义任务 ID
export JOB_ID=10087
```

---

## 八、故障信息收集

### 原则
- 问题复现场景开启完整信息收集
- 正常运行时关闭以减少开销

### 典型现象
- 问题难以定位
- 算子执行异常无详细信息

### 优化思路

```bash
# 故障信息保存路径
export NPU_COLLECT_PATH=$HOME/debug/

# 开启 HCCL 诊断日志
export HCCL_DIAGNOSE_ENABLE=1

# 通信算子调用日志
export HCCL_ENTRY_LOG_ENABLE=1

# 详细模块日志
export HCCL_DEBUG_CONFIG="ALG,TASK,RESOURCE"
```

---

## 九、确定性计算

### 原则
- 确定性计算可保证多次执行结果一致
- 开启后会有性能损失

### 典型现象
- 模型多次执行结果不同
- 精度调优困难

### 优化思路

```bash
# 开启确定性计算
export HCCL_DETERMINISTIC=true

# 开启严格确定性计算（保序）
export HCCL_DETERMINISTIC=strict
```

**支持算子**：AllReduce、ReduceScatter、ReduceScatterV、Reduce

---

## 十、环境变量快速参考表

### 性能优化类

| 环境变量 | 说明 | 推荐值 |
|----------|------|--------|
| `TE_PARALLEL_COMPILER` | 并行编译进程数 | 8 |
| `MAX_COMPILE_CORE_NUMBER` | 图编译核数 | 5 |
| `ACLNN_CACHE_LIMIT` | 算子缓存条目 | 10000 |
| `HCCL_BUFFSIZE` | 通信缓冲区（MB） | 200 |
| `HCCL_RDMA_QPS_PER_CONNECTION` | RDMA QP 数 | 1-4 |

### 通信配置类

| 环境变量 | 说明 | 推荐值 |
|----------|------|--------|
| `HCCL_ALGO` | 通信算法 | 自适应 |
| `HCCL_INTRA_PCIE_ENABLE` | Server 内 PCIe | 1 |
| `HCCL_IF_IP` | Host 通信 IP | 实际网卡 IP |

### 调试配置类

| 环境变量 | 说明 | 推荐值 |
|----------|------|--------|
| `ASCEND_GLOBAL_LOG_LEVEL` | 日志级别 | 3（ERROR） |
| `PROFILING_MODE` | Profiling 开关 | true |
| `NPU_COLLECT_PATH` | 故障信息路径 | 调试时设置 |

> 外部链接请参考 [URL.md](./URL.md)