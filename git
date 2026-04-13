#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 提取 GitHub 地址
extract_github_url() {
    local url=$1
    local github_path=$(echo "$url" | grep -oP 'github\.[^/]+/[^/]+/[^/.]+(\.git)?' | head -1)
    if [ -n "$github_path" ]; then
        echo "https://$github_path"
    else
        echo ""
    fi
}

# 询问用户
ask_confirmation() {
    local prompt=$1
    local answer
    read -p "$(echo -e "${YELLOW}$prompt [y/N]: ${NC}")" answer
    echo $answer
}

ask_choice() {
    local prompt=$1
    local answer
    read -p "$(echo -e "${YELLOW}$prompt: ${NC}")" answer
    echo $answer
}

# git pull 处理函数（支持强制拉取）
handle_git_pull() {
    local repo=$1
    
    print_info "  正在执行 git pull..."
    
    if git pull 2>&1; then
        print_success "  git pull 成功"
        return 0
    else
        print_warning "  git pull 失败"
        
        # 检查是否有本地修改
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo -e "  ${YELLOW}检测到本地有未提交的修改${NC}"
            git status --short
            echo ""
            
            echo "  请选择处理方式："
            echo "    1. 放弃本地修改，强制拉取（git reset --hard）"
            echo "    2. 暂存本地修改后拉取（git stash）"
            echo "    3. 跳过此仓库"
            echo "    4. 查看详细差异"
            
            local choice=$(ask_choice "  请输入选项 [1-4]")
            
            case $choice in
                1)
                    print_warning "  放弃本地修改，强制拉取..."
                    git reset --hard
                    git pull
                    print_success "  强制拉取完成"
                    ;;
                2)
                    print_info "  暂存本地修改..."
                    git stash push -m "auto-stash-$(date +%Y%m%d_%H%M%S)"
                    print_info "  正在拉取远程更新..."
                    if git pull; then
                        print_success "  拉取成功"
                        print_info "  恢复本地修改..."
                        git stash pop
                        if [ $? -ne 0 ]; then
                            print_warning "  恢复本地修改时出现冲突，请手动处理"
                        else
                            print_success "  本地修改已恢复"
                        fi
                    else
                        print_error "  拉取仍然失败"
                    fi
                    ;;
                3)
                    print_info "  跳过此仓库的 pull 操作"
                    return 1
                    ;;
                4)
                    echo -e "${BLUE}--- 本地修改详情 ---${NC}"
                    git diff
                    echo -e "${BLUE}--- 远程状态 ---${NC}"
                    git fetch
                    git log HEAD..origin/HEAD --oneline 2>/dev/null || echo "无法获取远程日志"
                    echo ""
                    handle_git_pull "$repo"
                    ;;
                *)
                    print_error "  无效选择，跳过此仓库"
                    return 1
                    ;;
            esac
        else
            echo "  请选择处理方式："
            echo "    1. 重试 git pull"
            echo "    2. 跳过此仓库"
            echo "    3. 查看错误详情"
            
            local choice=$(ask_choice "  请输入选项 [1-3]")
            
            case $choice in
                1)
                    handle_git_pull "$repo"
                    ;;
                2)
                    print_info "  跳过此仓库"
                    return 1
                    ;;
                3)
                    echo -e "${BLUE}--- 错误详情 ---${NC}"
                    git pull --verbose 2>&1
                    echo ""
                    handle_git_pull "$repo"
                    ;;
                *)
                    print_error "  无效选择，跳过此仓库"
                    return 1
                    ;;
            esac
        fi
        return 1
    fi
}

