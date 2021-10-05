#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 允许无管理员权限启动
source `dirname ${BASH_SOURCE[0]}`/polkit.sh


# 必备软件包
[ -f /bin/apt ] && [ ! -f /bin/machinectl ] && apt install -y systemd-container
[ -f /bin/dnf ] && [ ! -f /bin/machinectl ] && dnf install -y systemd-container
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` != *wayland* ]]; then
    [ -f /bin/pacman ] && [ ! -f /bin/xhost ] && pacman -S xorg-xhost --noconfirm --needed
    [ -f /bin/apt ] && [ ! -f /bin/xhost ] && apt install -y x11-xserver-utils
    [ -f /bin/dnf ] && [ ! -f /bin/xhost ] && dnf install -y xhost
fi


# 初始化配置
ln -sf /home/$SUDO_USER/.machines/$1 /var/lib/machines
[ -f "/bin/$1-distro-info" ] && mv /bin/$1-distro-info /bin/bak-$1-distro-info
rm -f /bin/$1-*
[ -f "/bin/bak-$1-distro-info" ] && mv /bin/bak-$1-distro-info /bin/$1-distro-info


# 获取用户目录
source `dirname ${BASH_SOURCE[0]}`/user-dirs.sh


# 配置容器
[[ $(machinectl list) =~ $1 ]] && machinectl stop $1
mkdir -p /home/share && chmod 777 /home/share
cat > /var/lib/machines/$1/config.sh <<EOF
[[ ! \$(cat /etc/hosts | grep \$HOSTNAME) ]] && echo "127.0.0.1 \$HOSTNAME" >> /etc/hosts
/bin/sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
/bin/sed -i 's/# zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen
/sbin/locale-gen
locale
$(echo -e "$SOURCES_LIST")
[[ ! \$(cat /etc/securetty | grep pts/0) ]] && echo -e "\n# systemd-container\npts/0\npts/1\npts/2\npts/3\npts/4\npts/5\npts/6\n" >> /etc/securetty
[[ ! \$(cat /etc/securetty | grep pts/9) ]] && echo -e "pts/7\npts/8\npts/9\n" >> /etc/securetty
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
for i in {1000..1005}; do
    [[ ! \$(groups u\$i | grep audio) ]] && adduser u\$i audio
done
EOF

chroot /var/lib/machines/$1/ /bin/bash /config.sh


# 禁用MIT-SHM
sleep 0.1
source `dirname ${BASH_SOURCE[0]}`/xnoshm.sh $1


# 配置启动环境变量
DESKTOP_ENVIRONMENT=
X11_BIND_AND_CONFIG=
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` == *wayland* ]]; then
X11_BIND_AND_CONFIG="# Xauthority
machinectl bind --read-only --mkdir $1 \$XAUTHORITY
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XAUTHORITY"
else
X11_BIND_AND_CONFIG="# Xauthority
machinectl bind --read-only --mkdir $1 \$XAUTHORITY /home/u\$UID/.Xauthority
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XAUTHORITY /home/u\$UID/.Xauthority
xhost +local:"
DESKTOP_ENVIRONMENT="export XAUTHORITY=/home/u\$UID/.Xauthority"
fi
cat > /bin/$1-start  <<EOF
#!/bin/bash
$(echo "$DESKTOP_ENVIRONMENT")
export XDG_RUNTIME_DIR=/run/user/\$UID
export PULSE_SERVER=unix:\$XDG_RUNTIME_DIR/pulse/native
$(echo "$DISABLE_MITSHM")
dex \$@
EOF

chmod 755 /bin/$1-start
echo cat /bin/$1-start
cat /bin/$1-start


# 调试
cat > /bin/systemd-nspawn-debug <<EOF
#!/bin/bash
export NSPAWN_LOG_FILE=/home/nspawn.log
touch \$NSPAWN_LOG_FILE
echo \$(date) \$NSPAWN_LOG_FILE >> \$NSPAWN_LOG_FILE
echo -e "tree -L 2 /run/user \n" "\$(tree -L 2 /run/user)" >> \$NSPAWN_LOG_FILE
echo -e "env \n" "\$(env)" \n >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/dri " "\$(ls /dev/dri)" \n >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/shm " "\$(ls /dev/shm)" \n >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/snd " "\$(ls /dev/snd)" \n >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/fuse " "\$(ls /dev/fuse)" \n >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/nvidia* " "\$(ls /dev/nvidia*)" \n >> \$NSPAWN_LOG_FILE
echo -e "echo /tmp " "\$(ls /tmp)" \n >> \$NSPAWN_LOG_FILE
chmod 777 \$NSPAWN_LOG_FILE
EOF

