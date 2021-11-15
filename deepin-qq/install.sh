#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

if [ ! -f /usr/bin/zstd ]; then
    [ -f /usr/bin/apt ] && /usr/bin/apt install -y zstd
    [ -f /usr/bin/pacman ] && /usr/bin/pacman -S zstd
    [ -f /usr/bin/dnf ] && /usr/bin/dnf install -y zstd
fi

if [ ! -d $HOME/.machines ]; then
    mkdir $HOME/.machines
fi

if [ -d $HOME/.machines/debian ]; then
    echo 容器 debian 已经存在，安装之前必须先卸载并删除旧容器！ && sleep 2
    source `dirname ${BASH_SOURCE[0]}`/remove.sh
fi

sudo tar -xpvf `dirname ${BASH_SOURCE[0]}`/deepin.tar.zst --directory=$HOME
sudo `dirname ${BASH_SOURCE[0]}`/nspawn-deepinwine/deepin-config.sh
echo 安装完成！
