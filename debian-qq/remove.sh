#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

# 仅允许普通用户权限执行
if [ $EUID == 0 ]; then
    echo $(basename $0) 命令只允许普通用户执行
    exit 1
fi

sudo `dirname ${BASH_SOURCE[0]}`/nspawn-deepinwine/remove-debian.sh

echo -n -e "\033[31m需要我自动帮您删除~/.machines/debian吗？[y/N]\033[0m"
read -p " " choice
case $choice in
Y | y) sudo rm -rf $HOME/.machines/debian && echo $HOME/.machines/debian 已被删除！;;
N | n | '') echo 再见！ && sleep 2 && exit ;;
*) echo 错误选择，请手动删除！ && sleep 2 && exit 1 ;;
esac
