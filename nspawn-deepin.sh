#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o ”$SUDO_USER“ == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 允许无管理员权限启动
source `dirname ${BASH_SOURCE[0]}`/nspawn-polkit.sh


# 创建容器
apt install -y systemd-container debootstrap
mkdir -p /home/$SUDO_USER/.machines/deepin
ln -sf /home/$SUDO_USER/.machines/deepin /var/lib/machines
ln -sf /usr/share/debootstrap/scripts/stable /usr/share/debootstrap/scripts/apricot
debootstrap --include=systemd-container,dex,sudo,locales,dialog,fonts-noto-core,fonts-noto-cjk,neofetch,pulseaudio,bash-completion --no-check-gpg apricot /var/lib/machines/deepin https://community-packages.deepin.com/deepin



# 配置容器
[[ $(machinectl list) =~ deepin ]] && machinectl stop deepin
mkdir -p /home/share && chmod 777 /home/share
cat > /var/lib/machines/deepin/config.sh <<EOF
echo -e 'Section "Extensions"
    Option "MIT-SHM" "Disable"
EndSection' > /etc/X11/xorg.conf
[[ ! \$(cat /etc/hosts | grep \$HOSTNAME) ]] && echo "127.0.0.1 \$HOSTNAME" >> /etc/hosts
/usr/sbin/dpkg-reconfigure locales
locale
echo "deb [by-hash=force] https://community-packages.deepin.com/deepin/ apricot main contrib non-free" > /etc/apt/sources.list
echo "deb https://com-store-packages.uniontech.com/appstore deepin appstore" > /etc/apt/sources.list.d/appstore.list
mkdir -p /home/share && chmod 777 /home/share
/usr/bin/id -u user > /dev/null 2>&1
[ "$?" == "0" ] && /usr/sbin/userdel -r user
for i in {1000..1005}; do
    /usr/bin/id -u u\$i > /dev/null 2>&1
    [ "$?" == "0" ] && /usr/sbin/userdel -r u\$i
    /usr/sbin/useradd -u \$i -m -s /bin/bash -G sudo u\$i
    echo u\$i:passwd | /usr/sbin/chpasswd
    cd /home/u\$i/
    mkdir -p .local/share/fonts .config .cache 文档 下载 桌面 图片 视频 音乐 云盘
    chown -R u\$i:u\$i .local .config .cache 文档 下载 桌面 图片 视频 音乐 云盘
done
EOF

chroot /var/lib/machines/deepin/ /bin/bash /config.sh



# 配置启动环境变量
DESKTOP_ENVIRONMENT=
X11_BIND_AND_CONFIG=
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $1}') -p Type` == *wayland* ]]; then
DESKTOP_ENVIRONMENT=$(bash -c 'echo -e "export QT_X11_NO_MITSHM=1"')
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
export GTK_IM_MOUDLE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MOUDLE=ibus
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
ExecStart=systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth -U --settings=override --machine=%i --drop-capability=CAP_IPC_OWNER --setenv=LANGUAGE=zh_CN:zh --property=DeviceAllow='/dev/dri rw' --property=DeviceAllow='char-drm rwm' --property=DeviceAllow='char-input r'
# GPU
DeviceAllow=/dev/dri rw
DeviceAllow=char-drm rwm
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
Bind = /dev/shm
"')


# 重写启动服务参数，授予访问权限
cat >> /etc/systemd/system/systemd-nspawn@deepin.service.d/override.conf <<EOF
# NVIDIA
# nvidia-smi 需要
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia0 rw
# OpenCL 需要
DeviceAllow=/dev/nvidia-uvm rw
DeviceAllow=/dev/nvidia-uvm-tools rw
# Vulkan 需要
DeviceAllow=/dev/nvidia-modeset rw
DeviceAllow=/dev/shm rw
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
# cat /etc/systemd/system/machines.target.wants/systemd-nspawn@deepin.service
machinectl start deepin
machinectl list
machinectl show deepin


# 配置容器权限与绑定
cat > /bin/deepin-config <<EOF
#!/bin/bash

