#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 确认管理员权限
if [[ $EUID != 0 ]]; then
    echo "请打开终端，在脚本前添加 sudo 执行，或者 sudo -s 获得管理员权限后再执行。"
    exit 1
fi


# 容器不存在时先创建
if [ ! -d /home/$SUDO_USER/.machines/deepin ]; then
    echo "容器 deepin 不存在，即将自动创建，请耐心等待..."
    source `dirname ${BASH_SOURCE[0]}`/nspawn-deepin.sh
    exit 0
fi


# 设置专属环境变量
SOURCES_LIST="echo 'deb [by-hash=force] https://community-packages.deepin.com/deepin/ apricot main contrib non-free' > /etc/apt/sources.list
echo 'deb https://com-store-packages.uniontech.com/appstore deepin appstore' > /etc/apt/sources.list.d/appstore.list"

IFS='' read -r -d '' INSTALL_QQ <<EOF
machinectl shell deepin /bin/bash -c "apt install -y com.qq.im.deepin x11-utils --no-install-recommends && apt autopurge -y"
EOF
IFS='' read -r -d '' INSTALL_TIM <<EOF
machinectl shell deepin /bin/bash -c "apt install -y com.qq.office.deepin x11-utils --no-install-recommends && apt autopurge -y"
EOF
IFS='' read -r -d '' INSTALL_WEIXIN <<EOF
machinectl shell deepin /bin/bash -c "apt install -y com.qq.weixin.deepin x11-utils --no-install-recommends && apt autopurge -y"
EOF


# 开始配置
source `dirname ${BASH_SOURCE[0]}`/base-config.sh deepin


# 安装深度商店
cat > /usr/local/bin/deepin-install-app-store <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y deepin-app-store --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-app-store

# 启动深度商店
cat > /usr/local/bin/deepin-app-store <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /usr/share/applications/deepin-app-store.desktop"
EOF

chmod 755 /usr/local/bin/deepin-app-store


# 安装腾讯会议
cat > /usr/local/bin/deepin-install-wemeet <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.qq.wemeet libgl1-mesa-dev --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-wemeet

# 启动腾讯会议
cat > /usr/local/bin/deepin-wemeet <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.wemeet/entries/applications/com.qq.wemeet.desktop"
EOF

chmod 755 /usr/local/bin/deepin-wemeet


# 安装迅雷
cat > /usr/local/bin/deepin-install-xunlei <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.xunlei.download libxss1 libdbus-glib-1-2 --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-xunlei

# 启动迅雷
cat > /usr/local/bin/deepin-xunlei <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.xunlei.download/entries/applications/com.xunlei.download.desktop"
EOF

chmod 755 /usr/local/bin/deepin-xunlei


# 安装腾讯视频
cat > /usr/local/bin/deepin-install-tenvideo <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.qq.tenvideo --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-tenvideo

# 启动腾讯视频
cat > /usr/local/bin/deepin-tenvideo <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.tenvideo/entries/applications/com.qq.tenvideo.desktop"
EOF

chmod 755 /usr/local/bin/deepin-tenvideo


# 安装金山词霸
cat > /usr/local/bin/deepin-install-powerword <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.kingsoft.powerword --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-powerword

# 启动金山词霸
cat > /usr/local/bin/deepin-powerword <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.kingsoft.powerword/entries/applications/com.kingsoft.powerword.desktop"
EOF

chmod 755 /usr/local/bin/deepin-powerword


# 安装央视影音
cat > /usr/local/bin/deepin-install-cbox <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.cbox.deepin --no-install-recommends && sed -i 's/LD_PRELOAD=/LD_DONT_PRELOAD=/g' /opt/apps/com.cbox.deepin/files/run.sh && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-cbox

# 启动央视影音
cat > /usr/local/bin/deepin-cbox <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.cbox.deepin/entries/applications/com.cbox.deepin.desktop"
EOF

chmod 755 /usr/local/bin/deepin-cbox


# 安装飞书
cat > /usr/local/bin/deepin-install-feishu <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.bytedance.feishu --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-feishu

# 启动飞书
cat > /usr/local/bin/deepin-feishu <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.bytedance.feishu/entries/applications/com.bytedance.feishu.desktop"
EOF

chmod 755 /usr/local/bin/deepin-feishu


# 安装向日葵远程控制
cat > /usr/local/bin/deepin-install-sunlogin <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.oray.sunlogin.client --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-sunlogin

# 启动向日葵远程控制
cat > /usr/local/bin/deepin-sunlogin <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.oray.sunlogin.client/entries/applications/com.oray.sunlogin.client.desktop"
EOF

chmod 755 /usr/local/bin/deepin-sunlogin


# 安装向日葵远程控制
cat > /usr/local/bin/deepin-install-sunlogin <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.oray.sunlogin.client --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-sunlogin

# 启动向日葵远程控制
cat > /usr/local/bin/deepin-sunlogin <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.oray.sunlogin.client/entries/applications/com.oray.sunlogin.client.desktop"
EOF

chmod 755 /usr/local/bin/deepin-sunlogin


