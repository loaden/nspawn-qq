#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

sudo `dirname ${BASH_SOURCE[0]}`/nspawn-deepinwine/remove-deepin.sh

echo -n -e "\033[31m需要我自动帮您删除~/.machines/deepin吗？[y/N]\033[0m"
read -p " " choice
case $choice in
Y | y) sudo rm -rf $HOME/.machines/deepin && echo $HOME/.machines/deepin 已被删除！;;
N | n | '') echo 再见！ && sleep 2 && exit ;;
*) echo 错误选择，请手动删除！ && sleep 2 && exit 1 ;;
esac
