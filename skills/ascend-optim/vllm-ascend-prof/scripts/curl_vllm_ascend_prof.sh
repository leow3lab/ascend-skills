
#!/bin/bash

# 1. 定义目标测试组 (格式为 "IP:PORT|MODEL_NAME")
TARGETS=(
    "<YOUR_SERVER_IP>:8446|llama3-8b"
    "<YOUR_SERVER_IP>:8446|qwen-7b"
    "<YOUR_SERVER_IP>:8000|mistral-v0.1"
)

# 2. 定义测试 Prompt 列表
PROMPTS=(
    "Who are you"
    "What is the capital of France"
)


unset ftp_proxy && unset https_proxy && unset http_proxy



for TARGET in "${TARGETS[@]}"; do
    IFS="|" read -r ADDR MODEL <<< "$TARGET"
    
    echo ">>>> Starting Batch for Server: $ADDR (Model: $MODEL) <<<<"

    for i in "${!PROMPTS[@]}"; do
        PROMPT="${PROMPTS[$i]}"
     
        SAFE_ADDR=$(echo $ADDR | tr ':' '_')
        LOG_FILE="prof_results/${SAFE_ADDR}_${MODEL}_task${i}.json"

        echo "--- Processing: $PROMPT ---"


        set -x
        curl -X POST "http://${ADDR}/start_profile"

   
        curl -s "http://${ADDR}/v1/completions" \
          -H "Content-Type: application/json" \
          -d "{
            \"model\": \"${MODEL}\",
            \"prompt\": \"${PROMPT}\",
            \"max_tokens\": 10,
            \"temperature\": 0
        }" 

      
        curl -X POST "http://${ADDR}/stop_profile"
        set +x
        echo "Done. Saved to $LOG_FILE"
    done
done

echo "All batches completed."