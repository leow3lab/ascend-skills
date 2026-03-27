#!/bin/bash

set -eu

# =================================================================
# 脚本名称: pip 镜像源配置工具
# 支持镜像源: 阿里云、清华大学、中科大、豆瓣
# =================================================================

# 引入公共函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common_lib.sh"

# ==================== 镜像源配置 ====================
declare -A MIRRORS=(
    ["aliyun"]="https://mirrors.aliyun.com/pypi/simple/"
    ["tsinghua"]="https://pypi.tuna.tsinghua.edu.cn/simple/"
    ["ustc"]="https://pypi.mirrors.ustc.edu.cn/simple/"
    ["douban"]="https://pypi.doubanio.com/simple/"
)

declare -A MIRROR_NAMES=(
    ["aliyun"]="阿里云镜像源"
    ["tsinghua"]="清华大学镜像源"
    ["ustc"]="中科大镜像源"
    ["douban"]="豆瓣镜像源"
)

declare -A TRUSTED_HOSTS=(
    ["aliyun"]="mirrors.aliyun.com"
    ["tsinghua"]="pypi.tuna.tsinghua.edu.cn"
    ["ustc"]="pypi.mirrors.ustc.edu.cn"
    ["douban"]="pypi.doubanio.com"
)

DEFAULT_SOURCE="aliyun"

# ==================== 帮助信息 ====================
show_help() {
    cat << EOF
pip 镜像源配置脚本

用法: $0 [选项]

选项:
    -s, --source SOURCE    选择镜像源: aliyun (默认) | tsinghua | ustc | douban
    --uninstall           恢复为官方 PyPI 源
    --help                显示此帮助信息

示例:
    $0                      # 使用阿里云镜像源（默认）
    $0 -s tsinghua          # 使用清华大学镜像源
    $0 -s ustc              # 使用中科大镜像源
    $0 --uninstall          # 恢复为官方 PyPI 源

支持的镜像源:
    aliyun   - 阿里云镜像源 (默认)
    tsinghua - 清华大学镜像源
    ustc     - 中科大镜像源
    douban   - 豆瓣镜像源

注意:
    - pip 配置文件: ~/.pip/pip.conf (用户级) 或 /etc/pip.conf (系统级)
    - 会自动备份现有配置
EOF
}

# ==================== 参数解析 ====================
SOURCE_TYPE="$DEFAULT_SOURCE"
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE_TYPE="$2"
            shift 2
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证镜像源类型
if [ "$UNINSTALL" = false ]; then
    if [[ ! -v MIRRORS["$SOURCE_TYPE"] ]]; then
        log_error "不支持的镜像源类型: $SOURCE_TYPE"
        log_info "支持的类型: ${!MIRRORS[*]}"
        exit 1
    fi
fi

# ==================== 执行步骤 ====================

# 1. 检测 pip 是否已安装
log_step "步骤 1/3: 检测 pip 安装状态"

if ! check_pip_installed; then
    log_error "未检测到 pip，请先安装 Python"
    exit 1
fi

PIP_CMD=$(get_pip_command)
log_success "检测到 pip: $PIP_CMD"

# 2. 备份现有配置
log_step "步骤 2/3: 备份现有 pip 配置"

PIP_CONF_DIR="$HOME/.pip"
PIP_CONF_FILE="$PIP_CONF_DIR/pip.conf"

if [ -f "$PIP_CONF_FILE" ]; then
    BACKUP_DIR="${PIP_CONF_DIR}/backup"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="${PIP_CONF_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PIP_CONF_FILE" "$BACKUP_FILE"
    log_success "已备份: $PIP_CONF_FILE -> $BACKUP_FILE"
else
    log_info "未检测到现有 pip 配置文件，将创建新配置"
    mkdir -p "$PIP_CONF_DIR"
fi

# 3. 配置镜像源
log_step "步骤 3/3: 配置 pip 镜像源"

if [ "$UNINSTALL" = true ]; then
    log_info "恢复为官方 PyPI 源..."
    if [ -f "$PIP_CONF_FILE" ]; then
        rm -f "$PIP_CONF_FILE"
        log_success "已删除自定义配置文件"
    fi
    SOURCE_NAME="官方 PyPI 源"
    SOURCE_URL="https://pypi.org/simple/"
else
    SOURCE_URL="${MIRRORS[$SOURCE_TYPE]}"
    SOURCE_NAME="${MIRROR_NAMES[$SOURCE_TYPE]}"
    TRUSTED_HOST="${TRUSTED_HOSTS[$SOURCE_TYPE]}"

    log_info "配置 $SOURCE_NAME..."

    cat > "$PIP_CONF_FILE" << EOF
[global]
index-url = ${SOURCE_URL}
trusted-host = ${TRUSTED_HOST}
timeout = 120
EOF

    log_success "pip 镜像源配置完成"
fi

# 4. 验证配置
echo ""
log_info "当前 pip 配置:"
$PIP_CMD config list
echo ""

# 5. 测试连接
log_info "测试镜像源连接..."
if $PIP_CMD install --dry-run requests > /dev/null 2>&1; then
    log_success "pip 镜像源连接测试成功"
else
    log_warning "pip 镜像源连接测试失败，请检查网络配置"
fi

# 完成
echo ""
log_success "${BOLD}pip 镜像源配置完成！${NC}"
echo ""
log_info "配置信息:"
log_info "  镜像源名称: $SOURCE_NAME"
log_info "  镜像源地址: $SOURCE_URL"
log_info "  配置文件: $PIP_CONF_FILE"
echo ""