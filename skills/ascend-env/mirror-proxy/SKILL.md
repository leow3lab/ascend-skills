---
name: mirror-proxy
description: 国内镜像源配置工具（代理、pip、npm、apt 镜像源配置）。当用户需要配置国内镜像加速、设置代理环境变量或优化下载速度时使用。
---

# 概述

国内网络环境访问国外资源可能较慢，本技能提供常用工具的镜像源自动化配置，包括：

- pip 镜像源配置（阿里云、清华、中科大等）
- npm 镜像源配置（淘宝、华为云等）
- apt 镜像源配置（阿里云、清华、中科大等）
- 代理环境变量配置（支持自定义代理服务器）
- Docker 代理配置
- Git 代理配置

# 前置条件

- 需要 root 或 sudo 权限（用于系统级配置）
- 服务器已安装对应工具（Python/pip、Node.js/npm 等，根据需要）

# 快速开始

## 1. 配置 pip 镜像源

```bash
# 使用阿里云镜像源（推荐）
bash skills/ascend-env/mirror-proxy/scripts/run_set_pip_mirror.sh

# 使用清华大学镜像源
bash run_set_pip_mirror.sh -s tsinghua

# 使用中科大镜像源
bash run_set_pip_mirror.sh -s ustc

# 恢复为官方 PyPI 源
bash run_set_pip_mirror.sh --uninstall
```

**支持的镜像源：**
- 阿里云（默认）：`https://mirrors.aliyun.com/pypi/simple/`
- 清华大学：`https://pypi.tuna.tsinghua.edu.cn/simple/`
- 中科大：`https://pypi.mirrors.ustc.edu.cn/simple/`
- 豆瓣：`https://pypi.doubanio.com/simple/`

## 2. 配置 npm 镜像源

```bash
# 使用淘宝镜像源（推荐）
bash skills/ascend-env/mirror-proxy/scripts/run_set_npm_mirror.sh

# 使用华为云镜像源
bash run_set_npm_mirror.sh -s huawei

# 恢复为官方 npm 源
bash run_set_npm_mirror.sh --uninstall
```

**支持的镜像源：**
- 淘宝（默认）：`https://registry.npmmirror.com`
- 华为云：`https://mirrors.huaweicloud.com/repository/npm/`

## 3. 配置 apt 镜像源（Ubuntu/Debian）

```bash
# 使用阿里云镜像源（默认）
bash skills/ascend-env/mirror-proxy/scripts/run_set_apt_mirror.sh

# 使用清华大学镜像源
bash run_set_apt_mirror.sh -s tsinghua

# 使用中科大镜像源
bash run_set_apt_mirror.sh -s ustc
```

**支持的镜像源：**
- 阿里云（默认）：`https://mirrors.aliyun.com/ubuntu/`
- 清华大学：`https://mirrors.tuna.tsinghua.edu.cn/ubuntu/`
- 中科大：`https://mirrors.ustc.edu.cn/ubuntu/`

## 4. 配置代理环境变量

```bash
# 配置系统代理环境变量
bash skills/ascend-env/mirror-proxy/scripts/run_set_proxy.sh \
    -h <proxy_host> -p <proxy_port>

# 带认证的代理配置
bash run_set_proxy.sh \
    -h proxy.example.com \
    -p 7890 \
    -u <username> \
    -P <password>
```

**脚本功能：**
- 将代理配置写入 `/etc/profile.d/proxy.sh`（持久生效）
- 自动配置 Docker 代理（如果检测到 Docker）
- 自动配置 Git 代理

## 验证配置

### 验证 pip
```bash
pip config list
pip install --dry-run accelerate
```

### 验证 npm
```bash
npm config list
npm ping
```

### 验证 apt
```bash
apt update
apt cache policy
```

### 验证代理
```bash
env | grep -i proxy
curl -I https://www.google.com
```

# 脚本说明

## run_set_pip_mirror.sh - pip 镜像源配置

