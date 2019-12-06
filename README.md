#### 简介

用于自动化测试，目前分为三个阶段。

第一阶段为编译：如源码仓库有更新则执行编译；如无更新则直接退出，不再执行接下来两个阶段；

第二阶段为安装：仅当第一阶段生成新的镜像时才会执行此阶段，首先是在原镜像的基础上生成一个仅执行自动安装的镜像，然后使用此自动安装镜像来把系统安装到硬盘上。

第三阶段为测试：在安装好的系统里加入一段测试命令，这段测试命令会把结果输出到指定位置，宿主机通过测试命令的执行效果来判断测试的结果。

#### 目录结构

- oto_test.sh : 管理入口
- bin : 存放各种可执行的脚本
- out ：自动化脚本运行时存放临时文件，此目录不会被加到git仓库里

#### 运行前的准备

1. 下载oto8的源码

   ```
   mkdir oto8 && cd oto8
   scp lh@192.168.0.180:/usr/bin/repo /usr/bin
   repo init -u git://192.168.0.185/android-x86/manifest.git -b multiwindow-oreo
   repo sync
   ```

2. 安装docker

   ```
   sudo pacman -S docker	# 不同的发行版有不同的安装命令
   docker save -o oto8.tar oto_repo	# 在180服务器执行此命令
   scp lh@192.168.0.180:oto8.tar .	# 把oto8.tar下载到本机
   docker load -i oto8.tar
   docker create -it -name <NAME> -v <local_oto8_repo>:<docker_oto8_repo> oto_repo bash
   ```

3. docker里的编译脚本示例

   ```
   BASE_DIR=$(cd $(dirname $0); pwd)
   OTO_SRC_DIR=$BASE_DIR/oto8
   OTO_IMG_DIR=$OTO_SRC_DIR/out/target/product/openthos
   OTO_IMG=openthos_x86_64_oto.img
   date=`date +%Y%m%d%H%M`
   
   if [ ! -d ./prop ]; then
       mkdir ./prop
   fi
   
   if [ ! -d ./logs ]; then
       mkdir ./logs
   fi
   
   pushd $OTO_SRC_DIR
   rm -rf out
   source build/envsetup.sh
   lunch openthos_x86_64-$1
   make -j8 oto_img | tee ../logs/$date"-oto8-"$1"-log.txt"
   repo manifest -r -o ../prop/$date"-oto8-"$1".xml"
   popd
   
   cp $OTO_IMG_DIR/$OTO_IMG $BASE_DIR/$date"-oto8-"$1.img
   cp $OTO_IMG_DIR/$OTO_IMG $2/$date"-oto8-"$1.img
   ```

4. 本地编译的环境配置(ubuntu 18.04)

   ```
   sudo apt install m4 libssl-dev pyton-mako libxml2-utils
   ```
   
   
   
5. 用于自动安装的install.img的制作方法

   ```
   sudo mount -o loop,offset=1048576 openthos8.img /mnt
   	# offset是通过'fdisk -l'命令计算出来的：起始扇区*每个扇区的大小
   cp /mnt/OpenThos/install.img /tmp && cd /tmp
   mv install.img install.img.gz && gunzip install.img.gz
   mkdir install && cd install
   cpio -i -F ../install.img
   vim scripts/1-install
   	# 函数hd_auto_install修改如下：
   	# rebuild_all_partition /dev/sdb
   	# hd_install_all /dev/sdb
   	# sync
   	# umount -a
   	# 函数hd_install修改如下：
   	# hd_prepare_install
   	# hd_auto_install
   	# poweroff -f
   	# halt -f
   cpio -o -H newc > ~/install.img
   cd ~ && gzip -9 install.img
   mv install.img.gz install.img
   ```

6. 用于自动安装的efi.tar.bz2的制作方法

   ```
   sudo mount -o loop,offset=1048576 openthos8.img /mnt
   cp /mnt/OpenThos/efi.tar.bz2 /tmp && cd /tmp
   vim efi/boto/refind.conf
   	# 把timeout的20改为-1
   tar cjf efi.tar.bz2 ./efi
   ```

   

7. 脚本里支持发送邮件

   ```
   # 需要安装s-nail
   # 对于ubuntu是s-nail命令，对于manjaro是mail命令
   # 修改配置文件，对于ubuntu在/etc/s-nail，对mainjaro在/etc/mail
   	set from="发送者的邮箱"
   	set smtp="发送者的smtp服务器域名"
   	set smtp-auth-user="发送者的邮箱"
   	set smtp-auto-password="授权码，需登陆邮箱设置"
   	set smtp-auto=login
   ```

   

#### 执行自动化测试

```
sudo oto_test.sh <path/to/oto_repo> <path/to/build_script>
	# mount命令需要root权限
```

