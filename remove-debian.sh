#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi

# 移除旧版本可能遗留文件
if [[ ! -f /usr/local/bin/deepin-terminal && -f /bin/deepin-terminal ]]; then
    rm -f /bin/debian-terminal
fi

# 开始移除
source `dirname ${BASH_SOURCE[0]}`/base-remove.sh debian
rm -f /usr/local/bin/debian-terminal
