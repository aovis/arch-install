#!/bin/bash
#bahiaps@sina.com
read -p "ENTER To Continue"
#设置时区时间
ln -svf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc --utc
#启用字符集
sed -i '/zh_CN.UTF-8/{s/#//}' /etc/locale.gen
sed -i '/en_US.UTF-8/{s/#//}' /etc/locale.gen
sed -i '/zh_TW.UTF-8/{s/#//}' /etc/locale.gen
sed -i '/zh_CN.GB18030/{s/#//}' /etc/locale.gen
sed -i '/zh_CN.GBK/{s/#//}' /etc/locale.gen
locale-gen
#默认zh_CN.utf-8
echo LANG=zh_CN.UTF-8 > /etc/locale.conf
#主机名
HOSTNAME=$(dialog --title "Input Box" --inputbox "Please input your hostname" 10 60 localhost 3>&1 1>&2 2>&3)
#dialog 退出 状态  
#0为确定
#1为取消
exitstatus=$?
if [ $exitstatus = 1 ];
then
	HOSTNAME="localhost"
fi
echo $HOSTNAME > /etc/hostname
#root 密码
PASSWD=""
REPASSWD=""
TMP="n"
while [ "$TMP" == "n" ] || [ "$TMP" == "N" ];
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
#查看是否为/usr 建立单独挂载点
ISUSR=`mount | grep /dev | grep usr`
#如果有usr挂载点  修改/etc/mkinitcpio.conf 文件 在HOOKS中加入 shutdown usr
if [ "$ISUSR" != "" ];
then
	 ISMK=`cat /etc/mkinitcpio.conf | grep "HOOKS=\"base shutdown usr"`
	 if [ "$ISMK" == "" ];
	 then
		 sed -i 's/^HOOKS="base/HOOKS=\"base shutdown usr /g' /etc/mkinitcpio.conf
	 fi
	 mkinitcpio -p linux
fi
#安装grub
echo -e "\033[31m input n install grub , input y install efibootmgr grub! \033[0m"
read -p "Are you efi ? (y or enter " TMP
if [ "$TMP" == "Y" -o "$TMP" == "y" ];
then
	TMP=n
	while [ "$TMP" == "n" ] || [ "$TMP" == "N" ];
	do
		pacman -S --noconfirm grub efibootmgr -y && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch && grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "\033[31m input n try again , input y continue! \033[0m"
		read -p "Successfully installed ? (n or Enter " TMP
	done
else 
	TMP=n
	while [ "$TMP" == "n" ] || [ "$TMP" == "N" ];
	do
		pacman -S --noconfirm grub && fdisk -l
        echo -e "\033[31m input disk name like /dev/sda \033[0m"
		read -p "Input the disk you want to install the grub (/dev/sdx : " GRUB
		grub-install --target=i386-pc $GRUB
		grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "\033[31m input n try again , input y continue! \033[0m"
		read -p "Successfully installed ? (n or Enter " TMP
	done
fi



#安装显卡驱动
TMP=n
while [ "$TMP" == "n" ] || [ "$TMP" == "N" ];
do
	VIDEO=7
	while [ "$VIDEO" != "1" ] && [ "$VIDEO" != "2" ] && [ "$VIDEO" != "3" ] && [ "$VIDEO" != "4" ] && [ "$VIDEO" != "5" ] && [ "$VIDEO" != "6" ];
	do
		echo "What is your video card ?
		[1]  intel
		[2]  nvidia
		[3]  intel/nvidia
		[4]  ATI/AMD
		[5]  vbox
		[6]  vmware"
		read VIDEO
		if [ "$VIDEO" == "1" ];
		then
		   	pacman -S --noconfirm xf86-video-intel -y
		elif [ "$VIDEO" == "2" ];
		then TMP=4
			while [ "$TMP" != "1" ] && [ "$TMP" != "2" ] && [ "$TMP" != "3" ];
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
			while [ "$TMP" != "1" ] && [ "$TMP" != "2" ] && [ "$TMP" != "3" ];
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
		elif [ "$VIDEO" == "5" ]
		then
			pacman -S linux-headers
			pacman -S virtualbox-guest-utils
			modprobe -a vboxguest vboxsf vboxvideo
		elif [ "$VIDEO" == "6" ]
		then
			pacman -S xf86-video-vmware
		else
			echo Error ! Input the number again
		fi
	done
    echo -e "\033[31m input n try again , input y continue! \033[0m"
	read -p "Successfully installed ? (n or Enter  " TMP
done
#加archlinuxcn 软件仓库
ISCN=`cat /etc/pacman.conf | grep "\[archlinuxcn\]"`
if [ "$ISCN" == "" ];
then
echo "[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch" >> /etc/pacman.conf
fi
TMP="n"
#安装Xwindows 和 一些必要的软件
while [ "$TMP" == "n" ] || [ "$TMP" == "N" ];
do
	pacman -Syy && pacman -S --noconfirm archlinuxcn-keyring yaourt
	pacman -S --noconfirm networkmanager xorg-server xorg-xinit firefox wqy-zenhei
	systemctl enable NetworkManager

    echo -e "\033[31m input n continue , input install bluetooth (lanya) \033[0m"
	read -p "Do you have bluetooth ? (y or Enter " TMP
	if [ "$TMP" == "y" -o "$TMP" == "Y" ];
	then
		pacman -S --noconfirm bluez blueman && systemctl enable bluetooth
	fi
    echo -e "\033[31m input n try again , input y continue! \033[0m"
	read -p "Successfully installed ? (n or Enter" TMP
done
#安装桌面环境
TMP=n
while [ "$TMP" == "n" ] || [ "$TMP" == "N" ];
do
	echo -e "\033[31m Which desktop you want to install :  \033[0m"
	DESKTOP=0
	while [ "$DESKTOP" != "1" ] && [ "$DESKTOP" != "2" ] && [ "$DESKTOP" != "3" ] && [ "$DESKTOP" != "4" ] && [ "$DESKTOP" != "5" ] && [ "$DESKTOP" != "6" ] && [ "$DESKTOP" != "7" ] && [ "$DESKTOP" != "8" ] && [ "$DESKTOP" != "9" ] && [ "$DESKTOP" != "10" ];
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
					  pacman -S --noconfirm i3 rofi rxvt-unicode lightdm lightdm-gtk-greeter

					  ;;
				  *) echo Error ! Input the number again
					  ;;
			  esac
			  done
              echo -e "\033[31m input n try again , input y continue! \033[0m"
			  read -p "Successfully installed ? (n or Enter  " TMP
done

#建立用户

echo -e "\033[31m add a new user input username \033[0m"
read -p "Input the user name you want to use :  " USER
useradd -m -g users -G wheel -s /bin/bash $USER
passwd $USER
#为用户启用sudo
#chmod +rw /etc/sudoers
#ISSU=`cat /etc/sudoers | grep "$USER ALL=(ALL) ALL"`
#if [ "ISSU" == "" ];
#then
#	`sed -i "/root ALL=(ALL) ALL/a\ $USER ALL=(ALL) ALL" /etc/sudoers`
#	chmod -w /etc/sudoers
#	chmod o-r /etc/sudoers
#fi
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
else	
	gpasswd -a $USER lightdm
	systemctl enable lightdm
fi