**用法：**
```bash
bash scripts/run_set_pip_mirror.sh [选项]

选项:
    -s, --source SOURCE    选择镜像源: aliyun (默认) | tsinghua | ustc | douban
    --uninstall           恢复为官方源
    --help                显示帮助信息
```

## run_set_npm_mirror.sh - npm 镜像源配置

**用法：**
```bash
bash scripts/run_set_npm_mirror.sh [选项]

选项:
    -s, --source SOURCE    选择镜像源: taobao (默认) | huawei
    --uninstall           恢复为官方源
    --help                显示帮助信息
```

## run_set_apt_mirror.sh - APT 镜像源配置

**用法：**
```bash
bash scripts/run_set_apt_mirror.sh [选项]

选项:
    -s, --source SOURCE    选择镜像源: aliyun (默认) | tsinghua | ustc
    --help                显示帮助信息
```

## run_set_proxy.sh - 代理环境变量配置

**用法：**
```bash
bash scripts/run_set_proxy.sh [选项]

选项:
    -h, --host HOST        代理服务器地址（必填）
    -p, --port PORT        代理服务器端口（必填）
    -u, --username USER    代理用户名（可选）
    -P, --password PASS    代理密码（可选）
    --skip-docker          跳过 Docker 代理配置
    --skip-git             跳过 Git 代理配置
    --help                 显示帮助信息
```

# 手动配置方法

## pip 配置

### 阿里云镜像
```bash
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
pip config set install.trusted-host mirrors.aliyun.com
```

### 清华大学镜像
```bash
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
pip config set install.trusted-host pypi.tuna.tsinghua.edu.cn
```

## npm 配置

### 淘宝镜像
```bash
npm config set registry https://registry.npmmirror.com
```

## Docker 代理

```bash
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://proxy_host:proxy_port/"
Environment="HTTPS_PROXY=http://proxy_host:proxy_port/"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
EOF

systemctl daemon-reload
systemctl restart docker
```

## Git 代理

```bash
git config --global http.proxy http://proxy_host:proxy_port/
git config --global https.proxy http://proxy_host:proxy_port/
```

# 镜像源地址汇总

| 工具 | 阿里云 | 清华大学 | 中科大 | 淘宝 |
|------|--------|----------|--------|------|
| pip | `mirrors.aliyun.com/pypi/simple/` | `pypi.tuna.tsinghua.edu.cn/simple/` | `pypi.mirrors.ustc.edu.cn/simple/` | - |
| npm | - | - | - | `registry.npmmirror.com` |
| apt | `mirrors.aliyun.com/ubuntu/` | `mirrors.tuna.tsinghua.edu.cn/ubuntu/` | `mirrors.ustc.edu.cn/ubuntu/` | - |

# 常见问题

## 1. pip 安装包失败

**解决方法：**
```bash
# 检查镜像源配置
pip config list

# 尝试切换镜像源
bash scripts/run_set_pip_mirror.sh -s tsinghua
```

## 2. npm 连接超时

**解决方法：**
```bash
# 检查网络和代理
npm config list

# 切换镜像源
bash scripts/run_set_npm_mirror.sh -s taobao
```

## 3. Docker 拉取镜像失败

**解决方法：**
```bash
# 检查 Docker 代理配置
cat /etc/systemd/system/docker.service.d/http-proxy.conf

# 重启 Docker
systemctl restart docker
```

## 4. 恢复原始配置

### 恢复 pip
```bash
bash scripts/run_set_pip_mirror.sh --uninstall
```

### 恢复 npm
```bash
bash scripts/run_set_npm_mirror.sh --uninstall
```

### 恢复代理
```bash
rm /etc/profile.d/proxy.sh
rm /etc/systemd/system/docker.service.d/http-proxy.conf
systemctl daemon-reload
systemctl restart docker
```

# 参考文档

更多详细资料请参考：
- `reference/WIKI.md` - 完整的配置指南和问题排查
- `reference/README.md` - 相关工具文档