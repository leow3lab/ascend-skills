# 镜像源和代理配置工具

## 概述

本技能提供国内常用的镜像源配置工具，帮助加速软件包下载和更新。

## 镜像源列表

### pip 镜像源

| 名称 | 地址 | 说明 |
|------|------|------|
| 阿里云 | `https://mirrors.aliyun.com/pypi/simple/` | 推荐，速度快 |
| 清华大学 | `https://pypi.tuna.tsinghua.edu.cn/simple/` | 教育网首选 |
| 中科大 | `https://pypi.mirrors.ustc.edu.cn/simple/` | 速度稳定 |
| 豆瓣 | `https://pypi.doubanio.com/simple/` | 备选 |

### npm 镜像源

| 名称 | 地址 | 说明 |
|------|------|------|
| 淘宝 | `https://registry.npmmirror.com` | 推荐，同步快 |
| 华为云 | `https://mirrors.huaweicloud.com/repository/npm/` | 备选 |

### APT 镜像源

| 名称 | 地址 | 说明 |
|------|------|------|
| 阿里云 | `https://mirrors.aliyun.com/ubuntu/` | 推荐 |
| 清华大学 | `https://mirrors.tuna.tsinghua.edu.cn/ubuntu/` | 教育网首选 |
| 中科大 | `https://mirrors.ustc.edu.cn/ubuntu/` | 速度稳定 |

## 脚本列表

| 脚本 | 功能 | 使用权限 |
|------|------|---------|
| `run_set_pip_mirror.sh` | pip 镜像源配置 | 用户/root |
| `run_set_npm_mirror.sh` | npm 镜像源配置 | 用户 |
| `run_set_apt_mirror.sh` | APT 镜像源配置 | root |
| `run_set_proxy.sh` | 系统代理环境变量配置 | root |
| `run_set_docker_mirror.sh` | Docker 守护进程代理配置 | root |

## 使用示例

```bash
# 配置 pip 使用阿里云镜像（默认）
bash scripts/run_set_pip_mirror.sh

# 配置 pip 使用清华大学镜像
bash scripts/run_set_pip_mirror.sh -s tsinghua

# 配置 npm 使用淘宝镜像（默认）
bash scripts/run_set_npm_mirror.sh

# 配置 apt 使用阿里云镜像（需要 sudo）
sudo bash scripts/run_set_apt_mirror.sh

# 配置系统代理
sudo bash scripts/run_set_proxy.sh -h 192.168.1.100 -p 7890

# 配置 Docker 代理
sudo bash scripts/run_set_docker_mirror.sh -h 192.168.1.100 -p 7890
```

## 常见问题

### pip 安装失败

1. 检查镜像源配置：`pip config list`
2. 切换镜像源：`bash scripts/run_set_pip_mirror.sh -s tsinghua`
3. 检查网络连接和代理配置

### npm 连接超时

1. 检查镜像源配置：`npm config list`
2. 切换镜像源：`bash scripts/run_set_npm_mirror.sh -s taobao`
3. 测试连接：`npm ping`

### Docker 拉取镜像失败

1. 检查 Docker 代理配置：`cat /etc/systemd/system/docker.service.d/http-proxy.conf`
2. 重启 Docker：`systemctl restart docker`
3. 测试拉取：`docker pull hello-world`

## 相关文档

- [URL.md](./URL.md) - 外部参考链接
- [SKILL.md](../SKILL.md) - 技能使用说明