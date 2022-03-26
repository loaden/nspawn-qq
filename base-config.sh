#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 不能单独执行提醒
if [[ `basename $0` == base-config.sh ]]; then
    echo "'`basename $0`' 命令不能单独执行"
    exit 1
fi

# 多用户支持选项：启用动态绑定
[[ ! $MULTIUSER_SUPPORT ]] && MULTIUSER_SUPPORT=1

# systemd 247 bug 解决方案，禁止多用户支持，去除动态绑定
# 详见：https://www.mail-archive.com/debian-bugs-dist@lists.debian.org/msg1816433.html
if [[ $MULTIUSER_SUPPORT = 1 && $(systemctl --version | grep systemd) =~ 247 ]]; then
    MULTIUSER_SUPPORT=0
    echo -e "\033[31m当前 systemd 有bug，不支持多用户动态绑定，已强制启用单用户模式。"
    systemd --version | grep systemd
    echo -e "\033[0m"
    sleep 3
fi

# 必备软件包
[ -f /usr/bin/apt ] && [[ ! -f /usr/bin/machinectl && ! -f /bin/machinectl ]] && apt install -y systemd-container
[ -f /usr/bin/dnf ] && [[ ! -f /usr/bin/machinectl && ! -f /bin/machinectl ]] && dnf install -y systemd-container
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` == *x11* ]]; then
    [ -f /usr/bin/pacman ] && [ ! -f /usr/bin/xhost ] && pacman -S xorg-xhost --noconfirm --needed
    [ -f /usr/bin/apt ] && [ ! -f /usr/bin/xhost ] && apt install -y x11-xserver-utils
    [ -f /usr/bin/dnf ] && [ ! -f /usr/bin/xhost ] && dnf install -y xhost
    [ -f /usr/bin/emerge ] && [ ! -f /usr/bin/xhost ] && emerge -u xhost
fi

# 禁用SELinux
if [[ -f /usr/bin/sestatus && $(sestatus |grep 'SELinux status:') == *enabled ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    [ -f /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    echo -e "\033[31m已禁用SELinux！如有需要，可手动开启：sudo sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' /etc/sysconfig/selinux\033[0m"
    setenforce 0
fi

# 初始化配置
EXEC_FROM_CONFIG=1 source `dirname ${BASH_SOURCE[0]}`/remove-$1.sh
ROOT=/var/lib/machines/$1
ln -sfnv /home/$SUDO_USER/.machines/$1 $ROOT
[ ! -d /usr/local/bin ] && mkdir /usr/local/bin


# 允许无管理员权限启动
source `dirname ${BASH_SOURCE[0]}`/polkit.sh


# 获取用户目录
source `dirname ${BASH_SOURCE[0]}`/user-dirs.sh


# 设置容器目录权限
cat > /lib/systemd/system/nspawn-$1.service <<EOF
chmod 0777 $ROOT
[Service]
Type=simple
ExecStart=/bin/bash -c "chmod 0755 $ROOT"
[Install]
WantedBy=machines.target
After=machines.target
EOF

systemctl enable nspawn-$1.service


# 配置容器
[[ $(machinectl list) =~ $1 ]] && machinectl stop $1 && sleep 1
cat > $ROOT/config.sh <<EOF
#!/bin/bash
source /etc/profile
source ~/.bashrc
env
[ -n $(which neofetch) ] && neofetch
echo $1 > /etc/hostname
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/cache/apt/archives/lock
dpkg --configure -a
apt install -f
apt purge --yes less:amd64
if [ -z $(which less) ]; then
    dpkg --add-architecture i386
    apt update
fi
apt install --yes --no-install-recommends sudo procps pulseaudio libpam-systemd locales xdg-utils dbus-x11 dex bash-completion neofetch nano fonts-wqy-microhei
apt install --yes --no-install-recommends less:i386
echo -e "127.1 $1\n::1 $1" > /etc/hosts
sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
sed -i 's/# zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen
locale-gen
locale
$(echo -e "$SOURCES_LIST")
[[ ! -f /etc/securetty || ! \$(cat /etc/securetty | grep pts/0) ]] && echo -e "\n# systemd-container\npts/0\npts/1\npts/2\npts/3\npts/4\npts/5\npts/6" >> /etc/securetty
[[ ! \$(cat /etc/securetty | grep pts/9) ]] && echo -e "pts/7\npts/8\npts/9" >> /etc/securetty
[[ \$(cat /etc/passwd | grep user:) ]] && userdel -r user
for i in {1000..1005}; do
    [[ ! \$(cat /etc/passwd | grep u\$i:) ]] && useradd -u \$i -m -s /bin/bash -G sudo u\$i
    echo u\$i:u\$i | chpasswd
    cd /home/u\$i/
    mkdir -p .local/share/fonts .config .cache $USER_DOCUMENTS $USER_DOWNLOAD $USER_DESKTOP $USER_PICTURES $USER_VIDEOS $USER_MUSIC $USER_CLOUDDISK
    chown -R u\$i:u\$i .local .config .cache $USER_DOCUMENTS $USER_DOWNLOAD $USER_DESKTOP $USER_PICTURES $USER_VIDEOS $USER_MUSIC $USER_CLOUDDISK
done
for i in {1000..1005}; do
    echo u\$i:u\$i | chpasswd
    [[ ! \$(groups u\$i | grep audio) ]] && usermod -aG audio u\$i
    mkdir -p /home/u\$i/.local/share/fonts
    mkdir -p /home/u\$i/.config/fontconfig
done
# No password for sudo
sed -i "s/.*sudo.*ALL=(ALL:ALL) ALL/%sudo ALL=(ALL) NOPASSWD:ALL/" /etc/sudoers
# 移除奇怪的软链接
[ -L /bin/X11 ] && /bin/unlink /bin/X11
EOF

chroot $ROOT /bin/bash /config.sh


# 禁用MIT-SHM
sleep 0.5
source `dirname ${BASH_SOURCE[0]}`/xnoshm.sh $1


#精简容器空间
cat > $ROOT/clean.sh <<EOF
#!/bin/bash
source /etc/profile
source ~/.bashrc

if [ -f /usr/bin/xfce4-terminal ]; then
    apt update && apt upgrade --yes
    apt install --yes lxterminal --no-install-recommends
    apt purge --yes xfce4-terminal fonts-dejavu-core
fi

# Save space
rm -rfv /usr/share/doc
rm -rfv /usr/share/man
rm -fv /usr/share/fonts/opentype/noto/*.ttc
/bin/rm -rfv /tmp/*
apt autopurge --yes
apt clean
EOF

chroot $ROOT /bin/bash /clean.sh


# 确保宿主机当前用户相关目录或文件存在
su - $SUDO_USER -c "mkdir -p /home/$SUDO_USER/.local/share/fonts"
su - $SUDO_USER -c "touch /home/$SUDO_USER/.config/user-dirs.dirs"
su - $SUDO_USER -c "touch /home/$SUDO_USER/.config/user-dirs.locale"


# 配置启动环境变量
if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` == *x11* ]]; then
X11_BIND_AND_CONFIG="# Xauthority
machinectl bind --read-only $1 \$XAUTHORITY /home/u\$UID/.Xauthority
[ \$? != 0 ] && echo error: machinectl bind --read-only $1 \$XAUTHORITY /home/u\$UID/.Xauthority
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
env
dex \$@
EOF

