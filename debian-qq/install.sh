#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117
# 钉钉群：35948877

# 仅允许普通用户权限执行
if [ $EUID == 0 ]; then
    echo $(basename $0) 命令只允许普通用户执行
    exit 1
fi

if [ ! -f /usr/bin/zstd ]; then
    [ -f /usr/bin/apt ] && sudo /usr/bin/apt install -y zstd
    [ -f /usr/bin/pacman ] && sudo /usr/bin/pacman -S zstd
    [ -f /usr/bin/dnf ] && sudo /usr/bin/dnf install -y zstd
fi

if [ ! -d $HOME/.machines ]; then
    mkdir $HOME/.machines
fi

if [ -d $HOME/.machines/debian ]; then
    echo 容器 debian 已经存在，安装之前必须先卸载并删除旧容器！ && sleep 2
    source `dirname ${BASH_SOURCE[0]}`/remove.sh
fi

sudo tar -xpvf `dirname ${BASH_SOURCE[0]}`/debian.tar.zst --directory=$HOME/.machines
sudo `dirname ${BASH_SOURCE[0]}`/nspawn-qq/debian-config.sh
debian-upgrade
debian-update-store
KEEP_QUIET=1 debian-clean
debian-query
echo 安装完成！
