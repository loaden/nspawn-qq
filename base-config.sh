#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o ”$SUDO_USER“ == "root" ]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi

# 多用户支持选项：启用动态绑定
[[ ! $MULTIUSER_SUPPORT ]] && MULTIUSER_SUPPORT=1

# systemd 247 bug 解决方案，禁止多用户支持，去除动态绑定
# 详见：https://www.mail-archive.com/debian-bugs-dist@lists.debian.org/msg1816433.html
if [[ $MULTIUSER_SUPPORT = 1 && $(systemd --version | grep systemd) =~ 247 ]]; then
    MULTIUSER_SUPPORT=0
    echo -e "\033[31m当前 systemd 有bug，不支持多用户动态绑定，已强制启用单用户模式。"
    systemd --version | grep systemd
    echo -e "\033[0m"
fi

# 必备软件包
[ -f /bin/apt ] && [ ! -f /bin/machinectl ] && apt install -y systemd-container
[ -f /bin/dnf ] && [ ! -f /bin/machinectl ] && dnf install -y systemd-container
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` != *wayland* ]]; then
    [ -f /bin/pacman ] && [ ! -f /bin/xhost ] && pacman -S xorg-xhost --noconfirm --needed
    [ -f /bin/apt ] && [ ! -f /bin/xhost ] && apt install -y x11-xserver-utils
    [ -f /bin/dnf ] && [ ! -f /bin/xhost ] && dnf install -y xhost
fi

# 禁用SELinux
if [[ -f /bin/sestatus && $(sestatus |grep 'SELinux status:') == *enabled ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    [ -f /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    echo -e "\033[31m已禁用SELinux！如有需要，可手动开启：sudo sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' /etc/sysconfig/selinux\033[0m"
    setenforce 0
fi

# 初始化配置
EXEC_FROM_CONFIG=1 source `dirname ${BASH_SOURCE[0]}`/remove-$1.sh
ln -s /home/$SUDO_USER/.machines/$1 /var/lib/machines/
[ ! -d /usr/local/bin ] && mkdir /usr/local/bin


# 允许无管理员权限启动
source `dirname ${BASH_SOURCE[0]}`/polkit.sh


# 获取用户目录
source `dirname ${BASH_SOURCE[0]}`/user-dirs.sh


# 设置容器目录权限
cat > /lib/systemd/system/nspawn-$1.service <<EOF
chmod 0777 /var/lib/machines/$1
[Service]
Type=simple
ExecStart=/bin/bash -c "chmod 0755 /var/lib/machines/$1"
[Install]
WantedBy=machines.target
After=machines.target
EOF

systemctl enable nspawn-$1.service


# 配置容器
[[ $(machinectl list) =~ $1 ]] && machinectl stop $1
mkdir -p /home/share && chmod 777 /home/share
cat > /var/lib/machines/$1/config.sh <<EOF
echo $1 > /etc/hostname
[[ ! \$(cat /etc/hosts | grep $1) ]] && echo "127.0.0.1 $1" >> /etc/hosts
/bin/sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
/bin/sed -i 's/# zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen
/sbin/locale-gen
locale
$(echo -e "$SOURCES_LIST")
[[ ! \$(cat /etc/securetty | grep pts/0) ]] && echo -e "\n# systemd-container\npts/0\npts/1\npts/2\npts/3\npts/4\npts/5\npts/6\n" >> /etc/securetty
[[ ! \$(cat /etc/securetty | grep pts/9) ]] && echo -e "pts/7\npts/8\npts/9\n" >> /etc/securetty
mkdir -p /home/share && chmod 777 /home/share
[[ \$(/bin/cat /etc/passwd | grep user:) ]] && /sbin/userdel -r user
for i in {1000..1005}; do
    [[ \$(/bin/cat /etc/passwd | grep u\$i:) ]] && continue
    /sbin/useradd -u \$i -m -s /bin/bash -G sudo u\$i
    echo u\$i:passwd | /sbin/chpasswd
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
sleep 0.5
source `dirname ${BASH_SOURCE[0]}`/xnoshm.sh $1


# 确保宿主机当前用户相关目录或文件存在
su - $SUDO_USER -c "mkdir -p /home/$SUDO_USER/.local/share/fonts"
su - $SUDO_USER -c "touch /home/$SUDO_USER/.config/user-dirs.dirs"
su - $SUDO_USER -c "touch /home/$SUDO_USER/.config/user-dirs.locale"


# 配置启动环境变量
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` == *wayland* ]]; then
X11_BIND_AND_CONFIG="# Xauthority
machinectl bind --read-only --mkdir $1 \$XAUTHORITY
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XAUTHORITY
"
else
X11_BIND_AND_CONFIG="# Xauthority
machinectl bind --read-only --mkdir $1 \$XAUTHORITY /home/u\$UID/.Xauthority
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XAUTHORITY /home/u\$UID/.Xauthority
"
DESKTOP_ENVIRONMENT="
export XAUTHORITY=/home/u\$UID/.Xauthority
"
fi
cat > /usr/local/bin/$1-start  <<EOF
#!/bin/bash$(echo "$DESKTOP_ENVIRONMENT")
export XDG_RUNTIME_DIR=/run/user/\$UID
export PULSE_SERVER=unix:\$XDG_RUNTIME_DIR/pulse/native
$(echo "$DISABLE_MITSHM")
dex \$@
EOF

