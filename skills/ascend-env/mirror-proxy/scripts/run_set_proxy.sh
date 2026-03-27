#!/bin/bash

set -xeu

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# ==================== 默认配置 ====================
PROXY_HOST=""
PROXY_PORT="7890"
PROXY_USERNAME=""
PROXY_PASSWORD=""
NO_PROXY="127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10"

# ==================== 帮助信息 ====================
show_help() {
    cat << EOF
代理环境变量配置脚本

用法: $0 [选项]

选项:
    -h, --host HOST           代理服务器地址（必填）
    -p, --port PORT           代理服务器端口（默认: 7890）
    -u, --username USERNAME   代理用户名（可选）
    -P, --password PASSWORD   代理密码（可选）
    --skip-docker             跳过 Docker 代理配置
    --skip-git                跳过 Git 代理配置
    --help                    显示此帮助信息

示例:
    $0 -h 192.168.1.100 -p 7890
    $0 -h proxy.example.com -p 8080 -u user -P pass
    $0 -h 127.0.0.1 -p 7890 --skip-docker

注意:
    - 配置将写入 /etc/profile.d/proxy.sh，重启后自动生效
    - 该脚本需要 root 权限执行
EOF
}

# ==================== 参数解析 ====================
SKIP_DOCKER=false
SKIP_GIT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            PROXY_HOST="$2"
            shift 2
            ;;
        -p|--port)
            PROXY_PORT="$2"
            shift 2
            ;;
        -u|--username)
            PROXY_USERNAME="$2"
            shift 2
            ;;
        -P|--password)
            PROXY_PASSWORD="$2"
            shift 2
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --skip-git)
            SKIP_GIT=true
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

# ==================== 验证输入 ====================
if [ -z "$PROXY_HOST" ]; then
    log_error "必须提供代理服务器地址 (-h 或 --host)"
    echo ""
    echo "用法: $0 -h <proxy_host> -p <proxy_port>"
    echo "使用 --help 查看更多选项"
    exit 1
fi

# ==================== 执行步骤 ====================

# 1. 权限检查
log_step "步骤 1/4: 检查权限"
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 或 root 账号运行此脚本"
    exit 1
fi
log_success "权限检查通过"

# 2. 设置系统环境变量
log_step "步骤 2/4: 配置系统代理环境变量"

PROXY_CONFIG_FILE="/etc/profile.d/proxy.sh"

if [ -n "$PROXY_USERNAME" ] && [ -n "$PROXY_PASSWORD" ]; then
    PROXY_URL="http://${PROXY_USERNAME}:${PROXY_PASSWORD}@${PROXY_HOST}:${PROXY_PORT}/"
else
    PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}/"
fi

cat > "$PROXY_CONFIG_FILE" << EOF
# 代理配置 - 由脚本自动生成
export http_proxy="${PROXY_URL}"
export https_proxy="${PROXY_URL}"
export no_proxy="${NO_PROXY}"
export HTTP_PROXY="${PROXY_URL}"
export HTTPS_PROXY="${PROXY_URL}"
export NO_PROXY="${NO_PROXY}"
EOF

log_success "代理配置已写入: $PROXY_CONFIG_FILE"

# 立即加载配置到当前会话
source "$PROXY_CONFIG_FILE"
log_success "代理环境变量已加载到当前会话"

echo ""
log_info "${BOLD}代理信息${NC}"
log_info "  代理地址: ${PROXY_HOST}:${PROXY_PORT}"
if [ -n "$PROXY_USERNAME" ]; then
    log_info "  用户名: ${PROXY_USERNAME}"
fi
log_info "  no_proxy: ${NO_PROXY}"
echo ""

# 3. 配置 Docker 代理（如果已安装）
log_step "步骤 3/4: 配置 Docker 代理"

if [ "$SKIP_DOCKER" = true ]; then
    log_warning "已跳过 Docker 代理配置 (--skip-docker)"
elif command -v docker > /dev/null 2>&1; then
    DOCKER_CONFIG_DIR="/etc/systemd/system/docker.service.d"
    DOCKER_PROXY_CONFIG="${DOCKER_CONFIG_DIR}/http-proxy.conf"

    if [ ! -d "$DOCKER_CONFIG_DIR" ]; then
        mkdir -p "$DOCKER_CONFIG_DIR"
        log_success "创建 Docker 配置目录: $DOCKER_CONFIG_DIR"
    fi

    cat > "$DOCKER_PROXY_CONFIG" << EOF
[Service]
Environment="HTTP_PROXY=${PROXY_URL}"
Environment="HTTPS_PROXY=${PROXY_URL}"
Environment="NO_PROXY=${NO_PROXY}"
EOF

    log_success "Docker 代理配置已写入: $DOCKER_PROXY_CONFIG"

    log_info "正在重新加载 systemd 配置并重启 Docker..."
    systemctl daemon-reload
    systemctl restart docker

    if systemctl is-active --quiet docker; then
        log_success "Docker 服务重启成功"
    else
        log_error "Docker 服务重启失败，请检查: systemctl status docker"
        exit 1
    fi
else
    log_info "未检测到 Docker，跳过 Docker 代理配置"
fi

# 4. 配置 Git 代理
log_step "步骤 4/4: 配置 Git 代理"

if [ "$SKIP_GIT" = true ]; then
    log_warning "已跳过 Git 配置 (--skip-git)"
elif command -v git > /dev/null 2>&1; then
    git config --global http.proxy "${PROXY_URL}"
    git config --global https.proxy "${PROXY_URL}"

    log_success "Git 代理已配置"
    log_info "  http.proxy: ${PROXY_URL}"
    log_info "  https.proxy: ${PROXY_URL}"
else
    log_info "未检测到 Git，跳过 Git 配置"
fi

# 5. 验证代理配置
log_step "步骤 5/5: 验证代理配置"

echo ""
log_info "当前代理环境变量:"
env | grep -i proxy | sort
echo ""

log_info "测试代理连接..."
if curl -s -m 5 --connect-timeout 3 https://www.google.com > /dev/null 2>&1; then
    log_success "代理连接测试成功"
else
    log_warning "代理连接测试失败，请检查配置"
fi

echo ""
log_success "${BOLD}代理配置完成！${NC}"
echo ""
log_info "下次登录时自动加载代理配置（通过 /etc/profile.d/proxy.sh）"
log_info "如需立即生效，当前用户请执行: source /etc/profile.d/proxy.sh"
log_info "如需禁用代理，请删除: $PROXY_CONFIG_FILE"
echo ""