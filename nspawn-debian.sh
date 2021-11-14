#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 确认管理员权限
if [[ $EUID != 0 ]]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi


# 创建容器
[ -f /usr/bin/apt ] && /usr/bin/apt install -y systemd-container debootstrap
[ -f /usr/bin/pacman ] && /usr/bin/pacman -S --noconfirm --needed debootstrap
[ -f /usr/bin/dnf ] && /usr/bin/dnf install -y systemd-container debootstrap
[ -z $(which debootstrap) ] && echo "工具debootstrap没有安装！请反馈您的系统，谢谢。" && exit -1
mkdir -p /home/$SUDO_USER/.machines/debian
ln -sfnv /home/$SUDO_USER/.machines/debian /var/lib/machines/debian
[ ! -d /var/lib/machines/debian/home/u1000 ] && debootstrap --variant=minbase --include=systemd-container --no-check-gpg buster /var/lib/machines/debian https://mirrors.tuna.tsinghua.edu.cn/debian

# 判断容器创建是否成功
if [[ $? == 1 ]]; then
    echo "容器 debian 已存在或者创建失败！请将运行日志反馈给我，谢谢。"
    exit 1
fi

# 配置容器
source `dirname ${BASH_SOURCE[0]}`/debian-config.sh


# 默认安装
debian-install-terminal
debian-install-file
debian-install-qq

# 清理
KEEP_QUIET=1 debian-clean