chmod 755 /usr/local/bin/$1-start
echo
echo cat /usr/local/bin/$1-start
cat /usr/local/bin/$1-start


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
echo
echo /bin/systemd-nspawn-debug
cat /bin/systemd-nspawn-debug


# 重写启动服务参数
rm -rf /etc/systemd/system/systemd-nspawn@$1.service.d
mkdir -p /etc/systemd/system/systemd-nspawn@$1.service.d
cat > /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf <<EOF
[Unit]
After=systemd-hostnamed.service
[Service]
ExecStartPre=chmod 0755 /var/lib/machines/%i
ExecStart=
ExecStart=systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth -U --settings=override --machine=%i --setenv=LANGUAGE=zh_CN:zh --property=DeviceAllow='/dev/dri rw' --property=DeviceAllow='/dev/snd rw' --property=DeviceAllow='char-drm rwm' --property=DeviceAllow='/dev/shm rw' --property=DeviceAllow='char-input r'
ExecStartPost=systemd-nspawn-debug
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
if [[ $(lspci -k | egrep -A2 "VGA|3D" | grep 'Kernel driver in use') == *nvidia ]]; then
NVIDIA_BIND="
# NVIDIA
# 视情况而定
# 主机先装好N卡驱动，容器安装 lib 部分 nvidia-utils
# 容器运行 nvidia-smi 测试，如报错，则 strace 跟踪
# OpenGL 与 nvidia-smi
Bind = /dev/nvidia0
Bind = /dev/nvidiactl
$([[ $(lsmod | grep nvidia_modeset) ]] && echo \# Vulkan)
$([[ $(lsmod | grep nvidia_modeset) ]] && echo Bind = /dev/nvidia-modeset)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo \# OpenCL 与 CUDA)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo Bind = /dev/nvidia-uvm)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo Bind = /dev/nvidia-uvm-tools)
"

# 重写启动服务参数，授予访问权限
cat >> /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf <<EOF
# NVIDIA
# nvidia-smi 需要
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia0 rw
$([[ $(lsmod | grep nvidia_modeset) ]] && echo \# Vulkan 需要)
$([[ $(lsmod | grep nvidia_modeset) ]] && echo DeviceAllow=/dev/nvidia-modeset rw)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo \# OpenCL 需要)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo DeviceAllow=/dev/nvidia-uvm rw)
$([[ $(lsmod | grep nvidia_uvm) ]] && echo DeviceAllow=/dev/nvidia-uvm-tools rw)
EOF
fi


# 静态绑定
if [ $MULTIUSER_SUPPORT = 0 ]; then
    if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` == *wayland* ]]; then
        STATIC_XAUTHORITY_BIND="BindReadOnly = $XAUTHORITY"
    else
        STATIC_XAUTHORITY_BIND="BindReadOnly = $XAUTHORITY:/home/u$UID/.Xauthority"
    fi

    [ -d /home/$SUDO_USER/$USER_CLOUDDISK ] && STATIC_CLOUDDISK_BIND="Bind = /home/$SUDO_USER/$USER_CLOUDDISK:/home/u$SUDO_UID/$USER_CLOUDDISK"
    [ -f /home/$SUDO_USER/.config/user-dirs.dirs ] && STATIC_USERDIRS_BIND="Bind = /home/$SUDO_USER/.config/user-dirs.dirs:/home/u$SUDO_UID/.config/user-dirs.dirs"
    [ -f /home/$SUDO_USER/.config/user-dirs.locale ] && STATIC_USERLOCALE_BIND="Bind = /home/$SUDO_USER/.config/user-dirs.locale:/home/u$SUDO_UID/.config/user-dirs.locale"
    [ -d /home/$SUDO_USER/.local/share/fonts ] && STATIC_FONTS_BIND="Bind = /home/$SUDO_USER/.local/share/fonts:/home/u$SUDO_UID/.local/share/fonts"

    STATIC_BIND="# 单用户模式：静态绑定
#---------------
# PulseAudio && D-Bus && DConf
BindReadOnly = /run/user/$SUDO_UID/pulse
BindReadOnly = /run/user/$SUDO_UID/bus
Bind = /run/user/$SUDO_UID/dconf
#---------------
# 主目录
Bind = /home/$SUDO_USER/$USER_DOCUMENTS:/home/u$SUDO_UID/$USER_DOCUMENTS
Bind = /home/$SUDO_USER/$USER_DOWNLOAD:/home/u$SUDO_UID/$USER_DOWNLOAD
Bind = /home/$SUDO_USER/$USER_DESKTOP:/home/u$SUDO_UID/$USER_DESKTOP
Bind = /home/$SUDO_USER/$USER_PICTURES:/home/u$SUDO_UID/$USER_PICTURES
Bind = /home/$SUDO_USER/$USER_VIDEOS:/home/u$SUDO_UID/$USER_VIDEOS
Bind = /home/$SUDO_USER/$USER_MUSIC:/home/u$SUDO_UID/$USER_MUSIC
#---------------
# 其它文件或目录
$(echo "$STATIC_USERDIRS_BIND")
$(echo "$STATIC_USERLOCALE_BIND")
$(echo "$STATIC_FONTS_BIND")
$(echo "$STATIC_CLOUDDISK_BIND")
"
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
$(echo "$STATIC_BIND")

# 其它
Bind = /home/share
Bind = /usr/local/bin/$1-start:/bin/start

[Network]
VirtualEthernet = no
Private = no
EOF


# 移除多余空行
for i in {1..5}; do
    perl -0777 -pi -e 's/\n\n\n/\n\n/g' /etc/systemd/nspawn/$1.nspawn
    perl -0777 -pi -e 's/\n\n\n/\n\n/g' /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf
done


# 查看配置
echo
echo cat /etc/systemd/nspawn/$1.nspawn
cat /etc/systemd/nspawn/$1.nspawn
echo
echo cat /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf
cat /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf
echo


# 重新加载服务配置
systemctl daemon-reload


# 开机启动容器
sleep 0.5
# machinectl enable $1
# systemctl cat systemd-nspawn@$1.service
machinectl start $1
machinectl list
machinectl show $1


# 配置容器参数
[[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` != *wayland* ]] && XHOST_AUTH="xhost +local:"
cat > /usr/local/bin/$1-config <<EOF
#!/bin/bash

