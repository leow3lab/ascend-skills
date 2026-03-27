# Docker NPU 环境配置 参考链接

> 最后更新：2026-03-27

## Docker 官方文档

### 核心文档
- [Docker 官方文档](https://docs.docker.com/) - Docker 完整官方文档
- [Docker 参考文档](https://docs.docker.com/engine/reference/) - Docker 命令和配置参考

### 设备和权限管理
- [Docker 设备挂载](https://docs.docker.com/engine/reference/commandline/run/#device-access) - Docker 设备挂载参数说明
- [Docker 权限管理](https://docs.docker.com/engine/reference/commandline/run/#runtime-privilege-and-linux-capabilities) - 容器权限配置
- [Docker 卷挂载](https://docs.docker.com/engine/reference/commandline/run/#volume) - 数据卷挂载说明

### 网络配置
- [Docker 网络概述](https://docs.docker.com/engine/network/) - Docker 网络模式
- [Docker 网络驱动](https://docs.docker.com/engine/network/drivers/) - Bridge、Host 等网络驱动

### 安全指南
- [Docker 安全最佳实践](https://docs.docker.com/engine/security/) - 容器安全配置
- [保护 Docker 守护进程](https://docs.docker.com/engine/security/daemon-access/) - Daemon 访问控制

## Docker Compose

- [Docker Compose 官方文档](https://docs.docker.com/compose/) - Compose 完整文档
- [Docker Compose 参考文档](https://docs.docker.com/compose/compose-file/) - docker-compose.yml 语法
- [Docker Compose 安装指南](https://docs.docker.com/compose/install/) - 各平台安装方法
- [Docker Compose 网络配置](https://docs.docker.com/compose/networking/) - 多容器网络配置
- [Docker Compose 环境变量](https://docs.docker.com/compose/environment-variables/) - 环境变量配置

## Ascend NPU 驱动和工具

### CANN 工具包
- [CANN 工具包文档](https://www.hiascend.com/document) - CANN 官方文档
- [CANN 安装指南](https://www.hiascend.com/document/detail?nodeId=ascend_07_0060) - CANN 安装步骤
- [CANN 版本选择参考](https://www.hiascend.com/document/detail?nodeId=ascend_07_0061) - 版本兼容性

### 驱动和固件
- [NPU 设备驱动安装指南](https://www.hiascend.com/document/detail?nodeId=ascend_07_0015) - 驱动安装步骤
- [NPU 驱动版本兼容性](https://www.hiascend.com/document/detail?nodeId=ascend_07_0065) - 版本兼容检查
- [NPU 驱动升级指南](https://www.hiascend.com/document/detail?nodeId=ascend_07_0140) - 驱动升级方法

### 目录结构
- [NPU 设备目录结构说明](https://www.hiascend.com/document/detail?nodeId=ascend_07_0050) - 目录结构说明
- [CANN 环境变量配置](https://www.hiascend.com/document/detail?nodeId=ascend_07_0080) - 环境变量说明

## NPU 监控工具

- [npu-smi 使用指南](https://www.hiascend.com/document/detail?nodeId=ascend_07_0055) - npu-smi 完整使用说明
- [npu-smi 命令参考](https://www.hiascend.com/document/detail?nodeId=ascend_07_0056) - npu-smi 子命令详解
- [NPU 日志和调试](https://www.hiascend.com/document/detail?nodeId=ascend_07_0060) - 日志收集分析
- [NPU 性能分析工具](https://www.hiascend.com/document/detail?nodeId=ascend_07_0070) - Profiling 工具
- [NPU 常见错误码](https://www.hiascend.com/document/detail?nodeId=ascend_07_0085) - 错误码含义

## Ascend Docker 镜像

- [Quay.io - Ascend vLLM](https://quay.io/repository/ascend/vllm-ascend) - vLLM 推理框架镜像
- [Quay.io - Ascend CANN](https://quay.io/repository/ascend/cann) - CANN 开发环境镜像
- [昇腾社区镜像仓库](https://www.hiascend.com/developer/ascendhub) - MindSpeed 等镜像

## 容器化最佳实践

- [Docker 资源限制](https://docs.docker.com/config/containers/resource_constraints/) - CPU、内存资源限制
- [多阶段构建](https://docs.docker.com/develop/develop-images/multistage-build/) - 减小镜像大小
- [Docker 容器重启策略](https://docs.docker.com/config/containers/start-containers-automatically/) - 自动重启配置
- [Docker 日志管理](https://docs.docker.com/config/containers/logging/) - 日志收集管理
- [Docker 健康检查](https://docs.docker.com/engine/reference/builder/#healthcheck) - 容器健康检查

## 社区资源

- [昇腾社区](https://www.hiascend.com) - 华为 Ascend 开发者社区
- [Docker 论坛](https://forums.docker.com/) - Docker 官方论坛
- [Docker 官方教程](https://docs.docker.com/get-started/) - Docker 快速开始
- [vLLM-Ascend](https://github.com/vllm-project/vllm-ascend) - vLLM NPU 适配版本
- [MindSpeed-LLM](https://gitcode.com/Ascend/MindSpeed-LLM) - MindSpeed-LLM 训练框架
- [MindSpeed-RL](https://gitcode.com/Ascend/MindSpeed-RL) - MindSpeed-RL 强化学习框架
- [msmodelslim](https://gitcode.com/Ascend/msmodelslim) - 华为官方量化工具