#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 允许无管理员权限启动
source `dirname ${BASH_SOURCE[0]}`/nspawn-polkit.sh


# 必备软件包
[ -f /bin/apt ] && [ ! -f /bin/machinectl ] && apt install -y systemd-container
[ -f /bin/dnf ] && [ ! -f /bin/machinectl ] && dnf install -y systemd-container
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $1}') -p Type` != *wayland* ]]; then
    [ -f /bin/pacman ] && [ ! -f /bin/xhost ] && pacman -S xorg-xhost --noconfirm --needed
    [ -f /bin/apt ] && [ ! -f /bin/xhost ] && apt install -y x11-xserver-utils
    [ -f /bin/dnf ] && [ ! -f /bin/xhost ] && dnf install -y xhost
fi


# 初始化配置
[ -f /bin/pacman ] && [ ! -f /bin/xhost ] && pacman -S xorg-xhost --noconfirm --needed
ln -sf /home/$SUDO_USER/.machines/deepin /var/lib/machines
rm -f /bin/deepin-*


# 获取用户目录
source `dirname ${BASH_SOURCE[0]}`/user-dirs.sh


# 配置容器
[[ $(machinectl list) =~ deepin ]] && machinectl stop deepin
mkdir -p /home/share && chmod 777 /home/share
cat > /var/lib/machines/deepin/config.sh <<EOF
[[ ! \$(cat /etc/hosts | grep \$HOSTNAME) ]] && echo "127.0.0.1 \$HOSTNAME" >> /etc/hosts
/bin/sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
/bin/sed -i 's/# zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen
/sbin/locale-gen
locale
echo "deb [by-hash=force] https://community-packages.deepin.com/deepin/ apricot main contrib non-free" > /etc/apt/sources.list
echo "deb https://com-store-packages.uniontech.com/appstore deepin appstore" > /etc/apt/sources.list.d/appstore.list
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

chroot /var/lib/machines/deepin/ /bin/bash /config.sh


# 禁用MIT-SHM
source `dirname ${BASH_SOURCE[0]}`/xnoshm.sh deepin


# 配置启动环境变量
DESKTOP_ENVIRONMENT=
X11_BIND_AND_CONFIG=
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $1}') -p Type` == *wayland* ]]; then
X11_BIND_AND_CONFIG=$(bash -c 'echo -e "
# Xauthority
machinectl bind --read-only --mkdir deepin \$XAUTHORITY
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir deepin \$XAUTHORITY
"')
else
X11_BIND_AND_CONFIG=$(bash -c 'echo -e "
# Xauthority
machinectl bind --read-only --mkdir deepin \$XAUTHORITY /home/u\$UID/.Xauthority
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir deepin \$XAUTHORITY /home/u\$UID/.Xauthority
xhost +local:
"')
DESKTOP_ENVIRONMENT=$(bash -c 'echo -e "export XAUTHORITY=/home/u\$UID/.Xauthority"')
fi
cat > /bin/deepin-start  <<EOF
#!/bin/bash
$(echo "$DESKTOP_ENVIRONMENT")
export XDG_RUNTIME_DIR=/run/user/\$UID
export PULSE_SERVER=unix:\$XDG_RUNTIME_DIR/pulse/native
$(echo "$DISABLE_MITSHM")
dex \$@
EOF

chmod 755 /bin/deepin-start
echo cat /bin/deepin-start
cat /bin/deepin-start


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
rm -rf /etc/systemd/system/systemd-nspawn@deepin.service.d
mkdir -p /etc/systemd/system/systemd-nspawn@deepin.service.d
cat > /etc/systemd/system/systemd-nspawn@deepin.service.d/override.conf <<EOF
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
$([[ $(lsmod | grep nvidia_uvm) ]] && echo Bind = /dev/nvidia-uvm)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo Bind = /dev/nvidia-uvm-tools)
# Vulkan
Bind = /dev/nvidia-modeset
 "')


# 重写启动服务参数，授予访问权限
cat >> /etc/systemd/system/systemd-nspawn@deepin.service.d/override.conf <<EOF
# NVIDIA
# nvidia-smi 需要
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia0 rw
# OpenCL 需要
$([[ $(lsmod | grep nvidia_uvm) ]] && echo DeviceAllow=/dev/nvidia-uvm rw)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo DeviceAllow=/dev/nvidia-uvm-tools rw)
# Vulkan 需要
DeviceAllow=/dev/nvidia-modeset rw
EOF
fi


# 创建容器配置文件
[[ $(machinectl list) =~ deepin ]] && machinectl stop deepin
mkdir -p /etc/systemd/nspawn
cat > /etc/systemd/nspawn/deepin.nspawn <<EOF
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
Bind = /bin/deepin-start:/bin/start

[Network]
VirtualEthernet = no
Private = no
EOF


