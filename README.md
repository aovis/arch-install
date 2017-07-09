# arch-install
# Arch 半自动安装脚本 </br>
# 启动安装盘后请连接网络执行以下命令 </br>
\# wget https://raw.githubusercontent.com/aovis/arch-install/master/fdisk.sh  </br>
\# chmod +x fdisk.sh  </br>
\# ./fdisk.sh     
# virtualbox虚拟机中安装，可能会遇到X windows 无法启动问题 原因是没有安装 虚拟机的显示驱动在脚本运行完毕后运行下面命令解决
chroot进新系统
\# arch-chroot /mnt /bin/bash
安装内核头文件
\# pacman -S linux-headers
安装vbox的显示驱动程序
\# pacman -S virtualbox-guest-utils
安装完毕之后手动载入vbox的模块
\# modprobe -a vboxguest vboxsf vboxvideo
