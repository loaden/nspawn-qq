#!/bin/bash
# 维护：Yuchen Deng [Zz] QQ群：19346666、111601117

sudo `dirname ${BASH_SOURCE[0]}`/nspawn-deepinwine/remove-debian.sh

echo -n -e "\033[31m需要我自动帮您删除~/.machines/debian吗？[y/N]\033[0m"
read -p " " choice
case $choice in
Y | y) sudo rm -rf $HOME/.machines/debian && echo $HOME/.machines/debian 已被删除！;;
N | n | '') echo 再见！;;
*) echo 错误选择，请手动删除！;;
esac

