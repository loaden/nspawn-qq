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
4.  安装应用，请终端执行：debian-install-qq 或者 deepin-install-qq
5.  更多应用安装，请查看：ls /bin/*-install-*
6.  启动器中查找QQ或者微信启动，也可以终端启动，例如：debian-qq

#### 多系统配置
1.  自动安装的容器支持多系统共享，请提前做好~/.machines的软链接
2.  管理员权限执行：debian-config.sh 或者 deepin-config.sh
3.  如果同时配置两个容器，可以终端管理员权限执行：config.sh
4.  也可以同时安装两个容器：install.sh

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
