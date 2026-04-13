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

````bash
# 下载脚本
curl -O https://raw.githubusercontent.com/XingYunStar/sh/main/git.sh

# 赋予执行权限
chmod +x git.sh

# 运行（在包含多个 Git 仓库的目录下）
./git.sh
````

---

### 2. `NapcatPlugin.sh` —— Napcat 插件商店修复脚本

解决新版 Napcat 只能安装官方插件的问题，通过替换插件索引源来启用社区插件商店。

#### 问题说明

新版 Napcat 默认的插件商店只能安装官方插件，限制了社区插件的使用。

#### 解决方法

本脚本自动修改 Napcat 容器内的配置文件，将官方插件索引替换为社区插件索引。

#### 使用方法

````bash
# 下载脚本
curl -O https://raw.githubusercontent.com/XingYunStar/sh/main/NapcatPlugin.sh

# 赋予执行权限
chmod +x NapcatPlugin.sh

# 运行脚本
./NapcatPlugin.sh
````

#### 脚本内容

````bash
#!/bin/bash
# Napcat 插件商店修复脚本
# 替换插件索引源为社区版

sed -i 's/NapNeko\/napcat-plugin-index/HolyFoxTeam\/napcat-plugin-community-index/g' ./napcat/napcat.mjs

echo "修复完成！请重启 Napcat 容器后查看插件商店。"
````

#### 手动执行（如果不想使用脚本）

进入 Napcat 容器终端，执行：

````bash
sed -i 's/NapNeko\/napcat-plugin-index/HolyFoxTeam\/napcat-plugin-community-index/g' ./napcat/napcat.mjs
````

然后重启容器即可。

#### 注意事项

- 确保在 Napcat 容器的正确路径下执行（脚本默认路径为 `./napcat/napcat.mjs`）
- 执行后**必须重启容器**才能使修改生效
- 建议执行前备份原文件：
````bash
cp ./napcat/napcat.mjs ./napcat/napcat.mjs.bak
````

---

## 添加新脚本

1. 将新脚本放入仓库根目录
2. 更新本 `README.md`，在“包含脚本”部分添加说明
3. 确保脚本有执行权限并经过测试

## 脚本列表总览

| 脚本 | 用途 | 适用场景 |
|------|------|----------|
| `git.sh` | Git 仓库批量管理 | 批量更换远程地址、批量 pull |
| `napcat.sh` | Napcat 插件商店修复 | Napcat 容器无法显示社区插件 |

## 依赖

- Bash 4.0+
- Git（用于 `git.sh`）
- sed（用于 napcat.sh）
- 基础命令：grep、find、curl