# 判断容器是否启动
[[ ! \$(machinectl list | grep $1) ]] && machinectl start $1 && sleep 0.5

# 使容器与宿主机使用相同用户目录
[ \$USER != root ] && machinectl shell $1 /bin/bash -c "rm -f /home/\$USER && ln -s /home/u\$UID /home/\$USER && chown u\$UID:u\$UID /home/\$USER"

# 启动环境变量
INPUT_ENGINE=\$(echo \$XMODIFIERS | awk -F "=" '/@im=/ {print \$ 2}')
RUN_ENVIRONMENT="LANG=\$LANG DISPLAY=\$DISPLAY XMODIFIERS=\$XMODIFIERS INPUT_METHOD=\$INPUT_ENGINE GTK_IM_MODULE=\$INPUT_ENGINE QT_IM_MODULE=\$INPUT_ENGINE QT4_IM_MODULE=\$INPUT_ENGINE SDL_IM_MODULE=\$INPUT_ENGINE BROWSER=Thunar"
if [[ \$(loginctl show-session \$(loginctl | grep \$USER |awk '{print \$1}') -p Type) == *wayland* ]]; then
    RUN_ENVIRONMENT="\$RUN_ENVIRONMENT XAUTHORITY=\$XAUTHORITY"
fi

$(echo $XHOST_AUTH)
EOF

