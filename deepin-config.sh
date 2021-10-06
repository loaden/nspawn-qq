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
machinectl shell deepin /bin/bash -c "dpkg --add-architecture i386 && apt update && apt install -y com.qq.im.deepin x11-utils xterm:i386 && apt autopurge -y"
EOF
IFS='' read -r -d '' INSTALL_WEIXIN <<EOF
machinectl shell deepin /bin/bash -c "dpkg --add-architecture i386 && apt update && apt install -y com.qq.weixin.deepin x11-utils && apt autopurge -y"
EOF

# 开始配置
source `dirname ${BASH_SOURCE[0]}`/base-config.sh deepin


# 安装终端
cat > /bin/deepin-install-terminal <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y lxterminal --no-install-recommends && update-alternatives --set x-terminal-emulator /usr/bin/lxterminal && apt autopurge -y"
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
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y deepin-app-store && apt autopurge -y"
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
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.qq.wemeet libgl1-mesa-dev deepin-desktop-base && apt autopurge -y"
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
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.xunlei.download libxss1 libdbus-glib-1-2 && apt autopurge -y"
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
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.qq.tenvideo && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-tenvideo

# 启动腾讯视频
cat > /bin/deepin-tenvideo <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.tenvideo/entries/applications/com.qq.tenvideo.desktop"
EOF

chmod 755 /bin/deepin-tenvideo


# 安装金山词霸
cat > /bin/deepin-install-powerword <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.kingsoft.powerword && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-powerword

# 启动金山词霸
cat > /bin/deepin-powerword <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.kingsoft.powerword/entries/applications/com.kingsoft.powerword.desktop"
EOF

chmod 755 /bin/deepin-powerword


# 安装央视影音
cat > /bin/deepin-install-cbox <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.cbox.deepin && sed -i 's/LD_PRELOAD=/LD_DONT_PRELOAD=/g' /opt/apps/com.cbox.deepin/files/run.sh && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-cbox

# 启动央视影音
cat > /bin/deepin-cbox <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.cbox.deepin/entries/applications/com.cbox.deepin.desktop"
EOF

chmod 755 /bin/deepin-cbox


# 安装飞书
cat > /bin/deepin-install-feishu <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.bytedance.feishu && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-feishu

# 启动飞书
cat > /bin/deepin-feishu <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.bytedance.feishu/entries/applications/com.bytedance.feishu.desktop"
EOF

chmod 755 /bin/deepin-feishu


# 安装向日葵远程控制
cat > /bin/deepin-install-sunlogin <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.oray.sunlogin.client && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-sunlogin

# 启动向日葵远程控制
cat > /bin/deepin-sunlogin <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.oray.sunlogin.client/entries/applications/com.oray.sunlogin.client.desktop"
EOF

chmod 755 /bin/deepin-sunlogin


# 安装向日葵远程控制
cat > /bin/deepin-install-sunlogin <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.oray.sunlogin.client && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-sunlogin

# 启动向日葵远程控制
cat > /bin/deepin-sunlogin <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.oray.sunlogin.client/entries/applications/com.oray.sunlogin.client.desktop"
EOF

chmod 755 /bin/deepin-sunlogin


# 安装野狐围棋
cat > /bin/deepin-install-foxwq <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.foxwq.deepin && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-foxwq

# 启动野狐围棋
cat > /bin/deepin-foxwq <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.foxwq.deepin/entries/applications/com.foxwq.deepin.desktop"
EOF

chmod 755 /bin/deepin-foxwq


# 安装百度网盘
cat > /bin/deepin-install-baidunetdisk <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.baidu.baidunetdisk desktop-file-utils && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-baidunetdisk

# 启动百度网盘
cat > /bin/deepin-baidunetdisk <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.baidu.baidunetdisk/entries/applications/com.baidu.baidunetdisk.desktop"
EOF

chmod 755 /bin/deepin-baidunetdisk


# 安装反恐精英
cat > /bin/deepin-install-cstrike <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y cn.linuxgame.cstrike fuse && apt autopurge -y"
sudo modprobe fuse
EOF

chmod 755 /bin/deepin-install-cstrike

# 启动反恐精英
cat > /bin/deepin-cstrike <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/cn.linuxgame.cstrike/entries/applications/com.cs.cstrike.desktop"
EOF

chmod 755 /bin/deepin-cstrike


# 安装钉钉
cat > /bin/deepin-install-dingtalk-wine <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.dingtalk.deepin x11-utils && apt autopurge -y \
    && ! grep -c DingTalkUpdater.exe /opt/apps/com.dingtalk.deepin/files/run.sh \
    && echo 'cp -f /dev/null ~/.deepinwine/Deepin-Dding/drive_c/Program\ Files/DingDing/DingTalkUpdater.exe' >> /opt/apps/com.dingtalk.deepin/files/run.sh \
    && sed -i 's/LD_PRELOAD=/LD_DONT_PRELOAD=/g' /opt/apps/com.dingtalk.deepin/files/run.sh"
EOF

chmod 755 /bin/deepin-install-dingtalk-wine

cat > /bin/deepin-install-dingtalk <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.alibabainc.dingtalk libpulse-mainloop-glib0 && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-dingtalk


# 启动钉钉
cat > /bin/deepin-dingtalk-wine <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.dingtalk.deepin/entries/applications/com.dingtalk.deepin.desktop"
EOF

chmod 755 /bin/deepin-dingtalk-wine

cat > /bin/deepin-dingtalk <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.alibabainc.dingtalk/entries/applications/com.alibabainc.dingtalk.desktop"
EOF

chmod 755 /bin/deepin-dingtalk


# 安装企业微信
cat > /bin/deepin-install-work-weixin <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.qq.weixin.work.deepin && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-work-weixin

# 启动企业微信
cat > /bin/deepin-work-weixin <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop"
EOF

chmod 755 /bin/deepin-work-weixin


# 安装全民K歌
cat > /bin/deepin-install-wesing <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.wesing.deepin && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-wesing

# 启动全民K歌
cat > /bin/deepin-wesing <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.wesing.deepin/entries/applications/com.wesing.deepin.desktop"
EOF

chmod 755 /bin/deepin-wesing


# 安装保卫萝卜
cat > /bin/deepin-install-baoweiluobo <<EOF
#!/bin/bash
machinectl shell deepin /bin/bash -c "apt update && apt install -y com.baoweiluobo.deepin && apt autopurge -y"
EOF

chmod 755 /bin/deepin-install-baoweiluobo

# 启动保卫萝卜
cat > /bin/deepin-baoweiluobo <<EOF
#!/bin/bash
source /bin/deepin-config
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.baoweiluobo.deepin/entries/applications/com.baoweiluobo.deepin.desktop"
EOF

chmod 755 /bin/deepin-baoweiluobo
