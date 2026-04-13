# 个人命令工具集

一个用于存放各种实用命令脚本的仓库，方便快速使用和维护。

## 包含脚本

### 1. `git.sh` —— Git 仓库批量管理工具

交互式脚本，用于批量管理当前目录下所有 Git 仓库的远程地址和拉取操作。

#### 功能

- 自动扫描当前目录下的所有 Git 仓库
- 支持更换为原始 GitHub 地址或自定义加速地址（如 `https://ghproxy.net/`）
- 支持仅执行 `git pull`（不更改地址）
- `git pull` 失败时提供多种冲突处理选项：
  - 放弃本地修改强制拉取
  - 暂存本地修改后拉取并恢复
  - 跳过该仓库
  - 查看详细差异
- 批量 `git pull` 时支持预设处理策略（交互式/强制/暂存/跳过）
- 彩色输出，清晰显示进度和结果统计

#### 使用方法

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/XingYunStar/sh/main/git.sh

# 赋予执行权限
chmod +x git.sh

# 运行（在包含多个 Git 仓库的目录下）
./git.sh
