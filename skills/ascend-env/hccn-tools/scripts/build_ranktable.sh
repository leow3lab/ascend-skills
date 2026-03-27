#!/bin/bash

# 脚本名称: generate_rank_table.sh
# 功能: 自动生成双机 16 卡的 rank_table_file.json 并设置权限

OUTPUT_FILE="rank_table_file.json"

echo "-----------------------------------------------------"
echo "正在准备生成 ${OUTPUT_FILE}..."
echo "-----------------------------------------------------"

# 引导用户输入 Server 1 的信息
read -p "请输入 Server 1 (主节点) 的 IP (server_id): " SERVER_1_IP
read -p "请输入 Server 1 的 Container IP (若无特殊需求，直接回车同上): " CONT_1_IP
CONT_1_IP=${CONT_1_IP:-$SERVER_1_IP}

# 引导用户输入 Server 2 的信息
read -p "请输入 Server 2 的 IP (server_id): " SERVER_2_IP
read -p "请输入 Server 2 的 Container IP (若无特殊需求，直接回车同上): " CONT_2_IP
CONT_2_IP=${CONT_2_IP:-$SERVER_2_IP}

# 引导输入 Device IP (通常同一台机器的 Device IP 处于同一网段)
read -p "请输入 Server 1 的起始 Device IP (如 192.168.1.1): " START_IP_1
read -p "请输入 Server 2 的起始 Device IP (如 192.168.2.1): " START_IP_2

# 函数：生成 device 列表的 JSON 片段
generate_devices() {
    local start_ip=$1
    local start_rank=$2
    local ip_prefix=${start_ip%.*}
    local ip_last=${start_ip##*.}

    for i in {0..7}; do
        local current_rank=$((start_rank + i))
        local current_ip="${ip_prefix}.$((ip_last + i))"
        
        cat <<EOF
            {
               "device_id": "$i",
               "device_ip": "$current_ip",
               "rank_id": "$current_rank"
            }$( [[ $i -eq 7 ]] || echo "," )
EOF
    done
}

# 组装完整 JSON
cat <<EOF > $OUTPUT_FILE
{
   "server_count": "2",
   "server_list": [
      {
         "device": [
$(generate_devices "$START_IP_1" 0)
         ],
         "server_id": "$SERVER_1_IP",
         "container_ip": "$CONT_1_IP"
      },
      {
         "device": [
$(generate_devices "$START_IP_2" 8)
         ],
         "server_id": "$SERVER_2_IP",
         "container_ip": "$CONT_2_IP"
      }
   ],
   "status": "completed",
   "version": "1.0"
}
EOF

# 修改权限
if [ -f "$OUTPUT_FILE" ]; then
    chmod 640 "$OUTPUT_FILE"
    echo "-----------------------------------------------------"
    echo "成功！文件已生成: $OUTPUT_FILE"
    echo "权限已修改为: $(ls -l $OUTPUT_FILE | awk '{print $1}')"
    echo "-----------------------------------------------------"
else
    echo "错误：文件生成失败。"
fi