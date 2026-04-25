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

# 获取当前日期时间
get_datetime() {
    date +"%Y%m%d_%H%M%S"
}

# 在文件所在目录备份并删除文件
backup_and_remove() {
    local file="$1"
    local datetime="$2"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # 获取文件所在目录、文件名和扩展名
    local filedir=$(dirname "$file")
    local filename=$(basename "$file")
    local basename="${filename%.*}"
    local extension="${filename##*.}"
    
    # 如果文件名和扩展名相同（无扩展名的情况）
    if [ "$basename" = "$extension" ]; then
        backup_name="${basename}_${datetime}.bak"
    else
        backup_name="${basename}_${datetime}.${extension}.bak"
    fi
    
    local backup_path="${filedir}/${backup_name}"
    
    # 备份文件（在同一目录下）
    cp "$file" "$backup_path"
    print_info "  已备份: $file -> $backup_path"
    
    # 删除原文件
    rm -f "$file"
    print_info "  已删除: $file"
    
    return 0
}

# 主程序
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Git 冲突自动处理工具${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 检查是否在 Git 仓库中
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "当前目录不是 Git 仓库！"
        exit 1
    fi
    
    datetime=$(get_datetime)
    
    print_info "当前目录: $(pwd)"
    echo ""
    
    # 尝试 git pull 并捕获冲突文件
    print_info "正在执行 git pull..."
    pull_output=$(git pull 2>&1)
    pull_exit=$?
    
    echo "$pull_output"
    echo ""
    
    # 检查是否有冲突
    if [ $pull_exit -eq 0 ]; then
        print_success "git pull 成功，无冲突！"
        exit 0
    fi
    
    # 提取冲突文件列表 - 方法1：匹配 error 行后面的文件列表
    # 先获取 "overwritten by merge:" 之后的所有行，然后提取以空格开头的文件路径
    conflict_files=$(echo "$pull_output" | awk '/overwritten by merge:/,/^[^ ]/' | grep -E '^[[:space:]]+' | sed 's/^[[:space:]]*//')
    
    # 如果方法1失败，使用方法2：直接匹配以空格开头且包含路径特征的行
    if [ -z "$conflict_files" ]; then
        conflict_files=$(echo "$pull_output" | grep -E '^[[:space:]]+[^ ]+' | grep -E '\.(js|yaml|yml|json|md|png|jpg|css|html|py|sh|png|git)' | sed 's/^[[:space:]]*//')
    fi
    
    # 如果还是失败，使用 git status 获取冲突文件
    if [ -z "$conflict_files" ]; then
        print_info "从 git pull 输出无法识别，尝试使用 git status..."
        conflict_files=$(git status --porcelain | grep '^ M' | awk '{print $2}')
    fi
    
    if [ -z "$conflict_files" ]; then
        print_warning "无法自动识别冲突文件，请手动处理"
        exit 1
    fi
    
    # 去重并显示冲突文件
    conflict_files=$(echo "$conflict_files" | sort -u)
    
    print_warning "检测到以下冲突文件："
    echo "$conflict_files" | while read -r file; do
        if [ -n "$file" ]; then
            echo "  - $file"
        fi
    done
    echo ""
    
    # 询问是否自动处理
    read -p "$(echo -e "${YELLOW}是否自动备份并删除这些文件？ [y/N]: ${NC}")" confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "已取消操作"
        exit 0
    fi
    
    echo ""
    
    # 备份并删除每个冲突文件
    success_count=0
    fail_count=0
    declare -a backup_files
    
    while read -r file; do
        if [ -n "$file" ]; then
            # 文件路径相对于当前目录
            if [ -f "$file" ]; then
                if backup_and_remove "$file" "$datetime"; then
                    ((success_count++))
                    backup_files+=("$file")
                else
                    ((fail_count++))
                fi
            else
                print_warning "  文件不存在: $file"
                ((fail_count++))
            fi
        fi
    done <<< "$conflict_files"
    
    echo ""
    print_info "处理统计: 成功备份删除 $success_count 个，失败 $fail_count 个"
    echo ""
    
    # 再次尝试 git pull
    print_info "正在重新执行 git pull..."
    if git pull; then
        print_success "git pull 成功！"
        
        # 显示备份文件位置
        echo ""
        print_info "备份文件已保存在各文件的原目录中"
        print_info "备份格式: 原文件名_日期时间.扩展名.bak"
        echo ""
        
        # 显示备份文件列表
        if [ ${#backup_files[@]} -gt 0 ]; then
            print_info "备份文件列表："
            for file in "${backup_files[@]}"; do
                local filedir=$(dirname "$file")
                local filename=$(basename "$file")
                local basename="${filename%.*}"
                local extension="${filename##*.}"
                if [ "$basename" = "$extension" ]; then
                    echo "  - ${filedir}/${basename}_${datetime}.bak"
                else
                    echo "  - ${filedir}/${basename}_${datetime}.${extension}.bak"
                fi
            done
        fi
        
        # 询问是否删除备份文件
        echo ""
        read -p "$(echo -e "${YELLOW}是否删除所有备份文件？ [y/N]: ${NC}")" delete_confirm
        
        if [[ $delete_confirm =~ ^[Yy]$ ]]; then
            print_info "正在删除备份文件..."
            for file in "${backup_files[@]}"; do
                local filedir=$(dirname "$file")
                local filename=$(basename "$file")
                local basename="${filename%.*}"
                local extension="${filename##*.}"
                
                if [ "$basename" = "$extension" ]; then
                    backup_file="${filedir}/${basename}_${datetime}.bak"
                else
                    backup_file="${filedir}/${basename}_${datetime}.${extension}.bak"
                fi
                
                if [ -f "$backup_file" ]; then
                    rm -f "$backup_file"
                    print_success "  已删除: $backup_file"
                fi
            done
            print_success "所有备份文件已删除"
        else
            print_info "备份文件已保留，您可以在确认无误后手动删除"
        fi
    else
        print_error "git pull 仍然失败，请手动处理"
        print_info "备份文件已保存在各文件的原目录中"
        exit 1
    fi
}

# 运行主程序
main
