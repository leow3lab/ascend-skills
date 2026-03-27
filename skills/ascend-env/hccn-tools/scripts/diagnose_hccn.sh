#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

echo -e "${YELLOW}================ NPU 状态综合检查开始 ================${NC}"

# 1. 检查 /etc/hccn.conf 是否存在
echo -e "\n[1/7] 检查 hccn.conf 配置文件:"
if [ -f "/etc/hccn.conf" ]; then
    echo -e "${GREEN}SUCCESS: /etc/hccn.conf 已存在${NC}"
else
    echo -e "${RED}ERROR: 未找到 /etc/hccn.conf，请检查挂载或配置！${NC}"
fi

# 2. 链路状态检查 (Link Status)
echo -e "\n[2/7] 检查网口链路状态 (Expect: UP):"
for i in {0..7}; do
    res=$(hccn_tool -i $i -link -g)
    if [[ $res == *"UP"* ]]; then
        echo -e "Device $i: ${GREEN}$res${NC}"
    else
        echo -e "Device $i: ${RED}$res${NC}"
    fi
done

# 3. 网络健康检查 (Net Health)
echo -e "\n[3/7] 检查网络健康状态 (Expect: success):"
for i in {0..7}; do
    res=$(hccn_tool -i $i -net_health -g)
    if [[ $res == *"success"* ]]; then
        echo -e "Device $i: ${GREEN}$res${NC}"
    else
        echo -e "Device $i: ${RED}$res${NC}"
    fi
done

# 4. 获取 NPU IP 地址
echo -e "\n[4/7] 当前各卡 IP 地址配置:"
for i in {0..7}; do
    ip=$(hccn_tool -i $i -ip -g)
    echo "Device $i: $ip"
done

# 5. 检查网关与检测 IP
echo -e "\n[5/7] 检查网关与网络检测配置:"
for i in {0..7}; do
    gw=$(hccn_tool -i $i -gateway -g)
    det=$(hccn_tool -i $i -netdetect -g)
    echo "Device $i: Gateway -> $gw | Detect -> $det"
done

# 6. TLS 配置一致性检查
echo -e "\n[6/7] 检查 TLS 开关状态:"
for i in {0..7}; do
    tls=$(hccn_tool -i $i -tls -g)
    echo "Device $i: $tls"
done

# 7. 交互式 PING 测试 (可选)
echo -e "\n[7/7] 跨节点 PING 测试:"
read -p "是否执行跨节点 PING 测试? (y/n): " do_ping
if [[ "$do_ping" == "y" ]]; then
    read -p "请输入对端 NPU 的目标 IP 地址: " target_ip
    for i in {0..7}; do
        echo -n "Device $i PING $target_ip: "
        hccn_tool -i $i -ping -g address $target_ip
    done
fi

echo -e "\n${YELLOW}================ 检查完成 ================${NC}"