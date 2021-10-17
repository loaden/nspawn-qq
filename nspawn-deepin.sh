#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o ”$SUDO_USER“ == "root" ]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi


# 创建容器
[ -f /bin/apt ] && apt install -y systemd-container debootstrap
[ -f /bin/pacman ] && pacman -S --noconfirm --needed debootstrap
[ -f /bin/dnf ] && dnf install -y systemd-container debootstrap
mkdir -p /home/$SUDO_USER/.machines/deepin
ln -s /home/$SUDO_USER/.machines/deepin /var/lib/machines/deepin
ln -s /usr/share/debootstrap/scripts/stable /usr/share/debootstrap/scripts/apricot
debootstrap --include=systemd-container,dex,sudo,locales,dialog,fonts-noto-core,fonts-noto-cjk,neofetch,pulseaudio,bash-completion --no-check-gpg apricot /var/lib/machines/deepin https://community-packages.deepin.com/deepin


# 配置容器
source `dirname ${BASH_SOURCE[0]}`/deepin-config.sh


# 默认安装
su -w DISPLAY - $SUDO_USER -c "deepin-install-terminal"
su -w DISPLAY - $SUDO_USER -c "deepin-install-thunar"
su -w DISPLAY - $SUDO_USER -c "deepin-install-qq"

# 清理
su -w DISPLAY - $SUDO_USER -c "KEEP_QUIET=1 deepin-clean"
