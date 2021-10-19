#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 确认管理员权限
if [[ $EUID != 0 ]]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi


# 创建容器
[ -f /bin/apt ] && apt install -y systemd-container debootstrap
[ -f /bin/pacman ] && pacman -S --noconfirm --needed debootstrap
[ -f /bin/dnf ] && dnf install -y systemd-container debootstrap
mkdir -p /home/$SUDO_USER/.machines/debian
ln -s /home/$SUDO_USER/.machines/debian /var/lib/machines/
[[ $? == 0 ]] && debootstrap --include=systemd-container,dex,sudo,locales,dialog,fonts-noto-core,fonts-noto-cjk,neofetch,pulseaudio,bash-completion --no-check-gpg buster /var/lib/machines/debian https://mirrors.tuna.tsinghua.edu.cn/debian

# 判断容器创建是否成功
if [[ $? == 1 ]]; then
    echo "容器 debian 已存在或者创建失败！请将运行日志反馈给我，谢谢。"
    exit 1
fi

# 配置容器
source `dirname ${BASH_SOURCE[0]}`/debian-config.sh


# 默认安装
su -w DISPLAY - $SUDO_USER -c "debian-install-terminal"
su -w DISPLAY - $SUDO_USER -c "debian-install-thunar"
su -w DISPLAY - $SUDO_USER -c "debian-install-qq"

# 清理
su -w DISPLAY - $SUDO_USER -c "KEEP_QUIET=1 debian-clean"
