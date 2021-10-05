#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 创建容器
[ -f /bin/apt ] && apt install -y systemd-container debootstrap
[ -f /bin/pacman ] && pacman -S --noconfirm --needed debootstrap
[ -f /bin/dnf ] && dnf install -y systemd-container debootstrap
mkdir -p /home/$SUDO_USER/.machines/debian
ln -sf /home/$SUDO_USER/.machines/debian /var/lib/machines
debootstrap --include=systemd-container,dex,sudo,locales,dialog,fonts-noto-core,fonts-noto-cjk,neofetch,pulseaudio,bash-completion --no-check-gpg buster /var/lib/machines/debian https://mirrors.tuna.tsinghua.edu.cn/debian


# 配置容器
source `dirname ${BASH_SOURCE[0]}`/debian-config.sh


# 默认安装
[ -f /bin/flatpak ] && debian-install-flatpak
debian-install-terminal
debian-install-thunar
debian-install-qq

# 清理
debian-clean
