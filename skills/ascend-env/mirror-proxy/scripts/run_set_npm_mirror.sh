#!/bin/bash

# =================================================================
# 脚本名称: npm 镜像源配置工具
# 支持版本: Node.js 12+
# =================================================================

set -eu

# 引入公共函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common_lib.sh"

# ==================== 镜像源配置 ====================
TAOBAO_REGISTRY="https://registry.npmmirror.com"
TAOBAO_NAME="淘宝镜像源"

HUAWEI_REGISTRY="https://mirrors.huaweicloud.com/repository/npm/"
HUAWEI_NAME="华为云镜像源"

OFFICIAL_REGISTRY=""  # npm 官方源为空，使用 delete
OFFICIAL_NAME="官方源"

DEFAULT_SOURCE="taobao"

# ==================== 帮助信息 ====================
show_help() {
    cat << EOF
npm 镜像源配置脚本

用法: $0 [选项]

选项:
    -s, --source SOURCE    选择镜像源: taobao (默认) | huawei | npm
    --uninstall           恢复为官方源
    --help                显示此帮助信息

示例:
    $0                          # 使用淘宝镜像源（默认）
    $0 -s huawei                # 使用华为云镜像源
    $0 -s npm                   # 使用官方 npm 源
    $0 --uninstall              # 恢复为官方源

注意:
    - npm 配置文件: ~/.npmrc
    - 会自动备份现有配置
    - 用户配置优先级高于系统配置
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
    case "$SOURCE_TYPE" in
        taobao|huawei|npm)
            ;;
        *)
            log_error "不支持的镜像源类型: $SOURCE_TYPE"
            log_info "支持的类型: taobao, huawei, npm"
            exit 1
            ;;
    esac
fi

# ==================== 执行步骤 ====================

# 1. 检测 npm 是否已安装
log_step "步骤 1/3: 检测 npm 安装状态"

if ! check_npm_installed; then
    log_error "未检测到 npm，请先安装 Node.js"
    exit 1
fi

NPM_VERSION=$(npm --version 2>/dev/null)
log_success "检测到 npm: $NPM_VERSION"

# 2. 备份现有配置
log_step "步骤 2/3: 备份现有 npm 配置"

NPMRC_FILE="$HOME/.npmrc"
if [ -f "$NPMRC_FILE" ]; then
    BACKUP_FILE="${NPMRC_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$NPMRC_FILE" "$BACKUP_FILE"
    log_success "已备份: $NPMRC_FILE -> $BACKUP_FILE"
else
    log_info "未检测到现有 npm 配置文件，将创建新配置"
fi

# 3. 配置镜像源
log_step "步骤 3/3: 配置 npm 镜像源"

# 先删除所有可能的代理配置（clean slate）
npm config delete proxy > /dev/null 2>&1 || true
npm config delete https-proxy > /dev/null 2>&1 || true

if [ "$UNINSTALL" = true ]; then
    log_info "恢复为官方 npm 源..."
    npm config delete registry
    SOURCE_NAME="$OFFICIAL_NAME"
    SOURCE_URL="$OFFICIAL_REGISTRY"
elif [ "$SOURCE_TYPE" = "taobao" ]; then
    log_info "配置淘宝镜像源..."
    npm config set registry "$TAOBAO_REGISTRY"
    SOURCE_NAME="$TAOBAO_NAME"
    SOURCE_URL="$TAOBAO_REGISTRY"
elif [ "$SOURCE_TYPE" = "huawei" ]; then
    log_info "配置华为云镜像源..."
    npm config set registry "$HUAWEI_REGISTRY"
    SOURCE_NAME="$HUAWEI_NAME"
    SOURCE_URL="$HUAWEI_REGISTRY"
else
    log_info "配置官方 npm 源..."
    npm config delete registry
    SOURCE_NAME="$OFFICIAL_NAME"
    SOURCE_URL="$OFFICIAL_REGISTRY"
fi

log_success "npm 镜像源配置完成"

# 4. 验证配置
echo ""
log_info "当前 npm 配置:"
npm config list
echo ""

# 5. 测试连接
log_info "测试镜像源连接..."
if npm ping > /dev/null 2>&1; then
    log_success "npm 镜像源连接测试成功"
else
    log_warning "npm 镜像源连接测试失败，请检查网络配置"
    echo ""
    log_info "故障排查建议:"
    log_info "  1. 检查系统代理环境变量是否配置正确"
    log_info "  2. 确认网络连接正常"
    log_info "  3. 尝试临时切换到其他镜像源"
fi

# 完成
echo ""
log_success "${BOLD}npm 镜像源配置完成！${NC}"
echo ""
log_info "配置信息:"
log_info "  镜像源名称: $SOURCE_NAME"
if [ -n "$SOURCE_URL" ]; then
    log_info "  镜像源地址: $SOURCE_URL"
else
    log_info "  镜像源地址: 官方源 (删除自定义 registry 配置)"
fi
log_info "  配置文件: $NPMRC_FILE"
if [ -f "${NPMRC_FILE}.backup."* ]; then
    BACKUP_FILE=$(ls -t ${NPMRC_FILE}.backup.* 2>/dev/null | head -1)
    log_info "  备份文件: $BACKUP_FILE"
fi
echo ""
log_info "如需恢复原配置，可从备份文件恢复: ls -la ${NPMRC_FILE}.backup.*"
echo ""