# 安装野狐围棋
cat > /usr/local/bin/deepin-install-foxwq <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.foxwq.deepin --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-foxwq

# 启动野狐围棋
cat > /usr/local/bin/deepin-foxwq <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.foxwq.deepin/entries/applications/com.foxwq.deepin.desktop"
EOF

chmod 755 /usr/local/bin/deepin-foxwq


# 安装百度网盘
cat > /usr/local/bin/deepin-install-baidunetdisk <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.baidu.baidunetdisk desktop-file-utils --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-baidunetdisk

# 启动百度网盘
cat > /usr/local/bin/deepin-baidunetdisk <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.baidu.baidunetdisk/entries/applications/com.baidu.baidunetdisk.desktop"
EOF

chmod 755 /usr/local/bin/deepin-baidunetdisk


# 安装反恐精英
cat > /usr/local/bin/deepin-install-cstrike <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y cn.linuxgame.cstrike fuse --no-install-recommends && apt autopurge -y"
sudo modprobe fuse
EOF

chmod 755 /usr/local/bin/deepin-install-cstrike

# 启动反恐精英
cat > /usr/local/bin/deepin-cstrike <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/cn.linuxgame.cstrike/entries/applications/com.cs.cstrike.desktop"
EOF

chmod 755 /usr/local/bin/deepin-cstrike


# 安装钉钉
cat > /usr/local/bin/deepin-install-dingtalk-wine <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.dingtalk.deepin x11-utils --no-install-recommends && apt autopurge -y \
    && ! grep -c DingTalkUpdater.exe /opt/apps/com.dingtalk.deepin/files/run.sh \
    && echo 'cp -f /dev/null ~/.deepinwine/Deepin-Dding/drive_c/Program\ Files/DingDing/DingTalkUpdater.exe' >> /opt/apps/com.dingtalk.deepin/files/run.sh \
    && sed -i 's/LD_PRELOAD=/LD_DONT_PRELOAD=/g' /opt/apps/com.dingtalk.deepin/files/run.sh"
EOF

chmod 755 /usr/local/bin/deepin-install-dingtalk-wine

cat > /usr/local/bin/deepin-install-dingtalk <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.alibabainc.dingtalk libpulse-mainloop-glib0 --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-dingtalk


# 启动钉钉
cat > /usr/local/bin/deepin-dingtalk-wine <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.dingtalk.deepin/entries/applications/com.dingtalk.deepin.desktop"
EOF

chmod 755 /usr/local/bin/deepin-dingtalk-wine

cat > /usr/local/bin/deepin-dingtalk <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.alibabainc.dingtalk/entries/applications/com.alibabainc.dingtalk.desktop"
EOF

chmod 755 /usr/local/bin/deepin-dingtalk


# 安装企业微信
cat > /usr/local/bin/deepin-install-work-weixin <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.qq.weixin.work.deepin --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-work-weixin

# 启动企业微信
cat > /usr/local/bin/deepin-work-weixin <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop"
EOF

chmod 755 /usr/local/bin/deepin-work-weixin


# 安装全民K歌
cat > /usr/local/bin/deepin-install-wesing <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.wesing.deepin --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-wesing

# 启动全民K歌
cat > /usr/local/bin/deepin-wesing <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.wesing.deepin/entries/applications/com.wesing.deepin.desktop"
EOF

chmod 755 /usr/local/bin/deepin-wesing


# 安装保卫萝卜
cat > /usr/local/bin/deepin-install-baoweiluobo <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
machinectl shell deepin /bin/bash -c "apt install -y com.baoweiluobo.deepin --no-install-recommends && apt autopurge -y"
EOF

chmod 755 /usr/local/bin/deepin-install-baoweiluobo

# 启动保卫萝卜
cat > /usr/local/bin/deepin-baoweiluobo <<EOF
#!/bin/bash
source /usr/local/bin/deepin-config
source /usr/local/bin/deepin-bind
machinectl shell deepin /bin/su - u\$UID -c "\$RUN_ENVIRONMENT start /opt/apps/com.baoweiluobo.deepin/entries/applications/com.baoweiluobo.deepin.desktop"
EOF

chmod 755 /usr/local/bin/deepin-baoweiluobo


# 安装所有
cat > /usr/local/bin/deepin-install-all <<EOF
deepin-install-qq
deepin-install-weixin
deepin-install-terminal
deepin-install-file
deepin-install-chromium
deepin-install-libreoffice
deepin-install-mpv
deepin-install-shotwell
deepin-install-mupdf
deepin-install-app-store
deepin-install-xunlei
deepin-install-powerword
deepin-install-wemeet
deepin-install-cbox
deepin-install-feishu
deepin-install-sunlogin
deepin-install-baidunetdisk
deepin-install-tenvideo
deepin-install-cstrike
deepin-install-foxwq
deepin-install-dingtalk-wine
deepin-install-dingtalk
deepin-install-work-weixin
deepin-install-wesing
deepin-install-baoweiluobo
EOF

chmod 755 /usr/local/bin/deepin-install-all