# PulseAudio && D-Bus && DConf
machinectl bind --read-only --mkdir deepin \$XDG_RUNTIME_DIR/pulse
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir deepin \$XDG_RUNTIME_DIR/pulse
machinectl bind --read-only --mkdir deepin \$XDG_RUNTIME_DIR/bus
machinectl bind --mkdir deepin \$XDG_RUNTIME_DIR/dconf
[[ \$(ls /tmp | grep dbus) ]] && machinectl bind --read-only --mkdir deepin /tmp/\$(ls /tmp | grep dbus)

# 主目录
machinectl bind --mkdir deepin \$HOME/文档 /home/u\$UID/文档
[ \$? != 0 ] && echo error: machinectl bind --mkdir deepin \$HOME/文档 /home/u\$UID/文档
machinectl bind --mkdir deepin \$HOME/下载 /home/u\$UID/下载
machinectl bind --mkdir deepin \$HOME/桌面 /home/u\$UID/桌面
machinectl bind --mkdir deepin \$HOME/图片 /home/u\$UID/图片
machinectl bind --mkdir deepin \$HOME/视频 /home/u\$UID/视频
machinectl bind --mkdir deepin \$HOME/音乐 /home/u\$UID/音乐
[ -d \$HOME/云盘 ] && machinectl bind --mkdir deepin \$HOME/云盘 /home/u\$UID/云盘
machinectl bind --mkdir deepin \$HOME/.cache /home/u\$UID/.cache
machinectl bind --mkdir deepin \$HOME/.config/user-dirs.dirs /home/u\$UID/.config/user-dirs.dirs
machinectl bind --mkdir deepin \$HOME/.config/user-dirs.locale /home/u\$UID/.config/user-dirs.locale
machinectl bind --read-only --mkdir deepin \$HOME/.local/share/fonts /home/u\$UID/.local/share/fonts
$(echo "$X11_BIND_AND_CONFIG")

# 启动环境变量
RUN_ENVIRONMENT="DISPLAY=\$DISPLAY GDK_SYNCHRONIZE=1"
if [[ \$(loginctl show-session \$(loginctl | grep \$USER |awk '{print \$1}') -p Type) == *wayland* ]]; then
RUN_ENVIRONMENT="\$RUN_ENVIRONMENT WAYLAND_DISPLAY=\$WAYLAND_DISPLAY XAUTHORITY=\$XAUTHORITY"
fi
EOF

chmod 755 /bin/deepin-config
cat /bin/deepin-config


# 查询应用
cat > /bin/deepin-query <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/bash -c "ls /usr/share/applications"
EOF

chmod 755 /bin/deepin-query


# 清理缓存
cat > /bin/deepin-clean <<EOF
#!/bin/bash
source /bin/deepin-config
for i in {1000..1005}; do
    machinectl shell deepin /bin/bash -c "apt clean && rm -rf /home/u\$i/.deepinwine && du -hd1 /home/u\$i"
done
machinectl shell deepin /bin/bash -c "apt clean && df -h && du -hd0 /opt /home /var /usr"
EOF

chmod 755 /bin/deepin-clean



# 安装终端
cat > /bin/deepin-install-terminal <<EOF
#!/bin/bash
source /bin/deepin-config
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
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /usr/bin/bash -c "dpkg --add-architecture i386 && apt update && apt install -y com.qq.im.deepin && apt autopurge -y"
sudo cp -f /var/lib/machines/deepin/opt/apps/com.qq.im.deepin/entries/icons/hicolor/64x64/apps/com.qq.im.deepin.svg /usr/share/pixmaps/
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
#!/bin/bash
source /bin/deepin-config
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
$(echo EOF)
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
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-eCloud/ ~/.deepinwine/deepin-wine5/bin/regedit ~/云盘/丽娜/原创/ecloud.reg"
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
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y thunar catfish dbus-x11 --no-install-recommends && apt autopurge -y"
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
#!/bin/bash
source /bin/deepin-config
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
#!/bin/bash
source /bin/deepin-config
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
