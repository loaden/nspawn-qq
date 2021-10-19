#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 不能单独执行提醒
if [[ `basename $0` == base-remove.sh ]]; then
    echo "'`basename $0`' 命令不能单独执行"
    exit 1
fi

[[ $(machinectl list) =~ $1 ]] && machinectl stop $1
systemctl disable systemd-nspawn@$1.service
systemctl stop systemd-nspawn@$1.service

rm -f /var/lib/polkit-1/localauthority/10-vendor.d/machines.pkla
rm -f /usr/share/polkit-1/rules.d/10-machines.rules

# 移除旧版本可能遗留文件
if [[ ! -f /usr/local/bin/$1-start && -f /bin/$1-start ]]; then
    rm -f /bin/$1-install-*
    rm -f /bin/$1-start
    rm -f /bin/$1-config
    rm -f /bin/$1-query
    rm -f /bin/$1-clean
    rm -f /bin/$1-config-*
    rm -f /bin/$1-qq
    rm -f /bin/$1-weixin
    rm -f /bin/$1-ecloud
    rm -f /bin/$1-thunar
    rm -f /bin/$1-mpv
fi

[ -f /lib/systemd/system/nspawn-$1.service ] && systemctl disable nspawn-$1.service
rm -f /lib/systemd/system/nspawn-$1.service

rm -f /var/lib/machines/$1
rm -f /home/nspawn.log
rm -f /usr/local/bin/$1-install-*
rm -f /usr/local/bin/$1-start
rm -f /usr/local/bin/$1-config
rm -f /usr/local/bin/$1-query
rm -f /usr/local/bin/$1-clean
rm -f /usr/local/bin/$1-config-*
rm -f /usr/local/bin/$1-qq
rm -f /usr/local/bin/$1-weixin
rm -f /usr/local/bin/$1-ecloud
rm -f /usr/local/bin/$1-thunar
rm -f /usr/local/bin/$1-mpv

[[ -d /home/share && `ls -A /home/share |wc -w` == 0 ]] && rm -rf /home/share
rm -f /etc/X11/xorg.conf.d/disable-MIT-SHM.conf
[[ -d /etc/X11/xorg.conf.d && `ls -A /etc/X11/xorg.conf.d |wc -w` == 0 ]] && rm -rf /etc/X11/xorg.conf.d
[ -f /etc/X11/xorg.conf ] && perl -0777 -pi -e 's/Section "Extensions"\n    Option "MIT-SHM" "Disable"\nEndSection\n//g' /etc/X11/xorg.conf
[ -f /etc/X11/xorg.conf ] && [[ ! $(cat /etc/X11/xorg.conf) ]] && rm -f /etc/X11/xorg.conf

rm -f /bin/systemd-nspawn-debug
rm -rf /etc/systemd/system/systemd-nspawn@$1.service.d
rm -f /etc/systemd/nspawn/$1.nspawn
[[ -d /etc/systemd/nspawn && `ls -A /etc/systemd/nspawn |wc -w` == 0 ]] && rm -rf /home/share /etc/systemd/nspawn

if [[ ! $EXEC_FROM_CONFIG ]] && [ -f /usr/share/applications/deepin-qq.desktop ] && [[ $(cat /usr/share/applications/deepin-qq.desktop | grep $1-) ]]; then
    rm -f /usr/share/pixmaps/com.qq.im.deepin.svg
    rm -f /usr/share/applications/deepin-qq.desktop
fi

if [[ ! $EXEC_FROM_CONFIG ]] && [ -f /usr/share/applications/deepin-weixin.desktop ] && [[ $(cat /usr/share/applications/deepin-weixin.desktop | grep $1-) ]]; then
    rm -f /usr/share/pixmaps/com.qq.weixin.deepin.svg
    rm -f /usr/share/applications/deepin-weixin.desktop
fi

[[ ! $EXEC_FROM_CONFIG ]] && echo "为防止数据意外丢失，您需要手动删除 ~/.machines/$1 文件夹！"
