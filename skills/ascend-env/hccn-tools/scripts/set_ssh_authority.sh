#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}================ 多机环境自动化准备 ================${NC}"

# --- 功能 1: SSH 免密登录配置 ---
setup_ssh_copy_id() {
    echo -e "\n[1/2] 开始配置主机间 SSH 免密登录..."
    
    # 如果本地没有公钥，则生成一个 (一路回车)
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        echo "未检测到公钥，正在生成..."
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    fi

    read -p "请输入对端节点的 IP (Server ID): " REMOTE_HOST
    read -p "请输入对端节点的用户名 (默认 root): " REMOTE_USER
    REMOTE_USER=${REMOTE_USER:-root}

    echo "正在将公钥拷贝至 ${REMOTE_USER}@${REMOTE_HOST}..."
    ssh-copy-id -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCCESS: SSH 免密配置成功！${NC}"
    else
        echo -e "${RED}ERROR: SSH 免密配置失败，请检查网络或密码。${NC}"
    fi
}

# --- 功能 2: 批量 NPU IP 互通性检查 ---
check_npu_ping() {
    echo -e "\n[2/2] 开始批量检查 NPU IP 互通性..."
    
    echo "请输入对端节点（Server 2）的 8 个 NPU IP，空格分隔:"
    echo "提示：可以在 Server 2 执行 'for i in {0..7}; do hccn_tool -i \$i -ip -g; done' 获取"
    read -a REMOTE_NPU_IPS

    if [ ${#REMOTE_NPU_IPS[@]} -ne 8 ]; then
        echo -e "${RED}警告：检测到输入的 IP 数量不是 8 个，将按实际输入检查。${NC}"
    fi

    echo -e "\n开始执行本地 8 张卡对目标 IP 的 PING 测试..."
    for local_idx in {0..7}; do
        # 这里演示每张本地卡 PING 对应编号的对端卡（也可以根据需要修改为全遍历）
        target_ip=${REMOTE_NPU_IPS[$local_idx]}
        if [ -n "$target_ip" ]; then
            echo -n "本地 Device $local_idx PING 对端 $target_ip: "
            res=$(hccn_tool -i $local_idx -ping -g address $target_ip)
            if [[ $res == *"success"* ]]; then
                echo -e "${GREEN}PASS${NC}"
            else
                echo -e "${RED}FAIL ($res)${NC}"
            fi
        fi
    done
}

# 运行流程
setup_ssh_copy_id
check_npu_ping

echo -e "\n${YELLOW}================ 准备工作完成 ================${NC}"