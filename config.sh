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
	while (($VIDEO!=1&&$VIDEO!=2&&$VIDEO!=3&&$VIDEO!=4));
	do
		echo "What is your video card ?
		[1]  intel
		[2]  nvidia
		[3]  intel/nvidia
		[4]  ATI/AMD"
		read VIDEO
		if [ "$VIDEO" == "1" ];
		then
		   	pacman -S --noconfirm xf86-video-intel -y
		elif [ "$VIDEO" == "2" ];
		then TMP=4
			while (($TMP!=1&&$TMP!=2&&$TMP!=3));
			do
				echo "Version of nvidia-driver to install:
				[1]  GeForce-8 and newer
				[2]  GeForce-6/7
				[3]  Older  "
				read TMP
				if [ "$TMP" == "1" ];
				then
				   	pacman -S --noconfirm nvidia -y
				elif [ "$TMP" == "2" ];
				then
				   	pacman -S --noconfirm nvidia-304xx -y
				elif [ "$TMP" == "3" ];
				then
				   	pacman -S --noconfirm nvidia-340xx -y
				else 
					echo error ! input the number again
				fi
			done
		elif [ "$VIDEO" == "3" ];
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
				if [ "$TMP" == "1" ];
				then
				   	pacman -S --noconfirm nvidia -y
				elif [ "$TMP" == "2" ];
				then
				   	pacman -S --noconfirm nvidia-304xx -y
				elif [ "$TMP" == "3" ];
				then 
					pacman -S --noconfirm nvidia-340xx -y
				else 
					echo Error ! Input the currect number !
				fi
			done
		elif [ "$VIDEO" == "4" ];
		then 
			pacman -S --noconfirm xf86-video-ati -y
		else
			echo Error ! Input the number again
		fi
	done
	read -p "Successfully installed ? (n or Enter  " TMP
done

ISCN=`cat /etc/pacman.conf | grep "\[archlinuxcn\]"`
if [ "$ISCN" == "" ];
then
echo "[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = http://mirrors.163.com/archlinux-cn/\$arch" >> /etc/pacman.conf
fi
TMP="n"
while [ "$TMP" == "n" ];
do
	pacman -Syy && pacman -S --noconfirm archlinuxcn-keyring yaourt
	pacman -S --noconfirm networkmanager xorg-server xorg-xinit firefox wqy-zenhei
	systemctl enable NetworkManager
	read -p "Do you have bluetooth ? (y or Enter " TMP
	if [ "$TMP" == "y" -o "$TMP" == "Y" ];
	then
		pacman -S --noconfirm bluez blueman && systemctl enable bluetooth
	fi
	read -p "Successfully installed ? (n or Enter" TMP
done

TMP=n
while [ "$TMP" == n ];
do
	echo -e "\033[31m Which desktop you want to install :  \033[0m"
	DESKTOP=0
	while (($DESKTOP!=1&&$DESKTOP!=2&&$DESKTOP!=3&&$DESKTOP!=4&&$DESKTOP!=5&&$DESKTOP!=6&&$DESKTOP!=7&&$DESKTOP!=8&&$DESKTOP!=9&&$DESKTOP!=10));
	do
		echo "[1]  Gnome
			  [2]  Kde
			  [3]  Lxde
			  [4]  Lxqt
			  [5]  Mate
			  [6]  Xfce
			  [7]  Deepin
			  [8]  Budgie
			  [9]  Cinnamon
			  [10]  i3wm"
			  read DESKTOP
			  case $DESKTOP in
				  1) pacman -S --noconfirm gnome
					  ;;
				  2) pacman -S --noconfirm plasma kdebase kdeutils kdegraphics kde-l10n-zh_cn sddm
					  ;;
				  3) pacman -S --noconfirm lxde lightdm lightdm-gtk-greeter
					  ;;
				  4) pacman -S --noconfirm lxqt lightdm lightdm-gtk-greeter
					  ;;
				  5) pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter
					  ;;
				  6) pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
					  ;;
				  7) pacman -S --noconfirm deepin deepin-extra lightdm lightdm-gtk-greeter&&sed -i '108s/#greeter-session=example-gtk-gnome/greeter-session=lightdm-deepin-greeter/' /etc/lightdm/lightdm.conf
					  ;;
				  8) pacman -S--noconfirm  budgie-desktop lightdm lightdm-gtk-greeter
					  ;;
				  9) pacman -S --noconfirm cinnamon lightdm lightdm-gtk-greeter
					  ;;
				  10) 
					  pacman -S --noconfirm i3 rofi rxvt-unicode slim

					  ;;
				  *) echo Error ! Input the number again
					  ;;
			  esac
			  done
			  read -p "Successfully installed ? (n or Enter  " TMP
done


read -p "Input the user name you want to use :  " USER
useradd -m -g users -G wheel -s /bin/bash $USER
passwd $USER
usermod -aG root,bin,daemon,tty,disk,games,network,video,audio $USER
if [ "$VIDEO" == "4" ];
then  
	gpasswd -a $USER bumblebee
fi
if [ "$DESKTOP" == "1" ];
then
   	gpasswd -a $USER gdm
	systemctl enable gdm
elif [ "$DESKTOP" == "2" ];
then 
	gpasswd -a $USER sddm
	systemctl enable sddm
elif [ "$DESKTOP" == "10" ];
then
	gpasswd -a $USER slim
	systemctl enable slim
else	
	gpasswd -a $USER lightdm
	systemctl enable lightdm
fi

