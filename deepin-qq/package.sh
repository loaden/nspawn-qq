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

PKG=`pwd`/`dirname $0`/deepin.tar.zst
pushd $HOME/.machines
    sudo ZSTD_CLEVEL=19 ZSTD_NBTHREADS=$(nproc) tar -capvf $PKG deepin
popd
echo 打包完成！
