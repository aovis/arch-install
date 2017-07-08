#!/bin/bash
##fdisk
#DEVICE_COUNT 存放分区编号
DEVICE_COUNT=""
##分区函数
function fdisk_run()
{
	#$1=$DISK 磁盘名称
	#$2=$Size 分区大小
	#$3=$DEVICE_COUNT 分区编号
	#如果DEVICE_COUNT小于4 可分配主分区 调用Pdisk函数建立主分区
	if [ $3 -lt 4 ];
	then
		Pdisk "$1" "$2" "$3"
	#如果DEVICE_COUNT大于4 不可分配主分区 调用Edisk函数在扩展分区中建立分区
	elif [ $3 -gt 4 ];
	then
		Edisk "$1" "$2" "$3"
	else
		echo "error fdisk failed!"
	fi
}
#查找未使用的分区编号并存放在DEVICE_COUNT中
function count_device()
{
	for i in `fdisk -l | grep "Disk" | grep "/dev" | awk '{print $2}' | \
		awk -F: '{print $1}' | grep "${1}"`
	do
		DEVICE_COUNT=$(fdisk -l $i | grep "$i" | awk '{print $2}' | awk -F: '{print $1}' | wc -l)
	done

}
#建立主分区
function Pdisk()
{
	fdisk $1 << EOF
n
p
${3}

+${2}

w
EOF
}
#建立扩展分区
function Extdisk()
{
	echo "-----------------------------------"
	fdisk $1 << EOF
n
e


w
EOF
}
#在扩展分区上建立分区
function Edisk()
{
	fdisk $1 << EOF
n

+${2}

w
EOF
}
#function mountDIR()
#{
#	modir=`echo ${1} | sed 's/\"//g'`
#	echo $modir
#	sleep 3
#	mkfs -v -t ext4 $2$3
#	sleep 3
#	mkdir -pv /mnt${modir}
#	sleep 3
#	mount -v -t ext4 $2$3 /mnt${modir}
#}

#请空a.txt文件
> a.txt

#询问是否分区
read -p "Do you want to adjust the partition?(Input y to use fdisk or Enter to continue: " TMP
#如果输入y 进行分区
if [ "$TMP" == y ]
then
	#交互 显示复选框 选择要建立的挂载点
	POINT=$(whiptail --title "Mount Point" --checklist \
		"Please select folder for mount point" 20 60 7 \
		/ / ON \
		/boot /boot ON \
		/home /home OFF \
		/opt /opt OFF \
		/usr /usr OFF \
		/tmp /tmp OFF \
		/var /var OFF 3>&1 1>&2 2>&3)
	#复选框退出状态 0 为确认 1 为取消
	exitstatus=$?
	#输出本机磁盘信息
	echo `fdisk -l | grep "Disk" | grep "/dev"`
	#磁盘
	DISK=""
	#如果退出状态为0 进入分区
	if [ $exitstatus = 0 ];
	then
		#询问 要对哪个磁盘进行分区
		read -p "Whick disk do you want to partition?(/dev/sdx: " DISK
		#循环 每对应一个挂载 建立一个分区
		for s in $POINT 
		do
			#设置分区大小
			read -p "set ${s} Size: " Size
			#对/挂载点进行操作
			if [ "$s" == "\"/\"" ];
			then
				#获取未使用的分区号
				count_device "$DISK"
				#如果分区号为4 先建立扩展分区再进行操作
				if [ $DEVICE_COUNT -eq 4 ];
				then
					#建立扩展分区
					Extdisk "$DISK"
					#再次获取未使用的分区号
					count_device "$DISK"
					#进行分区
					fdisk_run "$DISK" "$Size" "$DEVICE_COUNT"
					#将记录追加到a.txt
					echo "$s:$DISK$DEVICE_COUNT" >> a.txt
				else   #分区号不为4  直接进行分区并将记录追加到a.txt
					fdisk_run "$DISK" "$Size" "$DEVICE_COUNT"
					echo "$s:$DISK$DEVICE_COUNT" >> a.txt
				fi

			else #对其他挂载点进行操作
				count_device "$DISK"
				echo "$DEVICE_COUNT"
				if [ $DEVICE_COUNT -eq 4 ];
				then
					Extdisk "$DISK"
					count_device "$DISK"
					fdisk_run "$DISK" "$Size" "$DEVICE_COUNT"
					echo "$s:$DISK$DEVICE_COUNT" >> a.txt
				else
					fdisk_run "$DISK" "$Size" "$DEVICE_COUNT"
					echo "$s:$DISK$DEVICE_COUNT" >> a.txt
				fi
			fi

		done
	else
		#退出状态为1  打印提示
		echo "you chose chancle"
	fi


fi
#列出分区信息
fdisk -l
