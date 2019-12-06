#!/bin/bash -x
# $1 : the location of oto8 repository 
# $2 : the script need running in docker
# NOTE : need to run this script as root, because of mount cmd.

# TODO : need to add other script just like subcommand , "./oto_test.sh subcommand [options]" .

BASE_DIR=$(cd $(dirname $0); pwd)
OUT_DIR=$BASE_DIR/out	# every output will be in $OUT_DIR
OUT_BUILD=$OUT_DIR/build.log
OUT_INSTALL=$OUT_DIR/install.log
OUT_LAUNCHER=$OUT_DIR/launcher.log
MAIL_CMD=s-nail

which s-nail
if [ $? -eq 1 ]; then
  MAIL_CMD=mail
fi

if [ -d $OUT_DIR ]; then
  rm -rf $OUT_DIR/*
else
  mkdir $OUT_DIR
fi

# ./bin/build.sh : 如果没有更新，返回2。如果有更新，编译user、userdebug和eng版的镜像。
# 输入：$1,oto8源码的位置；$2,编译脚本的绝对路径；$3,out目录的绝对路径。
# 输出：如返回2，则仓库无更新；否则，会在out目录下放user、userdebug和eng三个版本的镜像。
$BASE_DIR/bin/build.sh $1 $2 $OUT_DIR > $OUT_BUILD 2>&1
if [ $? -eq 2 ]; then
  echo `date +%Y%m%d`"仓库无更新" | $MAIL_CMD -s "AutoTest Result" shizhenxing@openthos.org
  exit
fi

# ./bin/install.sh : 把三个版本的镜像安装到对应的磁盘文件(user.qcow2, userdebug.qcow2, eng.qcow2)。
# 输入：out目录的绝对路径。
# 输出：在out目录下存放安装完系统的磁盘文件。
$BASE_DIR/bin/install.sh $OUT_DIR > $OUT_INSTALL 2>&1

# ./bin/launcher.sh : 启动各磁盘文件，把桌面进程的信息保存到对应的文件里(test.user, test.userdebug, test.eng)。
# 输入：out目录的绝对路径。
# 输出：在out目录下存放包含桌面进程信息的文件。
$BASE_DIR/bin/launcher.sh $OUT_DIR > $OUT_LAUNCHER 2>&1 

$MAIL_CMD -s "AutoTest Result" shizhenxing@openthos.org < $OUT_DIR/result.txt