# 批量 git pull（支持统一策略）
batch_git_pull() {
    local repos=("$@")
    local batch_strategy=$1
    shift
    local repos=("$@")
    
    case $batch_strategy in
        "force")
            print_warning "批量强制拉取模式（将放弃所有本地修改）..."
            for repo in "${repos[@]}"; do
                echo -e "${GREEN}----------------------------------------${NC}"
                print_info "处理仓库: $repo"
                cd "$repo" || continue
                git fetch origin
                git reset --hard origin/HEAD 2>/dev/null || git reset --hard origin/$(git branch --show-current)
                print_success "  强制拉取完成"
                cd - > /dev/null
            done
            ;;
        "stash")
            print_info "批量暂存拉取模式..."
            for repo in "${repos[@]}"; do
                echo -e "${GREEN}----------------------------------------${NC}"
                print_info "处理仓库: $repo"
                cd "$repo" || continue
                git stash push -m "auto-stash-$(date +%Y%m%d_%H%M%S)" 2>/dev/null
                if git pull; then
                    print_success "  拉取成功"
                    git stash pop 2>/dev/null
                else
                    print_warning "  拉取失败，已跳过"
                fi
                cd - > /dev/null
            done
            ;;
        "skip")
            print_info "批量拉取模式（失败跳过）..."
            for repo in "${repos[@]}"; do
                echo -e "${GREEN}----------------------------------------${NC}"
                print_info "处理仓库: $repo"
                cd "$repo" || continue
                if git pull; then
                    print_success "  拉取成功"
                else
                    print_warning "  拉取失败，已跳过"
                fi
                cd - > /dev/null
            done
            ;;
        *)
            print_info "交互式批量拉取模式..."
            for repo in "${repos[@]}"; do
                echo -e "${GREEN}----------------------------------------${NC}"
                print_info "处理仓库: $repo"
                cd "$repo" || continue
                handle_git_pull "$repo"
                cd - > /dev/null
            done
            ;;
    esac
}

