#!/bin/bash
# vLLM-Ascend Docker Compose 一键部署脚本

set -e

# 参数
IMAGE=""
MODEL_PATH=""
TP_SIZE=""
PORT="8000"
MAX_MODEL_LEN="8192"
GPU_MEMORY_UTIL="0.90"
HARDWARE=""
WORK_DIR="/mnt"
TOOL_CALL_PARSER=""
REASONING_PARSER=""

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --image) IMAGE="$2"; shift 2 ;;
    --model-path) MODEL_PATH="$2"; shift 2 ;;
    --tp-size) TP_SIZE="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --max-model-len) MAX_MODEL_LEN="$2"; shift 2 ;;
    --gpu-memory-util) GPU_MEMORY_UTIL="$2"; shift 2 ;;
    --hardware) HARDWARE="$2"; shift 2 ;;
    --work-dir) WORK_DIR="$2"; shift 2 ;;
    --tool-call-parser) TOOL_CALL_PARSER="$2"; shift 2 ;;
    --reasoning-parser) REASONING_PARSER="$2"; shift 2 ;;
    *) echo "未知参数：$1"; exit 1 ;;
  esac
done

# 参数校验
[[ -z "$MODEL_PATH" ]] && { echo "错误：--model-path 必填"; exit 1; }

# 自动检测硬件
if [[ -z "$HARDWARE" ]]; then
  NPU_COUNT=$(npu-smi info 2>/dev/null | grep -c "Ascend" || echo "8")
  HARDWARE=$([[ "$NPU_COUNT" -ge 16 ]] && echo "a3" || echo "a2")
fi

NPU_COUNT=$([[ "$HARDWARE" == "a3" ]] && echo "16" || echo "8")

# 镜像提示
if [[ -z "$IMAGE" ]]; then
  echo "请指定镜像：--image <IMAGE>"
  echo ""
  echo "查阅镜像：https://quay.io/repository/ascend/vllm-ascend?tab=tags"
  echo "提示：A3 选择带 -a3 后缀的 tag，A2 无后缀"
  exit 1
fi

TP_SIZE="${TP_SIZE:-$NPU_COUNT}"
CONTAINER_NAME="vllm-$(basename "$MODEL_PATH" | tr '[:upper:]' '[:lower:]')"
MODEL_NAME="$(basename "$MODEL_PATH")"

echo "=========================================="
echo "镜像: $IMAGE"
echo "模型: $MODEL_PATH"
echo "硬件: $HARDWARE ($NPU_COUNT NPU)"
echo "TP: $TP_SIZE"
echo "端口: $PORT"
[[ -n "$TOOL_CALL_PARSER" ]] && echo "工具调用: $TOOL_CALL_PARSER"
[[ -n "$REASONING_PARSER" ]] && echo "推理: $REASONING_PARSER"
echo "=========================================="

# 生成设备列表
DEVICES=""
for ((i=0; i<NPU_COUNT; i++)); do
  DEVICES+="      - /dev/davinci${i}:/dev/davinci${i}\n"
done
DEVICES+="      - /dev/davinci_manager:/dev/davinci_manager\n      - /dev/devmm_svm:/dev/devmm_svm\n      - /dev/hisi_hdc:/dev/hisi_hdc"

# 构建启动参数
VLLM_ARGS="--served-model-name ${MODEL_NAME} --host 0.0.0.0 --port ${PORT} --tensor-parallel-size ${TP_SIZE} --max-model-len ${MAX_MODEL_LEN} --gpu-memory-utilization ${GPU_MEMORY_UTIL} --trust-remote-code"
[[ -n "$TOOL_CALL_PARSER" ]] && VLLM_ARGS+=" --tool-call-parser $TOOL_CALL_PARSER --enable-auto-tool-choice"
[[ -n "$REASONING_PARSER" ]] && VLLM_ARGS+=" --reasoning-parser $REASONING_PARSER"

# 生成启动脚本
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cat > "$SCRIPT_DIR/start.sh" << EOF
#!/bin/bash
export PYTORCH_NPU_ALLOC_CONF="expandable_segments:True"
export OMP_NUM_THREADS=64
export VLLM_USE_V1=1
export HCCL_OP_EXPANSION_MODE=AIV
vllm serve ${MODEL_PATH} ${VLLM_ARGS} 2>&1 | tee /tmp/vllm_${CONTAINER_NAME}.log
EOF
chmod +x "$SCRIPT_DIR/start.sh"

# 生成 docker-compose.yml
cat > "$SCRIPT_DIR/docker-compose.yml" << EOF
version: "3.9"
services:
  vllm-ascend:
    image: ${IMAGE}
    container_name: ${CONTAINER_NAME}
    network_mode: host
    ipc: host
    privileged: true
    devices:
$(echo -e "$DEVICES")
    volumes:
      - /usr/local/Ascend/driver:/usr/local/Ascend/driver
      - /usr/local/Ascend/driver/lib64/:/usr/local/Ascend/driver/lib64/
      - /usr/local/bin/npu-smi:/usr/local/bin/npu-smi
      - /usr/local/sbin/npu-smi:/usr/local/sbin/npu-smi
      - /usr/local/sbin/:/usr/local/sbin/
      - /usr/local/Ascend/add-ons/:/usr/local/Ascend/add-ons/
      - /var/log/npu/:/usr/slog
      - /var/log/npu/slog/:/var/log/npu/slog
      - /var/log/npu/profiling/:/var/log/npu/profiling
      - /var/log/npu/dump/:/var/log/npu/dump
      - ${MODEL_PATH}:${MODEL_PATH}
      - ${WORK_DIR}:${WORK_DIR}
      - ./start.sh:/opt/vllm/start.sh:ro
    environment:
      - VLLM_USE_V1=1
    working_dir: ${WORK_DIR}
    entrypoint: ["bash", "-c"]
    command: ["bash /opt/vllm/start.sh"]
EOF

# 启动
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo ""
echo "✅ 启动成功"
echo ""
echo "验证：curl http://localhost:$PORT/health"
echo "日志：docker logs -f $CONTAINER_NAME"