chmod 755 /bin/systemd-nspawn-debug
cat /bin/systemd-nspawn-debug


# 重写启动服务参数
rm -rf /etc/systemd/system/systemd-nspawn@$1.service.d
mkdir -p /etc/systemd/system/systemd-nspawn@$1.service.d
cat > /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf <<EOF
[Unit]
After=systemd-hostnamed.service
[Service]
ExecStartPost=systemd-nspawn-debug
ExecStart=
ExecStart=systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth -U --settings=override --machine=%i --setenv=LANGUAGE=zh_CN:zh --property=DeviceAllow='/dev/dri rw' --property=DeviceAllow='/dev/snd rw' --property=DeviceAllow='char-drm rwm' --property=DeviceAllow='/dev/shm rw' --property=DeviceAllow='char-input r'
# GPU etc.
DeviceAllow=/dev/dri rw
DeviceAllow=/dev/snd rw
DeviceAllow=char-drm rwm
DeviceAllow=/dev/shm rw
DeviceAllow=char-input r
DeviceAllow=/dev/fuse rw
EOF


# Nvidia显卡专用绑定
NVIDIA_BIND=
if [[ $(lspci -k |egrep -A2 VGA\|3D) == *nvidia* ]]; then
NVIDIA_BIND="
# NVIDIA
# 视情况而定
# 主机先装好N卡驱动，容器安装 lib 部分 nvidia-utils
# 容器运行 nvidia-smi 测试，如报错，则 strace 跟踪
# OpenGL 与 nvidia-smi
Bind = /dev/nvidia0
Bind = /dev/nvidiactl
# Vulkan
Bind = /dev/nvidia-modeset"
$([[ $(lsmod | grep nvidia_uvm) ]] && echo \# OpenCL 与 CUDA)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo Bind = /dev/nvidia-uvm)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo Bind = /dev/nvidia-uvm-tools)


# 重写启动服务参数，授予访问权限
cat >> /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf <<EOF
# NVIDIA
# nvidia-smi 需要
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia0 rw
# Vulkan 需要
DeviceAllow=/dev/nvidia-modeset rw
$([[ $(lsmod | grep nvidia_uvm) ]] && echo \# OpenCL 需要)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo DeviceAllow=/dev/nvidia-uvm rw)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo DeviceAllow=/dev/nvidia-uvm-tools rw)
EOF
fi


# 创建容器配置文件
[[ $(machinectl list) =~ $1 ]] && machinectl stop $1
mkdir -p /etc/systemd/nspawn
cat > /etc/systemd/nspawn/$1.nspawn <<EOF
[Exec]
Boot = true
PrivateUsers = no

[Files]
# Xorg
BindReadOnly = /tmp/.X11-unix

# GPU etc.
Bind = /dev/dri
Bind = /dev/snd
Bind = /dev/shm
Bind = /dev/input
Bind = /dev/fuse
$(echo "$NVIDIA_BIND")

# 其它
Bind = /home/share
Bind = /bin/$1-start:/bin/start

[Network]
VirtualEthernet = no
Private = no
EOF


# 查看配置
echo cat /etc/systemd/nspawn/$1.nspawn
cat /etc/systemd/nspawn/$1.nspawn
echo
echo cat /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf
cat /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf
echo


# 重新加载服务配置
systemctl daemon-reload


# 开机启动容器
sleep 0.3
[[ `cat /etc/os-release` == *Fedora* ]] && setenforce 0
machinectl enable $1
# systemctl cat systemd-nspawn@$1.service
machinectl start $1
machinectl list
machinectl show $1


# 配置容器权限与绑定
cat > /bin/$1-config <<EOF
#!/bin/bash

# 判断容器是否启动
[[ ! \$(machinectl list | grep $1) ]] && machinectl start $1 && sleep 0.3

# 使容器与宿主机使用相同用户目录
machinectl shell $1 /bin/bash -c "rm -f \$HOME && ln -sf /home/u\$UID \$HOME"

# PulseAudio && D-Bus && DConf
machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/pulse
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/pulse
machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/bus
machinectl bind --mkdir $1 \$XDG_RUNTIME_DIR/dconf
[[ \$(ls /tmp | grep dbus) ]] && machinectl bind --read-only --mkdir $1 /tmp/\$(ls /tmp | grep dbus)

# 主目录
machinectl bind $1 \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
[ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
machinectl bind --mkdir $1 \$HOME/$USER_DOWNLOAD /home/u\$UID/$USER_DOWNLOAD
machinectl bind --mkdir $1 \$HOME/$USER_DESKTOP /home/u\$UID/$USER_DESKTOP
machinectl bind --mkdir $1 \$HOME/$USER_PICTURES /home/u\$UID/$USER_PICTURES
machinectl bind --mkdir $1 \$HOME/$USER_VIDEOS /home/u\$UID/$USER_VIDEOS
machinectl bind --mkdir $1 \$HOME/$USER_MUSIC /home/u\$UID/$USER_MUSIC
[ -d \$HOME/$USER_CLOUDDISK ] && machinectl bind --mkdir $1 \$HOME/$USER_CLOUDDISK /home/u\$UID/$USER_CLOUDDISK
machinectl bind --mkdir $1 \$HOME/.cache /home/u\$UID/.cache
machinectl bind --mkdir $1 \$HOME/.config/user-dirs.dirs /home/u\$UID/.config/user-dirs.dirs
machinectl bind --mkdir $1 \$HOME/.config/user-dirs.locale /home/u\$UID/.config/user-dirs.locale
machinectl bind --read-only --mkdir $1 \$HOME/.local/share/fonts /home/u\$UID/.local/share/fonts
$(echo "$X11_BIND_AND_CONFIG")

# 启动环境变量
RUN_ENVIRONMENT="LANG=\$LANG DISPLAY=\$DISPLAY GTK_IM_MODULE=\$GTK_IM_MODULE XMODIFIERS=\$XMODIFIERS QT_IM_MODULE=\$QT_IM_MODULE BROWSER=Thunar"
if [[ \$(loginctl show-session \$(loginctl | grep \$USER |awk '{print \$1}') -p Type) == *wayland* ]]; then
    RUN_ENVIRONMENT="\$RUN_ENVIRONMENT XAUTHORITY=\$XAUTHORITY"
fi
EOF

chmod 755 /bin/$1-config
cat /bin/$1-config


# 查询应用
cat > /bin/$1-query <<EOF
#!/bin/bash
if [ \$USER == root ]; then QUERY_USER=u\$SUDO_UID; else QUERY_USER=u\$UID; fi
machinectl shell $1 /bin/su - \$QUERY_USER -c "$(echo "$DISABLE_MITSHM") && ls /usr/share/applications \
    && find /opt -name "*.desktop" \
    && echo && echo query inode/directory && xdg-mime query default inode/directory \
    && echo query video/mp4 && xdg-mime query default video/mp4 \
    && echo query audio/flac && xdg-mime query default audio/flac \
    && echo && echo ldd /bin/bash && ldd /bin/bash | grep SHM \
    && echo ldd /bin/xterm && ldd /bin/xterm | grep SHM"
EOF

chmod 755 /bin/$1-query


# 清理缓存
cat > /bin/$1-clean <<EOF
#!/bin/bash
for i in {1000..1005}; do
    machinectl shell $1 /bin/bash -c "apt clean && rm -rf /home/u\$i/.deepinwine && du -hd1 /home/u\$i"
done
machinectl shell $1 /bin/bash -c "apt clean && df -h && du -hd0 /opt /home /var /usr"
EOF

chmod 755 /bin/$1-clean



# 安装QQ
cat > /bin/$1-install-qq <<EOF
#!/bin/bash
$(echo -e "$INSTALL_QQ")
sudo cp -f /var/lib/machines/$1/opt/apps/com.qq.im.deepin/entries/icons/hicolor/64x64/apps/com.qq.im.deepin.svg /usr/share/pixmaps/
sudo bash -c 'cat > /usr/share/applications/deepin-qq.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
Categories=Network;
Icon=com.qq.im.deepin
Exec=$1-qq %F
Terminal=false
Name=QQ
Name[zh_CN]=QQ
Comment=Tencent QQ Client on Deepin Wine
StartupWMClass=QQ.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /bin/$1-install-qq

# 配置QQ
cat > /bin/$1-config-qq <<EOF
#!/bin/bash
source /bin/$1-config
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-QQ ~/.deepinwine/deepin-wine5/bin/winecfg"
EOF

chmod 755 /bin/$1-config-qq

# 启动QQ
cat > /bin/$1-qq <<EOF
#!/bin/bash
source /bin/$1-config
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.im.deepin/entries/applications/com.qq.im.deepin.desktop"
EOF

chmod 755 /bin/$1-qq



# 安装微信
cat > /bin/$1-install-weixin <<EOF
#!/bin/bash
$(echo -e "$INSTALL_WEIXIN")
sudo cp -f /var/lib/machines/$1/opt/apps/com.qq.weixin.deepin/entries/icons/hicolor/64x64/apps/com.qq.weixin.deepin.svg /usr/share/pixmaps/
sudo bash -c 'cat > /usr/share/applications/deepin-weixin.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
X-Created-By=Deepin WINE Team
Categories=Network;
Icon=com.qq.weixin.deepin
Exec=$1-weixin %F
Terminal=false
Name=WeChat
Name[zh_CN]=微信
Comment=Tencent WeChat Client on Deepin Wine
StartupWMClass=WeChat.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /bin/$1-install-weixin

# 启动微信
cat > /bin/$1-weixin <<EOF
#!/bin/bash
source /bin/$1-config
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.weixin.deepin/entries/applications/com.qq.weixin.deepin.desktop"
EOF

chmod 755 /bin/$1-weixin



# 配置云盘
cat > /bin/$1-config-ecloud <<EOF
#!/bin/bash
source /bin/$1-config
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-eCloud/ ~/.deepinwine/deepin-wine5/bin/regedit ~/$USER_CLOUDDISK/丽娜/原创/ecloud.reg"
EOF

chmod 755 /bin/$1-config-ecloud

# 启动云盘
cat > /bin/$1-ecloud <<EOF
#!/bin/bash
source /bin/$1-config
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/cn.189.cloud.deepin/entries/applications/cn.189.cloud.deepin.desktop"
EOF

chmod 755 /bin/$1-ecloud



# 安装文件管理器
cat > /bin/$1-install-thunar <<EOF
#!/bin/bash
machinectl shell $1 /usr/bin/bash -c "apt update && apt install -y thunar thunar-archive-plugin libexo-1-0 catfish mousepad dbus-x11 xdg-utils --no-install-recommends && apt autopurge -y"
if [ \$USER == root ]; then INSTALL_USER=u\$SUDO_UID; else INSTALL_USER=u\$UID; fi
machinectl shell $1 /bin/su - \$INSTALL_USER -c "xdg-mime default Thunar.desktop inode/directory"
EOF

chmod 755 /bin/$1-install-thunar

# 启动文件管理器
cat > /bin/$1-thunar <<EOF
#!/bin/bash
source /bin/$1-config
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/Thunar.desktop"
EOF

chmod 755 /bin/$1-thunar



# 安装MPV
cat > /bin/$1-install-mpv <<EOF
#!/bin/bash
machinectl shell $1 /usr/bin/bash -c "apt update && apt install -y mpv --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /bin/$1-install-mpv

# 启动MPV
cat > /bin/$1-mpv <<EOF
#!/bin/bash
source /bin/$1-config
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/mpv.desktop"
EOF

chmod 755 /bin/$1-mpv



# 安装Flatpak
cat > /bin/$1-install-flatpak <<EOF
#!/bin/bash
machinectl shell $1 /usr/bin/bash -c "apt update && apt install -y flatpak && apt autopurge -y"
EOF

chmod 755 /bin/$1-install-flatpak



# 添加启动器
machinectl start $1 && sleep 0.3
[[ $($1-query | grep com.qq.im.deepin.desktop) ]] && [ ! -f /usr/share/applications/deepin-qq.desktop ] && $1-install-qq
[[ $($1-query | grep com.qq.weixin.deepin.desktop) ]] && [ ! -f /usr/share/applications/deepin-weixin.desktop ] && $1-install-weixin
[ -f /usr/share/applications/deepin-qq.desktop ] && cat /usr/share/applications/deepin-qq.desktop | grep $1-
[ -f /usr/share/applications/deepin-weixin.desktop ] && cat /usr/share/applications/deepin-weixin.desktop | grep $1-

# 开机启动
[[ $(systemctl status machines.target | grep 'machines.target; disabled;') ]] && systemctl enable machines.target