chmod 755 /usr/local/bin/$1-start
echo
echo cat /usr/local/bin/$1-start
cat /usr/local/bin/$1-start


# 调试
cat > /usr/bin/systemd-nspawn-debug <<EOF
#!/bin/bash
export NSPAWN_LOG_FILE=/home/nspawn.log
touch \$NSPAWN_LOG_FILE
echo \$(date) \$NSPAWN_LOG_FILE >> \$NSPAWN_LOG_FILE
echo -e "tree -L 2 /run/user \n" "\$(tree -L 2 /run/user)" >> \$NSPAWN_LOG_FILE
echo -e "env \n" "\$(env) \n\n" >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/dri \n" "\$(ls -la /dev/dri) \n" >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/shm \n" "\$(ls -la /dev/shm) \n" >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/snd \n" "\$(ls -la /dev/snd) \n" >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/fuse \n" "\$(ls -la /dev/fuse) \n" >> \$NSPAWN_LOG_FILE
echo -e "echo /dev/nvidia* \n" "\$(ls -la /dev/nvidia*) \n" >> \$NSPAWN_LOG_FILE
echo -e "echo /tmp \n" "\$(ls -la /tmp) \n" >> \$NSPAWN_LOG_FILE
chmod 777 \$NSPAWN_LOG_FILE
EOF

