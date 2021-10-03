# nspawn-deepinwine

#### 介绍
利用systemd-nspawn容器跑Deepin 20.2.3或者Debian 10，安装deepinwine，稳定运行QQ、微信、钉钉、深度商店等应用。低内存，高性能，沙盒机制不污染宿主机，支持多用户，理论上可在任何Linux发行版上运行。成功解决MIT-SHM导致的崩溃，好开心！现在很稳定了。

#### 软件架构
软件架构说明：amd64


#### 安装教程

1.  下载或者克隆源码库
2.  终端打开源码库所在路径

#### 使用说明

1.  在源码库脚本所在路径终端执行命令：sudo -s 获取管理员权限
2.  执行：./nspawn-debian.sh 安装 Debian 10
3.  或者：./nspawn-deepin.sh 安装 Deepin 20.2.3
4.  也可以：sudo ./nspawn-debian.sh 这种方式
5.  也可以同时安装两个容器：install.sh
6.  安装应用，请终端执行：debian-install-qq 或者 deepin-install-qq
7.  更多应用安装，请查看：ls \*-install-\*
8.  启动器中查找QQ或者微信启动，也可以终端启动，例如：debian-qq
9.  卸载软件请先安装终端：debian-install-terminal，之后进终端命令卸载

#### 多系统配置
1.  自动安装的容器支持多系统共享，请提前做好~/.machines的软链接
2.  管理员权限执行：sudo ./debian-config.sh 或者 sudo ./deepin-config.sh
3.  如果同时配置两个容器，可以终端管理员权限执行：sudo ./config.sh

#### 高级用法
1.  如果稳定性不佳，请同时禁用宿主机和容器的MIT-SHM扩展：sudo DISABLE_HOST_MITSHM=1 ./nspawn-config.sh
2.  注意：禁用宿主机MIT-SHM后，需要重启电脑才生效！
3.  可登录shell，执行：machinectl login debian，用户名u1000，密码passwd

#### 软件列表
1.  以 deepin 为例罗列应用，更多应用可在应用商店安装或者卸载。
2.  非本列表的应用，需要你在商店或者终端安装，然后添加启动脚本。
3.  欢迎为应用添加启动器图标，期待你的PR。

| 应用名称      | 安装脚本                     | 启动脚本                  |
| :---        | :----                       | :----                    |
| QQ          | deepin-install-qq           | deepin-qq                |
| 微信         | deepin-install-weixin       | deepin-weixin            |
| 商店         | deepin-install-app-store    | deepin-app-store         |
| 迅雷         | deepin-install-xunlei       | deepin-xunlei            |
| 终端         | deepin-install-terminal     | deepin-terminal          |
| 文件管理器    | deepin-install-thunar       | deepin-thunar            |
| 金山词霸      | deepin-install-powerword    | deepin-powerword         |
| 腾讯会议      | deepin-install-wemeet       | deepin-wemeet            |
| 央视影音      | deepin-install-cbox         | deepin-cbox              |
| 飞书         | deepin-install-feishu       | deepin-feishu            |
| 向日葵远程控制 | deepin-install-sunlogin     | deepin-sunlogin          |
| 视频播放器    | deepin-install-mpv          | deepin-mpv               |
| 百度网盘      | deepin-install-baidunetdisk | deepin-baidunetdisk      |
| 腾讯视频      | deepin-install-tenvideo     | deepin-tenvideo          |
| 反恐精英      | deepin-install-cstrike      | deepin-cstrike           |
| 野狐围棋      | deepin-install-foxwq        | deepin-foxwq             |
| 钉钉         | deepin-install-dingtalk     | deepin-dingtalk          |
| 企业微信      | deepin-install-work-weixin  | deepin-work-weixin       |
| 更多...      | 欢迎...                      | PR...                    |

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request

#### 致谢
Debian 容器用到了 https://deepin-wine.i-m.dev/ 的作品。
在此感谢作者为开源做出的贡献。
