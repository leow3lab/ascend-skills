#!/bin/bash
# #######################################################
#   ⎿  ▐▛███▜▌   
#      ▝▜█████▛▘  Updated：2026.1.22 
#        ▘▘ ▝▝    Author: Yang Jing (aka. WhyJ？)
# #######################################################


# pip install 'evalscope[app]' -U
# pip install 'evalscope[perf]' -U
# pip install 'swanlab[dashboard]'


# 没有安装 torch_npu 和 cann的环境需要下面的命令
export TORCH_DEVICE_BACKEND_AUTOLOAD=0

# ==============================================================================
# 配置区域：格式为 "API_URL | 模型名称"
# 配置来源：合并自 run_eval_acc.sh 和 run_eval_perf.sh
# ==============================================================================
CONFIG=(


    "http://<YOUR_SERVER_IP>:9000/v1|GLM-4.7-w8a8"


)

TOKENIZER_BASE_PATH=/nfs/shared/models/ZhipuAI/leo_GLM-4.7-W8A8


# 第一次加载数据集，会从modelscope进行自动下载
# ==================================
source /opt/tools/proxy.sh

# unset https_proxy &&  unset http_proxy && unset no_proxy
env | grep proxy 



timestamp=$(date +%Y-%m-%d_%H%M%S)



# eval 循环：对每组 API/模型执行一次

for config in "${CONFIG[@]}"; do
    # 解析配置：API_URL|MODEL
    IFS='|' read -r VLLM_API VLLM_MODEL_NAME <<< "$config"
    TOKENIZER_PATH="${TOKENIZER_BASE_PATH}/${VLLM_MODEL_NAME}"

    echo "=================================="
    echo "执行 EVAL 配置:"
    echo "API: ${VLLM_API}"
    echo "模型: ${VLLM_MODEL_NAME}"
    echo "=================================="

    model_safe_name=$(echo "${VLLM_MODEL_NAME}" | sed 's/\//_/g' | sed 's/ /_/g')

    OUTPUT_PATH=./acc_outputs/${model_safe_name}${timestamp}
    mkdir -p ${OUTPUT_PATH}
    log_file=${OUTPUT_PATH}/eval.log

    set -xeu
    evalscope eval \
        --eval-type openai_api \
        --model ${VLLM_MODEL_NAME} \
        --api-url ${VLLM_API} \
        --api-key  sk-1234  \
        --datasets   humaneval tool_bench aime25  live_code_bench\
        --work-dir ${OUTPUT_PATH} \
        --generation-config '{"do_sample":true,"temperature":1.0,"timeout":300000, "retries":3 }' \
        --ignore-errors \
        --eval-batch-size 16\
        --debug 2>&1 | tee ${log_file}

    # --generation-config '{"do_sample":true,"temperature":0.6 }' 

    set +xeu
done

# 注意一下，需要进行选择
# humaneval
# scicode  live_code_bench  tool_bench  general_fc
# evalscope app --outputs ./outputs  --server-name 0.0.0.0 --server-port 8887
