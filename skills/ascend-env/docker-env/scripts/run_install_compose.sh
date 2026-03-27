#!/bin/bash
#
# Docker Compose 安装脚本
# 支持自动检测系统架构并安装对应版本的 Docker Compose
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

# ==================== 配置参数 ====================
COMPOSE_VERSION="v2.24.5"
TARGET_PATH="/usr/libexec/docker/cli-plugins/docker-compose"
LINK_PATH="/usr/bin/docker-compose"

# ==================== 主函数 ====================
main() {
    log_step "开始安装 Docker Compose ${COMPOSE_VERSION}"

    # 检测系统架构
    local arch=$(detect_arch)
    log_info "检测到系统架构: ${arch}"
    if [ "${arch}" = "unknown" ]; then
        log_error "无法识别系统架构，支持: x86_64, aarch64"
        exit 1
    fi

    # 映射架构名称
    local compose_arch
    case "${arch}" in
        x86_64)  compose_arch="x86_64" ;;
        aarch64)  compose_arch="aarch64" ;;
        *)        log_error "不支持的架构: ${arch}"; exit 1 ;;
    esac

    # 检查 root 权限
    check_root

    # 检查 Docker 是否安装
    if ! command -v docker > /dev/null 2>&1; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    log_success "Docker 已安装"

    # 创建目标目录
    mkdir -p /usr/libexec/docker/cli-plugins/

    # 下载 Docker Compose
    local download_url="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${compose_arch}"

    log_info "正在从 GitHub 下载 Docker Compose..."
    log_info "下载地址: ${download_url}"

    if ! wget --no-check-certificate "${download_url}" -O "${TARGET_PATH}"; then
        log_error "下载失败，请检查网络连接"
        log_info "可以手动下载后放置到: ${TARGET_PATH}"
        exit 1
    fi

    # 授予执行权限
    log_info "设置执行权限..."
    chmod +x "${TARGET_PATH}"

    # 创建软链接
    ln -sf "${TARGET_PATH}" "${LINK_PATH}"

    # 验证安装
    log_info "验证安装结果..."
    ls -lh "${TARGET_PATH}"

    if docker-compose version > /dev/null 2>&1; then
        docker-compose version
        log_success "Docker Compose 安装成功！"
    else
        log_error "Docker Compose 验证失败"
        exit 1
    fi

    log_info "使用方法: docker-compose [command]"
    log_info "或使用: docker compose [command] (Docker 插件方式)"
}

# ==================== 执行主函数 ====================
main "$@"