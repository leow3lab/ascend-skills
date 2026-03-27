#!/bin/bash
#
# 公共函数库
# 提供：颜色定义、日志函数、自动检测等通用功能
#

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

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
    echo -e "${CYAN}${BOLD}>>>${NC} ${CYAN}$1${NC}"
}

# ==================== 检测函数 ====================

# 检测是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 或 root 账号运行此脚本"
        exit 1
    fi
}

# 检测操作系统类型
detect_os() {
    if [ -f /etc/redhat-release ]; then
        echo "CentOS"
    elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
        echo "Ubuntu"
    else
        echo "Unknown"
    fi
}

# 检测 Docker 是否安装
check_docker_installed() {
    if command -v docker > /dev/null 2>&1; then
        return 0
    elif systemctl list-unit-files | grep -q docker.service 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 检测 Docker 服务是否运行
check_docker_running() {
    systemctl is-active --quiet docker
}

# 检测是否在容器内运行
check_in_container() {
    [ -f /.dockerenv ] || grep -qa docker /proc/1/cgroup 2>/dev/null
}

# 检测 pip 是否安装
check_pip_installed() {
    command -v pip3 > /dev/null 2>&1 || command -v pip > /dev/null 2>&1
}

# 检测 npm 是否安装
check_npm_installed() {
    command -v npm > /dev/null 2>&1
}

# 检测 git 是否安装
check_git_installed() {
    command -v git > /dev/null 2>&1
}

# 获取 pip 命令（优先使用 pip3）
get_pip_command() {
    if command -v pip3 > /dev/null 2>&1; then
        echo "pip3"
    elif command -v pip > /dev/null 2>&1; then
        echo "pip"
    else
        echo ""
    fi
}

# ==================== 备份函数 ====================

# 备份文件
backup_file() {
    local file="$1"
    local backup_dir="$2"

    if [ -f "$file" ]; then
        if [ -n "$backup_dir" ] && [ ! -d "$backup_dir" ]; then
            mkdir -p "$backup_dir"
            log_info "创建备份目录: $backup_dir"
        fi

        local backup_file
        if [ -n "$backup_dir" ]; then
            backup_file="${backup_dir}/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
        else
            backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        cp "$file" "$backup_file"
        log_success "已备份: $file -> $backup_file"
        echo "$backup_file"
    fi
}

# ==================== 通用配置 ====================

# 默认的 no_proxy 配置（本地网络）
DEFAULT_NO_PROXY="127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10"

# 默认代理配置（空，需用户指定）
DEFAULT_PROXY_HOST=""
DEFAULT_PROXY_PORT="7890"