# 移除多余空行
for i in {1..3}; do
    perl -0777 -pi -e 's/\n\n\n/\n\n/g' /usr/local/bin/$1-config
done

chmod 755 /usr/local/bin/$1-config
echo
echo cat /usr/local/bin/$1-config
cat /usr/local/bin/$1-config


# 容器路径绑定
if [ $MULTIUSER_SUPPORT = 0 ]; then
cat > /usr/local/bin/$1-bind <<EOF
#!/bin/bash
EOF
else
cat > /usr/local/bin/$1-bind <<EOF
#!/bin/bash

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

# 其它目录和文件
[ -d \$HOME/$USER_CLOUDDISK ] && machinectl bind --mkdir $1 \$HOME/$USER_CLOUDDISK /home/u\$UID/$USER_CLOUDDISK
[ -f \$HOME/.config/user-dirs.dirs ] && machinectl bind --mkdir $1 \$HOME/.config/user-dirs.dirs /home/u\$UID/.config/user-dirs.dirs
[ -f \$HOME/.config/user-dirs.locale ] && machinectl bind --mkdir $1 \$HOME/.config/user-dirs.locale /home/u\$UID/.config/user-dirs.locale
[ -d \$HOME/.local/share/fonts ] && machinectl bind --read-only --mkdir $1 \$HOME/.local/share/fonts /home/u\$UID/.local/share/fonts

$(echo "$X11_BIND_AND_CONFIG")
EOF
fi

# 移除多余空行
for i in {1..3}; do
    perl -0777 -pi -e 's/\n\n\n/\n\n/g' /usr/local/bin/$1-bind
done

chmod 755 /usr/local/bin/$1-bind
echo
echo cat /usr/local/bin/$1-bind
cat /usr/local/bin/$1-bind


# 查询应用
cat > /usr/local/bin/$1-query <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
if [ \$USER == root ]; then QUERY_USER=u\$SUDO_UID; else QUERY_USER=u\$UID; fi
machinectl shell $1 /bin/su - \$QUERY_USER -c "$(echo "$DISABLE_MITSHM") && ls /usr/share/applications \
    && find /opt -name "*.desktop" \
    && echo && echo query inode/directory && xdg-mime query default inode/directory \
    && echo query video/mp4 && xdg-mime query default video/mp4 \
    && echo query audio/flac && xdg-mime query default audio/flac \
    && echo query application/pdf && xdg-mime query default application/pdf \
    && echo query image/png && xdg-mime query default image/png \
    && echo && echo ldd /bin/bash && ldd /bin/bash | grep SHM \
    && echo ldd /bin/mousepad && ldd /bin/mousepad | grep SHM"
