## name: vllm-ascend-deploy
description: vLLM 大模型在 Ascend NPU 服务器上部署工具。当用户需要在昇腾 NPU 服务器上部署 vLLM 推理服务时使用。

# vllm-ascend-deploy

昇腾 NPU 平台 vLLM-Ascend 大模型部署工具。

## 核心原则

---

1. **不假设、不猜测** - 关键参数必须从用户处获取并确认
2. **版本对齐** - CANN 与推理框架版本必须匹配
3. **动态查找** - 使用浏览器查找最新版本兼容性信息
4. **复用技能** - 网络、模型下载等场景复用已有技能

## 快速开始

### Step 1: 确认参数（必须）


| 参数     | 获取方式        |
| ------ | ----------- |
| 模型路径   | **必须询问用户**  |
| 容器镜像   | 根据硬件类型推荐    |
| TP 并行数 | 自动检测 NPU 卡数 |


### Step 2: 部署

**方式一：Shell 脚本**

```bash
# 创建容器
bash scripts/create_container.sh --image <IMAGE> --model-path <MODEL_PATH>

# 启动服务
bash scripts/start_service.sh --container <NAME> --model-path <PATH> --tp-size <N>
```

**方式二：Docker Compose（推荐）**

```bash
bash scripts/docker-compose-start.sh --image <IMAGE> --model-path <MODEL_PATH>
```

### Step 3: 验证

```bash
curl http://localhost:8000/health
```

---

## 硬件类型


| 类型  | NPU | 镜像 tag |
| --- | --- | ------ |
| A2  | 8   | 无后缀    |
| A3  | 16  | `-a3`  |


---

## 可选参数


| 参数                            | 说明      |
| ----------------------------- | ------- |
| `--hardware <a2|a3>`          | 硬件类型    |
| `--tool-call-parser <PARSER>` | 工具调用解析器 |
| `--reasoning-parser <PARSER>` | 推理解析器   |


**查阅模型参数**：[https://docs.vllm.ai/projects/ascend/zh-cn/main/tutorials/models/index.html](https://docs.vllm.ai/projects/ascend/zh-cn/main/tutorials/models/index.html)

---

## 部署后测试


| 技能                   | 用途      |
| -------------------- | ------- |
| `aisbench-perf-acc`  | 性能与精度测试 |
| `evalscope-perf-acc` | 性能与精度测试 |


---

## 官方资源

- 模型教程：[https://docs.vllm.ai/projects/ascend/zh-cn/main/tutorials/models/index.html](https://docs.vllm.ai/projects/ascend/zh-cn/main/tutorials/models/index.html)
- GitHub：[https://github.com/vllm-project/vllm-ascend](https://github.com/vllm-project/vllm-ascend)
- Issues：[https://github.com/vllm-project/vllm-ascend/issues](https://github.com/vllm-project/vllm-ascend/issues)
- 镜像：[https://quay.io/repository/ascend/vllm-ascend?tab=tags](https://quay.io/repository/ascend/vllm-ascend?tab=tags)

---

## 依赖技能 (遇到模型权重下载和镜像拉取的时候)


| 场景   | 技能                |
| ---- | ----------------- |
| 镜像源/代理 | `mirror-proxy`    |
| 模型下载 | `modelscope-cli`  |
| 外部镜像 | `docker-env`      |


---

## 脚本说明


| 脚本                        | 功能   |
| ------------------------- | ---- |
| `create_container.sh`     | 创建容器 |
| `start_service.sh`        | 启动服务 |
| `docker-compose-start.sh` | 一键部署 |


