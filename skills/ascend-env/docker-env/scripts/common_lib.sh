#!/bin/bash
#
# 公共函数库 - 简化版
# 提供：颜色定义、日志函数、系统检测功能
#

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==================== 日志函数 ====================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_step() {
    echo -e "${CYAN}>>>${NC} $1"
}

# ==================== 检测函数 ====================

# 检测是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 或 root 账号运行此脚本"
        exit 1
    fi
}

# 检测系统架构
detect_arch() {
    case "$(uname -m)" in
        x86_64)  echo "x86_64" ;;
        aarch64)  echo "aarch64" ;;
        arm64)    echo "aarch64" ;;
        *)        echo "unknown" ;;
    esac
}

# 检测 Docker 服务是否运行
check_docker_running() {
    systemctl is-active --quiet docker
}

# ==================== NPU 设备资源函数 ====================

# 获取已安装的 NPU 卡数量
get_npu_count() {
    local count=0
    while [ -e /dev/davinci${count} ] 2>/dev/null; do
        ((count++))
    done
    echo $count
}

# 生成 NPU 设备挂载参数
# 参数: $1 - NPU 卡数 (0-16)
# 返回: --device 参数列表
generate_npu_devices() {
    local count=$1
    local devices=""

    # davinci 设备
    for ((i=0; i<count; i++)); do
        devices="--device=/dev/davinci${i} $devices"
    done

    # 公共管理设备
    devices="$devices --device=/dev/davinci_manager --device=/dev/devmm_svm --device=/dev/hisi_hdc"

    echo "$devices"
}