EOF

chmod 755 /usr/local/bin/$1-query


# 清理缓存
cat > /usr/local/bin/$1-clean <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
answer=No
[[ ! "\$KEEP_QUIET" == "1" ]] && read -p "Delete the '~/.deepinwine' directory? [y/N]" answer
for i in {1000..1005}; do
    if [[ \${answer^^} == Y || \${answer^^} == YES ]]; then
        machinectl shell $1 /bin/bash -c "rm -rf /home/u\$i/.deepinwine"
    fi
    machinectl shell $1 /bin/bash -c "rm -rf /home/u\$i/.cache/* && ls /home/u\$i/.config | grep -v user-dirs | xargs rm -rf && ls /home/u\$i/.local/share | grep -v fonts | xargs rm -rf && du -hd1 /home/u\$i"
done
machinectl shell $1 /bin/bash -c "find /home -maxdepth 1 -type l -delete && apt clean && df -h && du -hd0 /opt /home /var /usr"
[[ \$(machinectl list) =~ $1 ]] && machinectl stop $1
EOF

chmod 755 /usr/local/bin/$1-clean


# 系统升级
cat > /usr/local/bin/$1-upgrade <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt update && apt upgrade -y && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/$1-upgrade



# 安装QQ
cat > /usr/local/bin/$1-install-qq <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
$(echo -e "$INSTALL_QQ")
sudo cp -f /var/lib/machines/$1/opt/apps/com.qq.im.deepin/entries/icons/hicolor/64x64/apps/com.qq.im.deepin.svg /usr/share/pixmaps/
[ ! -f /usr/share/applications/deepin-qq.desktop ] && sudo bash -c 'cat > /usr/share/applications/deepin-qq.desktop <<$(echo EOF)
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

chmod 755 /usr/local/bin/$1-install-qq

# 配置QQ
cat > /usr/local/bin/$1-config-qq <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-QQ ~/.deepinwine/deepin-wine5/bin/winecfg"
EOF

chmod 755 /usr/local/bin/$1-config-qq

# 启动QQ
cat > /usr/local/bin/$1-qq <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.im.deepin/entries/applications/com.qq.im.deepin.desktop"
EOF

chmod 755 /usr/local/bin/$1-qq



# 安装微信
cat > /usr/local/bin/$1-install-weixin <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
$(echo -e "$INSTALL_WEIXIN")
sudo cp -f /var/lib/machines/$1/opt/apps/com.qq.weixin.deepin/entries/icons/hicolor/64x64/apps/com.qq.weixin.deepin.svg /usr/share/pixmaps/
[ ! -f /usr/share/applications/deepin-weixin.desktop ] && sudo bash -c 'cat > /usr/share/applications/deepin-weixin.desktop <<$(echo EOF)
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

chmod 755 /usr/local/bin/$1-install-weixin

# 启动微信
cat > /usr/local/bin/$1-weixin <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.weixin.deepin/entries/applications/com.qq.weixin.deepin.desktop"
EOF

chmod 755 /usr/local/bin/$1-weixin



# 安装云盘
cat > /usr/local/bin/$1-install-ecloud <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
ECLOUD_DEB=/home/u\$UID/\$(basename \$(xdg-user-dir DOWNLOAD))/cn.189.cloud.deepin_6.3.2-1.deb
machinectl shell $1 /bin/bash -c "dpkg -i '\$ECLOUD_DEB'  && apt install -f && apt-mark hold cn.189.cloud.deepin"
EOF

chmod 755 /usr/local/bin/$1-install-ecloud

# 配置云盘
cat > /usr/local/bin/$1-config-ecloud <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-eCloud/ ~/.deepinwine/deepin-wine5/bin/regedit ~/$USER_DOWNLOAD/ecloud.reg"
EOF

