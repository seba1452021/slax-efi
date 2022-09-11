#!/bin/bash
shopt -s extglob

dir="$(dirname "$0")"
cd $dir

directory=$(pwd)

yes n | rm -r -f -i !(${0}|autorun.inf|logo.ico) &>/dev/null
case $? in 0) echo -e "existen cosas aparte de este script. \n \n ¿desea superponer? S/N \n \n" && read -n 2 resp KEY && sleep 2 && clear ;; esac
case $resp in [Yy]*|[Ss]*) boot=syslinux ;; *) boot=BOOT ;; esac

echo -e "\n cargando.. \n"

PART=$(df . | tail -n 1 | tr -s " " | cut -d " " -f 1)
DEV=$(echo $PART | sed -r "s:[0-9]+\$::" | sed -r "s:([0-9])[a-z]+\$:\\1:i")
NUM=$(echo $PART | sed -e "s|$DEV||g" -e "s|[a-z]||g")

VARS=`blkid ${PART} | sed -e "s|${PART}: ||g" | sed -e 's|"||g'`
export ${VARS}

clear
echo -e "\n opteniendo y/o actualizando dependencias.. \n"

apt install -y -f parted p7zip{,-full} wget efibootmgr mtools &>/dev/null

clear
echo -e "\n descargando y comprobando archivos.. \n"

n=10 existe=no
until [ $existe == si ];
do
pagina="http://ftp.sh.cvut.cz/slax/Slax-${n}.x/"
resultado=$(curl -s -I -L ${pagina}md5.txt | head -n 1 | awk '{print $2}')
case $resultado in 404) ((n++)) ;; *) existe=si ;; esac
done

i=1
until [ $i -eq 0 ]
do
test -f md5.txt || wget ${pagina}md5.txt &>/dev/null
grep 64bit md5.txt | tail -n 1 | cat > md5.txt.1 && mv md5.txt.1 ./md5.txt
imagen=$(cut -d " " -f 3 md5.txt)
test -f ${imagen} || rm ${imagen} &>/dev/null
test -f ${imagen} || wget ${pagina}${imagen} &>/dev/null
md5sum -c md5.txt &>/dev/null
i=$?
done

clear
echo -e "\n descomprimiendo archivos.. \n"

7z x ${imagen} &>/dev/null

clear
echo -e "\n procesando .. \n"

mkdir boot -p EFI/${boot}

mv slax/boot/EFI/Boot/!(bootx64.efi) EFI/${boot}/
mv slax/boot/{help.txt,initrfs.img,vmlinuz,*.png} boot/
rm readme* ${imagen} md5.txt -r slax/boot '[BOOT]'

boot_file="BOOTx64.EFI"

if [ -d EFI/syslinux/ ]; then boot_file="PreLoader.efi"; fi

cd EFI/${boot}/

clear
echo -e "\n descargando faltantes.. y comprobando.. \n"

i=1
until [ $i -eq 0 ]
do
test -f PreLoader.efi || wget https://blog.hansenpartnership.com/wp-uploads/2013/PreLoader.efi &>/dev/null
test -f HashTool.efi || wget https://blog.hansenpartnership.com/wp-uploads/2013/HashTool.efi &>/dev/null
echo -e '4f7a4f566781869d252a09dc84923a82  PreLoader.efi\n45639d23aa5f2a394b03a65fc732acf2  HashTool.efi' > md5.txt
md5sum -c md5.txt &>/dev/null
i=$?
rm md5.txt
done

mv PreLoader.efi ./${boot_file} &>/dev/null
mv syslinux.efi ./loader.efi

echo -e "\n editando archivos.. \n"

sed -i "s|/slax||g" syslinux.cfg
sed -i "s|help.txt|/boot/help.txt|g" syslinux.cfg
sed -i "s|vesamenu.c32|/EFI/${boot}/vesamenu.c32\nMENU TITLE Boot (EFI)|g" syslinux.cfg

echo "${boot_file},${boot},,This is the boot entry for syslinux" | tee -a BOOTX64.CSV &>/dev/null

if [ ${TYPE} == "vfat" ]; then

parted -s ${DEV} set ${NUM} boot on
cd $directory

if [ ! -d EFI/BOOT/ ]; then mkdir EFI/BOOT/; fi

file='' && for x in {fallback,fbx64}.efi; do [ "$file" != "" ]; case $? in 1) if [ -f EFI/BOOT/${x} ]; then file="EFI/BOOT/${x}"; fi ;; esac; done

if [ "$file" = "" ]; then file=/usr/lib/shim/fbx64.efi; fi
if [ ! -e $file ]; then apt-get download shim-signed &>/dev/null && d=`mktemp -d` && dpkg-deb --extract shim-signed*.deb $d &>/dev/null; fi
if [ "$file" = "" ]; then file=${d}/usr/lib/shim/fbx64.efi; fi
cp ${file} EFI/BOOT/ &>/dev/null

if [ -d EFI/syslinux/ ]; then efibootmgr --verbose --disk ${DEV} --part ${NUM} --create --label "Syslinux" --loader /EFI/${boot}/${boot_file} &>/dev/null; fi

bootnum=$(efibootmgr | grep Syslinux | sed -e "s/Syslinux//g" -e 's|Boot||g')
active=$(echo $bootnum | grep -q '*' && echo $?) 
case $active in 1) efibootmgr --bootnum $bootnum --active ;; esac

fi

clear
echo -e "\n listo, ya deberia estaria todo hecho.. \n"

exit 0
