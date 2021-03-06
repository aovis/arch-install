#!/bin/bash
function XFSM()
{
    isM="M"
    res=$(echo ${3} | grep "${isM}")
    if [ "${2}" == "/boot" ]
    then
        mkfs.xfs -f ${1} > /dev/null 2>&1
    elif [ "${res}" == "" -a ${3} -le 2 ]
    then
        mkfs.xfs -f -i size=512 -l size=64m,lazy-count=1 -d agcount=16 ${1} > /dev/null 2>&1
    else
        mkfs.xfs -f -i size=512 -l size=128m,lazy-count=1 -d agcount=16 ${1} > /dev/null 2>&1
    fi
}

echo -e "\033[31m input filesystem ext4 or xfs (like xfs) \033[0m" 
read -p "inptu filesystem : " FILESYSTEM
if [ "${FILESYSTEM}" == "" ]
then
    FILESYSTEM=ext4
fi
#循环读取 fdisk.sh 生成的分区信息
for line in `cat ${PWD}/a.txt`
do
	#去除双引号并分割字符串 存放到TMP1和TMP2中
	TMP1=`echo ${line} | sed 's/\"//g' | cut -d ":" -f1`
	TMP2=`echo ${line} | cut -d ":" -f2`
    TMP3=`echo ${line} | sed 's/G//g' | cut -d ":" -f3`
	#如果是根分区 直接格式化 交挂载到/mnt目录下
	if [ "$TMP1" == "/" ];
	then 
        if [ "$FILESYSTEM" == "XFS" -o "$FILESYSTEM" == "xfs" ]
        then
            XFSM "${TMP2}" "${TMP1}" "${TMP3}"
        else            
		    mkfs -F -v -t ${FILESYSTEM} ${TMP2} > /dev/null 2>&1
        fi
		mount -v -t ${FILESYSTEM} ${TMP2} /mnt
        sleep 3
	#如果是swap交换分区 格式化交启用swap交换分区
	elif [ "$TMP1" == "swap" ];
	then
		mkswap ${TMP2}
		swapon ${TMP2}
	#其他分区 建立目录 格式化分区 挂载到相应目录下 
	else
		mkdir -pv /mnt${TMP1}
        if [ "${FILESYSTEM}" == "XFS" -o "$FILESYSTEM" == "xfs" ]
        then
            XFSM "${TMP2}" "${TMP1}" "${TMP3}"
        else
		    mkfs -F -v -t ${FILESYSTEM} ${TMP2} > /dev/null 2>&1
        fi
		mount -v -t ${FILESYSTEM} ${TMP2} /mnt${TMP1}
        sleep 3
	fi
done
#显示挂载信息
mount | grep /dev/sd
#是否继续操作 
read -p "Do you want to continue? (n or Enter to continun" IS
#输入n结束操作退出脚本
if [ "$IS" == "n" -o "$IS" == "N" ];
then
	exit
#输入回车 继续脚本
else

	TMP=n
	while [ "$TMP" == "n" -o "$TMP" == "N" ]
	do

        #启用所有中国的镜像站
		sed -i '/China/!{n;/Server/s/^/#/};t;n' /etc/pacman.d/mirrorlist
		#更新缓存
		pacman -Syy
		#安装基本系统  base ， base-devel 是默认gcc 生产环境 grub 引导 vim 编辑器
		pacstrap -i /mnt base base-devel grub vim dialog --force
		#写入磁盘挂载信息到 /mnt/etc/fstab 里
		genfstab -U -p /mnt > /mnt/etc/fstab
		#是否成功安装基本系统 n 没有成功  重复安装 enter 成功安装 退出脚本

        echo -e "\033[31m input n try again , input y continue! \033[0m"
		read -p "Successfully installed ? (n or Enter  " TMP
	done
fi
wget https://raw.githubusercontent.com/aovis/arch-install/master/config.sh
mv $PWD/config.sh /mnt/root/
chmod +x /mnt/root/config.sh
arch-chroot /mnt /root/config.sh
