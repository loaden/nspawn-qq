#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 允许无管理员权限启动
source `dirname ${BASH_SOURCE[0]}`/nspawn-polkit.sh


# 初始化配置
[ -f /bin/apt ] && [ ! -f /bin/machinectl ] && apt install -y systemd-container
[ -f /bin/dnf ] && [ ! -f /bin/machinectl ] && dnf install -y systemd-container
ln -sf /home/$SUDO_USER/.machines/debian /var/lib/machines
[ -f "/bin/debian-distro-info" ] && mv /bin/debian-distro-info /bin/bak-debian-distro-info
rm -f /bin/debian-*
[ -f "/bin/bak-debian-distro-info" ] && mv /bin/bak-debian-distro-info /bin/debian-distro-info


# 获取用户目录
source `dirname ${BASH_SOURCE[0]}`/user-dirs.sh


# 配置容器
[[ $(machinectl list) =~ debian ]] && machinectl stop debian
mkdir -p /home/share && chmod 777 /home/share
cat > /var/lib/machines/debian/config.sh <<EOF
[[ ! \$(cat /etc/hosts | grep \$HOSTNAME) ]] && echo "127.0.0.1 \$HOSTNAME" >> /etc/hosts
/bin/sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
/bin/sed -i 's/# zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen
/sbin/locale-gen
locale
echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free" > /etc/apt/sources.list
mkdir -p /home/share && chmod 777 /home/share
[[ \$(/bin/cat /etc/passwd | grep user:) ]] && /usr/sbin/userdel -r user
for i in {1000..1005}; do
    [[ \$(/bin/cat /etc/passwd | grep u\$i:) ]] && continue
    /usr/sbin/useradd -u \$i -m -s /bin/bash -G sudo u\$i
    echo u\$i:passwd | /usr/sbin/chpasswd
    cd /home/u\$i/
    mkdir -p .local/share/fonts .config .cache $USER_DOCUMENTS $USER_DOWNLOAD $USER_DESKTOP $USER_PICTURES $USER_VIDEOS $USER_MUSIC $USER_CLOUDDISK
    chown -R u\$i:u\$i .local .config .cache $USER_DOCUMENTS $USER_DOWNLOAD $USER_DESKTOP $USER_PICTURES $USER_VIDEOS $USER_MUSIC $USER_CLOUDDISK
done
EOF

chroot /var/lib/machines/debian/ /bin/bash /config.sh


# 禁用MIT-SHM
source `dirname ${BASH_SOURCE[0]}`/xnoshm.sh debian