# 查看配置
echo cat /etc/systemd/nspawn/deepin.nspawn
cat /etc/systemd/nspawn/deepin.nspawn
echo
echo cat /etc/systemd/system/systemd-nspawn@deepin.service.d/override.conf
cat /etc/systemd/system/systemd-nspawn@deepin.service.d/override.conf
echo


# 重新加载服务配置
systemctl daemon-reload


# 开机启动容器
sleep 0.3
[[ `cat /etc/os-release` == *Fedora* ]] && setenforce 0
machinectl enable deepin
# systemctl cat systemd-nspawn@deepin.service
machinectl start deepin
machinectl list
machinectl show deepin


# 配置容器权限与绑定
cat > /bin/deepin-config <<EOF
#!/bin/bash

# 使容器与宿主机使用相同用户目录
machinectl shell deepin /bin/bash -c "rm -f \$HOME && ln -sf /home/u\$UID \$HOME"

# PulseAudio && D-Bus && DConf
machinectl bind --read-only --mkdir deepin \$XDG_RUNTIME_DIR/pulse
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir deepin \$XDG_RUNTIME_DIR/pulse
machinectl bind --read-only --mkdir deepin \$XDG_RUNTIME_DIR/bus
machinectl bind --mkdir deepin \$XDG_RUNTIME_DIR/dconf
[[ \$(ls /tmp | grep dbus) ]] && machinectl bind --read-only --mkdir deepin /tmp/\$(ls /tmp | grep dbus)

# 主目录
machinectl bind --mkdir deepin \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
[ \$? != 0 ] && echo error: machinectl bind --mkdir deepin \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
machinectl bind --mkdir deepin \$HOME/$USER_DOWNLOAD /home/u\$UID/$USER_DOWNLOAD
machinectl bind --mkdir deepin \$HOME/$USER_DESKTOP /home/u\$UID/$USER_DESKTOP
machinectl bind --mkdir deepin \$HOME/$USER_PICTURES /home/u\$UID/$USER_PICTURES
machinectl bind --mkdir deepin \$HOME/$USER_VIDEOS /home/u\$UID/$USER_VIDEOS
machinectl bind --mkdir deepin \$HOME/$USER_MUSIC /home/u\$UID/$USER_MUSIC
[ -d \$HOME/$USER_CLOUDDISK ] && machinectl bind --mkdir deepin \$HOME/$USER_CLOUDDISK /home/u\$UID/$USER_CLOUDDISK
machinectl bind --mkdir deepin \$HOME/.cache /home/u\$UID/.cache
machinectl bind --mkdir deepin \$HOME/.config/user-dirs.dirs /home/u\$UID/.config/user-dirs.dirs
machinectl bind --mkdir deepin \$HOME/.config/user-dirs.locale /home/u\$UID/.config/user-dirs.locale
machinectl bind --read-only --mkdir deepin \$HOME/.local/share/fonts /home/u\$UID/.local/share/fonts
$(echo "$X11_BIND_AND_CONFIG")

# 启动环境变量
RUN_ENVIRONMENT="LANG=\$LANG DISPLAY=\$DISPLAY GTK_IM_MODULE=\$GTK_IM_MODULE XMODIFIERS=\$XMODIFIERS QT_IM_MODULE=\$QT_IM_MODULE"
if [[ \$(loginctl show-session \$(loginctl | grep \$USER |awk '{print \$1}') -p Type) == *wayland* ]]; then
    RUN_ENVIRONMENT="\$RUN_ENVIRONMENT XAUTHORITY=\$XAUTHORITY"
fi
EOF

chmod 755 /bin/deepin-config
cat /bin/deepin-config


# 查询应用
cat > /bin/deepin-query <<EOF
machinectl shell deepin /bin/su - u\$UID -c "ls /usr/share/applications \
    && find /opt -name "*.desktop" \
    && echo && echo query inode/directory && xdg-mime query default inode/directory \
    && echo && echo query video/mp4 && xdg-mime query default video/mp4 \
    && echo && echo query audio/flac && xdg-mime query default audio/flac"
EOF

chmod 755 /bin/deepin-query


# 清理缓存
cat > /bin/deepin-clean <<EOF
for i in {1000..1005}; do
    machinectl shell deepin /bin/bash -c "apt clean && rm -rf /home/u\$i/.deepinwine && du -hd1 /home/u\$i"
done
machinectl shell deepin /bin/bash -c "apt clean && df -h && du -hd0 /opt /home /var /usr"
EOF

chmod 755 /bin/deepin-clean



# 安装终端
cat > /bin/deepin-install-terminal <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y lxterminal && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-terminal

# 启动终端
cat > /bin/deepin-terminal <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/lxterminal.desktop"
EOF

chmod 755 /bin/deepin-terminal