chmod 755 /usr/bin/systemd-nspawn-debug
echo
echo /usr/bin/systemd-nspawn-debug
cat /usr/bin/systemd-nspawn-debug


# 重写启动服务参数
rm -rf /etc/systemd/system/systemd-nspawn@$1.service.d
mkdir -p /etc/systemd/system/systemd-nspawn@$1.service.d
cat > /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf <<EOF
[Unit]
After=systemd-hostnamed.service
[Service]
ExecStartPre=chmod 0755 /var/lib/machines/%i
ExecStart=
ExecStart=systemd-nspawn --keep-unit --boot --link-journal=try-guest --network-veth -U --settings=override --machine=%i
ExecStartPost=systemd-nspawn-debug
# Other stuff.
DeviceAllow=/dev/shm rw
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
$([ -e /dev/nvidia-modeset ] && echo \# Vulkan)
$([ -e /dev/nvidia-modeset ] && echo Bind = /dev/nvidia-modeset)
$([ -e /dev/nvidia-uvm ] && echo \# OpenCL 与 CUDA)
$([ -e /dev/nvidia-uvm ] && echo Bind = /dev/nvidia-uvm)
$([ -e /dev/nvidia-uvm-tools ] && echo Bind = /dev/nvidia-uvm-tools)
"

# 重写启动服务参数，授予访问权限
cat >> /etc/systemd/system/systemd-nspawn@$1.service.d/override.conf <<EOF
# NVIDIA
# nvidia-smi 需要
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia0 rw
$([ -e /dev/nvidia-modeset ] && echo \# Vulkan 需要)
$([ -e /dev/nvidia-modeset ] && echo DeviceAllow=/dev/nvidia-modeset rw)
$([ -e /dev/nvidia-uvm ] && echo \# OpenCL 需要)
$([ -e /dev/nvidia-uvm ] && echo DeviceAllow=/dev/nvidia-uvm rw)
$([ -e /dev/nvidia-uvm-tools ] && echo DeviceAllow=/dev/nvidia-uvm-tools rw)
EOF
fi


# 静态绑定
if [ $MULTIUSER_SUPPORT = 0 ]; then
    if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` == *x11* ]]; then
        STATIC_XAUTHORITY_BIND="BindReadOnly = $XAUTHORITY:/home/u$UID/.Xauthority"
    fi

    [ -d /home/$SUDO_USER/$USER_CLOUDDISK ] && STATIC_CLOUDDISK_BIND="Bind = /home/$SUDO_USER/$USER_CLOUDDISK:/home/u$SUDO_UID/$USER_CLOUDDISK"
    [ -f /home/$SUDO_USER/.config/user-dirs.dirs ] && STATIC_USERDIRS_BIND="Bind = /home/$SUDO_USER/.config/user-dirs.dirs:/home/u$SUDO_UID/.config/user-dirs.dirs"
    [ -f /home/$SUDO_USER/.config/user-dirs.locale ] && STATIC_USERLOCALE_BIND="Bind = /home/$SUDO_USER/.config/user-dirs.locale:/home/u$SUDO_UID/.config/user-dirs.locale"
    [ -d /home/$SUDO_USER/.local/share/fonts ] && STATIC_FONTS_BIND="Bind = /home/$SUDO_USER/.local/share/fonts:/home/u$SUDO_UID/.local/share/fonts"
    [ -d /home/$SUDO_USER/.config/fontconfig ] && STATIC_FONTCONFIG_BIND="Bind = /home/$SUDO_USER/.config/fontconfig:/home/u$SUDO_UID/.config/fontconfig"

    STATIC_BIND="# 单用户模式：静态绑定
#---------------
# PulseAudio && D-Bus && DConf
BindReadOnly = /run/user/$SUDO_UID/pulse
BindReadOnly = /run/user/$SUDO_UID/bus
BindReadOnly = /run/user/$SUDO_UID/dconf
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
$(echo "$STATIC_FONTCONFIG_BIND")
$(echo "$STATIC_CLOUDDISK_BIND")
"
fi


# 创建容器配置文件
[[ $(machinectl list) =~ $1 ]] && machinectl stop $1 && sleep 1
mkdir -p /etc/systemd/nspawn
cat > /etc/systemd/nspawn/$1.nspawn <<EOF
[Exec]
Boot = true
PrivateUsers = no

[Files]
# Xorg
BindReadOnly = /tmp/.X11-unix

# Other stuff.
Bind = /dev/shm
Bind = /dev/fuse

$(echo "$NVIDIA_BIND")
$(echo "$STATIC_BIND")

# Scripts
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
[[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $ 1}') -p Type` == *x11* ]] && XHOST_AUTH="xhost +local:"
cat > /usr/local/bin/$1-config <<EOF
#!/bin/bash

# 不能单独执行提醒
if [[ \$(basename \$0) == $1-config ]]; then
    echo "'\$(which \$(basename \$0))' 命令不能单独执行，如果你要配置容器，请添加脚本路径执行：./\$(basename \$0).sh"
    exit 1
fi

# 获取HOST家目录、HOST用户名以及容器登录UID
if [ \$EUID == 0 ]; then
    HOST_HOME=\$(su - \$SUDO_USER -c "env | grep HOME= | awk -F '=' '/HOME=/ {print \$ 2}'")
    HOST_USER=\$SUDO_USER
    USER_UID=\$SUDO_UID
else
    HOST_HOME=\$HOME
    HOST_USER=\$USER
    USER_UID=\$UID
fi

SHELL_OPTIONS="--uid=\$USER_UID --setenv=HOST_USER=\$HOST_USER --setenv=HOST_HOME=\$HOST_HOME"
echo HOST_HOME=\$HOST_HOME
echo HOST_USER=\$HOST_USER
echo USER_UID=\$USER_UID

# 判断容器是否启动
[[ ! \$(machinectl list | grep $1) ]] && machinectl start $1 && sleep 0.5

# 使容器与宿主机使用相同用户目录
machinectl --setenv=USER_UID=\$USER_UID --setenv=HOST_HOME=\$HOST_HOME shell $1 /bin/bash -c '
    ln -sfnv /home/u\$USER_UID \$HOST_HOME && chown -h \$USER_UID:\$USER_UID \$HOST_HOME
'

# 启动环境变量
INPUT_ENGINE=\$(echo \$XMODIFIERS | awk -F "=" '/@im=/ {print \$ 2}')
RUN_ENVIRONMENT="LANG=\$LANG DISPLAY=\$DISPLAY TERM=xterm-256color XMODIFIERS=\$XMODIFIERS INPUT_METHOD=\$INPUT_ENGINE GTK_IM_MODULE=\$INPUT_ENGINE QT_IM_MODULE=\$INPUT_ENGINE QT4_IM_MODULE=\$INPUT_ENGINE SDL_IM_MODULE=\$INPUT_ENGINE BROWSER=Thunar"
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

# 仅允许普通用户权限执行
if [ \$EUID == 0 ]; then
    echo \$(basename \$0) 命令只允许普通用户执行
    exit 1
fi

$(echo $XHOST_AUTH)
EOF
else
cat > /usr/local/bin/$1-bind <<EOF
#!/bin/bash

# 仅允许普通用户权限执行
if [ \$EUID == 0 ]; then
    echo \$(basename \$0) 命令只允许普通用户执行
    exit 1
fi

# PulseAudio
machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/pulse
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/pulse

# Bus
machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/bus
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/bus

# DConf
machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/dconf
[ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$XDG_RUNTIME_DIR/dconf

# D-Bus
find /tmp/ -maxdepth 1 -name dbus* -exec machinectl bind --read-only --mkdir $1 {} \; -print

# 主目录
[ -n "$USER_DOCUMENTS" ] && [ -d \$HOME/$USER_DOCUMENTS ] && machinectl bind --mkdir $1 \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
[ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_DOCUMENTS /home/u\$UID/$USER_DOCUMENTS
[ -n "$USER_DOWNLOAD" ] && [ -d \$HOME/$USER_DOWNLOAD ] && machinectl bind --mkdir $1 \$HOME/$USER_DOWNLOAD /home/u\$UID/$USER_DOWNLOAD
[ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_DOWNLOAD /home/u\$UID/$USER_DOWNLOAD
[ -n "$USER_DESKTOP" ] && [ -d \$HOME/$USER_DESKTOP ] && machinectl bind --mkdir $1 \$HOME/$USER_DESKTOP /home/u\$UID/$USER_DESKTOP
[ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_DESKTOP /home/u\$UID/$USER_DESKTOP
[ -n "$USER_PICTURES" ] && [ -d \$HOME/$USER_PICTURES ] && machinectl bind --mkdir $1 \$HOME/$USER_PICTURES /home/u\$UID/$USER_PICTURES
[ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_PICTURES /home/u\$UID/$USER_PICTURES
[ -n "$USER_VIDEOS" ] && [ -d \$HOME/$USER_VIDEOS ] && machinectl bind --mkdir $1 \$HOME/$USER_VIDEOS /home/u\$UID/$USER_VIDEOS
[ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_VIDEOS /home/u\$UID/$USER_VIDEOS
[ -n "$USER_MUSIC" ] && [ -d \$HOME/$USER_MUSIC ] && machinectl bind --mkdir $1 \$HOME/$USER_MUSIC /home/u\$UID/$USER_MUSIC
[ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_MUSIC /home/u\$UID/$USER_MUSIC

# 其它目录和文件
[ -n "$USER_CLOUDDISK" ] && [ -d \$HOME/$USER_CLOUDDISK ] && machinectl bind --mkdir $1 \$HOME/$USER_CLOUDDISK /home/u\$UID/$USER_CLOUDDISK
[ -n "$USER_CLOUDDISK" ] && [ -d \$HOME/$USER_CLOUDDISK ] && [ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/$USER_CLOUDDISK /home/u\$UID/$USER_CLOUDDISK
[ -f \$HOME/.config/user-dirs.dirs ] && machinectl bind --mkdir $1 \$HOME/.config/user-dirs.dirs /home/u\$UID/.config/user-dirs.dirs
[ -f \$HOME/.config/user-dirs.dirs ] && [ \$? != 0 ] && echo error: machinectl --mkdir bind $1 \$HOME/.config/user-dirs.dirs /home/u\$UID/.config/user-dirs.dirs
[ -f \$HOME/.config/user-dirs.locale ] && machinectl bind --mkdir $1 \$HOME/.config/user-dirs.locale /home/u\$UID/.config/user-dirs.locale
[ -f \$HOME/.config/user-dirs.locale ] && [ \$? != 0 ] && echo error: machinectl bind --mkdir $1 \$HOME/.config/user-dirs.locale /home/u\$UID/.config/user-dirs.locale
[ -d \$HOME/.local/share/fonts ] && machinectl bind --read-only --mkdir $1 \$HOME/.local/share/fonts /home/u\$UID/.local/share/fonts
[ -d \$HOME/.local/share/fonts ] && [ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$HOME/.local/share/fonts /home/u\$UID/.local/share/fonts
[ -d \$HOME/.config/fontconfig ] && machinectl bind --read-only --mkdir $1 \$HOME/.config/fontconfig /home/u\$UID/.config/fontconfig
[ -d \$HOME/.config/fontconfig ] && [ \$? != 0 ] && echo error: machinectl bind --read-only --mkdir $1 \$HOME/.config/fontconfig /home/u\$UID/.config/fontconfig

$(echo "$X11_BIND_AND_CONFIG")
$(echo $XHOST_AUTH)
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
machinectl \$SHELL_OPTIONS --setenv=LD_PRELOAD=$DISABLE_MIT_SHM_SO shell $1 /bin/bash -c 'env ;
    echo /usr/share/applications && ls -l /usr/share/applications ;
    find /opt/ -name "*.desktop" && echo ;
    [ -n "\$(xdg-mime query default inode/directory)" ] && echo -n "The default open of inode/directory is " && xdg-mime query default inode/directory ;
    [ -n "\$(xdg-mime query default video/mp4)" ] && echo -n "The default open of video/mp4 is " && xdg-mime query default video/mp4 ;
    [ -n "\$(xdg-mime query default audio/flac)" ] && echo -n "The default open of audio/flac is " && xdg-mime query default audio/flac ;
    [ -n "\$(xdg-mime query default application/pdf)" ] && echo -n "The default open of application/pdf is " && xdg-mime query default application/pdf ;
    [ -n "\$(xdg-mime query default image/png)" ] && echo -n "The default open of image/png is " && xdg-mime query default image/png ;
    echo && echo ldd /bin/bash && echo \$(ldd /bin/bash | grep SHM) ;
    echo ldd /bin/less && echo \$(ldd /bin/less | grep SHM) ;
'
EOF

chmod 755 /usr/local/bin/$1-query


# 清理缓存
cat > /usr/local/bin/$1-clean <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
answer=No
[[ ! "\$KEEP_QUIET" == "1" ]] && read -p "Delete the '~/.deepinwine' directory? [y/N]" answer
[[ \${answer^^} == Y || \${answer^^} == YES ]] && DELETE_WINE=yes
machinectl --setenv=DELETE_WINE=\$DELETE_WINE shell $1 /bin/bash -c 'env ;
    for i in \$(find /home -maxdepth 1 -type d | grep /home/ | grep -v /home/share); do
        [ "\$DELETE_WINE" == "yes" ] && echo rm -rf \$i/.deepinwine && rm -rf \$i/.deepinwine ;
        rm -rf \$i/.cache/* ;
        ls \$i/.config | grep -v user-dirs | xargs rm -rf ;
        ls \$i/.local/share | grep -v fonts | xargs rm -rf ;
        du -hd0 \$i ;
    done;
    apt autopurge -y ;
    apt clean ;
    rm -rf /usr/share/doc ;
    rm -rf /usr/share/man ;
    rm -rf /tmp/* ;
    find /home -maxdepth 1 -type l -delete ;
    journalctl --vacuum-size 1M ;
    df -h && du -hd0 /opt /home /var /usr ;
'
EOF

chmod 755 /usr/local/bin/$1-clean


# 软件升级
cat > /usr/local/bin/$1-update <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
if [ ! -f /usr/bin/git ]; then
    [ -f /usr/bin/apt ] && sudo /usr/bin/apt install -y git
    [ -f /usr/bin/pacman ] && sudo /usr/bin/pacman -S git
    [ -f /usr/bin/dnf ] && sudo /usr/bin/dnf install -y git
fi
if [ ! -d \$HOME/.nspawn-qq/.git ]; then
    /usr/bin/git clone https://github.com/loaden/nspawn-qq.git \$HOME/.nspawn-qq
else
    pushd \$HOME/.nspawn-qq
        /usr/bin/git pull
    popd
fi
if [ ! -f \$HOME/.nspawn-qq/$1-config.sh ]; then
    echo 意外错误，请手动删除 \$HOME/.nspawn-qq 文件夹后再试。
else
    sudo \$HOME/.nspawn-qq/$1-config.sh
fi
EOF

chmod 755 /usr/local/bin/$1-update


# 系统升级
cat > /usr/local/bin/$1-upgrade <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y --no-install-recommends less:i386 && apt update && apt dist-upgrade -y && apt autopurge -y && apt list --upgradable -a"
EOF

chmod 755 /usr/local/bin/$1-upgrade



# 安装终端
cat > /usr/local/bin/$1-install-terminal <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y lxterminal libcanberra-gtk3-module --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/$1-install-terminal

# 启动终端
cat > /usr/local/bin/$1-terminal <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/lxterminal.desktop"
EOF

chmod 755 /usr/local/bin/$1-terminal



# 安装QQ
cat > /usr/local/bin/$1-install-qq <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
DEB_FILE=\$(find \$(xdg-user-dir DOWNLOAD)/ -name com.qq.im.*.deb)
if [ -z "\$DEB_FILE" ]; then
    $(echo -e "$INSTALL_QQ")
else
    source /usr/local/bin/$1-bind
    machinectl shell $1 /bin/bash -c "apt install --no-install-recommends \${DEB_FILE/\$USER/u\$UID} ; apt install -f ; apt-mark hold com.qq.im.deepin"
fi
[ ! -f /usr/share/pixmaps/com.qq.im.deepin.svg ] && sudo -S cp -f $ROOT/opt/apps/com.qq.im.deepin/entries/icons/hicolor/64x64/apps/com.qq.im.deepin.svg /usr/share/pixmaps/
[[ ! -f /usr/share/applications/deepin-qq.desktop && -f /usr/share/pixmaps/com.qq.im.deepin.svg ]] && sudo -S /bin/bash -c 'cat > /usr/share/applications/deepin-qq.desktop <<$(echo EOF)
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
machinectl stop $1
sleep 1
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



# 安装TIM
cat > /usr/local/bin/$1-install-tim <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
DEB_FILE=\$(find \$(xdg-user-dir DOWNLOAD)/ -name com.qq.office.*.deb)
if [ -z "\$DEB_FILE" ]; then
    $(echo -e "$INSTALL_TIM")
else
    source /usr/local/bin/$1-bind
    machinectl shell $1 /bin/bash -c "apt install --no-install-recommends \${DEB_FILE/\$USER/u\$UID} ; apt install -f ; apt-mark hold com.qq.office.deepin"
fi
[ ! -f /usr/share/pixmaps/com.qq.office.deepin.svg ] && sudo -S cp -f $ROOT/opt/apps/com.qq.office.deepin/entries/icons/hicolor/64x64/apps/com.qq.office.deepin.svg /usr/share/pixmaps/
[[ ! -f /usr/share/applications/deepin-tim.desktop && -f /usr/share/pixmaps/com.qq.office.deepin.svg ]] && sudo -S /bin/bash -c 'cat > /usr/share/applications/deepin-tim.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
Categories=Network;
Icon=com.qq.office.deepin
Exec=$1-tim %F
Terminal=false
Name=TIM
Name[zh_CN]=TIM
Comment=Tencent TIM Client on Deepin Wine
StartupWMClass=TIM.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /usr/local/bin/$1-install-tim

# 配置TIM
cat > /usr/local/bin/$1-config-tim <<EOF
#!/bin/bash
machinectl stop $1
sleep 1
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT WINEPREFIX=~/.deepinwine/Deepin-TIM ~/.deepinwine/deepin-wine5/bin/winecfg"
EOF

chmod 755 /usr/local/bin/$1-config-tim

# 启动TIM
cat > /usr/local/bin/$1-tim <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.office.deepin/entries/applications/com.qq.office.deepin.desktop"
EOF

chmod 755 /usr/local/bin/$1-tim



# 安装微信
cat > /usr/local/bin/$1-install-weixin <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
DEB_FILE=\$(find \$(xdg-user-dir DOWNLOAD)/ -name com.qq.weixin.*.deb)
if [ -z "\$DEB_FILE" ]; then
    $(echo -e "$INSTALL_WEIXIN")
else
    source /usr/local/bin/$1-bind
    machinectl shell $1 /bin/bash -c "apt install --no-install-recommends \${DEB_FILE/\$USER/u\$UID} ; apt install -f ; apt-mark hold com.qq.weixin.deepin"
fi
[ ! -f /usr/share/pixmaps/com.qq.weixin.deepin.svg ] && sudo -S cp -f $ROOT/opt/apps/com.qq.weixin.deepin/entries/icons/hicolor/64x64/apps/com.qq.weixin.deepin.svg /usr/share/pixmaps/
[[ ! -f /usr/share/applications/deepin-weixin.desktop && -f /usr/share/pixmaps/com.qq.weixin.deepin.svg ]] && sudo -S /bin/bash -c 'cat > /usr/share/applications/deepin-weixin.desktop <<$(echo EOF)
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

# 配置微信
cat > /usr/local/bin/$1-config-weixin <<EOF
#!/bin/bash
machinectl stop $1
sleep 1
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c ''"\$RUN_ENVIRONMENT"' WINEPREFIX=~/.deepinwine/Deepin-WeChat \
    \$(if [[ \$(grep version /opt/apps/com.qq.weixin.deepin/info) =~ Zz ]]; then
        echo ~/.deepinwine/deepin-wine5
    else
        echo /opt/deepin-wine6-stable
    fi)/bin/winecfg
'
EOF

chmod 755 /usr/local/bin/$1-config-weixin

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
DEB_FILE=\$(find \$(xdg-user-dir DOWNLOAD)/ -name cn.189.cloud.*.deb)
if [ -z "\$DEB_FILE" ]; then
    machinectl shell $1 /bin/bash -c "apt install -y cn.189.cloud.deepin x11-utils --no-install-recommends && apt autopurge -y"
else
    source /usr/local/bin/$1-bind
    machinectl shell $1 /bin/bash -c "apt install --no-install-recommends \${DEB_FILE/\$USER/u\$UID} ; apt install -f ; apt-mark hold cn.189.cloud.deepin"
fi
[ ! -f /usr/share/pixmaps/cn.189.cloud.deepin.svg ] && sudo -S cp -f $ROOT/opt/apps/cn.189.cloud.deepin/entries/icons/hicolor/64x64/apps/cn.189.cloud.deepin.svg /usr/share/pixmaps/
[[ ! -f /usr/share/applications/deepin-ecloud.desktop && -f /usr/share/pixmaps/cn.189.cloud.deepin.svg  ]] && sudo -S /bin/bash -c 'cat > /usr/share/applications/deepin-ecloud.desktop <<$(echo EOF)
[Desktop Entry]
Encoding=UTF-8
Type=Application
X-Created-By=Yuchen Deng
Categories=Network;
Icon=cn.189.cloud.deepin
Exec=$1-ecloud %F
Name=eCloud
Name[zh_CN]=天翼云盘
Comment=eCloud on Deepin Wine
StartupWMClass=eCloud.exe
MimeType=
$(echo EOF)'
EOF

chmod 755 /usr/local/bin/$1-install-ecloud

# 配置云盘
cat > /usr/local/bin/$1-config-ecloud <<EOF
#!/bin/bash
machinectl stop $1
sleep 1
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
cat > /usr/local/bin/$1-install-file <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y thunar thunar-archive-plugin xarchiver unrar catfish libexo-1-0 mousepad gpicview libcanberra-gtk-module --no-install-recommends && apt autopurge -y"
machinectl shell $1 /bin/su - u\$UID -c "xdg-mime default Thunar.desktop inode/directory"
EOF

chmod 755 /usr/local/bin/$1-install-file

# 启动文件管理器
cat > /usr/local/bin/$1-file <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
source /usr/local/bin/$1-bind
machinectl shell $1 /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/Thunar.desktop"
EOF

chmod 755 /usr/local/bin/$1-file



# 安装图片浏览器
cat > /usr/local/bin/$1-install-shotwell <<EOF
#!/bin/bash
source /usr/local/bin/$1-config
machinectl shell $1 /bin/bash -c "apt install -y shotwell --no-install-recommends && apt autopurge -y"
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
machinectl shell $1 /bin/bash -c "apt install -y chromium --no-install-recommends && apt autopurge -y"
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
machinectl shell $1 /bin/bash -c "apt install -y mupdf --no-install-recommends && apt autopurge -y"
machinectl shell $1 /bin/su - u\$UID -c "xdg-mime default mupdf.desktop application/pdf"
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
[ -n "$($1-query | grep com.qq.im.deepin.desktop)" ] && [[ ! -f /usr/share/applications/deepin-qq.desktop || ! -f /usr/share/pixmaps/com.qq.im.deepin.svg ]] && $1-install-qq
[ -n "$($1-query | grep com.qq.office.deepin.desktop)" ] && [[ ! -f /usr/share/applications/deepin-tim.desktop || ! -f /usr/share/pixmaps/com.qq.office.deepin.svg ]] && $1-install-tim
[ -n "$($1-query | grep com.qq.weixin.deepin.desktop)" ] && [[ ! -f /usr/share/applications/deepin-weixin.desktop || ! -f /usr/share/pixmaps/com.qq.weixin.deepin.svg ]] && $1-install-weixin
[ -f /usr/share/applications/deepin-qq.desktop ] && cat /usr/share/applications/deepin-qq.desktop | grep $1-
[ -f /usr/share/applications/deepin-tim.desktop ] && cat /usr/share/applications/deepin-tim.desktop | grep $1-
[ -f /usr/share/applications/deepin-weixin.desktop ] && cat /usr/share/applications/deepin-weixin.desktop | grep $1-

# 禁止开机启动
[ "$(systemctl is-enabled nspawn-$1.service)" == "enabled" ] && systemctl disable machines.target
