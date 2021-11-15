#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

if [ ! -f /usr/bin/zstd ]; then
    [ -f /usr/bin/apt ] && /usr/bin/apt install -y zstd
    [ -f /usr/bin/pacman ] && /usr/bin/pacman -S zstd
    [ -f /usr/bin/dnf ] && /usr/bin/dnf install -y zstd
fi

sudo tar -xpvf `dirname ${BASH_SOURCE[0]}`/debian.tar.zst --directory=$HOME
sudo `dirname ${BASH_SOURCE[0]}`/nspawn-deepinwine/debian-config.sh
echo 安装完成！

