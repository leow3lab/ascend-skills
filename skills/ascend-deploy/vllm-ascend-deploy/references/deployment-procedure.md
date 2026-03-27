# vLLM-Ascend 部署流程指南


## 核心原则

1. **版本对齐** - CANN 版本与推理框架版本必须匹配（如 Sglang v0.5.x → CANN 8.0.x）
2. **灵活变通** - 若环境已安装驱动版本不可变，优先调整镜像 Tag 而非死磕文档推荐
3. **动态查找** - 使用浏览器工具查找最新的版本兼容性信息和镜像推荐

## 部署前确认（必须执行）

**不假设、不猜测** - 所有关键参数必须从用户处获取或确认。

### 必需参数

| 参数 | 获取方式 | 说明 |
|------|----------|------|
| **服务器 IP** | 用户指定或 localhost | 部署目标 |
| **模型权重路径** | **必须询问用户** | 常见路径见下方 |
| **容器镜像** | 根据模型类型推荐 | 见镜像选择指南 |
| **容器名称** | 建议生成 | 格式：`vllm-<model-name>` |
| **TP 并行数** | 自动检测或用户指定 | 根据 NPU 卡数和模型大小 |

### 模型路径常见位置

```
/mnt/metis/huggface_models/<series>/<model>
/mnt2/hbw/model/<model>
```

### 确认话术模板

```
在开始部署 {MODEL_NAME} 之前，请确认以下信息：

| 参数 | 当前值 |
|------|--------|
| 服务器 IP | {SERVER_IP} |
| 容器镜像 | {IMAGE} |
| 模型路径 | 请提供 |
| 容器名称 | {CONTAINER_NAME} |
| TP 并行数 | 自动检测 |

请确认以上信息，并提供模型权重路径。
```

## 快速部署流程

### Step 1: 环境检查

```bash
# 检查 NPU 资源
npu-smi info

# 检查镜像
docker images | grep vllm-ascend

# 检查模型路径
ls <MODEL_PATH>/config.json
```

### Step 2: 创建容器

使用脚本自动创建容器（完整 NPU 配置）：

```bash
bash scripts/create_container.sh \
  --mode local \
  --image <IMAGE> \
  --model-path <MODEL_PATH> \
  --container-name <CONTAINER_NAME>
```

远程部署添加 `--mode remote --server <IP> --user <USER>` 参数。

### Step 3: 启动服务

```bash
bash scripts/start_service.sh \
  --container <CONTAINER_NAME> \
  --model-path <MODEL_PATH> \
  --port 8000 \
  --tp-size <TP_SIZE>
```

### Step 4: 验证部署

```bash
curl http://localhost:8000/health
curl http://localhost:8000/v1/models
```

## 镜像选择指南

**查找最新镜像信息**：使用浏览器访问以下地址获取最新版本兼容性信息。

### 官方镜像仓库

| 仓库 | 地址 | 用途 |
|------|------|------|
| Quay.io | quay.io/repository/ascend/vllm-ascend | 开源适配镜像 |
| AscendHub | hiascend.com/developer/ascendhub | 华为官方生产镜像 |

### 镜像选择原则

1. **CANN 版本对齐** - 驱动版本与镜像 CANN 版本必须匹配
2. **硬件适配** - Atlas A2/A3 需要对应镜像 Tag
3. **框架版本** - Sglang/vLLM 版本需与 CANN 兼容

**推荐做法**：使用浏览器搜索 `vllm-ascend <硬件型号> CANN <版本>` 获取最新推荐镜像。

## 依赖技能

当遇到以下场景时，调用对应技能：

| 场景 | 技能 |
|------|------|
| 镜像源/代理配置 | `mirror-proxy` |
| 从 ModelScope 下载模型 | `modelscope-cli` |

## 环境变量参考

```bash
# HCCL 通信优化
export HCCL_OP_EXPANSION_MODE="AIV"
export HCCL_BUFFSIZE=1024
export OMP_NUM_THREADS=1

# 内存管理
export PYTORCH_NPU_ALLOC_CONF="expandable_segments:True"
export TASK_QUEUE_ENABLE=1
```

## 模型参数参考

| 模型规模 | TP 并行数 | max-model-len | gpu-memory-utilization |
|----------|-----------|---------------|------------------------|
| 7B | 2 | 8192 | 0.90 |
| 14B | 4 | 8192 | 0.92 |
| 35B (MoE) | 8 | 32768 | 0.95 |
| 72B | 16 | 4096 | 0.94 |

**注意**：具体配置需根据实际 NPU 卡数和显存大小调整。

## 部署检查清单

- [ ] 模型路径确认
- [ ] 镜像选择（版本兼容性）
- [ ] NPU 设备挂载完整
- [ ] 驱动目录挂载
- [ ] network host 模式
- [ ] shm-size 16g
- [ ] 服务健康检查通过