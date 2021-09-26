#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 禁用MIT-SHM
[[ $(machinectl list) =~ $1 ]] && machinectl stop $1
DISABLE_X_MITSHM_EXTENSION=1

if [ $DISABLE_X_MITSHM_EXTENSION == 1 ]; then
    if [[ `loginctl show-session $(loginctl | grep $SUDO_USER |awk '{print $1}') -p Type` != *wayland* ]]; then
        mkdir -p /etc/X11/xorg.conf.d
        echo -e 'Section "Extensions"\n    Option "MIT-SHM" "Disable"\nEndSection' > /etc/X11/xorg.conf.d/disable-MIT-SHM.conf
    fi
    cat > /var/lib/machines/$1/disable-MIT-SHM.sh <<EOF
    rm -f /lib/i386-linux-gnu/disable-MIT-SHM.so
    rm -f /lib/x86_64-linux-gnu/disable-MIT-SHM.so
    mkdir -p /etc/X11/xorg.conf.d
    echo -e 'Section "Extensions"\n    Option "MIT-SHM" "Disable"\nEndSection' > /etc/X11/xorg.conf.d/disable-MIT-SHM.conf
EOF
else
    rm -f /etc/X11/xorg.conf.d/disable-MIT-SHM.conf
    [[ ! `ls -A /etc/X11/xorg.conf.d |wc -w` ]] && rm -f /etc/X11/xorg.conf.d
    cp -f `dirname ${BASH_SOURCE[0]}`/xnoshm.c /var/lib/machines/$1/disable-MIT-SHM.c
    cat > /var/lib/machines/$1/disable-MIT-SHM.sh <<EOF
    mkdir -p /etc/X11/xorg.conf.d
    echo -e 'Section "Extensions"\n    Option "MIT-SHM" "Disable"\nEndSection' > /etc/X11/xorg.conf.d/disable-MIT-SHM.conf
    if [[ ! -f /lib/i386-linux-gnu/disable-MIT-SHM.so || ! -f /lib/x86_64-linux-gnu/disable-MIT-SHM.so ]]; then
        dpkg --add-architecture i386
        apt update
        apt install -y gcc gcc-multilib libc6-dev libxext-dev
        gcc /disable-MIT-SHM.c -fPIC -shared -o /lib/x86_64-linux-gnu/disable-MIT-SHM.so
        chmod u+s /lib/x86_64-linux-gnu/disable-MIT-SHM.so
        ls -lh /lib/x86_64-linux-gnu/disable-MIT-SHM.so
        gcc /disable-MIT-SHM.c -fPIC -m32 -shared -o /lib/i386-linux-gnu/disable-MIT-SHM.so
        chmod u+s /lib/i386-linux-gnu/disable-MIT-SHM.so
        ls -lh /lib/i386-linux-gnu/disable-MIT-SHM.so
        rm -f /disable-MIT-SHM.c
        apt purge -y gcc gcc-multilib libc6-dev libxext-dev
        apt autopurge -y
    fi
EOF
fi

chroot /var/lib/machines/$1/ /bin/bash /disable-MIT-SHM.sh


# 导出SHM相关环境变量
DISABLE_MITSHM=$(bash -c 'echo -e "[[ -f /lib/x86_64-linux-gnu/disable-MIT-SHM.so && -f /lib/i386-linux-gnu/disable-MIT-SHM.so ]] && export LD_PRELOAD=disable-MIT-SHM.so
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export _MITSHM=0
"')
