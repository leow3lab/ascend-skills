# Ascend 模型推荐

## 推荐组织

### Eco-Tech 组织
- **链接**：[https://modelscope.cn/organization/Eco-Tech](https://modelscope.cn/organization/Eco-Tech)
- **特点**：提供专门针对 Ascend 平台优化的量化模型
- **量化类型**：W8A8Z、W4A8 等
- **适用场景**：Ascend NPU 推理，已优化可直接使用

### vllm-ascend 组织
- **链接**：[https://modelscope.cn/organization/vllm-ascend](https://modelscope.cn/organization/vllm-ascend)
- **特点**：vLLM-Ascend 官方提供的基准模型
- **量化类型**：BF16/FP16
- **适用场景**：vLLM-Ascend 推理基础测试

### ZhipuAI 组织
- **链接**：[https://modelscope.cn/models/ZhipuAI](https://modelscope.cn/models/ZhipuAI)
- **特点**：智谱 AI 官方开源模型，包括 GLM-4 系列
- **量化类型**：W8A8、BF16
- **适用场景**：中文对话、代码生成、多模态任务

### Qwen 系列（通义千问）
- **链接**：[https://modelscope.cn/collections/Qwen](https://modelscope.cn/collections/Qwen)
- **特点**：阿里巴巴通义千问系列大语言模型，包含 Qwen、Qwen2、Qwen3 等版本
- **量化类型**：W8A8Z、W4A8、BF16/FP16
- **适用场景**：通用对话、代码生成、数学推理、多语言任务

### MoonshotAI 组织
- **链接**：[https://modelscope.cn/organization/moonshotai](https://modelscope.cn/organization/moonshotai)
- **特点**：月之暗面科技开源模型，专注于长上下文任务
- **量化类型**：BF16/FP16
- **适用场景**：长文本处理、对话系统、文档分析

## 推荐模型查找指南

### 按组织查找

| 组织 | 链接 | 特点 | 推荐量化类型 |
|------|------|------|--------------|
| Eco-Tech | [链接](https://modelscope.cn/organization/Eco-Tech) | Ascend 优化量化模型，适合 A10B/A3B 等 NPU | W8A8Z、W4A8 |
| vllm-ascend | [链接](https://modelscope.cn/organization/vllm-ascend) | vLLM-Ascend 官方基准模型 | BF16/FP16 |
| ZhipuAI | [链接](https://modelscope.cn/models/ZhipuAI) | 智谱 GLM 系列，中文对话能力强 | W8A8、BF16 |
| Qwen | [链接](https://modelscope.cn/collections/Qwen) | 阿里巴巴通义千问，多语言代码生成 | W8A8Z、W4A8、BF16 |
| MoonshotAI | [链接](https://modelscope.cn/organization/moonshotai) | 长上下文处理，支持 128K 上下文 | BF16/FP16 |

**提示**：模型版本更新较快，请访问上述链接查看最新模型。

### 按参数量分类推荐

| 参数量范围 | 适用场景 | 推荐组织 |
|----------|----------|----------|
| 1-7B | 快速测试、边缘设备 | Eco-Tech, ZhipuAI |
| 7-13B | 标准对话应用 | Eco-Tech, Qwen, ZhipuAI |
| 13-34B | 企业级对话、代码生成 | Eco-Tech, Qwen, vllm-ascend |
| 34-70B+ | 大规模推理、复杂任务 | Eco-Tech, Qwen |

### 按量化类型选择

| 量化类型 | 内存占用建议 | 精度损失 | 推荐场景 |
|---------|--------------|----------|----------|
| BF16/FP16 | 32GB+ 几乎无 | 生产环境、企业部署 |
| W8A8Z | 16GB+ | 小 | A10B/A3B 大模型部署（推荐）|
| W4A8 | 8-16GB | 中等 | A3B 等较小显存型号 |
| W4A8 / Q4 | 8GB 以下 | 较大 | 边缘部署、测试环境 |

## 量化说明

### W8A8Z 量化
- **权重精度**：8位整数
- **激活精度**：8位整数
- **内存占用**：约为 BF16 的 1/2
- **性能影响**：精度损失较小，性能提升明显
- **推荐场景**：1024B288A/A10B/A3B 等大模型部署

### W4A8 量化
- **权重精度**：4位整数
- **激活精度**：8位整数
- **内存占用**：约为 BF16 的 1/4
- **性能影响**：需要配合校准，精度损失可接受
- **推荐场景**：A3B 等较小显存型号，或边缘部署

### 模型量化工具
- [msmodelslim](https://gitcode.com/Ascend/msmodelslim) - 华为官方量化工具，支持多种量化方案
- [Ascend 开源组织](https://gitcode.com/Ascend) - 华为昇腾开源项目总入口
- 更多信息请参考 `reference/README.md` 中的 Ascend 量化模型章节