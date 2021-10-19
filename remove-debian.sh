#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 确认管理员权限
if [[ $EUID != 0 ]]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi

# 移除旧版本可能遗留文件
if [[ ! -f /usr/local/bin/deepin-terminal && -f /bin/deepin-terminal ]]; then
    rm -f /bin/debian-terminal
fi

# 开始移除
source `dirname ${BASH_SOURCE[0]}`/base-remove.sh debian
rm -f /usr/local/bin/debian-terminal
