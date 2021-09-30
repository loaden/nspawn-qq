#!/bin/bash
# 维护：Yuchen Deng QQ群：19346666、111601117

# 确认管理员权限
if [ $UID != 0 -o "$SUDO_USER" == "root" ]; then
    echo "请先打开终端，执行 sudo -s 获得管理员权限后再运行本脚本。"
    exit 1
fi


# 设置专属环境变量
SOURCES_LIST="echo 'deb [by-hash=force] https://community-packages.deepin.com/deepin/ apricot main contrib non-free' > /etc/apt/sources.list
echo 'deb https://com-store-packages.uniontech.com/appstore deepin appstore' > /etc/apt/sources.list.d/appstore.list"

IFS='' read -r -d '' INSTALL_QQ <<EOF
machinectl shell deepin /usr/bin/bash -c "dpkg --add-architecture i386 && apt update && apt install -y com.qq.im.deepin && apt autopurge -y"
EOF
IFS='' read -r -d '' INSTALL_WEIXIN <<EOF
machinectl shell deepin /usr/bin/bash -c "dpkg --add-architecture i386 && apt update && apt install -y com.qq.weixin.deepin x11-utils && apt autopurge -y"
EOF

# 开始配置
source `dirname ${BASH_SOURCE[0]}`/base-config.sh deepin


# 安装终端
cat > /bin/deepin-install-terminal <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y lxterminal deepin-desktop-base --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-terminal

# 启动终端
cat > /bin/deepin-terminal <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/lxterminal.desktop"
EOF

chmod 755 /bin/deepin-terminal


# 安装深度商店
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


# 安装腾讯视频
cat > /bin/deepin-install-tenvideo <<EOF
machinectl shell deepin /usr/bin/bash -c "apt update && apt install -y com.qq.tenvideo && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-tenvideo

# 启动腾讯视频
cat > /bin/deepin-tenvideo <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.tenvideo/entries/applications/com.qq.tenvideo.desktop"
EOF

chmod 755 /bin/deepin-tenvideo
