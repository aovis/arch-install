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




TMP=n
while [ "$TMP" == n ];
do
	VIDEO=5
	while (($VIDEO!=1&&$VIDEO!=2&&VIDEO!=3&&VIDEO!=4));
	do
		echo "What is your video card ?
		[1]  intel
		[2]  nvidia
		[3]  intel/nvidia
		[4]  ATI/AMD"
		read VIDEO
		if (($VIDEO==1))
		then
		   	pacman -S --noconfirm xf86-video-intel -y
		elif (($VIDEO==2))
		then TMP=4
			while (($TMP!=1&&$TMP!=2&&$TMP!=3));
			do
				echo "Version of nvidia-driver to install:
				[1]  GeForce-8 and newer
				[2]  GeForce-6/7
				[3]  Older  "
				read TMP
				if (($TMP==1))
				then
				   	pacman -S --noconfirm nvidia -y
				elif (($TMP==2))
				then
				   	pacman -S --noconfirm nvidia-304xx -y
				elif (($TMP==3))
				then
				   	pacman -S --noconfirm nvidia-340xx -y
				else 
					echo error ! input the number again
				fi
			done
		elif (($VIDEO == 3))
		then
		   	pacman -S --noconfirm bumblebee -y
			systemctl enable bumblebeed
			TMP=4
			while (($TMP!=1&&$TMP!=2&&$TMP!=3));
			do
				echo "Version of nvidia-driver to install:
				[1]  GeForce-8 and newer
				[2]  GeForce-6/7
				[3]  Older   "
				read TMP
				if (($TMP==1))
				then
				   	pacman -S --noconfirm nvidia -y
				elif (($TMP==2))
				then
				   	pacman -S --noconfirm nvidia-304xx -y
				elif (($TMP==3))
				then 
					pacman -S --noconfirm nvidia-340xx -y
				else 
					echo Error ! Input the currect number !
				fi
			done
		elif (($VIDEO==4))
		then 
			pacman -S --noconfirm xf86-video-ati -y
		else
			echo Error ! Input the number again
		fi
	done
	read -p "Successfully installed ? (n or Enter  " TMP
done

echo "[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = http://mirrors.163.com/archlinux-cn/\$arch" >> /etc/pacman.conf
TMP="n"
while [ "$TMP" == "n" && "$TMP" =="N" ];
do
	pacman -Syu yaourt && pacman -S --noconfirm archlinuxcn-keyring
	pacman -S --noconfirm networkmanager xorg-server xorg-xinit firefox wqy-zenhei
	systemctl enable NetworkManager
	read -p "Do you have bluetooth ? (y or Enter " TMP
	if [ "$TMP" == "y" -o "$TMP" == "Y" ];
	then
		pacman -S --noconfirm bluez blueman && systemctl enable bluetooth
	fi
	read -p "Successfully installed ? (n or Enter" TMP
done
