#!/bin/bash
# vLLM 服务启动脚本

set -e

# 参数
CONTAINER_NAME=""
MODEL_PATH=""
TP_SIZE=""
PORT="8000"
MAX_MODEL_LEN="8192"
GPU_MEMORY_UTIL="0.90"
MODE="local"
SERVER_IP=""
SSH_USER="root"

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --container) CONTAINER_NAME="$2"; shift 2 ;;
    --model-path) MODEL_PATH="$2"; shift 2 ;;
    --tp-size) TP_SIZE="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --max-model-len) MAX_MODEL_LEN="$2"; shift 2 ;;
    --gpu-memory-util) GPU_MEMORY_UTIL="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --server) SERVER_IP="$2"; shift 2 ;;
    --user) SSH_USER="$2"; shift 2 ;;
    *) echo "未知参数：$1"; exit 1 ;;
  esac
done

# 参数校验
[[ -z "$CONTAINER_NAME" ]] && { echo "错误：--container 必填"; exit 1; }
[[ -z "$MODEL_PATH" ]] && { echo "错误：--model-path 必填"; exit 1; }
[[ -z "$TP_SIZE" ]] && { echo "错误：--tp-size 必填"; exit 1; }
[[ "$MODE" == "remote" && -z "$SERVER_IP" ]] && { echo "错误：远程模式需要 --server"; exit 1; }

echo "=========================================="
echo "容器: $CONTAINER_NAME"
echo "模型: $MODEL_PATH"
echo "TP: $TP_SIZE"
echo "端口: $PORT"
[[ "$MODE" == "remote" ]] && echo "服务器: ${SSH_USER}@${SERVER_IP}"
echo "=========================================="

# vLLM 启动命令
LOG_FILE="/tmp/vllm_${CONTAINER_NAME}.log"

VLLM_CMD="
export PYTORCH_NPU_ALLOC_CONF=\"expandable_segments:True\"
export HCCL_OP_EXPANSION_MODE=\"AIV\"
export HCCL_BUFFSIZE=1024
export OMP_NUM_THREADS=1
export VLLM_USE_V1=1

vllm serve $MODEL_PATH \
  --served-model-name \"$(basename $MODEL_PATH)\" \
  --host 0.0.0.0 --port $PORT \
  --tensor-parallel-size $TP_SIZE \
  --max-model-len $MAX_MODEL_LEN \
  --gpu-memory-utilization $GPU_MEMORY_UTIL \
  --trust-remote-code \
  > $LOG_FILE 2>&1 &
"

# 执行
if [[ "$MODE" == "remote" ]]; then
  ssh ${SSH_USER}@${SERVER_IP} "docker exec -d $CONTAINER_NAME bash -c '$VLLM_CMD'"
else
  docker exec -d $CONTAINER_NAME bash -c "$VLLM_CMD"
fi

echo ""
echo "✅ 服务启动中"
echo ""
echo "验证：curl http://localhost:$PORT/health"
echo "日志：docker exec $CONTAINER_NAME tail -f $LOG_FILE"