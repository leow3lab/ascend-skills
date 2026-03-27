#!/bin/bash
# AISBench 评测执行脚本
# 用法：./run_benchmark.sh --model <config> --dataset <dataset> --num-prompts <N> [其他参数]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$WORKSPACE_DIR/aisbench-results"

# 默认参数
MODEL_CONFIG="vllm_api_stream_chat"
DATASET=""
NUM_PROMPTS=""
EXTRA_ARGS=""
HOST_IP="localhost"
HOST_PORT="8080"
API_KEY=""
STREAM=true

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --model) MODEL_CONFIG="$2"; shift 2 ;;
        --dataset) DATASET="$2"; shift 2 ;;
        --num-prompts) NUM_PROMPTS="$2"; shift 2 ;;
        --host-ip) HOST_IP="$2"; shift 2 ;;
        --host-port) HOST_PORT="$2"; shift 2 ;;
        --api-key) API_KEY="$2"; shift 2 ;;
        --non-stream) STREAM=false; shift ;;
        --merge-ds) EXTRA_ARGS="$EXTRA_ARGS --merge-ds"; shift ;;
        --dump-eval-details) EXTRA_ARGS="$EXTRA_ARGS --dump-eval-details"; shift ;;
        --help) 
            echo "用法：$0 --model <config> --dataset <dataset> [选项]"
            echo ""
            echo "必需参数:"
            echo "  --model          模型配置名称（不含 .py，如 vllm_api_stream_chat）"
            echo "  --dataset        数据集配置名称（不含 .py，如 gsm8k_gen_4_shot_cot_chat_prompt）"
            echo ""
            echo "可选参数:"
            echo "  --num-prompts    测试数据量（默认：全部）"
            echo "  --host-ip        推理服务 IP（默认：localhost）"
            echo "  --host-port      推理服务端口（默认：8080）"
            echo "  --api-key        API 认证密钥（默认：无）"
            echo "  --non-stream     禁用流式输出"
            echo "  --merge-ds       合并多文件数据集（MMLU/C-Eval 等）"
            echo "  --dump-eval-details  导出每个样本的评估详情"
            exit 0
            ;;
        *) shift ;;
    esac
done

# 验证必需参数
if [ -z "$DATASET" ]; then
    echo "❌ 错误：--dataset 是必需参数"
    echo "用法：$0 --help"
    exit 1
fi

# 构建模型配置内容
STREAM_STR="True"
if [ "$STREAM" = false ]; then
    STREAM_STR="False"
fi

MODEL_CONFIG_CONTENT=$(cat <<EOF
from ais_bench.benchmark.models import VLLMCustomAPIChat
from ais_bench.benchmark.utils.postprocess.model_postprocessors import extract_non_reasoning_content

models = [
    dict(
        attr="service",
        type=VLLMCustomAPIChat,
        abbr="vllm-api-stream-chat",
        path="",
        model="",
        stream=$STREAM_STR,
        request_rate=0,
        use_timestamp=False,
        retry=2,
        api_key="$API_KEY",
        host_ip="$HOST_IP",
        host_port=$HOST_PORT,
        url="",
        max_out_len=512,
        batch_size=1,
        trust_remote_code=False,
        generation_kwargs=dict(
            temperature=0.01,
            ignore_eos=False,
        ),
        pred_postprocessor=dict(type=extract_non_reasoning_content),
    )
]
EOF
)

# 创建结果目录
mkdir -p "$RESULTS_DIR"

echo "🚀 开始 AISBench 评测"
echo "   模型配置：$MODEL_CONFIG"
echo "   数据集：$DATASET"
echo "   服务地址：http://$HOST_IP:$HOST_PORT"
[ -n "$NUM_PROMPTS" ] && echo "   数据量：$NUM_PROMPTS 条"
echo ""

# 构建并执行命令
AISBENCH_CMD="ais_bench --models $MODEL_CONFIG --datasets $DATASET"
[ -n "$NUM_PROMPTS" ] && AISBENCH_CMD="$AISBENCH_CMD --num-prompts $NUM_PROMPTS"
AISBENCH_CMD="$AISBENCH_CMD $EXTRA_ARGS"

echo "📦 执行命令:"
echo "   docker run --rm -w /workspace/benchmark \\"
echo "     -v $RESULTS_DIR:/workspace/benchmark/outputs \\"
echo "     aisbench:latest bash -c '"
echo "     cat > /workspace/benchmark/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py << \"EOF\""
echo "$MODEL_CONFIG_CONTENT"
echo "     EOF"
echo "     $AISBENCH_CMD"
echo "     '"
echo ""

# 执行
docker run --rm -w /workspace/benchmark \
    -v "$RESULTS_DIR:/workspace/benchmark/outputs" \
    aisbench:latest bash -c "
cat > /workspace/benchmark/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py << 'EOFCONFIG'
$MODEL_CONFIG_CONTENT
EOFCONFIG
$AISBENCH_CMD
"

echo ""
echo "✅ 评测完成！"
echo "   结果保存在：$RESULTS_DIR/"
