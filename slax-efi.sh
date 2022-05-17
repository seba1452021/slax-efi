#!/bin/bash
shopt -s extglob

dir="$(dirname "$0")"
cd $dir

directory=$(pwd)

yes n | rm -r -f -i !(${0}|autorun.inf|logo.ico) &>/dev/null
case $? in 1) ;; 0) echo -e "existen cosas aparte de este script. \n \n ¿desea superponer? S/N \n \n" && read -n 2 resp KEY && sleep 2 && clear ;; esac
case $resp in "s"|"S"|"y"|"Y") boot=syslinux ;; *) boot=BOOT ;; esac


PART="$(df . | tail -n 1 | tr -s " " | cut -d " " -f 1)"
DEV="$(echo "$PART" | sed -r "s:[0-9]+\$::" | sed -r "s:([0-9])[a-z]+\$:\\1:i")"   #"
NUM="$(echo $PART | sed -e "s|"$DEV"||g" -e "s|"[a-z]"||g")"
VARS=`blkid ${PART} | sed -e "s|${PART}:||g" | sed -e 's|"||g'`
export ${VARS}

apt install -y -f parted p7zip{,-full} wget efibootmgr &>/dev/null

i=1
until [ $i -eq 0 ]
do
if [ -f slax-64bit-11.3.0.iso ]; then rm slax-64bit-11.3.0.iso; fi
test -f slax-64bit-11.3.0.iso || wget https://ftp.sh.cvut.cz/slax/Slax-11.x/slax-64bit-11.3.0.iso &>/dev/null
test -f md5.txt || echo '9d94c1796ba4c79fb05bb9f35c3fe188  slax-64bit-11.3.0.iso' > md5.txt
md5sum -c md5.txt &>/dev/null
i=$?
done

7z x slax-64bit-11.3.0.iso &>/dev/null

mkdir boot -p EFI/${boot}

mv slax/boot/EFI/Boot/!(bootx64.efi) EFI/${boot}/
mv slax/boot/{help.txt,initrfs.img,vmlinuz,*.png} boot/
rm readme.txt slax-64bit-11.3.0.iso md5.txt -r slax/boot '[BOOT]'

cd EFI/${boot}/

wget https://blog.hansenpartnership.com/wp-uploads/2013/{PreLoader,HashTool}.efi &>/dev/null
mv PreLoader.efi ./BOOTx64.EFI
mv syslinux.efi ./loader.efi

sed -i "s|/slax||g" syslinux.cfg
sed -i "s|help.txt|/boot/help.txt|g" syslinux.cfg
sed -i "s|vesamenu.c32|/EFI/${boot}/vesamenu.c32\nMENU TITLE Boot (EFI)|g" syslinux.cfg

if [ ${TYPE} == "vfat" ]; then
parted -s ${DEV} set ${NUM} boot on
else
echo -e "UI /EFI/${boot}/menu.c32\nprompt 0\ntimeout 0\ndefault new_config\nLABEL new_config\nKERNEL /EFI/${boot}/vesamenu.c32\nAPPEND root=UUID=${UUID}" | tee -a syslinux1.cfg &>/dev/null
fi

cd $directory

if [ -d EFI/syslinux/ ]; then echo "BOOTx64.EFI,${boot},,This is the boot entry for syslinux" | tee -a BOOTX64.CSV &>/dev/null && cp /usr/lib/shim/fbx64.efi EFI/syslinux/ && efibootmgr --verbose --disk ${DEV} --part ${NUM} --create --label "Syslinux" --loader /EFI/${boot}/BOOTx64.EFI &>/dev/null; fi

exit 0
