#!/bin/bash

# 检查参数数量
if [ "$#" -ne 2 ]; then
    echo "使用方法: $0 <源仓库路径> <目标仓库路径>"
    exit 1
fi

SOURCE_REPO=$1
TARGET_REPO=$2

# 检查目录是否存在
if [ ! -d "$SOURCE_REPO/.git" ]; then
    echo "错误: 源路径 '$SOURCE_REPO' 不是一个有效的 Git 仓库。"
    exit 1
fi

if [ ! -d "$TARGET_REPO/.git" ]; then
    echo "错误: 目标路径 '$TARGET_REPO' 不是一个有效的 Git 仓库。"
    exit 1
fi

echo "正在从 $SOURCE_REPO 拷贝配置到 $TARGET_REPO ..."

# 获取源仓库的所有本地配置项
# --local 表示只获取该仓库的配置，不包含全局配置
git -C "$SOURCE_REPO" config --local --list | while read -r line; do
    # 分割 key 和 value
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)

    # 过滤掉不应拷贝的特定项（黑名单）
    # 比如 remote (远程地址), branch (分支追踪), core (仓库格式等)
    case "$key" in
        remote.*)      continue ;; # 跳过远程仓库配置
        branch.*)      continue ;; # 跳过分支配置
        core.repositoryformatversion) continue ;;
        core.filemode)                continue ;;
        core.bare)                    continue ;;
        core.logallrefupdates)        continue ;;
    esac

    # 将配置应用到目标仓库
    echo "设置: $key = $value"
    git -C "$TARGET_REPO" config "$key" "$value"
done

echo "完成！配置已同步。"
