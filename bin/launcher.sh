#!/bin/bash -x
# $1 : out dir

BASE_DIR=$(dirname $1)

if [ ! -e /dev/nbd0 ]; then
  modprobe nbd
fi

# launcher_test : print the pid of launcher to a file
# $1 : out dir
# $2 : the version of openthos(user,userdebug,eng)
function launcher_test() {
  touch $1/result.txt
  if [ ! -f $1/$2.qcow2 ]; then
    echo "* $2.qcow2不存在" >> $1/result.txt
    return 0
  else
    echo "* $2.qcow2已生成" >> $1/result.txt
  fi
  qemu-nbd -c /dev/nbd0 $1/$2.qcow2
  sleep 1

  if [ ! -e /dev/nbd0p2 ]; then
    echo "/dev/nbd0p2 does not exist"
    qemu-nbd -d /dev/nbd0
    return 2
  fi

  mount /dev/nbd0p2 $1/mnt_point
  sed -i '$d' $1/mnt_point/etc/init.sh
  cat $BASE_DIR/tools/check_launcher.txt >> $1/mnt_point/etc/init.sh
  sync
  umount -l $1/mnt_point

  timeout 300 qemu-system-x86_64 -bios $BASE_DIR/tools/OVMF.fd -m 4G -enable-kvm -hda /dev/nbd0 -vnc :3

  mount /dev/nbd0p3 $1/mnt_point
  cp $1/mnt_point/media/0/result.txt $1/result_launcher.$2
  umount $1/mnt_point
  qemu-nbd -d /dev/nbd0
}

# generate_result : generate result.txt which is human friendly
# $1 : out dir
function generate_result() {
  touch $1/result.txt
  for i in {user,userdebug,eng}; do
    if [ ! -f $1/result_launcher.$i ]; then
      echo "* result_launcher.$i不存在" >> $1/result.txt
      continue
    fi
    grep launcher $1/result_launcher.$i
    if [ $? == 0 ]; then 
      echo "* $i版正常启动至桌面。" >> $1/result.txt
    else
      echo "* $i版未能启动至桌面。" >> $1/result.txt
    fi
  done
}

echo "#### 安装结果" >> $1/result.txt
launcher_test $1 user
launcher_test $1 userdebug
launcher_test $1 eng

echo "#### 启动结果" >> $1/result.txt
generate_result $1
