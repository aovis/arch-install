#!/bin/bash
#循环读取 fdisk.sh 生成的分区信息
for line in `cat ${PWD}/a.txt`
do
	#去除双引号并分割字符串 存放到TMP1和TMP2中
	TMP1=`echo ${line} | sed 's/\"//g' | cut -d ":" -f1`
	TMP2=`echo ${line} | sed 's/\"//g' | cut -d ":" -f2`
	#如果是根分区 直接格式化 交挂载到/mnt目录下
	if [ "$TMP1" == "/" ];
	then 
		mkfs -f -v -t ext4 ${TMP2} > /dev/null 2>&1
		mount -v -t ext4 ${TMP2} /mnt
	#如果是swap交换分区 格式化交启用swap交换分区
	elif [ "$TMP1" == "swap" ];
	then
		mkswap ${TMP2}
		swapon ${TMP2}
	#其他分区 建立目录 格式化分区 挂载到相应目录下 
	else
		mkdir -pv /mnt${TMP1}
		mkfs -f -v -t ext4 ${TMP2} > /dev/null 2>&1
		mount -v -t ext4 ${TMP2} /mnt${TMP1}
	fi
done
#显示挂载信息
mount | grep /dev/sd
#是否继续操作 
read -p "Do you want to continue? (n or Enter to continun" IS
#输入n结束操作退出脚本
if [ "$IS" == "n" ];
then
	exit
#输入回车 继续脚本
else

	TMP=n
	while [ "$TMP" == "n" ]
	do

        #启用所有中国的镜像站
		sed -i '/China/!{n;/Server/s/^/#/};t;n' /etc/pacman.d/mirrorlist
		#更新缓存
		pacman -Syy
		#安装基本系统  base ， base-devel 是默认gcc 生产环境 grub 引导 vim 编辑器 iw wpa_supplicant dialog 网络连接依赖
		#这里只安装无线网络   有线网络 请查看相关wiki
		pacstrap -i /mnt base base-devel grub vim iw wpa_supplicant dialog --force
		#写入磁盘挂载信息到 /mnt/etc/fstab 里
		genfstab -U -p /mnt > /mnt/etc/fstab
		#是否成功安装基本系统 n 没有成功  重复安装 enter 成功安装 退出脚本
		read -p "Successfully installed ? (n or Enter  " TMP
	done
fi
