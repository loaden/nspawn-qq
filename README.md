# nspawn-qq

#### 介绍
利用systemd-nspawn容器跑Deepin 20.5或者Debian 11，安装deepinwine，稳定运行QQ、TIM、微信、深度商店等应用。低内存，高性能，沙盒机制不污染宿主机，支持多用户，可在任何以systemd为init的Linux发行版上运行。

<p><b>技术支持QQ群：19346666、111601117</b></p>
<p><b>技术支持钉钉群：35948877</b></p>
TIM下载deepin-tim包。<b>解决微信输入框乱码，执行：deepin-config-weixin，Windows版本选择"Windows 10",“字体”标签页取消选择“允许加载Windows Fonts目录下的字体”。</b>

#### 软件架构
软件架构说明：amd64

#### 一键安装、卸载
1. 下载成品容器压缩包，解压
2. 安装执行：install.sh
3. 卸载执行：remove.sh

#### 从零开始生成容器
1.  执行：sudo ./nspawn-debian.sh 创建 Debian 容器
2.  或者：sudo ./nspawn-deepin.sh 创建 Deepin 容器
3.  也可以同时创建两个容器：sudo ./install.sh
4.  安装微信为例：deepin-install-weixin 或者 debian-install-weixin
5.  配置微信举例：deepin-config-weixin 或者 debian-config-weixin
6.  启动器中查找QQ或者微信启动，或终端启动，例如：deepin-qq 或者 debian-qq
7.  打开容器内的终端：deepin-terminal 或者 debian-terminal

#### 多系统配置
1.  自动安装的容器支持多系统共享，请提前做好 ~/.machines 的软链接
2.  管理员权限执行：sudo ./debian-config.sh 或者 sudo ./deepin-config.sh
3.  可以同时配置两个容器：sudo ./config.sh

#### 升级方法
1.  普通用户权限执行：deepin-update 或者 debian-update
2.  如果需要升级容器，执行：deepin-upgrade 或者 debian-upgrade

#### 高级用法
1.  如果稳定性不佳，请同时禁用宿主机和容器的MIT-SHM扩展：sudo DISABLE_HOST_MITSHM=1 ./deepin-config.sh (注意：深度商店点击链接崩溃是软件不稳定，不是容器不稳定)
2.  注意：禁用宿主机MIT-SHM后，需要重启电脑才生效！
3.  可登录shell，执行：machinectl login debian，<b>用户名u1000，密码与用户名相同。</b>
4.  可禁止多用户模式：sudo MULTIUSER_SUPPORT=0 ./deepin-config.sh

#### 软件列表
1.  以 deepin 为例罗列应用，带星号(*)的代表 debian 容器也有。
2.  非本列表的应用，需要你在商店或者终端安装，然后添加启动脚本。
3.  如遇到容器中的无法打开链接之类的问题，请为容器安装相关软件。
4.  终端中启动容器软件后，可以关闭终端窗口。
5.  为什么会包含一些原生软件：因为容器中文件关联需要，例如QQ打开链接，文件管理器编辑文档、播放视频音频、查看图片等。

| 应用名称      | 安装脚本                     | 启动脚本                  |
| :---        | :----                       | :----                    |
| QQ*         | deepin-install-qq           | deepin-qq                |
| TIM*        | deepin-install-tim          | deepin-tim               |
| 微信*        | deepin-install-weixin       | deepin-weixin            |
| 天翼云盘*     | deepin-install-ecloud       | deepin-ecloud            |
| 终端*        | deepin-install-terminal     | deepin-terminal          |
| 文件管理器*   | deepin-install-file         | deepin-file              |
| 浏览器*      | deepin-install-chromium     | deepin-chromium          |
| LibreOffice*| deepin-install-libreoffice  | deepin-libreoffice       |
| 媒体播放器*   | deepin-install-mpv          | deepin-mpv               |
| 图片浏览*     | deepin-install-shotwell     | deepin-shotwell          |
| PDF阅读*     | deepin-install-mupdf        | deepin-mupdf             |
| 商店         | deepin-install-app-store    | deepin-app-store         |
| 迅雷         | deepin-install-xunlei       | deepin-xunlei            |
| 金山词霸      | deepin-install-powerword    | deepin-powerword         |
| 腾讯会议      | deepin-install-wemeet       | deepin-wemeet            |
| 央视影音      | deepin-install-cbox         | deepin-cbox              |
| 向日葵远程控制 | deepin-install-sunlogin     | deepin-sunlogin          |
| 百度网盘      | deepin-install-baidunetdisk | deepin-baidunetdisk      |
| 腾讯视频      | deepin-install-tenvideo     | deepin-tenvideo          |
| 反恐精英      | deepin-install-cstrike      | deepin-cstrike           |
| 野狐围棋      | deepin-install-foxwq        | deepin-foxwq             |
| 企业微信      | deepin-install-work-weixin  | deepin-work-weixin       |
| 全民K歌      | deepin-install-wesing       | deepin-wesing            |
| 保卫萝卜      | deepin-install-baoweiluobo  | deepin-baoweiluobo       |
| 更多...      | 欢迎...                      | PR...                    |

#### 参与贡献
1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request

#### 致谢
Debian 容器用到了 https://deepin-wine.i-m.dev/ 的作品。
在此感谢作者为开源做出的贡献。
