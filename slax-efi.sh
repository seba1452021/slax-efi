#!/bin/bash
shopt -s extglob

dir="$(dirname "$0")"
cd $dir

directory=$(pwd)

yes n | rm -r -f -i !(${0}|autorun.inf|logo.ico) &>/dev/null
case $? in 1) ;; 0) echo -e "existen cosas aparte de este script. \n \n ¿desea superponer? S/N \n \n" && read -n 2 resp KEY && sleep 2 && clear ;; esac
case $resp in "s"|"S"|"y"|"Y") boot=syslinux ;; *) boot=BOOT ;; esac

echo -e "\n cargando.. \n"

PART="$(df . | tail -n 1 | tr -s " " | cut -d " " -f 1)"
DEV="$(echo "$PART" | sed -r "s:[0-9]+\$::" | sed -r "s:([0-9])[a-z]+\$:\\1:i")"   #"
NUM="$(echo $PART | sed -e "s|"$DEV"||g" -e "s|"[a-z]"||g")"
VARS=`blkid ${PART} | sed -e "s|${PART}:||g" | sed -e 's|"||g'`
export ${VARS}

clear
echo -e "\n opteniendo y/o actualizando dependencias.. \n"

apt install -y -f parted p7zip{,-full} wget efibootmgr syslinux-common &>/dev/null

clear
echo -e "\n descargando y comprobando archivos.. \n"

i=1
until [ $i -eq 0 ]
do
if [ -f slax-64bit-11.3.0.iso ]; then rm slax-64bit-11.3.0.iso; fi
test -f slax-64bit-11.3.0.iso || wget https://ftp.sh.cvut.cz/slax/Slax-11.x/slax-64bit-11.3.0.iso &>/dev/null
test -f md5.txt || echo '9d94c1796ba4c79fb05bb9f35c3fe188  slax-64bit-11.3.0.iso' > md5.txt
md5sum -c md5.txt &>/dev/null
i=$?
done

clear
echo -e "\n descomprimiendo archivos.. \n"

7z x slax-64bit-11.3.0.iso &>/dev/null

clear
echo -e "\n procesando .. \n"

mkdir boot -p EFI/${boot}

mv slax/boot/EFI/Boot/!(bootx64.efi) EFI/${boot}/
mv slax/boot/{help.txt,initrfs.img,vmlinuz,*.png} boot/
rm readme* slax-64bit-11.3.0.iso md5.txt -r slax/boot '[BOOT]'

cd EFI/${boot}/

clear
echo -e "\n descargando faltantes.. \n"

wget https://blog.hansenpartnership.com/wp-uploads/2013/{PreLoader,HashTool}.efi &>/dev/null
mv PreLoader.efi ./BOOTx64.EFI
mv syslinux.efi ./loader.efi

clear
echo -e "\n editando archivos.. \n"

sed -i "s|/slax||g" syslinux.cfg
sed -i "s|help.txt|/boot/help.txt|g" syslinux.cfg
sed -i "s|vesamenu.c32|/EFI/${boot}/vesamenu.c32\nMENU TITLE Boot (EFI)|g" syslinux.cfg

echo "BOOTx64.EFI,${boot},,This is the boot entry for syslinux" | tee -a BOOTX64.CSV &>/dev/null

if [ ${TYPE} == "vfat" ]; then
parted -s ${DEV} set ${NUM} boot on
cd $directory

if [ ! -d EFI/BOOT/ ]; then mkdir EFI/BOOT/; fi

file='' && for x in {fallback,fbx64}.efi; do [ "$file" != "" ]; case $? in 1) if [ -f EFI/BOOT/${x} ]; then file="EFI/BOOT/${x}"; fi ;; *) ;; esac; done

if [ "$file" = "" ]; then cp /usr/lib/shim/fbx64.efi EFI/BOOT/; fi

if [ -d EFI/syslinux/ ]; then efibootmgr --verbose --disk ${DEV} --part ${NUM} --create --label "Syslinux" --loader /EFI/${boot}/BOOTx64.EFI &>/dev/null; fi
fi

clear
echo -e "\n listo, ya deberia estaria todo hecho.. \n"

exit 0
