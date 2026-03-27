---
name: modelscope-cli
description: ModelScope 阿里达摩院模型社区下载工具。当用户需要从达摩院平台获取模型或数据集、批量下载 Ascend NPU 优化模型时使用。
---

# 概述

ModelScope 是阿里达摩院开源的模型社区，提供大量预训练模型和开源数据集。本技能提供通过 ModelScope CLI 批量下载模型和数据集的工具。

**推荐：对于 Ascend NPU 部署，建议优先从 [Eco-Tech 组织](https://modelscope.cn/organization/Eco-Tech) 下载经过量化和优化的模型**，这些模型已针对 Ascend 平台进行了适配。

**主要功能：**
- 批量下载 ModelScope 模型和数据集
- 文件过滤（排除不需要的文件类型）
- SHA256 校验确保文件完整性
- 下载前后确认机制防误操作
- 统计模型参数量和分析精度类型
- 循环重试机制处理网络不稳定

# 前置条件

- Python 3.7+ 环境
- 已安装 ModelScope：`pip install modelscope -i https://pypi.tuna.tsinghua.edu.cn/simple`
- 足够的磁盘空间（建议预留 100GB+）
- 网络连接（如需配置代理，请使用 `huawei_proxy_skill`）

# 快速开始

## 批量下载模型

1. 编辑 `scripts/run_ms_model_download.sh` 中的 `MODELS` 数组
2. 执行脚本：

```bash
bash scripts/ascend-deploy/modelscope_cli_skill/scripts/run_ms_model_download.sh
```

**推荐组织：** 访问以下链接获取最新的 Ascend 优化模型
- [Eco-Tech](https://modelscope.cn/organization/Eco-Tech) - W8A8Z、W4A8 等量化模型
- [vllm-ascend](https://modelscope.cn/organization/vllm-ascend) - vLLM-Ascend 适配模型
- [ZhipuAI](https://modelscope.cn/models/ZhipuAI) - 智谱 GLM 系列
- [Qwen](https://modelscope.cn/collections/Qwen) - 通义千问系列
- [MoonshotAI](https://modelscope.cn/organization/moonshotai) - 长上下文模型

**示例配置：**
```bash
MODELS=(
  Eco-Tech/Qwen3.5-397B-A17B-w8a8-mtp
)
```

## 批量下载数据集

```bash
bash scripts/ascend-deploy/modelscope_cli_skill/scripts/run_ms_datasets_download.sh
```

## 循环重试（网络不稳定时使用）

```bash
bash scripts/ascend-deploy/modelscope_cli_skill/scripts/ms_loop.sh scripts/run_ms_model_download.sh 2>&1 | tee model_download.log
```

> **提示：** 使用 `tee` 将输出重定向到日志文件，方便排查问题。

## 统计模型参数量

```bash
bash scripts/ascend-deploy/modelscope_cli_skill/scripts/run_report_param.sh /path/to/models
```

**报告内容：** 权重文件数量、总大小、数据精度类型、推测参数量

# CLI 使用方法

## 模型下载

```bash
# 下载到默认目录
modelscope download --model 'Eco-Tech/Qwen3.5-397B-A17B-w8a8-mtp'

# 下载到指定目录
modelscope download --model 'Eco-Tech/Qwen3.5-397B-A17B-w8a8-mtp' --local_dir ./models

# 排除特定文件
modelscope download --model 'Eco-Tech/Qwen3.5-397B-A17B-w8a8-mtp' --exclude '*.onnx,*.onnx_data'

# 下载特定版本
modelscope download --model 'Eco-Tech/Qwen3.5-397B-A17B-w8a8-mtp' --revision v1.0.0
```

## 数据集下载

```bash
modelscope download --dataset PAI/OmniThought --local_dir ./datasets
```

# 脚本说明

## run_ms_model_download.sh - 批量模型下载

**功能：** 批量下载多个模型，支持文件过滤、自动创建目录、下载前后确认

**配置变量：**
- `MODELS`: 模型 ID 数组
- `EXCLUDE`: 排除的文件模式（默认 `*.onnx *.onnx_data`）
- `DIR`: 下载根目录（默认当前目录）

**用法：**
```bash
# 直接执行（交互式）
bash scripts/run_ms_model_download.sh

# 结合循环重试和日志记录
bash scripts/ms_loop.sh scripts/run_ms_model_download.sh 2>&1 | tee model_download.log
```

## run_ms_datasets_download.sh - 批量数据集下载

**功能：** 批量下载数据集，支持文件过滤和下载确认

**配置变量：**
- `DATASETS`: 数据集 ID 数组

## run_check_sha.sh - SHA256 校验

**功能：** 校验已下载文件的 SHA256 完整性

**用法：**
```bash
bash scripts/run_check_sha.sh /path/to/model
```

## run_report_param.sh - 模型参数量统计

**功能：** 根据文件大小和精度标识统计模型参数量

**精度识别：**
| 精度类型 | 每参数字节数 | 文件名标识 |
|-----------|---------------|------------|
| FP32 | 4.0 | `*FP32*` |
| BF16/FP16 | 2.0 | `*BF16*`, `*FP16*` |
| W8A8Z/W8A8 | 1.0 | `*W8A8Z*`, `*W8A8*` |
| W4A8/Q4 | 0.5 | `*W4A8*`, `*Q4*` |

## ms_loop.sh - 循环重试脚本

**功能：** 失败时等待 5 秒后自动重试，直到成功

**用法：**
```bash
bash scripts/ms_loop.sh <script_path>
```

# 常见问题

## 1. SSL 证书验证失败

**原因：** 内网环境或自签名证书

**解决方法：**
```bash
# 方法 1：使用 huawei_proxy_skill 安装证书
bash skills/ascend-env/huawei_proxy_skill/scripts/run_set_ssl_cert.sh

# 方法 2：Python 全局禁用 SSL 验证
#（执行下载前运行以下代码）
python -c "
import ssl, os, urllib3, requests
ssl._create_default_https_context = ssl._create_unverified_context
os.environ['CURL_CA_BUNDLE'] = os.environ['REQUESTS_CA_BUNDLE'] = ''
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
requests.Session.__init__ = lambda *args, **kwargs: setattr(requests.Session(), 'verify', False) or super(requests.Session, type(args[0])).__init__(*args, **kwargs)"
```

## 2. 下载速度慢或中断

**解决方法：**
- 使用循环重试脚本：`bash scripts/ms_loop.sh scripts/run_ms_model_download.sh 2>&1 | tee model_download.log`
- 查看日志排查：`grep -i "error\|fail\|timeout" model_download.log`

## 3. 磁盘空间不足

**解决方法：**
```bash
# 检查磁盘空间
df -h

# 清理缓存
rm -rf ~/.cache/modelscope/hub/

# 修改脚本中的 DIR 变量指定到其他磁盘
```

## 4. 模型 ID 找不到

**解决方法：**
- 确认模型 ID 格式：`组织/模型名`
- 访问 https://modelscope.cn/models 搜索模型
- 检查模型名称大小写是否正确

## 5. 部分文件下载失败

**解决方法：**
- 重新运行脚本，ModelScope 会自动跳过已下载的文件
- 删除失败文件后重新下载

## 6. 权限错误

**解决方法：**
```bash
# 修改目录所有者为当前用户
sudo chown -R $USER:$USER /path/to/dir
```

# 参考文档

- [ModelScope 官方文档](https://modelscope.cn/docs)
- [ModelScope 模型下载指南](https://modelscope.cn/docs/models/download)
- [WIKI.md](./reference/WIKI.md) - CLI 和 Python SDK 详细使用说明
- [README.md](./reference/README.md) - 相关工具文档