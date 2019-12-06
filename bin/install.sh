#!/bin/bash -x
# $1 : the out dir

BASE_DIR=$(dirname $1)
IMG_USER=`ls -t $1 | grep "user.img"`
IMG_USERDBG=`ls -t $1 | grep "userdebug.img"`
IMG_ENG=`ls -t $1 | grep "eng.img"`
touch $1/result.txt


if [ ! -d $1/mnt_point ]; then
  mkdir  $1/mnt_point
fi

# mk_auto_install_img : make auto install img
# $1 : img name
# $2 : the out dir
function mk_auto_install_img() {
  mount -o loop,offset=1048576 $2/$1 $2/mnt_point
  cp -f $BASE_DIR/tools/refind.conf $2/mnt_point/efi/boto/
  cp -f $BASE_DIR/tools/boto_linux.conf $2/mnt_point/OpenThos/
  cp -f $BASE_DIR/tools/install.img $2/mnt_point/OpenThos/
  cp -f $BASE_DIR/tools/efi.tar.bz2 $2/mnt_point/OpenThos/
  sync
  umount $2/mnt_point
}

# auto_install : auto install img to disk
# $1 : img name
# $2 : the out dir
# $3 : disk name
function auto_install() {
  qemu-img create -f qcow2 $2/$3 10G
  wait
  qemu-system-x86_64 -m 4G -enable-kvm -bios $BASE_DIR/tools/OVMF.fd -hda $2/$1 -hdb $2/$3 -vnc :3
}

echo "#### 编译结果" >> $1/result.txt

if [ -z $IMG_USER ]; then
  echo "* user版镜像编译失败!" >> $1/result.txt
else
  echo "* user版镜像编译成功!" >> $1/result.txt
  mk_auto_install_img $IMG_USER $1
  auto_install $IMG_USER $1 user.qcow2
fi

if [ -z $IMG_USERDBG];then
  echo "* userdebug版镜像编译失败!" >> $1/result.txt
else
  echo "* userdebug版镜像编译成功!" >> $1/result.txt
  mk_auto_install_img $IMG_USERDBG $1
  auto_install $IMG_USERDBG $1 userdebug.qcow2
fi

if [ -z $IMG_ENG ]; then
  echo "* eng版镜像编译失败!" >> $1/result.txt
else
  echo "* eng版镜像编译成功!" >> $1/result.txt
  mk_auto_install_img $IMG_ENG $1
  auto_install $IMG_ENG $1 eng.qcow2
fi


