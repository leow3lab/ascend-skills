# 模型权重与镜像资源指南

## 核心原则

1. **版本对齐** - CANN 版本与推理框架版本必须匹配（如 Sglang v0.5.x → CANN 8.0.x）
2. **灵活变通** - 若环境驱动版本不可变，优先调整镜像 Tag 而非死磕文档推荐
3. **动态查找** - 使用浏览器查找最新的版本兼容性和镜像推荐

## 模型权重来源

### ModelScope（国内首选）

- **地址**：https://modelscope.cn/models
- **特点**：国内直连，Qwen、GLM 等国产模型一手分发

**Ascend 适配组织**：
- [Eco-Tech](https://modelscope.cn/organization/Eco-Tech) - 量化优化模型（W8A8、W4A8）
- [vllm-ascend](https://modelscope.cn/organization/vllm-ascend) - NPU 适配模型

**下载模型**：调用 `modelscope-cli` 技能

### Modelers（昇腾原生）

- **地址**：https://modelers.cn/
- **特点**：昇腾环境原生首选，大量 Atlas A2/A3 调优权重（W8A8/W4A8 量化）

### Hugging Face Mirror

- **地址**：https://hf-mirror.com/
- **特点**：国际主流模型镜像

---

## Docker 镜像来源

### 官方镜像

| 仓库 | 地址 | 用途 |
|------|------|------|
| Quay.io | quay.io/repository/ascend/vllm-ascend | vLLM 开源镜像 |
| AscendHub | hiascend.com/developer/ascendhub | 华为官方镜像 |
| DockerHub | docker.io/lmsysorg/sglang | Sglang 镜像 |

---

## 镜像选择指南

### 首选参考：官方资源

**遇到不确定的模型配置时，优先查阅官方文档**：

| 资源 | 地址 |
|------|------|
| **模型教程** | https://docs.vllm.ai/projects/ascend/zh-cn/main/tutorials/models/index.html |
| **GitHub 仓库** | https://github.com/vllm-project/vllm-ascend |
| **Issues 搜索** | https://github.com/vllm-project/vllm-ascend/issues |

### 版本兼容性查询

**使用浏览器搜索**：
- `vllm-ascend CANN <版本> <硬件型号>`
- `Sglang NPU CANN compatibility`

### 硬件 Tag 映射

| 硬件 | Tag 后缀 |
|------|----------|
| Atlas 800I A3 | `-a3` |
| Atlas 800I A2 | 无后缀 |

### 选择流程

1. 检查驱动版本：`npu-smi info`
2. 使用浏览器查找兼容的镜像版本
3. 选择对应硬件和 CANN 版本的镜像 Tag

---

## 网络问题处理

遇到镜像拉取慢、模型下载超时等问题时：

**调用 `mirror-proxy` 技能**：
```bash
# 配置镜像源
bash skills/ascend-env/mirror-proxy/scripts/run_set_pip_mirror.sh
bash skills/ascend-env/mirror-proxy/scripts/run_set_npm_mirror.sh

# 配置代理（如有）
bash skills/ascend-env/mirror-proxy/scripts/run_set_proxy.sh -h <proxy_host> -p <proxy_port>
```

---

## 相关技能

| 场景 | 技能 |
|------|------|
| 模型下载 | `modelscope-cli` |
| 网络代理 | `mirror-proxy` |