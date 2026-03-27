---
applicable_aisbench_version: "v0.2.0 - v0.3.x"
last_verified: 2026-03-12
version_check_warning: 本故障排查指南基于 AISBench v0.2.x 版本。更高版本可能涉及不同的错误日志格式或诊断命令，请根据实际版本调整排查步骤。
---

# AISBench 故障排查指南

## 常见问题

### 问题 1：任务卡在推理阶段，进度 0%

**症状：** 推理进度卡在 0%，日志显示 warmup 完成但无后续输出

**检查步骤：**
```bash
# 1. 检查推理服务是否可访问
curl -s http://<host_ip>:<host_port>/v1/models -H "Authorization: Bearer <api_key>"

# 2. 检查容器内配置文件
docker exec <container_id> cat /workspace/benchmark/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py

# 3. 查看推理服务日志，确认是否收到请求
```

**解决方案：**
- 改用非流式配置 `vllm_api_general_chat.py`
- 检查推理服务日志是否有错误

---

### 问题 2：配置文件语法错误

**症状：** 启动时立即报错 `unterminated string literal` 或 `invalid syntax`

**原因：** heredoc 方式的 `cat > ... EOF` 因特殊字符导致解析问题

**解决方案：** 使用 `docker cp` 间接写入
```bash
# 1. 保存配置文件到宿主机
cat > config.py << 'EOF'
from ais_bench.benchmark.models import VLLMCustomAPIChat
...
EOF

# 2. 复制到容器
docker cp config.py <container_id>:/workspace/benchmark/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py

# 3. 执行评测
docker exec <container_id> ais_bench ...
```

---

### 问题 3：结果保存目录为空

**检查：**
```bash
# 检查 volume mount 路径
docker inspect <container_id> | grep -A "Mounts"

# 检查容器内 outputs 目录权限
ls -la /workspace/benchmark/outputs/
```

---

### 问题 4：进度条长时间无反应

**说明：** AISBench 启动后需要 20-40 秒初始化（加载配置、连接服务、启动监控）

**建议：**
- 等待 30-60 秒，不要过早终止
- 超过 2 分钟无进展再排查

---

## 调试技巧

### 保留容器进行调试
```bash
# 去掉 --rm 参数，容器会保留
docker run -it -v $(pwd)/aisbench-results:/workspace/benchmark/outputs aisbench:latest bash

# 进入容器查看
docker ps -a                    # 查看容器 ID
docker exec -it <container_id> bash

# 查看日志
ls outputs/default/*/logs/
cat outputs/default/*/logs/infer/*/gsm8k.out
```

### 从镜像获取默认配置对比
```bash
docker run --rm aisbench:latest cat /workspace/benchmark/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py
```

---

## 流式接口问题

**症状：** 推理进度卡在 0%

**原因：** `stream=True` 配置与某些推理服务不兼容

**解决：** 改用非流式配置
- `vllm_api_general_chat.py`（非流式，对话格式）
- `vllm_api_general.py`（非流式，字符串格式）