chmod 755 /usr/local/bin/$1-config-ecloud

# 启动云盘
cat > /usr/local/bin/$1-ecloud <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/cn.189.cloud.deepin/entries/applications/cn.189.cloud.deepin.desktop"
EOF

chmod 755 /usr/local/bin/$1-ecloud



# 安装文件管理器
cat > /usr/local/bin/$1-install-thunar <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y thunar thunar-archive-plugin xarchiver unrar catfish mousepad:i386 libexo-1-0 dbus-x11 xdg-utils --no-install-recommends && apt autopurge -y"
if [ \$USER == root ]; then INSTALL_USER=u\$SUDO_UID; else INSTALL_USER=u\$UID; fi
machinectl shell $1 /bin/su - \$INSTALL_USER -c "xdg-mime default Thunar.desktop inode/directory"
EOF

chmod 755 /usr/local/bin/$1-install-thunar

# 启动文件管理器
cat > /usr/local/bin/$1-thunar <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/Thunar.desktop"
EOF

chmod 755 /usr/local/bin/$1-thunar



# 安装图片浏览器
cat > /usr/local/bin/$1-install-shotwell <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y shotwell && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/$1-install-shotwell

# 启动图片浏览器
cat > /usr/local/bin/$1-shotwell <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/shotwell.desktop"
EOF

chmod 755 /usr/local/bin/$1-shotwell



# 安装网页浏览器
cat > /usr/local/bin/$1-install-chromium <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y chromium && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/$1-install-chromium

# 启动网页浏览器
cat > /usr/local/bin/$1-chromium <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/chromium.desktop"
EOF

chmod 755 /usr/local/bin/$1-chromium



# 安装PDF浏览器
cat > /usr/local/bin/$1-install-mupdf <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y mupdf && apt autopurge -y"
if [ \$USER == root ]; then INSTALL_USER=u\$SUDO_UID; else INSTALL_USER=u\$UID; fi
machinectl shell $1 /bin/su - \$INSTALL_USER -c "xdg-mime default mupdf.desktop application/pdf"
EOF

chmod 755 /usr/local/bin/$1-install-mupdf



# 安装MPV
cat > /usr/local/bin/$1-install-mpv <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y mpv --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/$1-install-mpv

# 启动MPV
cat > /usr/local/bin/$1-mpv <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/mpv.desktop"
EOF

chmod 755 /usr/local/bin/$1-mpv



# 安装LibreOffice
cat > /usr/local/bin/$1-install-libreoffice <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y libreoffice-writer libreoffice-impress libreoffice-calc libreoffice-gtk3 libreoffice-style-breeze libreoffice-style-elementary libreoffice-l10n-zh-cn libcanberra-gtk3-module packagekit-gtk3-module --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/$1-install-libreoffice

# 启动LibreOffice
cat > /usr/local/bin/$1-libreoffice <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/libreoffice-startcenter.desktop"
EOF

chmod 755 /usr/local/bin/$1-libreoffice



# 添加启动器
machinectl start $1 && sleep 0.5
echo
[[ $($1-query | grep com.qq.im.deepin.desktop) ]] && [ ! -f /usr/share/applications/deepin-qq.desktop ] && $1-install-qq
[[ $($1-query | grep com.qq.weixin.deepin.desktop) ]] && [ ! -f /usr/share/applications/deepin-weixin.desktop ] && $1-install-weixin
[ -f /usr/share/applications/deepin-qq.desktop ] && cat /usr/share/applications/deepin-qq.desktop | grep $1-
[ -f /usr/share/applications/deepin-weixin.desktop ] && cat /usr/share/applications/deepin-weixin.desktop | grep $1-

# 开机启动
[[ $(systemctl status machines.target | grep 'machines.target; disabled;') ]] && systemctl enable machines.target
