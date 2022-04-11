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

[ -f /lib/systemd/system/nspawn-$1.service ] && systemctl disable nspawn-$1.service
rm -vf /lib/systemd/system/nspawn-$1.service

rm -vrf /var/lib/machines/.machines
rm -vf /var/lib/machines/$1
rm -vf /home/nspawn.log
rm -vf /usr/local/bin/$1-install-*
rm -vf /usr/local/bin/$1-start
rm -vf /usr/local/bin/$1-config
rm -vf /usr/local/bin/$1-query
rm -vf /usr/local/bin/$1-bind
rm -vf /usr/local/bin/$1-clean
rm -vf /usr/local/bin/$1-update
rm -vf /usr/local/bin/$1-upgrade
rm -vf /usr/local/bin/$1-config-*
rm -vf /usr/local/bin/$1-qq
rm -vf /usr/local/bin/$1-tim
rm -vf /usr/local/bin/$1-weixin
rm -vf /usr/local/bin/$1-ecloud
rm -vf /usr/local/bin/$1-file
rm -vf /usr/local/bin/$1-mpv
rm -vf /usr/local/bin/$1-chromium
rm -vf /usr/local/bin/$1-shotwell
rm -vf /usr/local/bin/$1-libreoffice

[[ -d /home/share && `ls -A /home/share |wc -w` == 0 ]] && rm -vrf /home/share
rm -vf /etc/X11/xorg.conf.d/disable-MIT-SHM.conf
[[ -d /etc/X11/xorg.conf.d && `ls -A /etc/X11/xorg.conf.d |wc -w` == 0 ]] && rm -vrf /etc/X11/xorg.conf.d
[ -f /etc/X11/xorg.conf ] && perl -0777 -pi -e 's/Section "Extensions"\n    Option "MIT-SHM" "Disable"\nEndSection\n//g' /etc/X11/xorg.conf
[ -f /etc/X11/xorg.conf ] && [[ ! $(cat /etc/X11/xorg.conf) ]] && rm -vf /etc/X11/xorg.conf

rm -vf /usr/bin/systemd-nspawn-debug
rm -vrf /etc/systemd/system/systemd-nspawn@$1.service.d
rm -vf /etc/systemd/nspawn/$1.nspawn
[[ -d /etc/systemd/nspawn && `ls -A /etc/systemd/nspawn |wc -w` == 0 ]] && rm -vrf /etc/systemd/nspawn

if [[ ! $EXEC_FROM_CONFIG ]] && [ -f /usr/share/applications/deepin-qq.desktop ] && [[ $(cat /usr/share/applications/deepin-qq.desktop | grep $1-) ]]; then
    rm -vf /usr/share/pixmaps/com.qq.im.deepin.svg
    rm -vf /usr/share/applications/deepin-qq.desktop
fi

if [[ ! $EXEC_FROM_CONFIG ]] && [ -f /usr/share/applications/deepin-tim.desktop ] && [[ $(cat /usr/share/applications/deepin-tim.desktop | grep $1-) ]]; then
    rm -vf /usr/share/pixmaps/com.qq.office.deepin.svg
    rm -vf /usr/share/applications/deepin-tim.desktop
fi

if [[ ! $EXEC_FROM_CONFIG ]] && [ -f /usr/share/applications/deepin-weixin.desktop ] && [[ $(cat /usr/share/applications/deepin-weixin.desktop | grep $1-) ]]; then
    rm -vf /usr/share/pixmaps/com.qq.weixin.deepin.svg
    rm -vf /usr/share/applications/deepin-weixin.desktop
fi

if [[ ! $EXEC_FROM_CONFIG ]] && [ -f /usr/share/applications/deepin-ecloud.desktop ] && [[ $(cat /usr/share/applications/deepin-ecloud.desktop | grep $1-) ]]; then
    rm -vf /usr/share/pixmaps/cn.189.cloud.deepin.svg
    rm -vf /usr/share/applications/deepin-ecloud.desktop
fi

if [ ! -f /usr/local/bin/*-config ]; then
    rm -vf /var/lib/polkit-1/localauthority/10-vendor.d/machines.pkla
    rm -vf /usr/share/polkit-1/rules.d/10-machines.rules
fi

[[ ! $EXEC_FROM_CONFIG ]] && echo "为防止数据意外丢失，您需要手动删除 ~/.machines/$1 文件夹！"
