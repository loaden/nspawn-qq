#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi

# 配置Debian容器
source `dirname ${BASH_SOURCE[0]}`/debian-config.sh
sleep 1

# 配置Deepin容器
source `dirname ${BASH_SOURCE[0]}`/deepin-config.sh
