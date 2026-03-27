---
name: docker-env
description: Docker 容器中 Ascend NPU 环境配置工具。当用户需要使用 Docker 部署 NPU 容器、自动映射设备或配置驱动目录时使用。
---

# 概述

本技能提供在 Docker 容器中使用 Ascend NPU 的环境配置方法，包括：
- NPU 设备自动检测和挂载（支持 A2: 8卡, A3: 16卡）
- 驱动和工具链目录映射
- Docker Compose 安装（支持多架构）
- NPU 状态监控

# 前置条件

- 已安装 Docker
- 已安装 NPU 驱动和固件
- 已安装 CANN (Compute Architecture for Neural Networks)

# 核心配置

## Ascend 常见镜像仓库地址

### 官方镜像仓库

| 镜像名称 | 仓库地址 | 说明 |
|-----------|----------|------|
| [vLLM-Ascend](https://quay.io/repository/ascend/vllm-ascend) | `quay.io/ascend/vllm-ascend` | vLLM 推理框架 NPU 版本 |
| [CANN](https://quay.io/repository/ascend/cann) | `quay.io/ascend/cann` | CANN 开发环境镜像 |
| [MindSpeed-LLM](https://www.hiascend.com/developer/ascendhub/detail/e26da9266559438b93354792f25b2f4a) | [昇腾社区](https://www.hiascend.com/developer/ascendhub) | MindSpeed-LLM 训练框架 |
| [MindSpeed-RL](https://www.hiascend.com/developer/ascendhub/detail/5e7654ed7a8044c1a7c42a3b2ee9165f) | [昇腾社区](https://www.hiascend.com/developer/ascendhub) | MindSpeed-RL 强化学习 |
| [MindSpeed-MM](https://www.hiascend.com/developer/ascendhub/detail/6857f6fc2cfa4a678710a7075426ee5e) | [昇腾社区](https://www.hiascend.com/developer/ascendhub) | MindSpeed-MM 多模态 |

> **昇腾社区镜像仓库**：https://www.hiascend.com/developer/ascendhub

### SGLang-Ascend

**Docker Hub 镜像**：`docker.io/lmsysorg/sglang:{tag}`

**Tag 命名规则**：
- 基于 `main` 分支：将 `main` 替换为具体版本（如 `v0.5.6`）
- Atlas 800I A3：`{tag}-cann8.5.0-a3`
- Atlas 800I A2：`{tag}-cann8.5.0-910b`

**示例**：
```bash
# A3 产品
docker.io/lmsysorg/sglang:v0.5.6-cann8.5.0-a3

# A2 产品
docker.io/lmsysorg/sglang:v0.5.6-cann8.5.0-910b
```


### 华为云 SWR 镜像

**镜像地址**：`swr.cn-south-1.myhuaweicloud.com/ascendhub/`

**常用镜像**：
- CANN: `swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.3.rc1.alpha002-910b-ubuntu22.04-py3.11`



## NPU 设备自动检测

本技能脚本会自动检测服务器上的 NPU 卡数：
- **A2 产品**: 8 卡 NPU
- **A3 产品**: 16 卡 NPU





检测命令：
```bash
ls /dev/davinci*
```

## NPU 设备挂载

脚本会自动根据检测到的 NPU 卡数生成挂载参数：

**单卡配置示例**（手动配置）：
```bash
docker run --device=/dev/davinci0 \
           --device=/dev/davinci_manager \
           --device=/dev/devmm_svm \
           --device=/dev/hisi_hdc \
           -it <image_name>
```

**多卡配置示例**（脚本自动生成）：
```bash
docker run --device=/dev/davinci0:rw \
           --device=/dev/davinci1:rw \
           ...
           --device=/dev/davinci15:rw \  # A3: 16卡
           --device=/dev/davinci_manager \
           --device=/dev/devmm_svm \
           --device=/dev/hisi_hdc \
           -it <image_name>
```

## 驱动目录映射

```bash
docker run -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
           -v /usr/local/Ascend/ascend-toolkit:/usr/local/Ascend/ascend-toolkit
```

## 环境变量配置

```bash
docker run -e ASCEND_HOME=/usr/local/Ascend \
           -e LD_LIBRARY_PATH=/usr/local/Ascend/driver/lib64:/usr/local/Ascend/ascend-toolkit/latest/lib64
```

# 脚本说明

## 1. 启动 NPU Docker 容器

脚本 `run_build_npu_docker_container.sh` 会启动一个完整的 NPU Docker 容器，自动配置：
- NPU 设备挂载（自动检测卡数）
- 驱动和工具链目录映射
- 日志目录映射
- 网络和权限配置

### 使用方法

```bash
# 使用默认参数（容器名: container-name, 镜像: cann:8.3, 代码路径: /mnt）
scripts/run_build_npu_docker_container.sh

# 指定容器名称
scripts/run_build_npu_docker_container.sh my-container

# 指定容器名称和镜像
scripts/run_build_npu_docker_container.sh my-container swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.3.rc1.alpha002-910b-ubuntu22.04-py3.11

# 指定容器名称、镜像和代码路径
scripts/run_build_npu_docker_container.sh my-container my-image /path/to/code
```

### 环境变量配置

可通过环境变量自定义容器配置：

```bash
# 示例：配置网络模式和端口
NETWORK=bridge PORT=9000 \
scripts/run_build_npu_docker_container.sh my-container
```

| 环境变量 | 默认值 | 说明 |
|-----------|--------|------|
| NETWORK | host | 网络模式 |
| IPC | ipc | IPC 模式 |
| USER | root | 容器内用户 |
| PORT | 8080 | 端口映射 |
| PRIVILEGED | true | 是否启用特权模式 |

## 2. 安装 Docker Compose

脚本 `run_install_compose.sh` 用于安装 Docker Compose，支持自动检测系统架构。

### 使用方法

```bash
# 需要 root 权限
sudo bash scripts/run_install_compose.sh
```

### 功能特性

- 自动检测系统架构（x86_64 / aarch64）
- 从 GitHub 官方下载对应版本
- 验证安装结果

### 支持的架构

| 系统 | 架构 | 支持状态 |
|------|------|----------|
| Ubuntu | x86_64 | ✅ |
| Ubuntu | aarch64 | ✅ |
| CentOS | x86_64 | ✅ |
| CentOS | aarch64 | ✅ |

## 3. NPU 监控命令

使用 `npu-smi` 查看设备状态和实时监控：

```bash
# 查看 NPU 设备状态
npu-smi info

# 持续监控（类似 nvidia-smi）
watch -n 1 npu-smi info
```

# 完整示例

## 单卡推理服务

```bash
docker run -d --name vllm-service \
    --device=/dev/davinci0 \
    --device=/dev/davinci_manager \
    --device=/dev/devmm_svm \
    --device=/dev/hisi_hdc \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    -v /usr/local/Ascend/ascend-toolkit:/usr/local/Ascend/ascend-toolkit \
    -v /nfs/models:/nfs/models \
    -p 8000:8000 \
    -e ASCEND_HOME=/usr/local/Ascend \
    <docker_image>
```

## 使用脚本启动完整环境

```bash
# 1. 安装 Docker Compose（如需要）
sudo bash scripts/run_install_compose.sh

# 2. 启动 NPU 容器
bash scripts/run_build_npu_docker_container.sh my-training-container

# 3. 查看 NPU 状态
npu-smi info
```

# 常见问题

## 1. NPU 设备检测失败

**问题**：脚本提示未检测到 NPU 设备

**解决**：
```bash
# 检查 NPU 驱动是否安装
ls -l /usr/local/Ascend/driver/

# 检查设备文件是否存在
ls -l /dev/davinci*

# 检查驱动服务状态
systemctl status npu-smi
```

## 2. Docker 容器内无法访问 NPU

**问题**：容器内运行 `npu-smi info` 出错

**解决**：
- 确保容器启动时使用了 `--device=/dev/davinci*` 参数
- 确保映射了 `/usr/local/Ascend/driver` 目录
- 检查容器是否使用了 `--privileged=true`（部分场景需要）

## 3. Docker Compose 安装失败

**问题**：下载失败或权限不足

**解决**：
```bash
# 使用 sudo 运行脚本
sudo bash scripts/run_install_compose.sh

# 或手动下载后放置
wget https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-aarch64
sudo mv docker-compose-linux-aarch64 /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
```

## 4. A3 产品（16卡）配置

**问题**：脚本默认只挂载 8 卡，A3 产品需要 16 卡

**解决**：

脚本已自动支持 A3 产品，会自动检测 NPU 卡数并挂载所有设备。如需手动配置：

```bash
# 手动指定 16 卡
# 修改脚本中的 NPU 设备检测部分
```

# 输出与验证

启动容器后，可通过以下方式验证：

```bash
# 1. 检查容器状态
docker ps | grep <container_name>

# 2. 进入容器
docker exec -it <container_name> /bin/bash

# 3. 容器内验证 NPU 访问
npu-smi info
# 应该显示所有 NPU 卡的信息

# 4. 验证驱动目录
ls -l /usr/local/Ascend/driver/
# 应该能看到驱动文件和版本信息
```

# 高级配置

## 自定义目录映射

如需挂载额外的目录，修改 `run_build_npu_docker_container.sh` 脚本中的 docker run 命令，添加额外的 `-v` 参数：

```bash
-v /path/to/data:/data \
-v /path/to/models:/models \
```

## 多服务编排

对于需要多个容器协同工作的场景，可以使用 Docker Compose：

```yaml
version: '3.8'
services:
  training:
    image: swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.3
    devices:
      - /dev/davinci0
      - /dev/davinci1
      - /dev/davinci_manager
      - /dev/devmm_svm
      - /dev/hisi_hdc
    volumes:
      - /usr/local/Ascend/driver:/usr/local/Ascend/driver
      - ./code:/workspace
    privileged: true
    network_mode: host
```

```bash
docker compose up -d
```