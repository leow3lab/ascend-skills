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

# ==================== 帮助信息 ====================
show_help() {
    cat << EOF
Docker 代理配置脚本

用法: $0 [选项]

选项:
    -h, --host HOST           代理服务器地址（必填）
    -p, --port PORT           代理服务器端口（默认: 7890）
    -u, --username USERNAME   代理用户名（可选）
    -P, --password PASSWORD   代理密码（可选）
    --skip-test               跳过测试拉取镜像
    --help                    显示此帮助信息

示例:
    $0 -h 192.168.1.100 -p 7890
    $0 -h proxy.example.com -p 8080 -u user -P pass
    $0 -h 127.0.0.1 -p 7890 --skip-test

注意:
    - 该脚本需要 root 权限执行
    - 配置后 Docker 服务会自动重启
    - 配置文件位置: /etc/systemd/system/docker.service.d/http-proxy.conf
EOF
}

# ==================== 默认配置 ====================
PROXY_HOST=""
PROXY_PORT="7890"
PROXY_USERNAME=""
PROXY_PASSWORD=""
NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
SKIP_TEST=false

# ==================== 参数解析 ====================
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
        --skip-test)
            SKIP_TEST=true
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
    log_error "必须提供代理服务器地址"
    echo ""
    echo "用法: $0 -h <proxy_host> -p <proxy_port>"
    echo "使用 --help 查看更多选项"
    exit 1
fi

# ==================== 执行步骤 ====================

# 1. 权限检查
log_step "步骤 1/6: 检查权限"
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 或 root 账号运行此脚本"
    exit 1
fi

# 2. 检查 Docker 是否已安装
log_step "步骤 2/6: 检查 Docker 安装状态"
if command -v docker > /dev/null 2>&1; then
    log_success "Docker 已安装: $(docker --version 2>/dev/null | head -n1)"
elif systemctl list-unit-files | grep -q docker.service 2>/dev/null; then
    log_success "检测到 Docker 服务已安装"
else
    log_error "未检测到 Docker 安装，请先安装 Docker"
    exit 1
fi

# 3. 检测并备份 Docker 服务状态
log_step "步骤 3/6: 检测 Docker 服务状态"
if systemctl is-active --quiet docker; then
    log_success "Docker 服务正在运行"
    DOCKER_WAS_RUNNING=true
elif systemctl is-enabled --quiet docker; then
    log_info "Docker 服务已配置但未运行"
    DOCKER_WAS_RUNNING=false
else
    log_error "Docker 服务未配置，请先安装或启用 Docker"
    exit 1
fi

# 4. 配置 Docker 代理
log_step "步骤 4/6: 配置 Docker 代理"

DOCKER_CONFIG_DIR="/etc/systemd/system/docker.service.d"
DOCKER_PROXY_CONFIG="${DOCKER_CONFIG_DIR}/http-proxy.conf"

# 备份现有配置
if [ -f "$DOCKER_PROXY_CONFIG" ]; then
    BACKUP_FILE="${DOCKER_PROXY_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$DOCKER_PROXY_CONFIG" "$BACKUP_FILE"
    log_success "已备份原配置: $BACKUP_FILE"
fi

if [ ! -d "$DOCKER_CONFIG_DIR" ]; then
    mkdir -p "$DOCKER_CONFIG_DIR"
    log_success "创建 Docker 配置目录: $DOCKER_CONFIG_DIR"
fi

if [ -n "$PROXY_USERNAME" ] && [ -n "$PROXY_PASSWORD" ]; then
    PROXY_URL="http://${PROXY_USERNAME}:${PROXY_PASSWORD}@${PROXY_HOST}:${PROXY_PORT}"
else
    PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
fi

cat > "$DOCKER_PROXY_CONFIG" << EOF
[Service]
Environment="HTTP_PROXY=${PROXY_URL}"
Environment="HTTPS_PROXY=${PROXY_URL}"
Environment="NO_PROXY=${NO_PROXY}"
EOF

log_success "Docker 代理配置已写入: $DOCKER_PROXY_CONFIG"
log_info "  代理地址: ${PROXY_HOST}:${PROXY_PORT}"
log_info "  NO_PROXY: ${NO_PROXY}"

# 5. 重启 Docker 服务
log_step "步骤 5/6: 重新加载并重启 Docker 服务"
log_info "正在重新加载 systemd 配置..."
systemctl daemon-reload
log_success "systemd 配置已重新加载"

log_info "正在重启 Docker 服务..."
if systemctl restart docker; then
    log_success "Docker 服务重启成功"
else
    log_error "Docker 服务重启失败，请检查: systemctl status docker"
    exit 1
fi

# 等待 Docker 服务完全启动
log_info "等待 Docker 服务完全启动..."
sleep 3

if systemctl is-active --quiet docker; then
    log_success "Docker 服务运行正常"
else
    log_error "Docker 服务未正常运行，请检查: systemctl status docker"
    exit 1
fi

# 6. 验证配置和测试
log_step "步骤 6/6: 验证配置和测试"

echo ""
log_info "Docker 服务环境变量:"
systemctl show --property=Environment docker 2>/dev/null | sed 's/Environment=//; s/ /\n  /g' | sed 's/^/  /' || log_warning "无法获取 Docker 环境变量"
echo ""

log_info "Docker 系统信息:"
docker info > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_success "Docker 系统信息获取成功"
    docker info | grep -E "Server Version|Operating System|Docker Root Dir"
else
    log_warning "Docker 系统信息获取失败"
fi

echo ""

# 测试拉取镜像
if [ "$SKIP_TEST" = true ]; then
    log_warning "已跳过测试拉取镜像 (--skip-test)"
else
    log_info "测试拉取 Docker 镜像 (hello-world)..."
    if docker pull hello-world > /tmp/docker_pull.log 2>&1; then
        log_success "镜像拉取成功"
        log_info "镜像大小信息:"
        grep "Downloaded newer image" /tmp/docker_pull.log || true

        echo ""
        log_info "运行测试容器..."
        if docker run --rm hello-world > /tmp/docker_run.log 2>&1; then
            log_success "测试容器运行成功"
            grep "Hello from Docker" /tmp/docker_run.log || true
        else
            log_warning "测试容器运行失败，请检查日志: /tmp/docker_run.log"
        fi
    else
        log_error "镜像拉取失败，请检查代理配置"
        log_info "错误日志: /tmp/docker_pull.log"
        cat /tmp/docker_pull.log | tail -20
    fi
fi

echo ""
log_success "${BOLD}Docker 代理配置完成！${NC}"
echo ""
log_info "配置信息:"
log_info "  代理地址: ${PROXY_HOST}:${PROXY_PORT}"
log_info "  配置文件: ${DOCKER_PROXY_CONFIG}"
log_info "  Docker 服务状态: $(systemctl is-active docker)"
echo ""
log_info "如需修改代理配置，请编辑: $DOCKER_PROXY_CONFIG"
log_info "编辑后执行: systemctl daemon-reload && systemctl restart docker"
echo ""