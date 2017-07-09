#!/bin/bash
read -p "ENTER To Continue"
ln -svf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc --utc
sed -i '/zh_CN.UTF-8/{s/#//}' /etc/locale.gen
sed -i '/en_US.UTF-8/{s/#//}' /etc/locale.gen
sed -i '/zh_TW.UTF-8/{s/#//}' /etc/locale.gen
sed -i '/zh_CN.GB18030/{s/#//}' /etc/locale.gen
sed -i '/zh_CN.GBK/{s/#//}' /etc/locale.gen
locale-gen
echo LANG=zh_CN.UTF-8 > /etc/locale.conf
HOSTNAME=$(dialog --title "Input Box" --inputbox "Please input your hostname" 10 60 localhost 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 1 ];
then
	HOSTNAME="localhost"
fi
echo $HOSTNAME > /etc/hostname
PASSWD=""
REPASSWD=""
TMP="n"
while [ "$TMP" == "n" ];
do
	PASSWD=$(dialog --title "Password Box" --passwordbox "Change your root passwd and choose OK to continue." 10 30 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 1 -o "$PASSWD" == "" ];
	then
		echo "Default passwd : 123456789"
		PASSWD="123456789"
	fi
	REPASSWD=$(dialog --title "REPassword Box" --passwordbox "Retype password. and choose OK to continum." 10 30 3>&1 1>&2 2>&3 )
	exitstatus=$?
	if [ $exitstatus = 1 -o "$REPASSWD" == "" ];
	then
		REPASSWD="123456789"
	fi
	if [ "$PASSWD" == "$REPASSWD" ];
	then
		TMP="y"
	else
		echo "try again"
	fi
done
passwd << EOF
$PASSWD
$REPASSWD
EOF
ISUSR=`mount | grep /dev | grep usr`
if [ "$ISUSR" != "" ];
then
	 ISMK=`cat /etc/mkinitcpio.conf | grep "HOOKS=\"base shutdown usr"`
	 if [ "$ISMK" == "" ];
	 then
		 sed -i 's/^HOOKS="base/HOOKS=\"base shutdown usr /g' /etc/mkinitcpio.conf
	 fi
	 mkinitcpio -p linux
fi
read -p "Are you efi ? (y or enter " TMP
if [ "$TMP" == "Y" -o "$TMP" == "y" ];
then
	TMP=n
	while [ "$TMP" == "n" -o "$TMP" == "N" ];
	do
		pacman -S --noconfirm grub efibootmgr -y && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch && grub-mkconfig -o /boot/grub/grub.cfg
		read -p "Successfully installed ? (n or Enter " TMP
	done
else 
	TMP=n
	while [ "$TMP" == "n" -o "$TMP" == "N" ];
	do
		pacman -S --noconfirm grub && fdisk -l
		read -p "Input the disk you want to install the grub " GRUB
		grub-install --target=i386-pc $GRUB
		grub-mkconfig -o /boot/grub/grub.cfg
		read -p "Successfully installed ? (n or Enter " TMP
	done
fi
