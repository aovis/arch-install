#!/bin/bash
##fdisk
DEVICE_COUNT=""
function fdisk_run()
{
	if [ $3 -lt 4 ];
	then
		Pdisk "$1" "$2" "$3"
	elif [ $3 -gt 4 ];
	then
		Edisk "$1" "$2" "$3"
	else
		echo "error fdisk failed!"
	fi
}
function count_device()
{
	for i in `fdisk -l | grep "Disk" | grep "/dev" | awk '{print $2}' | \
		awk -F: '{print $1}' | grep "${1}"`
	do
		DEVICE_COUNT=$(fdisk -l $i | grep "$i" | awk '{print $2}' | awk -F: '{print $1}' | wc -l)
	done

}
function Pdisk()
{
	echo $2
	fdisk $1 << EOF
n
p
${3}

+${2}

w
EOF
}
function Extdisk()
{
	echo "-----------------------------------"
	fdisk $1 << EOF
n
e


w
EOF
}
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
> a.txt
read -p "Do you want to adjust the partition?(Input y to use fdisk or Enter to continue: " TMP
if [ "$TMP" == y ]
then
	POINT=$(whiptail --title "Mount Point" --checklist \
		"Please select folder for mount point" 20 60 7 \
		/ / ON \
		/boot /boot ON \
		/home /home OFF \
		/opt /opt OFF \
		/usr /usr OFF \
		/tmp /tmp OFF \
		/var /var OFF 3>&1 1>&2 2>&3)
	exitstatus=$?
	echo `fdisk -l | grep "Disk" | grep "/dev"`
	DISK=""
	if [ $exitstatus = 0 ];
	then
		read -p "Whick disk do you want to partition?(/dev/sdx: " DISK
		for s in $POINT 
		do
			read -p "set ${s} Size: " Size
			if [ "$s" == "\"/\"" ];
			then
				echo $s
				count_device "$DISK"
				echo "${DEVICE_COUNT}"
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

			else
				echo $s
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
		echo "you chose chancle"
	fi


fi
fdisk -l
