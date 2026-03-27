#!/bin/bash
# vLLM-Ascend 容器创建脚本
# 支持本地/远程部署，自动检测 NPU 数量

set -e

# 参数
IMAGE=""
MODEL_PATH=""
CONTAINER_NAME=""
WORK_DIR=""
MODE="local"
SERVER_IP=""
SSH_USER="root"

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --image) IMAGE="$2"; shift 2 ;;
    --model-path) MODEL_PATH="$2"; shift 2 ;;
    --container-name) CONTAINER_NAME="$2"; shift 2 ;;
    --work-dir) WORK_DIR="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --server) SERVER_IP="$2"; shift 2 ;;
    --user) SSH_USER="$2"; shift 2 ;;
    *) echo "未知参数：$1"; exit 1 ;;
  esac
done

# 参数校验
[[ -z "$IMAGE" ]] && { echo "错误：--image 必填"; exit 1; }
[[ -z "$MODEL_PATH" ]] && { echo "错误：--model-path 必填"; exit 1; }
[[ "$MODE" == "remote" && -z "$SERVER_IP" ]] && { echo "错误：远程模式需要 --server"; exit 1; }

# 默认值
CONTAINER_NAME="${CONTAINER_NAME:-vllm-$(basename "$MODEL_PATH" | tr '[:upper:]' '[:lower:]')}"
WORK_DIR="${WORK_DIR:-$(dirname "$MODEL_PATH")}"

# 检测 NPU 数量
detect_npu_count() {
  local cmd="npu-smi info | grep -c 'Ascend'"
  if [[ "$MODE" == "remote" ]]; then
    ssh ${SSH_USER}@${SERVER_IP} "$cmd" 2>/dev/null || echo "8"
  else
    eval "$cmd" 2>/dev/null || echo "8"
  fi
}

NPU_COUNT=$(detect_npu_count)

echo "=========================================="
echo "镜像: $IMAGE"
echo "模型: $MODEL_PATH"
echo "容器: $CONTAINER_NAME"
echo "NPU: $NPU_COUNT 卡"
[[ "$MODE" == "remote" ]] && echo "服务器: ${SSH_USER}@${SERVER_IP}"
echo "=========================================="

# 构建设备参数
DEVICES=""
for ((i=0; i<NPU_COUNT; i++)); do
  DEVICES+="--device=/dev/davinci${i} "
done
DEVICES+="--device=/dev/davinci_manager --device=/dev/devmm_svm --device=/dev/hisi_hdc"

# Docker 命令
DOCKER_CMD="docker run -itd \
  --network host --shm-size 16G --privileged \
  $DEVICES \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/add-ons/:/usr/local/Ascend/add-ons/ \
  -v /usr/local/bin/npu-smi:/usr/local/bin/npu-smi \
  -v /usr/local/sbin/npu-smi:/usr/local/sbin/npu-smi \
  -v /usr/local/sbin/:/usr/local/sbin/ \
  -v /var/log/npu/:/usr/slog \
  -v /var/log/npu/slog/:/var/log/npu/slog \
  -v /var/log/npu/profiling/:/var/log/npu/profiling \
  -v /var/log/npu/dump/:/var/log/npu/dump \
  -v /var/log/npu/conf/slog/slog.conf:/var/log/npu/conf/slog/slog.conf \
  -v /usr/lib/jvm/:/usr/lib/jvm \
  -v ${MODEL_PATH}:${MODEL_PATH} \
  -v ${WORK_DIR}:${WORK_DIR} \
  -w ${WORK_DIR} \
  --name=${CONTAINER_NAME} \
  --entrypoint=/bin/bash \
  ${IMAGE}"

# 执行
if [[ "$MODE" == "remote" ]]; then
  ssh ${SSH_USER}@${SERVER_IP} "$DOCKER_CMD"
else
  eval "$DOCKER_CMD"
fi

echo ""
echo "✅ 容器创建成功"
echo ""
echo "下一步："
echo "  bash scripts/start_service.sh --container $CONTAINER_NAME --model-path $MODEL_PATH --tp-size $NPU_COUNT"
[[ "$MODE" == "remote" ]] && echo "  --mode remote --server $SERVER_IP"