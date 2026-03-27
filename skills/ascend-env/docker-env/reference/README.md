# Docker NPU 环境配置指南

本文档提供 Docker NPU 环境配置的使用说明。

## NPU 设备配置

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

## 验证 NPU 可用性

启动容器后，验证 NPU 设备是否可用：

```bash
# 进入容器
docker exec -it <container_name> /bin/bash

# 查看 NPU 状态
npu-smi info
```

## 根据硬件选择镜像

- **Atlas 800I A2** (8卡)：选择带有 `-910b` 标签的镜像
- **Atlas 800I A3** (16卡)：选择带有 `-a3` 标签的镜像

## 常见问题排查

### 设备和驱动问题

- 检查设备挂载是否正确
- 确认 NPU 驱动版本兼容性
- 验证设备文件权限

### 网络和通信

- 检查 Docker 网络模式配置
- 确认容器间网络通信正常

### 性能和资源

- 监控 NPU 性能指标
- 分析性能瓶颈

## 相关文档

- [URL.md](./URL.md) - 外部参考链接
- [ASCEND_DOCKER.md](./ASCEND_DOCKER.md) - Ascend Docker 镜像仓库
- [SKILL.md](../SKILL.md) - 技能使用说明