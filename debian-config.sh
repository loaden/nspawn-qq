#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 设置专属环境变量
SOURCES_LIST="echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free' > /etc/apt/sources.list"

IFS='' read -r -d '' INSTALL_QQ <<EOF
machinectl shell debian /bin/bash -c "[ ! -f /etc/apt/sources.list.d/deepin-wine.i-m.dev.list ] && apt install wget -y && wget -O- https://deepin-wine.i-m.dev/setup.sh | sh"
machinectl shell debian /bin/bash -c "apt update && apt install -y com.qq.im.deepin x11-utils xterm:i386 && apt autopurge -y"
EOF
IFS='' read -r -d '' INSTALL_WEIXIN <<EOF
machinectl shell debian /bin/bash -c "[ ! -f /etc/apt/sources.list.d/deepin-wine.i-m.dev.list ] && apt install wget -y && wget -O- https://deepin-wine.i-m.dev/setup.sh | sh"
machinectl shell debian /bin/bash -c "apt update && apt install -y com.qq.weixin.deepin x11-utils && apt autopurge -y"
EOF


# 开始配置
source `dirname ${BASH_SOURCE[0]}`/base-config.sh debian


# 安装终端
cat > /bin/debian-install-terminal <<EOF
#!/bin/bash
machinectl shell debian /bin/bash -c "apt update && apt install -y xfce4-terminal && apt autopurge -y"
EOF

chmod 755 /bin/debian-install-terminal

# 启动终端
cat > /bin/debian-terminal <<EOF
#!/bin/bash
source /bin/debian-config
machinectl shell debian /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/xfce4-terminal.desktop"
EOF

chmod 755 /bin/debian-terminal
