#!/bin/bash

# =================================================================
# 脚本名称: Ubuntu 镜像源切换工具
# 支持镜像源: 阿里云、清华大学、中科大
# 支持版本: Ubuntu 18.04 / 20.04 / 22.04 / 24.04
# =================================================================

set -xeu

# 引入公共函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common_lib.sh"

# ==================== 镜像源配置 ====================
declare -A MIRRORS=(
    ["aliyun"]="mirrors.aliyun.com"
    ["tsinghua"]="mirrors.tuna.tsinghua.edu.cn"
    ["ustc"]="mirrors.ustc.edu.cn"
)

declare -A MIRROR_NAMES=(
    ["aliyun"]="阿里云镜像源"
    ["tsinghua"]="清华大学镜像源"
    ["ustc"]="中科大镜像源"
)

DEFAULT_SOURCE="aliyun"

# ==================== 帮助信息 ====================
show_help() {
    cat << EOF
APT 镜像源配置脚本 (Ubuntu/Debian)

用法: $0 [选项]

选项:
    -s, --source SOURCE    选择镜像源: aliyun (默认) | tsinghua | ustc
    --help                 显示此帮助信息

支持系统:
    Ubuntu 18.04 (bionic)
    Ubuntu 20.04 (focal)
    Ubuntu 22.04 (jammy)
    Ubuntu 24.04 (noble)
    Debian 系统

支持镜像源:
    aliyun   - 阿里云镜像源 (默认)
    tsinghua - 清华大学镜像源
    ustc     - 中科大镜像源

注意:
    - 此脚本需要 root 权限执行
    - 会自动备份原始配置文件
    - Ubuntu 24.04 会自动处理新的 DEB822 源格式

示例:
    $0                    # 配置阿里云镜像源（默认）
    $0 -s tsinghua        # 配置清华大学镜像源
    $0 -s ustc            # 配置中科大镜像源
EOF
}

# ==================== 参数解析 ====================
SOURCE_TYPE="$DEFAULT_SOURCE"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 验证镜像源类型
if [[ ! -v MIRRORS["$SOURCE_TYPE"] ]]; then
    log_error "不支持的镜像源类型: $SOURCE_TYPE"
    log_info "支持的类型: ${!MIRRORS[*]}"
    exit 1
fi

MIRROR_HOST="${MIRRORS[$SOURCE_TYPE]}"
MIRROR_NAME="${MIRROR_NAMES[$SOURCE_TYPE]}"

# ==================== 执行步骤 ====================

# 1. 权限检查
log_step "步骤 1/6: 检查权限"
check_root
log_success "权限检查通过"

# 2. 检测操作系统和版本
log_step "步骤 2/6: 检测操作系统和版本"

OS=$(detect_os)
if [ "$OS" != "Ubuntu" ]; then
    log_error "此脚本仅支持 Ubuntu/Debian 系统，检测到系统: $OS"
    exit 1
fi

# 检查 lsb_release 是否可用
if ! command -v lsb_release > /dev/null 2>&1; then
    log_error "未检测到 lsb_release 命令，请先安装: apt install lsb-release"
    exit 1
fi

CODENAME=$(lsb_release -c | awk '{print $2}')
DATE=$(date +%Y%m%d_%H%M%S)

log_success "系统版本: Ubuntu $CODENAME"

# 3. 安装 HTTPS 支持
log_step "步骤 3/6: 安装 HTTPS 传输支持"
log_info "正在更新 apt 软件包列表..."
apt update > /dev/null 2>&1
log_success "apt 软件包列表更新完成"

log_info "正在安装 apt-transport-https 和 ca-certificates..."
apt install -y apt-transport-https ca-certificates > /dev/null 2>&1
log_success "HTTPS 传输支持已安装"

# 4. 备份原始文件
log_step "步骤 4/6: 备份原始配置文件"

SOURCE_LIST="/etc/apt/sources.list"
if [ -f "$SOURCE_LIST" ]; then
    BACKUP_FILE="${SOURCE_LIST}.bak_${DATE}"
    cp "$SOURCE_LIST" "$BACKUP_FILE"
    log_success "已备份: $SOURCE_LIST -> $BACKUP_FILE"
else
    log_warning "未找到源文件: $SOURCE_LIST，将创建新文件"
fi

# 5. 写入镜像源配置
log_step "步骤 5/6: 配置 $MIRROR_NAME"

log_info "正在写入镜像源配置..."
cat > "$SOURCE_LIST" << EOF
# ---------------------------------------------------------
# $MIRROR_NAME (当前生效)
# ---------------------------------------------------------
deb https://$MIRROR_HOST/ubuntu/ $CODENAME main restricted universe multiverse
deb https://$MIRROR_HOST/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb https://$MIRROR_HOST/ubuntu/ $CODENAME-backports main restricted universe multiverse
deb https://$MIRROR_HOST/ubuntu/ $CODENAME-security main restricted universe multiverse

# 源码镜像 (默认关闭)
# deb-src https://$MIRROR_HOST/ubuntu/ $CODENAME main restricted universe multiverse
EOF

log_success "镜像源配置已写入"

# 6. 处理 Ubuntu 24.04 的特殊配置
log_step "步骤 6/6: 处理系统特定配置"

if [ "$CODENAME" = "noble" ]; then
    UBUNTU_SOURCES="/etc/apt/sources.list.d/ubuntu.sources"
    if [ -f "$UBUNTU_SOURCES" ]; then
        log_info "检测到 Ubuntu 24.04，正在备份并禁用默认的 DEB822 源配置..."
        mv "$UBUNTU_SOURCES" "${UBUNTU_SOURCES}.bak_${DATE}"
        log_success "已移动: $UBUNTU_SOURCES -> ${UBUNTU_SOURCES}.bak_${DATE}"
    fi
fi

# 7. 更新软件包索引
echo ""
log_info "正在更新 APT 软件包索引..."
if apt update; then
    log_success "APT 软件包索引更新成功"
else
    log_error "APT 软件包索引更新失败，请检查镜像源配置"
    exit 1
fi

# 完成
echo ""
log_success "${BOLD}镜像源切换完成！${NC}"
echo ""
log_info "配置信息:"
log_info "  当前镜像源: $MIRROR_NAME (https://$MIRROR_HOST/ubuntu/)"
log_info "  系统版本: Ubuntu $CODENAME"
log_info "  配置文件: $SOURCE_LIST"
log_info "  备份文件: ${BACKUP_FILE:-无（新建文件）}"
echo ""