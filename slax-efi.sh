#!/bin/bash
thumbdrive=/dev/sda
d=`mktemp -d`
cd $d
wget https://ftp.sh.cvut.cz/slax/Slax-9.x/slax-64bit-9.11.0.iso
test -f slax-64bit-*.iso
apt install -y parted syslinux-common syslinux-efi
dd if=/dev/zero of=${thumbdrive} bs=1M count=5
sync
/sbin/parted ${thumbdrive} mklabel msdos --script
/sbin/parted ${thumbdrive} mkpart primary 0% 100% --script
mkfs.vfat ${thumbdrive}1
mkdir /media/{source,target}
mount -o loop -t iso9660 slax-64bit-*.iso /media/source
mount -t vfat ${thumbdrive}1 /media/target
cp -axv /media/source/slax /media/target/slax
bash -x /media/target/slax/boot/bootinst.sh
mkdir -p /media/target/EFI/Boot/
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /media/target/EFI/Boot/bootx64.efi
cd /usr/lib/syslinux/modules/efi64/
cp ldlinux.e64 menu.c32 libcom32.c32 libutil.c32 vesamenu.c32 /media/target/EFI/Boot
cat > /media/target/EFI/Boot/syslinux.cfg <<"SYSLINUXCFG"
PROMPT 0
TIMEOUT 40

UI vesamenu.c32
MENU TITLE Boot (EFI)

MENU CLEAR
MENU HIDDEN
MENU HIDDENKEY Enter default
MENU BACKGROUND /slax/boot/bootlogo.png

MENU WIDTH 80
MENU MARGIN 20
MENU ROWS 5
MENU TABMSGROW 9
MENU CMDLINEROW 9
MENU HSHIFT 0
MENU VSHIFT 19

MENU COLOR BORDER  30;40      #00000000 #00000000 none
MENU COLOR SEL     47;30      #FF000000 #FFFFFFFF none
MENU COLOR UNSEL   37;40      #FFFFFFFF #FF000000 none
MENU COLOR TABMSG  32;40      #FF60CA00 #FF000000 none

F1 /slax/boot/help.txt /slax/boot/zblack.png

MENU AUTOBOOT Press Esc for options, automatic boot in # second{,s} ...
MENU TABMSG [F1] help     

LABEL default
MENU LABEL Run Slax (Persistent changes)
KERNEL /slax/boot/vmlinuz
APPEND vga=normal initrd=/slax/boot/initrfs.img load_ramdisk=1 prompt_ramdisk=0 rw printk.time=0 consoleblank=0 slax.flags=perch,automount

LABEL perch
MENU LABEL Run Slax (Fresh start)
KERNEL /slax/boot/vmlinuz
APPEND vga=normal initrd=/slax/boot/initrfs.img load_ramdisk=1 prompt_ramdisk=0 rw printk.time=0 consoleblank=0 slax.flags=automount

LABEL toram
MENU LABEL Run Slax (Copy to RAM)
KERNEL /slax/boot/vmlinuz
APPEND vga=normal initrd=/slax/boot/initrfs.img load_ramdisk=1 prompt_ramdisk=0 rw printk.time=0 consoleblank=0 slax.flags=toram
SYSLINUXCFG
