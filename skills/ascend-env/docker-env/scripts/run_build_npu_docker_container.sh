#!/bin/bash
#
# NPU Docker 容器启动脚本
# 支持自动检测 NPU 卡数（A2: 8卡, A3: 16卡）
# 使用方法: ./run_build_npu_docker_container.sh [容器名称] [镜像名称] [代码路径]
#

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载公共函数库
if [ -f "${SCRIPT_DIR}/common_lib.sh" ]; then
    source "${SCRIPT_DIR}/common_lib.sh"
else
    echo "错误: 找不到公共函数库 common_lib.sh"
    exit 1
fi

# ==================== 配置参数（可修改） ====================
# 容器名称
CONTAINER_NAME="${1:-container-name}"

# Docker 镜像
IMAGE_NAME="${2:-swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.3.rc1.alpha002-910b-ubuntu22.04-py3.11}"

# 代码挂载路径
CODE_PATH="${3:-/mnt}"

# 容器配置
NETWORK="${NETWORK:-host}"
IPC="${IPC:-ipc}"
USER="${USER:-root}"
PORT="${PORT:-8080}"
WORKDIR="${CODE_PATH}"
PRIVILEGED="${PRIVILEGED:-true}"

# ==================== NPU 设备检测 ====================
log_step "检测 NPU 设备"
NPU_COUNT=$(get_npu_count)

if [ "${NPU_COUNT}" -eq 0 ]; then
    log_error "未检测到 NPU 设备，请确认 NPU 驱动已正确安装"
    exit 1
fi

if ! check_docker_running; then
    log_error "Docker 服务未运行，请先启动 Docker"
    exit 1
fi

log_success "检测到 ${NPU_COUNT} 块 NPU 卡"
log_info "A2 产品: 8卡, A3 产品: 16卡"

# 生成 NPU 设备挂载参数
NPU_DEVICES=$(generate_npu_devices ${NPU_COUNT})

# ==================== 容器管理函数 ====================
train_docker_run() {
    log_step "删除已存在的容器 '${CONTAINER_NAME}'"
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

    log_step "启动 NPU Docker 容器"
    log_info "容器名称: ${CONTAINER_NAME}"
    log_info "Docker 镜像: ${IMAGE_NAME}"
    log_info "NPU 卡数: ${NPU_COUNT}"
    log_info "工作目录: ${WORKDIR}"

    docker run -itd -u ${USER} --name ${CONTAINER_NAME} \
        --network ${NETWORK} \
        --ipc ${IPC} \
        ${NPU_DEVICES} \
        --privileged=${PRIVILEGED} \
        -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
        -v /usr/local/Ascend/add-ons/:/usr/local/Ascend/add-ons/ \
        -v /usr/local/sbin/:/usr/local/sbin/ \
        -v /usr/local/sbin/npu-smi:/usr/local/sbin/npu-smi \
        -v /var/log/npu/conf/slog/slog.conf:/var/log/npu/conf/slog/slog.conf \
        -v /var/log/npu/slog/:/var/log/npu/slog \
        -v /var/log/npu/profiling/:/var/log/npu/profiling \
        -v /var/log/npu/dump/:/var/log/npu/dump \
        -v /var/log/npu/:/usr/slog \
        -v /lib/modules:/lib/modules \
        -p ${PORT}:${PORT} \
        -w ${WORKDIR} \
        --entrypoint /bin/bash \
        -v ${CODE_PATH}:${CODE_PATH} \
        ${IMAGE_NAME}

    log_success "容器启动成功"
    log_info "正在进入容器..."

    docker exec -it ${CONTAINER_NAME} /bin/bash
}

# ==================== 主函数 ====================
main() {
    log_info "=== NPU Docker 容器启动脚本 ==="
    train_docker_run
}

# ==================== 执行主函数 =================###
main "$@"