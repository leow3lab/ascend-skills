# Ascend Docker 镜像仓库

本文档整理了 Ascend NPU 相关的 Docker 镜像仓库地址和获取方式。

## 目录

- [官方镜像仓库](#官方镜像仓库)
- [SGLang-Ascend](#sglang-ascend)
- [VERL](#verl)
- [华为云 SWR 镜像](#华为云-swr-镜像)
- [镜像使用建议](#镜像使用建议)

---

## 官方镜像仓库

### Quay.io 镜像

| 镜像名称 | 仓库地址 | 说明 | 标签 |
|-----------|----------|------|------|
| [vLLM-Ascend](https://quay.io/repository/ascend/vllm-ascend) | `quay.io/ascend/vllm-ascend` | vLLM 推理框架 NPU 版本 | `latest` |
| [CANN](https://quay.io/repository/ascend/cann) | `quay.io/ascend/cann` | CANN 开发环境镜像 | `latest`, `8.x` |

### 昇腾社区镜像

| 镜像名称 | 说明 | 获取方式 |
|-----------|------|----------|
| [MindSpeed-LLM](https://www.hiascend.com/developer/ascendhub/detail/e26da9266559438b93354792f25b2f4a) | MindSpeed-LLM 训练框架 | [昇腾社区](https://www.hiascend.com/developer/ascendhub) |
| [MindSpeed-RL](https://www.hiascend.com/developer/ascendhub/detail/5e7654ed7a8044c1a7c42a3b2ee9165f) | MindSpeed-RL 强化学习框架 | [昇腾社区](https://www.hiascend.com/developer/ascendhub) |
| [MindSpeed-MM](https://www.hiascend.com/developer/ascendhub/detail/6857f6fc2cfa4a678710a7075426ee5e) | MindSpeed-MM 多模态框架 | [昇腾社区](https://www.hiascend.com/developer/ascendhub) |

> **昇腾社区镜像仓库**：https://www.hiascend.com/developer/ascendhub

---

## SGLang-Ascend

### 镜像信息

- **Docker Hub 仓库**：`docker.io/lmsysorg/sglang`
- **GitHub 仓库**：https://github.com/lmsysorg/sglang

### Tag 命名规则

SGLang-Ascend 的 Tag 命名遵循以下规则：

- **基于版本分支**：将 `main` 替换为具体版本（如 `v0.5.6`）
- **Atlas 800I A3**：`{tag}-cann8.5.0-a3`
- **Atlas 800I A2**：`{tag}-cann8.5.0-910b`

### 使用示例

```bash
# 拉取 A3 产品镜像
docker pull docker.io/lmsysorg/sglang:v0.5.6-cann8.5.0-a3

# 拉取 A2 产品镜像
docker pull docker.io/lmsysorg/sglang:v0.5.6-cann8.5.0-910b

# 运行容器
docker run -it --device=/dev/davinci0 \
    --device=/dev/davinci_manager \
    --device=/dev/devmm_svm \
    --device=/dev/hisi_hdc \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    docker.io/lmsysorg/sglang:v0.5.6-cann8.5.0-910b
```

---

## VERL

VERL (Verifiable Reinforcement Learning) 的 NPU 适配版本。

### 获取方式

VERL 的 NPU 适配镜像请参考[昇腾社区](https://www.hiascend.com/developer/ascendhub)获取最新镜像地址和使用说明。

### 功能特性

- 可验证强化学习
- 支持 NPU 加速
- 适配大模型训练场景

---

## 华为云 SWR 镜像

### 镜像仓库地址

- **SWR (Software Repository for Container)**：`swr.cn-south-1.myhuaweicloud.com/ascendhub/`
- **区域**：华南-深圳 (cn-south-1)

### 常用镜像

| 镜像名称 | 完整地址 | 说明 |
|-----------|----------|------|
| CANN Base | `swr...cann:8.3.rc1.alpha002-910b-ubuntu22.04-py3.11` | CANN 8.3 基础环境，支持 910B，Ubuntu 22.04，Python 3.11 |

### 拉取镜像

```bash
# 从 SWR 拉取镜像
docker pull swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.3.rc1.alpha002-910b-ubuntu22.04-py3.11

# 登录 SWR（如需要）
docker login swr.cn-south-1.myhuaweicloud.com
```

---

## 镜像使用建议

### 1. 选择合适的镜像

- **开发环境**：使用 CANN 基础镜像，自定义安装依赖
- **推理服务**：使用 vLLM-Ascend 镜像
- **训练任务**：使用 MindSpeed-LLM 或 MindSpeed-RL 镜像
- **多模态任务**：使用 MindSpeed-MM 镜像

### 2. NPU 设备配置

所有 NPU 镜像都需要正确配置设备挂载：

```bash
docker run \
    --device=/dev/davinci0 \
    --device=/dev/davinci1 \
    --device=/dev/davinci_manager \
    --device=/dev/devmm_svm \
    --device=/dev/hisi_hdc \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    <image_name>
```

### 3. 驱动目录映射

确保映射 NPU 驱动和工具链目录：

```bash
docker run \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    -v /usr/local/Ascend/ascend-toolkit:/usr/local/Ascend/ascend-toolkit \
    <image_name>
```

### 4. 验证 NPU 可用性

启动容器后，验证 NPU 设备是否可用：

```bash
# 进入容器
docker exec -it <container_name> /bin/bash

# 查看 NPU 状态
npu-smi info
```

### 5. 根据硬件选择镜像

- **Atlas 800I A2** (8卡)：选择带有 `-910b` 标签的镜像
- **Atlas 800I A3** (16卡)：选择带有 `-a3` 标签的镜像

### 6. 镜像加速

如果在国内网络环境拉取镜像较慢，可以：

1. 使用华为云 SWR 镜像仓库
2. 配置 Docker 镜像加速器
3. 使用代理服务器

---

## 相关资源

- [Docker NPU 环境配置技能](../SKILL.md) - 本技能的主文档
- [Docker 官方文档](https://docs.docker.com/) - Docker 完整文档
- [昇腾社区](https://www.hiascend.com) - 华为 Ascend 开发者社区
- [CANN 文档中心](https://www.hiascend.com/document) - CANN 框架官方文档
- [MindSpeed-LLM](https://gitcode.com/Ascend/MindSpeed-LLM) - MindSpeed-LLM 训练框架
- [MindSpeed-RL](https://gitcode.com/Ascend/MindSpeed-RL) - MindSpeed-RL 强化学习框架
- [msmodelslim](https://gitcode.com/Ascend/msmodelslim) - 华为官方量化工具