# 配置启动环境变量
DESKTOP_ENVIRONMENT=
X11_BIND_AND_CONFIG=
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $1}') -p Type` == *wayland* ]]; then
X11_BIND_AND_CONFIG=$(bash -c 'echo -e "
# Xauthority
machinectl bind --read-only --mkdir debian \$XAUTHORITY
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir debian \$XAUTHORITY
"')
else
X11_BIND_AND_CONFIG=$(bash -c 'echo -e "
# Xauthority
machinectl bind --read-only --mkdir debian \$XAUTHORITY /home/u\$UID/.Xauthority
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir debian \$XAUTHORITY /home/u\$UID/.Xauthority
xhost +local:
"')
DESKTOP_ENVIRONMENT=$(bash -c 'echo -e "export XAUTHORITY=/home/u\$UID/.Xauthority"')
fi
cat > /bin/debian-start  <<EOF
#!/bin/bash
$(echo "$DESKTOP_ENVIRONMENT")
export XDG_RUNTIME_DIR=/run/user/\$UID
export PULSE_SERVER=unix:\$XDG_RUNTIME_DIR/pulse/native
$(echo "$DISABLE_MITSHM")
dex \$@
EOF

chmod 755 /bin/debian-start
echo cat /bin/debian-start
cat /bin/debian-start


# 调试
cat > /bin/systemd-nspawn-debug <<EOF
#!/bin/bash
export NSPAWN_LOG_FILE=/home/nspawn.log
touch \$NSPAWN_LOG_FILE
echo \$(date) \$NSPAWN_LOG_FILE >> \$NSPAWN_LOG_FILE
echo -e "tree -L 2 /run/user \n" "\$(tree -L 2 /run/user)" >> \$NSPAWN_LOG_FILE
echo -e "env \n" "\$(env)" \n >> \$NSPAWN_LOG_FILE
chmod 777 \$NSPAWN_LOG_FILE
EOF

chmod 755 /bin/systemd-nspawn-debug
cat /bin/systemd-nspawn-debug


# 重写启动服务参数
rm -rf /etc/systemd/system/systemd-nspawn@debian.service.d
mkdir -p /etc/systemd/system/systemd-nspawn@debian.service.d
cat > /etc/systemd/system/systemd-nspawn@debian.service.d/override.conf <<EOF
[Service]
ExecStartPost=systemd-nspawn-debug
ExecStart=
ExecStart=systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth -U --settings=override --machine=%i --setenv=LANGUAGE=zh_CN:zh --property=DeviceAllow='/dev/dri rw' --property=DeviceAllow='char-drm rwm' --property=DeviceAllow='/dev/shm rw' --property=DeviceAllow='char-input r'
# GPU
DeviceAllow=/dev/dri rw
DeviceAllow=char-drm rwm
DeviceAllow=/dev/shm rw
# Controller
DeviceAllow=char-input r
EOF


# Nvidia显卡专用绑定
NVIDIA_BIND=
if [[ $(lspci -k |egrep -A2 VGA\|3D) == *nvidia* ]]; then
NVIDIA_BIND=$(bash -c 'echo -e "
# NVIDIA
# 视情况而定
# 主机先装好N卡驱动，容器安装 lib 部分 nvidia-utils
# 容器运行 nvidia-smi 测试，如报错，则 strace 跟踪
# OpenGL 与 nvidia-smi
Bind = /dev/nvidia0
Bind = /dev/nvidiactl
# OpenCL 与 CUDA
Bind = /dev/nvidia-uvm
Bind = /dev/nvidia-uvm-tools
# Vulkan
Bind = /dev/nvidia-modeset
 "')


# 重写启动服务参数，授予访问权限
cat >> /etc/systemd/system/systemd-nspawn@debian.service.d/override.conf <<EOF
# NVIDIA
# nvidia-smi 需要
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia0 rw
# OpenCL 需要
DeviceAllow=/dev/nvidia-uvm rw
DeviceAllow=/dev/nvidia-uvm-tools rw
# Vulkan 需要
DeviceAllow=/dev/nvidia-modeset rw
EOF
fi


# 创建容器配置文件
[[ $(machinectl list) =~ debian ]] && machinectl stop debian
mkdir -p /etc/systemd/nspawn
cat > /etc/systemd/nspawn/debian.nspawn <<EOF
[Exec]
Boot = true
PrivateUsers = no

[Files]
# Xorg
BindReadOnly = /tmp/.X11-unix

# GPU
Bind = /dev/dri
Bind = /dev/shm
$(echo "$NVIDIA_BIND")
# Controller
Bind = /dev/input

# 其它
Bind = /home/share
Bind = /bin/debian-start:/bin/start

[Network]
VirtualEthernet = no
Private = no
EOF


# 查看配置
echo cat /etc/systemd/nspawn/debian.nspawn
cat /etc/systemd/nspawn/debian.nspawn
echo
echo cat /etc/systemd/system/systemd-nspawn@debian.service.d/override.conf
cat /etc/systemd/system/systemd-nspawn@debian.service.d/override.conf
echo


# 重新加载服务配置
systemctl daemon-reload


# 开机启动容器
sleep 0.3
[[ `cat /etc/os-release` == *Fedora* ]] && setenforce 0
machinectl enable debian
# systemctl cat systemd-nspawn@debian.service
machinectl start debian
machinectl list
machinectl show debian


# 配置容器权限与绑定
cat > /bin/debian-config <<EOF
#!/bin/bash

# 使容器与宿主机使用相同用户目录
machinectl shell debian /bin/bash -c "rm -f \$HOME && ln -sf /home/u\$UID \$HOME"

# PulseAudio && D-Bus && DConf
machinectl bind --read-only --mkdir debian \$XDG_RUNTIME_DIR/pulse
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir debian \$XDG_RUNTIME_DIR/pulse
machinectl bind --read-only --mkdir debian \$XDG_RUNTIME_DIR/bus
machinectl bind --mkdir debian \$XDG_RUNTIME_DIR/dconf
[[ \$(ls /tmp | grep dbus) ]] && machinectl bind --read-only --mkdir debian /tmp/\$(ls /tmp | grep dbus)

# 主目录
machinectl bind debian \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
[ \$? != 0 ] && echo error: machinectl bind --mkdir debian \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
machinectl bind --mkdir debian \$HOME/$USER_DOWNLOAD /home/u\$UID/$USER_DOWNLOAD
machinectl bind --mkdir debian \$HOME/$USER_DESKTOP /home/u\$UID/$USER_DESKTOP
machinectl bind --mkdir debian \$HOME/$USER_PICTURES /home/u\$UID/$USER_PICTURES
machinectl bind --mkdir debian \$HOME/$USER_VIDEOS /home/u\$UID/$USER_VIDEOS
machinectl bind --mkdir debian \$HOME/$USER_MUSIC /home/u\$UID/$USER_MUSIC
[ -d \$HOME/$USER_CLOUDDISK ] && machinectl bind --mkdir debian \$HOME/$USER_CLOUDDISK /home/u\$UID/$USER_CLOUDDISK
machinectl bind --mkdir debian \$HOME/.cache /home/u\$UID/.cache
machinectl bind --mkdir debian \$HOME/.config/user-dirs.dirs /home/u\$UID/.config/user-dirs.dirs
machinectl bind --mkdir debian \$HOME/.config/user-dirs.locale /home/u\$UID/.config/user-dirs.locale
machinectl bind --read-only --mkdir debian \$HOME/.local/share/fonts /home/u\$UID/.local/share/fonts
$(echo "$X11_BIND_AND_CONFIG")

# 启动环境变量
RUN_ENVIRONMENT="LANG=\$LANG DISPLAY=\$DISPLAY GTK_IM_MODULE=\$GTK_IM_MODULE XMODIFIERS=\$XMODIFIERS QT_IM_MODULE=\$QT_IM_MODULE"
if [[ \$(loginctl show-session \$(loginctl | grep \$USER |awk '{print \$1}') -p Type) == *wayland* ]]; then
    RUN_ENVIRONMENT="\$RUN_ENVIRONMENT XAUTHORITY=\$XAUTHORITY"
fi
EOF

chmod 755 /bin/debian-config
cat /bin/debian-config


# 查询应用
cat > /bin/debian-query <<EOF
machinectl shell debian /bin/su - u\$UID -c "ls /usr/share/applications \
    && echo && echo query inode/directory && xdg-mime query default inode/directory \
    && echo && echo query video/mp4 && xdg-mime query default video/mp4 \
    && echo && echo query audio/flac && xdg-mime query default audio/flac"
EOF

chmod 755 /bin/debian-query


# 清理缓存
cat > /bin/debian-clean <<EOF
for i in {1000..1005}; do
    machinectl shell debian /bin/bash -c "apt clean && rm -rf /home/u\$i/.deepinwine && du -hd1 /home/u\$i"
done
machinectl shell debian /bin/bash -c "apt clean && df -h && du -hd0 /opt /home /var /usr"
EOF

chmod 755 /bin/debian-clean



# 安装终端
cat > /bin/debian-install-terminal <<EOF
machinectl shell debian /usr/bin/bash -c "apt update && apt install -y xfce4-terminal && apt autopurge -y"
EOF

chmod 755 /bin/debian-install-terminal

# 启动终端
cat > /bin/debian-terminal <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/xfce4-terminal.desktop"
EOF

chmod 755 /bin/debian-terminal



# 安装QQ
cat > /bin/debian-install-qq <<EOF
machinectl shell debian /usr/bin/bash -c "[ ! -f /etc/apt/sources.list.d/deepin-wine.i-m.dev.list ] && apt install wget -y && wget -O- https://deepin-wine.i-m.dev/setup.sh | sh"
machinectl shell debian /usr/bin/bash -c "apt update && apt install -y com.qq.im.deepin && apt autopurge -y"
sudo cp -f /var/lib/machines/debian/opt/apps/com.qq.im.deepin/entries/icons/hicolor/64x64/apps/com.qq.im.deepin.svg /usr/share/pixmaps/
sudo bash -c 'cat > /usr/share/applications/deepin-qq.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
Categories=Network;
Icon=com.qq.im.deepin
Exec=debian-qq %F
Terminal=false
Name=QQ
Name[zh_CN]=QQ
Comment=Tencent QQ Client on Deepin Wine
StartupWMClass=QQ.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /bin/debian-install-qq

# 配置QQ
cat > /bin/debian-config-qq <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-QQ ~/.deepinwine/deepin-wine5/bin/winecfg"
EOF

chmod 755 /bin/debian-config-qq

# 启动QQ
cat > /bin/debian-qq <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.im.deepin/entries/applications/com.qq.im.deepin.desktop"
EOF

chmod 755 /bin/debian-qq



# 安装微信
cat > /bin/debian-install-weixin <<EOF
machinectl shell debian /usr/bin/bash -c "[ ! -f /etc/apt/sources.list.d/deepin-wine.i-m.dev.list ] && apt install wget -y && wget -O- https://deepin-wine.i-m.dev/setup.sh | sh"
machinectl shell debian /usr/bin/bash -c "apt update && apt install -y com.qq.weixin.deepin x11-utils && apt autopurge -y"
sudo cp -f /var/lib/machines/debian/opt/apps/com.qq.weixin.deepin/entries/icons/hicolor/64x64/apps/com.qq.weixin.deepin.svg /usr/share/pixmaps/
sudo bash -c 'cat > /usr/share/applications/deepin-weixin.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
X-Created-By=Deepin WINE Team
Categories=Network;
Icon=com.qq.weixin.deepin
Exec=debian-weixin %F
Terminal=false
Name=WeChat
Name[zh_CN]=微信
Comment=Tencent WeChat Client on Deepin Wine
StartupWMClass=WeChat.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /bin/debian-install-weixin

# 启动微信
cat > /bin/debian-weixin <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.weixin.deepin/entries/applications/com.qq.weixin.deepin.desktop"
EOF

chmod 755 /bin/debian-weixin



# 配置云盘
cat > /bin/debian-config-ecloud <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-eCloud/ ~/.deepinwine/deepin-wine5/bin/regedit ~/$USER_CLOUDDISK/丽娜/原创/ecloud.reg"
EOF

chmod 755 /bin/debian-config-ecloud

# 启动云盘
cat > /bin/debian-ecloud <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/cn.189.cloud.deepin/entries/applications/cn.189.cloud.deepin.desktop"
EOF

chmod 755 /bin/debian-ecloud



# 安装文件管理器
cat > /bin/debian-install-thunar <<EOF
machinectl shell debian /usr/bin/bash -c "apt update && apt install -y thunar catfish dbus-x11 xdg-utils --no-install-recommends && apt autopurge -y"
machinectl shell debian /bin/su - u\$UID -c "xdg-mime default Thunar.desktop inode/directory"
EOF

chmod 755 /bin/debian-install-thunar

# 启动文件管理器
cat > /bin/debian-thunar <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/Thunar.desktop"
EOF

chmod 755 /bin/debian-thunar



# 安装MPV
cat > /bin/debian-install-mpv <<EOF
machinectl shell debian /usr/bin/bash -c "apt update && apt install -y mpv --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /bin/debian-install-mpv

# 启动MPV
cat > /bin/debian-mpv <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/mpv.desktop"
EOF

chmod 755 /bin/debian-mpv
