#!/bin/bash

# ModelScope 批量模型下载脚本
# 支持批量下载多个模型，并可选过滤文件类型
#
# 推荐：对于 Ascend NPU 部署，建议优先从 Eco-Tech 组织下载
# 经过量化和优化的模型，这些模型已针对 Ascend 平台进行了适配。

set -e

# 配置：需要下载的模型列表
# 推荐：优先使用 Eco-Tech 组织的量化模型（针对 Ascend NPU 优化）
# 提示：请访问 https://modelscope.cn/models 搜索并复制最新模型 ID
MODELS=(
  # 从 ModelScope 官网复制最新模型 ID
  # 推荐：Eco-Tech 量化模型（已针对 Ascend NPU 优化）
  # 访问以下链接查看最新模型：
  #   - Eco-Tech:       https://modelscope.cn/organization/Eco-Tech
  #   - ZhipuAI:        https://modelscope.cn/models/ZhipuAI
  #   - Qwen 系列:       https://modelscope.cn/collections/Qwen
  #   - MoonshotAI:      https://modelscope.cn/organization/moonshotai

  # 示例：使用 Eco-Tech 优化的 397B 模型
  Eco-Tech/Qwen3.5-397B-A17B-w8a8-mtp

  # 更多实例模型请参考 SKILL.md 推荐模型列表
  # 示例：ZhipuAI GLM 系列
  # ZhipuAI/GLM-4-9B-Chat
  # 示例：Qwen 系列
  # Eco-Tech/Qwen-72B-A10B-w8a8
  # 示例：MoonshotAI 系列（长上下文）
  # moonshotai/Moonshot-v1-128k
)

# 配置：文件过滤选项
ALLOW_PATTERNS=""  # 需要包含的文件模式（glob 格式，留空表示包含所有）
EXCLUDE="*.onnx *.onnx_data"  # 需要排除的文件模式

# 配置：下载目标目录
DIR=${PWD}

# ==================== 下载前确认 ====================

echo "========================================"
echo "ModelScope 模型批量下载 - 下载前确认"
echo "========================================"
echo ""
echo "⚠️  请确认以下下载配置信息："
echo ""
echo "【下载目标目录】"
echo "  ${DIR}"
echo ""
echo "【文件过滤配置】"
echo "  排除: ${EXCLUDE}"
echo ""
echo "【待下载模型列表】"
for i in "${!MODELS[@]}"; do
    echo "  [$((i+1))] ${MODELS[$i]}"
done
echo ""
echo "========================================"
echo ""

# 请求用户确认
read -p "确认以上配置，开始下载？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ 用户取消下载"
    exit 1
fi

echo ""
echo "✅ 用户确认，开始下载..."
echo ""

# ==================== 开始下载 ====================

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_MODELS=()

# 遍历模型列表进行下载
for MODEL_ID in "${MODELS[@]}"; do
    LOCAL_DIR=${DIR}/${MODEL_ID}

    # 创建目标目录（如果不存在）
    if [ ! -d "${LOCAL_DIR}" ]; then
        mkdir -p ${LOCAL_DIR}
    fi

    # 构建下载命令
    cmd="modelscope download --model ${MODEL_ID} --local_dir ${LOCAL_DIR} --exclude '${EXCLUDE}'"

    # 显示执行的命令
    echo -e "\n========================================"
    echo "正在下载: ${MODEL_ID}"
    echo "目标目录: ${LOCAL_DIR}"
    echo "========================================"
    echo -e "\t>${cmd}"
    echo ""

    # 执行下载命令
    set +e
    eval ${cmd}
    EXIT_CODE=$?
    set -e

    # 检查下载结果
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ ${MODEL_ID} 下载完成"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ ${MODEL_ID} 下载失败，退出码: $EXIT_CODE"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_MODELS+=("${MODEL_ID}")
    fi
done

# ==================== 下载后确认 ====================

echo ""
echo "========================================"
echo "ModelScope 模型批量下载 - 下载完成"
echo "========================================"
echo ""
echo "【下载结果摘要】"
echo "  总计模型数量: ${#MODELS[@]}"
echo "  下载成功: ${SUCCESS_COUNT}"
echo "  下载失败: ${FAILED_COUNT}"
echo ""

if [ ${FAILED_COUNT} -gt 0 ]; then
    echo "【失败模型列表】"
    for failed_model in "${FAILED_MODELS[@]}"; do
        echo "  ❌ ${failed_model}"
    done
    echo ""
fi

# 显示磁盘使用情况
echo "【磁盘使用情况】"
du -sh ${DIR}/* 2>/dev/null | tail -5 || echo "  (无法获取磁盘使用信息)"
echo ""

echo "========================================"
echo ""

# 请求用户确认
read -p "请确认下载结果，退出脚本？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "⚠️  用户未确认，请手动检查下载结果"
    exit 1
fi

echo "✅ 下载完成，脚本退出"