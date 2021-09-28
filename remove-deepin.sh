#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi

rm -f /var/lib/polkit-1/localauthority/10-vendor.d/machines.pkla
rm -f /usr/share/polkit-1/rules.d/10-machines.rules

chattr -i /var/lib/machines/deepin/var/lib/deepin/deepin_security_verify.whitelist
rm -f /var/lib/machines/deepin
rm -f /bin/deepin-*

[[ -d /home/share && `ls -A /home/share |wc -w` == 0 ]] && rm -rf /home/share
rm -f /etc/X11/xorg.conf.d/disable-MIT-SHM.conf
[[ -d /etc/X11/xorg.conf.d && `ls -A /etc/X11/xorg.conf.d |wc -w` == 0 ]] && rm -rf /etc/X11/xorg.conf.d
[ -f /etc/X11/xorg.conf ] && perl -0777 -pi -e 's/Section "Extensions"\n    Option "MIT-SHM" "Disable"\nEndSection\n//g' /etc/X11/xorg.conf
[ -f /etc/X11/xorg.conf ] && [[ ! $(cat /etc/X11/xorg.conf) ]] && rm -f /etc/X11/xorg.conf

rm -f /bin/systemd-nspawn-debug
rm -rf /etc/systemd/system/systemd-nspawn@debian.service.d
rm -f /etc/systemd/nspawn/debian.nspawn
[[ -d /etc/systemd/nspawn && `ls -A /etc/systemd/nspawn |wc -w` == 0 ]] && rm -rf /home/share /etc/systemd/nspawn

rm -f /usr/share/pixmaps/com.qq.im.deepin.svg
rm -f /usr/share/pixmaps/com.qq.weixin.deepin.svg
rm -f /usr/share/applications/deepin-qq.desktop
rm -f /usr/share/applications/deepin-weixin.desktop

echo "为防止数据意外丢失，您需要手动删除 ~/.machines 文件夹！"
