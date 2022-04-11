#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 确认管理员权限
if [[ $EUID != 0 ]]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi

# 特殊处理
[ -f /var/lib/machines/deepin/var/lib/deepin/deepin_security_verify.whitelist ] && chattr -i /var/lib/machines/deepin/var/lib/deepin/deepin_security_verify.whitelist
rm -vf /usr/share/debootstrap/scripts/apricot

# 开始移除
source `dirname ${BASH_SOURCE[0]}`/base-remove.sh deepin
rm -vf /usr/local/bin/deepin-terminal
rm -vf /usr/local/bin/deepin-app-store
rm -vf /usr/local/bin/deepin-wemeet
rm -vf /usr/local/bin/deepin-xunlei
rm -vf /usr/local/bin/deepin-tenvideo
rm -vf /usr/local/bin/deepin-powerword
rm -vf /usr/local/bin/deepin-cbox
rm -vf /usr/local/bin/deepin-sunlogin
rm -vf /usr/local/bin/deepin-foxwq
rm -vf /usr/local/bin/deepin-baidunetdisk
rm -vf /usr/local/bin/deepin-cstrike
rm -vf /usr/local/bin/deepin-work-weixin
rm -vf /usr/local/bin/deepin-wesing
rm -vf /usr/local/bin/deepin-baoweiluobo

# 过期软件移除
rm -vf /usr/local/bin/deepin-feishu
rm -vf /usr/local/bin/deepin-dingtalk*
if [ -f /usr/share/applications/dingtalk.desktop ] && [[ $(cat /usr/share/applications/dingtalk.desktop | grep deepin-) ]]; then
    rm -vf /usr/share/pixmaps/dingtalk.svg
    rm -vf /usr/share/applications/dingtalk.desktop
fi

echo ls -la /usr/local/bin/
ls -la /usr/local/bin/
