#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 仅允许普通用户权限执行
if [ $EUID == 0 ]; then
    echo $(basename $0) 命令只允许普通用户执行
    exit 1
fi

tags=$(git tag)
for i in $tags; do
    if [ -z $prev ]; then
        cmd="git log $i --oneline"
        echo -e "$cmd\n$($cmd)" > changelog.txt
        prev=$i
    else
        cmd="git log $prev..$i --oneline"
        echo -e "$cmd\n$($cmd)\n\n$(cat changelog.txt)" > changelog.txt
        prev=$i
    fi
    sleep 0.1
done
