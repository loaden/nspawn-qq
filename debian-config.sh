#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 确认管理员权限
if [[ $EUID != 0 ]]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi


# 容器不存在时先创建
if [ ! -d /home/$SUDO_USER/.machines/debian ]; then
    echo "容器 debian 不存在，即将自动创建，请耐心等待..."
    source `dirname ${BASH_SOURCE[0]}`/nspawn-debian.sh
    exit 0
fi


# 设置专属环境变量
SOURCES_LIST="echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free' > /etc/apt/sources.list"

IFS='' read -r -d '' INSTALL_QQ <<EOF
machinectl shell debian /bin/bash -c "[ ! -f /etc/apt/sources.list.d/deepin-wine.i-m.dev.list ] && apt install wget -y && wget -O- https://deepin-wine.i-m.dev/setup.sh | sh"
machinectl shell debian /bin/bash -c "apt install -y com.qq.im.deepin x11-utils --no-install-recommends && apt autopurge -y"
EOF
IFS='' read -r -d '' INSTALL_WEIXIN <<EOF
machinectl shell debian /bin/bash -c "[ ! -f /etc/apt/sources.list.d/deepin-wine.i-m.dev.list ] && apt install wget -y && wget -O- https://deepin-wine.i-m.dev/setup.sh | sh"
machinectl shell debian /bin/bash -c "apt install -y com.qq.weixin.deepin x11-utils --no-install-recommends && apt autopurge -y"
EOF


# 开始配置
source `dirname ${BASH_SOURCE[0]}`/base-config.sh debian


# 安装终端
cat > /usr/local/bin/debian-install-terminal <<EOF
#!/bin/bash
source /usr/local/bin/debian-config
machinectl shell debian /bin/bash -c "apt install -y xfce4-terminal libcanberra-gtk3-module --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/debian-install-terminal

# 启动终端
cat > /usr/local/bin/debian-terminal <<EOF
#!/bin/bash
source /usr/local/bin/debian-config
source /usr/local/bin/debian-bind
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/xfce4-terminal.desktop"
EOF

chmod 755 /usr/local/bin/debian-terminal


# 安装所有
cat > /usr/local/bin/debian-install-all <<EOF
debian-install-qq
debian-install-weixin
debian-install-terminal
debian-install-thunar
debian-install-chromium
debian-install-libreoffice
debian-install-mpv
debian-install-shotwell
debian-install-mupdf
EOF

chmod 755 /usr/local/bin/debian-install-all
