# nspawn-deepinwine

#### 介绍
利用systemd-nspawn容器跑Deepin 20.2.4或者Debian 10，安装deepinwine，稳定运行QQ、微信、钉钉、深度商店等应用。低内存，高性能，沙盒机制不污染宿主机，支持多用户，理论上可在任何Linux发行版上运行。成功解决MIT-SHM导致的崩溃，好开心！现在很稳定了。

<p><b>技术支持QQ群：19346666、111601117</b></p>

#### 软件架构
软件架构说明：amd64

#### 安装教程
1.  下载或者克隆源码库
2.  终端打开源码库所在路径

#### 使用说明
1.  执行：sudo ./nspawn-debian.sh 安装 Debian 10
2.  或者：sudo ./nspawn-deepin.sh 安装 Deepin 20.2.4
3.  也可以同时安装两个容器：sudo ./install.sh
4.  安装应用，请终端执行：debian-install-qq 或者 deepin-install-qq
5.  更多应用安装，请查看：ls /usr/local/bin/\*-install-\*
6.  启动器中查找QQ或者微信启动，或终端启动，例如：debian-qq
7.  卸载软件请先安装终端：debian-install-terminal，之后进终端命令卸载

#### 多系统配置
1.  自动安装的容器支持多系统共享，请提前做好 ~/.machines 的软链接
2.  管理员权限执行：sudo ./debian-config.sh 或者 sudo ./deepin-config.sh
3.  如果同时配置两个容器，可以终端管理员权限执行：sudo ./config.sh

#### 升级方法
1.  管理员权限执行：sudo ./debian-config.sh 或者 sudo ./deepin-config.sh
2.  如果同时升级两个容器，可以终端管理员权限执行：sudo ./config.sh

#### 高级用法
1.  如果稳定性不佳，请同时禁用宿主机和容器的MIT-SHM扩展：sudo DISABLE_HOST_MITSHM=1 ./deepin-config.sh (注意：深度商店点击链接崩溃是软件不稳定，不是容器不稳定)
2.  注意：禁用宿主机MIT-SHM后，需要重启电脑才生效！
3.  可登录shell，执行：machinectl login debian，<b>用户名u1000，密码passwd</b>
4.  可禁止多用户模式：sudo MULTIUSER_SUPPORT=0 ./deepin-config.sh
5.  注意：Debian 11 以及 Ubuntu 21.10 等系统因 systemd 247 版本存在 bug，将自动禁用多用户模式。

#### 软件列表
1.  以 deepin 为例罗列应用，带星号(*)的代表 debian 容器也有。
2.  非本列表的应用，需要你在商店或者终端安装，然后添加启动脚本。
3.  如遇到容器中的无法打开链接之类的问题，请为容器安装相关软件。
4.  终端中启动容器软件后，可以关闭终端窗口。

| 应用名称      | 安装脚本                     | 启动脚本                  |
| :---        | :----                       | :----                    |
| QQ*         | deepin-install-qq           | deepin-qq                |
| 微信*        | deepin-install-weixin       | deepin-weixin            |
| 终端*        | deepin-install-terminal     | deepin-terminal          |
| 文件管理器*   | deepin-install-thunar       | deepin-thunar            |
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
| 飞书         | deepin-install-feishu       | deepin-feishu            |
| 向日葵远程控制 | deepin-install-sunlogin     | deepin-sunlogin          |
| 百度网盘      | deepin-install-baidunetdisk | deepin-baidunetdisk      |
| 腾讯视频      | deepin-install-tenvideo     | deepin-tenvideo          |
| 反恐精英      | deepin-install-cstrike      | deepin-cstrike           |
| 野狐围棋      | deepin-install-foxwq        | deepin-foxwq             |
| 钉钉wine     | deepin-install-dingtalk-wine | deepin-dingtalk-wine    |
| 钉钉         | deepin-install-dingtalk     | deepin-dingtalk          |
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
