#!/bin/bash
# #######################################################
#   ⎿  ▐▛███▜▌   
#      ▝▜█████▛▘  Updated：2026.1.22 
#        ▘▘ ▝▝    Author: Yang Jing (aka. WhyJ？)
# #######################################################

# pip install 'evalscope[app]' -U
#pip install 'evalscope[perf]' -U
# pip install 'swanlab[dashboard]'


# 没有安装 torch_npu 和 cann的环境需要下面的命令
export TORCH_DEVICE_BACKEND_AUTOLOAD=0

# ==============================================================================
# 配置区域：格式为 "API_URL | 模型名称 | 
# 配置来源：合并自 run_eval_acc.sh 和 run_eval_perf_mtp.sh
# ==============================================================================
CONFIG=(
    "http://<YOUR_SERVER_IP>:8088/v1|Qwen/Qwen3-Coder-30B-A3B-Instruct"
    # "http://<YOUR_SERVER_IP>:8088/v1|Qwen/Qwen3-Coder-Next"
)

TOKENIZER_BASE_PATH=/nfs/shared/models/huggingface


# 第一次加载数据集，会从modelscope进行自动下载
# ==================================
unset https_proxy &&  unset http_proxy && unset no_proxy
env | grep proxy 
timestamp=$(date +%Y-%m-%d_%H%M%S)


# ==================================
# PERF 测试真实数据的性能表现
# ==================================
mkdir -p  ./custom_perf_outputs

# 循环执行每组配置
for config in "${CONFIG[@]}"; do
    # 解析配置：API_URL|MODEL|PROMPT_LENGTH|MAX_TOKENS
    IFS='|' read -r VLLM_API VLLM_MODEL_NAME  <<< "$config"
    TOKENIZER_MODEL_NAME=${VLLM_MODEL_NAME}
    TOKENIZER_PATH="${TOKENIZER_BASE_PATH}/${TOKENIZER_MODEL_NAME}"
    
    echo "=================================="
    echo "执行配置:"
    echo "API: ${VLLM_API}"
    echo "模型: ${VLLM_MODEL_NAME}"
    echo "Tokenizer: ${TOKENIZER_MODEL_NAME}"
    echo "=================================="
    
    # 为每个配置生成唯一的时间戳和日志文件名
    model_safe_name=$(echo "${VLLM_MODEL_NAME}" | sed 's/\//_/g' | sed 's/ /_/g')

    OUTPUT_PATH=./custom_perf_outputs/${model_safe_name}-${timestamp}
    mkdir -p ${OUTPUT_PATH}

    config_safe_name="${model_safe_name}_mtp"
    log_file="${OUTPUT_PATH}/perf.log"

    set +xeu
    evalscope perf \
        --swanlab-api-key local \
        --name ${config_safe_name} \
        --url ${VLLM_API}/chat/completions \
        --parallel 1 \
        --number 10  \
        --model ${VLLM_MODEL_NAME} \
        --tokenizer-path  ${TOKENIZER_PATH} \
        --api openai \
        --api-key sk-1234  \
        --dataset line_by_line \
        --dataset-path ./assert/aime2025.txt \
        --extra-args '{"ignore_eos": true}' \
        --outputs-dir ${OUTPUT_PATH} \
        --debug 2>&1 | tee ${log_file}
    set -xeu 
    echo "配置执行完成，日志保存在: ${log_file}"
    
done

echo "所有配置执行完成!"

