#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 不能单独执行提醒
if [[ `basename $0` == user-dirs.sh ]]; then
    echo "'`basename $0`' 命令不能单独执行"
    exit 1
fi

# 获取用户目录
[ ! -f /usr/bin/xdg-user-dir ] && [ -f /usr/bin/apt ] && apt install -y xdg-user-dirs
[ ! -f /usr/bin/xdg-user-dir ] && [ -f /usr/bin/dnf ] && dnf install -y xdg-user-dirs
[ ! -f /usr/bin/xdg-user-dir ] && [ -f /usr/bin/pacman ] && pacman -S --noconfirm --needed xdg-user-dirs
USER_DESKTOP=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir DESKTOP') && echo ${ret##*/})
USER_DOWNLOAD=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir DOWNLOAD') && echo ${ret##*/})
USER_TEMPLATES=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir TEMPLATES') && echo ${ret##*/})
USER_PUBLICSHARE=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir PUBLICSHARE') && echo ${ret##*/})
USER_DOCUMENTS=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir DOCUMENTS') && echo ${ret##*/})
USER_MUSIC=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir MUSIC') && echo ${ret##*/})
USER_PICTURES=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir PICTURES') && echo ${ret##*/})
USER_VIDEOS=$(ret=$(su - $SUDO_USER -c 'xdg-user-dir VIDEOS') && echo ${ret##*/})

USER_CLOUDDISK=$(su - $SUDO_USER -c 'xdg-user-dir')/云盘
if [[ -d $USER_CLOUDDISK ]]; then
    USER_CLOUDDISK=$(basename $USER_CLOUDDISK)
else
    USER_CLOUDDISK=
fi
