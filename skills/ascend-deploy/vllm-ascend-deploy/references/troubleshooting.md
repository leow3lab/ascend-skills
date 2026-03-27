# 故障排查手册

## 排查原则

1. **先检查基础环境** - NPU 驱动、Docker、网络
2. **查看日志定位问题** - 关键词搜索
3. **版本兼容性** - 使用浏览器查找最新的版本兼容性信息

## 常见问题

### 1. 容器创建失败

**症状**：`device not found` 或 `NPU not detected`

**排查步骤**：
```bash
# 检查 NPU 驱动
npu-smi info

# 检查设备文件
ls -la /dev/davinci*
```

**解决方案**：
- 确认 NPU 驱动已安装
- 使用脚本创建容器（自动配置设备映射）

### 2. 服务启动失败

**症状**：`HCCL initialization failed`

**排查步骤**：
```bash
# 检查容器内 NPU 可见性
docker exec <container> npu-smi info

# 查看启动日志
docker logs <container>
```

**解决方案**：
```bash
# 检查环境变量
export HCCL_OP_EXPANSION_MODE="AIV"
export HCCL_BUFFSIZE=1024

# 确保使用 --network host
```

### 3. 显存不足（OOM）

**症状**：`NPU memory exhausted`

**解决方案**：
```bash
# 降低显存占用
--gpu-memory-utilization 0.85
--max-model-len 4096
--max-num-seqs 64

# 或增加 TP 并行数
--tensor-parallel-size 16
```

### 4. 服务响应慢

**可能原因**：
- TP 设置过小
- 模型加载未完成
- NPU 降频

**排查**：
```bash
# 检查 NPU 状态
npu-smi info -t board -i 0

# 检查服务状态
curl http://localhost:8000/health

# 查看日志
docker exec <container> tail -f /tmp/vllm_service.log
```

### 5. 网络/下载问题

**症状**：镜像拉取慢、模型下载超时

**解决方案**：调用 `mirror-proxy` 技能配置镜像源或代理
```bash
# 配置镜像源
bash skills/ascend-env/mirror-proxy/scripts/run_set_pip_mirror.sh

# 配置代理（如有）
bash skills/ascend-env/mirror-proxy/scripts/run_set_proxy.sh -h <proxy_host> -p <proxy_port>
```

### 6. 镜像不兼容

**症状**：模型加载失败、算子不支持

**排查步骤**：
1. 检查驱动版本：`npu-smi info`
2. 使用浏览器查找 CANN 与推理框架的版本兼容性
3. 选择匹配的镜像版本

### 7. 远程 SSH 连接失败

**解决方案**：
```bash
# 测试 SSH 连接
ssh <user>@<server-ip> "npu-smi info"

# 配置免密登录
ssh-copy-id <user>@<server-ip>
```

## 日志关键词

| 关键词 | 含义 |
|--------|------|
| `Uvicorn running` | 服务启动成功 |
| `Loading model weights` | 模型加载中 |
| `HCCL initialized` | 通信初始化成功 |
| `Error/Exception` | 错误，需排查 |
| `OOM` | 显存不足 |

## 快速诊断命令

```bash
# 容器状态
docker ps | grep vllm

# 容器日志
docker logs <container> --tail 100

# NPU 状态
docker exec <container> npu-smi info

# 服务健康
curl http://localhost:8000/v1/models

# 端口占用
netstat -tlnp | grep 8000
```

## 求助渠道

当遇到文档中未记录的问题时：

### 官方资源

| 资源 | 地址 |
|------|------|
| **GitHub 仓库** | https://github.com/vllm-project/vllm-ascend |
| **Issues 搜索** | https://github.com/vllm-project/vllm-ascend/issues |
| **模型教程** | https://docs.vllm.ai/projects/ascend/zh-cn/main/tutorials/models/index.html |

### 排查建议

1. **搜索 Issues** - 在 GitHub Issues 中搜索错误信息关键词
2. **浏览器搜索** - 搜索错误信息 + `vllm-ascend` 或 `CANN`
3. **内部知识库** - 3ms 社区搜索相关案例