# 安装QQ
cat > /bin/deepin-install-qq <<EOF
machinectl shell deepin /usr/bin/bash -c "dpkg --add-architecture i386 && apt update && apt install -y com.qq.im.deepin && apt autopurge -y"
sudo cp -f /var/lib/machines/deepin/opt/apps/com.qq.im.deepin/entries/icons/hicolor/64x64/apps/com.qq.im.deepin.svg /usr/share/pixmaps/
sudo bash -c 'cat > /usr/share/applications/deepin-qq.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
Categories=Network;
Icon=com.qq.im.deepin
Exec=deepin-qq %F
Terminal=false
Name=QQ
Name[zh_CN]=QQ
Comment=Tencent QQ Client on Deepin Wine
StartupWMClass=QQ.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /bin/deepin-install-qq

# 配置QQ
cat > /bin/deepin-config-qq <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-QQ ~/.deepinwine/deepin-wine5/bin/winecfg"
EOF

chmod 755 /bin/deepin-config-qq

# 启动QQ
cat > /bin/deepin-qq <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.im.deepin/entries/applications/com.qq.im.deepin.desktop"
EOF

chmod 755 /bin/deepin-qq



# 安装微信
cat > /bin/deepin-install-weixin <<EOF
machinectl shell deepin /usr/bin/bash -c "dpkg --add-architecture i386 && apt update && apt install -y com.qq.weixin.deepin x11-utils && apt autopurge -y"
sudo cp -f /var/lib/machines/deepin/opt/apps/com.qq.weixin.deepin/entries/icons/hicolor/64x64/apps/com.qq.weixin.deepin.svg /usr/share/pixmaps/
sudo bash -c 'cat > /usr/share/applications/deepin-weixin.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
X-Created-By=Deepin WINE Team
Categories=Network;
Icon=com.qq.weixin.deepin
Exec=deepin-weixin %F
Terminal=false
Name=WeChat
Name[zh_CN]=微信
Comment=Tencent WeChat Client on Deepin Wine
StartupWMClass=WeChat.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /bin/deepin-install-weixin

# 启动微信
cat > /bin/deepin-weixin <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.weixin.deepin/entries/applications/com.qq.weixin.deepin.desktop"
EOF

chmod 755 /bin/deepin-weixin



# 配置云盘
cat > /bin/deepin-config-ecloud <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-eCloud/ ~/.deepinwine/deepin-wine5/bin/regedit ~/$USER_CLOUDDISK/丽娜/原创/ecloud.reg"
EOF

chmod 755 /bin/deepin-config-ecloud

# 启动云盘
cat > /bin/deepin-ecloud <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/cn.189.cloud.deepin/entries/applications/cn.189.cloud.deepin.desktop"
EOF

chmod 755 /bin/deepin-ecloud



# 安装文件管理器
cat > /bin/deepin-install-thunar <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y thunar catfish dbus-x11 xdg-utils --no-install-recommends && apt autopurge -y"
machinectl shell deepin /bin/su - u\$UID -c "xdg-mime default Thunar.desktop inode/directory"
EOF

chmod 755 /bin/deepin-install-thunar

# 启动文件管理器
cat > /bin/deepin-thunar <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/Thunar.desktop"
EOF

chmod 755 /bin/deepin-thunar



# 安装商店
cat > /bin/deepin-install-app-store <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y deepin-app-store && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-app-store

# 启动深度商店
cat > /bin/deepin-app-store <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/deepin-app-store.desktop"
EOF

chmod 755 /bin/deepin-app-store



# 安装腾讯会议
cat > /bin/deepin-install-wemeet <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y com.qq.wemeet libgl1-mesa-dev && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-wemeet

# 启动腾讯会议
cat > /bin/deepin-wemeet <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.wemeet/entries/applications/com.qq.wemeet.desktop"
EOF

chmod 755 /bin/deepin-wemeet



# 安装迅雷
cat > /bin/deepin-install-xunlei <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y com.xunlei.download libxss1 libdbus-glib-1-2 && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-xunlei

# 启动迅雷
cat > /bin/deepin-xunlei <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.xunlei.download/entries/applications/com.xunlei.download.desktop"
EOF

chmod 755 /bin/deepin-xunlei



# 安装MPV
cat > /bin/deepin-install-mpv <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y mpv --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-mpv

# 启动MPV
cat > /bin/deepin-mpv <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/mpv.desktop"
EOF

chmod 755 /bin/deepin-mpv



# 添加启动器
[[ $(deepin-query | grep com.qq.im.deepin.desktop) ]] && [ ! -f /usr/share/applications/deepin-qq.desktop ] && deepin-install-qq
[[ $(deepin-query | grep com.qq.weixin.deepin.desktop) ]] && [ ! -f /usr/share/applications/deepin-weixin.desktop ] && deepin-install-weixin
