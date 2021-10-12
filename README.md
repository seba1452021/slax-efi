# slax-efi
Configuración EFI para slax.
Se utiliza syslinux-efi y una particion fat de un dispositivo con mbr.
la memoria a preparar debe de estar siendo reconocida como "sda" en su sistema, fijese que hace, no me puedo hacer responsable, esta responsabilidad cae en la persona que hace uso de esto.
El dispositivo reconocido como "sda" sera formateado

## Preparación
Puede hacerlo de manera manual, la cual es sencilla y segura :

Descargue slax de https://slax.org
A partir de descargar su archivo .iso ,descomprima, lea el contenido del archivo "readme.txt", realice lo que se le indica, si tiene problemas busque y/o use un traductor, recomiendo deepl https://www.deepl.com/translator.
instale los programas: syslinux-common syslinux-efi
abra la terminal, busquela entre sus aplicaciones o con las teclas "ctrl + alt + t".
en esta, si utiliza debian/ubuntu.. copie y con el raton seleccione "pegar": sudo apt install --yes syslinux-common syslinux-efi
despues:
mkdir -p /DIRECTORIO/DEL/DISPOSITIVO/EFI/Boot/
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /directorio/del/dispositivo/EFI/Boot/bootx64.efi
cd /usr/lib/syslinux/modules/efi64/"
cp ldlinux.e64 menu.c32 libcom32.c32 libutil.c32 vesamenu.c32 /directorio/del/dispositivo/EFI/Boot
Cree en el directorio /EFI/boot de su dispositivo a preparar, un archivo llamado "syslinux.cfg"
Y  ponga de contenido:
"
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
"
...

O puede hacerlo todo automatico, lo cual no es muy recomendable pero comodo...

si sabe lo que hace, esta seguro de todo, descarge el archivo "slax-efi.sh".
ejecutelo..
y espere..
con eso ya estaria todo..

---------------------------------

bueno gracias por todo, espero no hallan problemas, inconvenientes...
no haber molestado, estoy iniciando aqui, sin experiencia...
solo queria dar algunos aportes...
no se si hice algo indebido, mal...

no se me da el ingles, asi que utilizo un traductor, recomiendo deepl, https://www.deepl.com/translator .
