---
name: hccl-bench
description: HCCL 集群通信性能基准测试工具。当用户需要测试 NPU 集群通信带宽、测量延迟或验证集群网络性能时使用。
---

# 概述
HCCL (Huawei Collective Communication Library) 是 Ascend NPU 集群通信的核心库。本技能提供 HCCL 性能基准测试方法，用于验证集群通信带宽和延迟指标。

# 前置条件
- 已安装 CANN 工具包
- 拥有多卡 NPU 服务器或 NPU 集群
- 拥有 root 或 sudo 权限

# 使用方法

## 单节点多卡测试
加载 HCCL 测试环境并运行测试：
```bash
source /usr/local/Ascend/ascend-toolkit/latest/tools/hccl_test/set_env.sh
cd /usr/local/Ascend/ascend-toolkit/latest/tools/hccl_test
./execute_hccl_test.sh
```

## 多节点集群测试
准备 hostfile 文件，格式为每行一个服务器 IP：
```bash
cat > hostfile << EOF
10.1.1.10 slots=8
10.1.1.11 slots=8
10.1.1.12 slots=8
10.1.1.13 slots=8
EOF
```

使用 mpirun 运行多节点 HCCL 测试（需先安装 OpenMPI）：
```bash
mpirun -np 32 -hostfile hostfile \
    -bind-to none -map-by slot \
    -x HCCL_IF_TCP=1 \
    ./execute_hccl_test.sh
```

## 输出与分析
测试结果会输出每个通讯规模（8k ~ 16G）的：
- 带宽 (GB/s)
- 延迟 (μs)
- 效率指标

结果默认保存到/tmp/hccl_test_logs/目录。

# TODO 脚本
- run_hccl_single_node.sh - 单节点多卡 HCCL 测试脚本
- run_hccl_multi_node.sh - 多节点 HCCL 测试脚本
- analyze_hccl_results.sh - HCCL 测试结果分析脚本
- check_hccl_network.sh - HCCL 网络连通性检查脚本

更多详细资料请参考 CANN 工具包文档中关于 HCCL 测试的章节。
