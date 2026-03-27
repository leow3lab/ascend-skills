---
name: hccn-tools
description: HCCN (华为计算节点通信) 网络配置和诊断工具集。当用户需要配置 NPU 集群网络、诊断连接问题或生成 Rank Table 时使用。
---

# 概述
HCCN (Huawei Communications for Compute Node) 是 Ascend NPU 集群通信的网络协议栈。本技能提供 HCCN 配置、诊断和优化相关工具的使用方法。

# 前置条件
- 已安装 CANN 工具包
- 拥有 root 或 sudo 权限
- 硬件已正确连接 RDMA 网络

# 脚本工具

## 1. diagnose_hccn.sh - HCCN 网络诊断脚本

### 功能描述
一键诊断 HCCN 网络配置和状态，自动执行以下检查：
- hccn.conf 配置文件检查
- 网口链路状态检测（UP/DOWN）
- 网络健康状态检查
- NPU IP 地址配置查询
- 网关和网络检测配置验证
- TLS 配置一致性检查
- 可选的跨节点 PING 测试

### 使用方法
```bash
# 进入脚本目录
cd /path/to/hccn-tools/scripts/

# 执行诊断脚本
./diagnose_hccn.sh

# 执行过程中会提示是否执行跨节点 PING 测试
```

### 输出特点
- 彩色输出：绿色表示正常状态，红色表示异常状态
- 清晰的进度指示：[x/7] 显示当前检查项目
- 交互式测试：支持可选的跨节点连通性测试

---

## 2. build_rank_table.sh - Rank Table 生成脚本

### 功能描述
交互式生成分布式训练所需的 `rank_table_file.json` 配置文件，支持双机 16 卡配置。

### 使用方法
```bash
cd /path/to/hccn-tools/scripts/
./build_rank_table.sh
```

按提示输入：
- Server 1 的 IP 和 Container IP
- Server 2 的 IP 和 Container IP
- 两台机器的起始 Device IP

### 输出
- 自动生成 `rank_table_file.json` 文件
- 文件权限自动设置为 640

---

## 3. set_ssh_authority.sh - 多机环境自动化准备

### 功能描述
自动化配置多节点分布式训练环境：
- SSH 免密登录配置
- NPU IP 批量互通性检查

### 使用方法
```bash
cd /path/to/hccn-tools/scripts/
./set_ssh_authority.sh
```

### 功能特点
- 自动生成 SSH 公钥（如不存在）
- 使用 `ssh-copy-id` 配置免密登录
- 执行本地 8 张卡对对端 8 个 NPU IP 的 PING 测试

---

## 1. 基础命令工具

### hccn_tool - HCCN 配置管理工具

#### 查看当前配置
```bash
hccn_tool -i 0 -info -g
```

#### 配置静态 IP
```bash
hccn_tool -i 0 -ip 10.0.0.10 255.255.255.0
```

#### 测试网络连通性
```bash
hccn_tool -i 0 -ping 10.0.0.20
```

### hccn_status - 查看设备状态
```bash
hccn_status
```

### RDMA 性能测试
```bash
ib_write_bw -d roce -d <hccn_device> -i 1 -s 8192 -t 60
```

---

## 诊断命令参考

### 单节点验证流程
```bash
# 1. 检查远程交换机端口
for i in {0..7}; do hccn_tool -i $i -lldp -g | grep Ifname; done

# 2. 检查网口链路状态
for i in {0..7}; do hccn_tool -i $i -link -g; done

# 3. 检查网络健康状态
for i in {0..7}; do hccn_tool -i $i -net_health -g; done

# 4. 查看网络检测到的 IP 配置
for i in {0..7}; do hccn_tool -i $i -netdetect -g; done

# 5. 查看网关配置
for i in {0..7}; do hccn_tool -i $i -gateway -g; done
```

### 跨节点通信验证
```bash
# 获取 NPU IP 地址
for i in {0..7}; do hccn_tool -i $i -ip -g; done

# 跨节点 PING 测试（将 x.x.x.x 替换为目标 NPU IP）
for i in {0..7}; do hccn_tool -i $i -ping -g address x.x.x.x; done
```

### TLS 配置一致性检查
```bash
# TLS 设置应在所有节点保持一致
for i in {0..7}; do hccn_tool -i $i -tls -g | grep switch; done
```

---

# 参考资源

详细故障排查指南和案例参考请查阅：
- [reference/README.md](./reference/README.md) - 官方文档和命令速查
- [reference/WIKI.md](./reference/WIKI.md) - 故障排查案例与社区资源

---

# 计划中的功能

以下功能尚未实现，欢迎贡献：
- **cluster_hccn_config.sh** - 批量配置集群网络脚本，支持从配置文件读取批量设置
- **check_hccl_connectivity.sh** - HCCL 集群连通性测试工具（高级版）