# 主程序
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Git 仓库管理工具${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 查找所有 Git 仓库
    print_info "正在扫描当前目录下的 Git 仓库..."
    repos=()
    while IFS= read -r gitdir; do
        repo=$(dirname "$gitdir")
        repos+=("$repo")
    done < <(find . -maxdepth 2 -name ".git" -type d)
    
    if [ ${#repos[@]} -eq 0 ]; then
        print_error "未找到任何 Git 仓库！"
        exit 1
    fi
    
    print_success "找到 ${#repos[@]} 个 Git 仓库"
    echo ""
    
    # 显示所有仓库
    print_info "仓库列表："
    for i in "${!repos[@]}"; do
        echo "  $((i+1)). ${repos[$i]}"
    done
    echo ""
    
    # 询问操作类型
    echo -e "${BLUE}请选择操作：${NC}"
    echo "  1. 更换为原始 GitHub 地址（https://github.com/...）"
    echo "  2. 更换为自定义加速地址"
    echo "  3. 仅查看当前地址，不做修改"
    echo "  4. 仅执行 git pull（不更换地址）"
    read -p "$(echo -e "${YELLOW}请选择 [1-4]: ${NC}")" choice
    
    case $choice in
        1)
            proxy_prefix=""
            print_info "将更换为原始 GitHub 地址"
            
            # 询问是否执行 git pull
            pull_choice=$(ask_confirmation "是否在更换地址后执行 git pull？")
            if [[ $pull_choice =~ ^[Yy]$ ]]; then
                do_pull=true
                print_info "将在更换地址后执行 git pull"
            else
                do_pull=false
                print_info "将不会执行 git pull"
            fi
            ;;
        2)
            read -p "$(echo -e "${YELLOW}请输入加速地址前缀（例如：https://ghproxy.net/）: ${NC}")" proxy_prefix
            if [[ ! "$proxy_prefix" =~ /$ ]]; then
                proxy_prefix="${proxy_prefix}/"
            fi
            print_info "将使用加速地址：$proxy_prefix"
            
            # 询问是否执行 git pull
            pull_choice=$(ask_confirmation "是否在更换地址后执行 git pull？")
            if [[ $pull_choice =~ ^[Yy]$ ]]; then
                do_pull=true
                print_info "将在更换地址后执行 git pull"
            else
                do_pull=false
                print_info "将不会执行 git pull"
            fi
            ;;
        3)
            print_info "仅查看模式，不会修改任何配置"
            do_pull=false
            ;;
        4)
            print_info "仅执行 git pull 模式（不更换地址）"
            do_pull=true
            change_url=false
            
            # 询问批量处理策略
            echo ""
            echo -e "${BLUE}请选择 pull 失败时的处理策略：${NC}"
            echo "  1. 交互式处理（每个仓库单独询问）"
            echo "  2. 自动放弃本地修改强制拉取（危险）"
            echo "  3. 自动暂存后拉取"
            echo "  4. 遇到失败跳过该仓库"
            
            read -p "$(echo -e "${YELLOW}请选择 [1-4]: ${NC}")" strategy
            
            case $strategy in
                1)
                    batch_strategy="interactive"
                    print_info "使用交互式策略"
                    ;;
                2)
                    batch_strategy="force"
                    print_warning "使用自动强制拉取策略（将放弃所有本地修改）"
                    ;;
                3)
                    batch_strategy="stash"
                    print_info "使用自动暂存策略"
                    ;;
                4)
                    batch_strategy="skip"
                    print_info "使用跳过策略（遇到失败直接跳过）"
                    ;;
                *)
                    print_error "无效选择，使用默认交互式策略"
                    batch_strategy="interactive"
                    ;;
            esac
            
            # 执行批量 git pull
            batch_git_pull "$batch_strategy" "${repos[@]}"
            
            echo -e "${GREEN}========================================${NC}"
            print_success "处理完成！"
            echo -e "${GREEN}========================================${NC}"
            exit 0
            ;;
        *)
            print_error "无效选择！"
            exit 1
            ;;
    esac
    
    echo ""
    
    # 处理每个仓库（选项 1、2、3）
    failed_repos=()
    for repo in "${repos[@]}"; do
        echo -e "${GREEN}----------------------------------------${NC}"
        print_info "处理仓库: $repo"
        
        cd "$repo" || continue
        
        # 获取当前远程地址
        current_url=$(git config --get remote.origin.url)
        echo "  当前地址: $current_url"
        
        # 选项 3：仅查看模式
        if [ $choice -eq 3 ]; then
            print_info "  仅查看模式，不修改地址"
            cd - > /dev/null
            continue
        fi
        
        # 选项 1 和 2：更换地址
        # 提取真实的 GitHub 地址
        real_github_url=$(extract_github_url "$current_url")
        
        if [ -z "$real_github_url" ]; then
            print_warning "  无法提取 GitHub 地址，跳过此仓库"
            failed_repos+=("$repo (无法提取地址)")
            cd - > /dev/null
            continue
        fi
        
        echo "  提取的地址: $real_github_url"
        
        if [ -z "$proxy_prefix" ]; then
            # 使用原始地址
            new_url=$(echo "$real_github_url" | sed 's|github\.[^/]*|github.com|')
        else
            # 使用加速地址
            repo_path=$(echo "$real_github_url" | grep -oP 'github\.[^/]+/\K[^/]+/[^/.]+(\.git)?')
            new_url="${proxy_prefix}github.com/${repo_path}"
        fi
        
        echo "  新地址: $new_url"
        
        # 更换远程地址
        git remote set-url origin "$new_url"
        print_success "  已更换远程地址"
        
        # 执行 git pull（如果需要）
        if [ "$do_pull" = true ]; then
            handle_git_pull "$repo"
            if [ $? -ne 0 ]; then
                failed_repos+=("$repo")
            fi
        fi
        
        cd - > /dev/null
        echo ""
    done
    
    echo -e "${GREEN}========================================${NC}"
    print_success "处理完成！"
    
    # 显示失败统计
    if [ ${#failed_repos[@]} -gt 0 ]; then
        print_warning "以下 ${#failed_repos[@]} 个仓库处理失败："
        for repo in "${failed_repos[@]}"; do
            echo "  - $repo"
        done
    else
        if [ $choice -ne 3 ]; then
            print_success "所有仓库处理成功！"
        fi
    fi
    echo -e "${GREEN}========================================${NC}"
}

# 运行主程序
main
