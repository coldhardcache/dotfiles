echo "Beginning Install Script"

# Assumption that the two partitions have been made!!!
# $1 is the install drive
# $2 is the username

# cryptsetup
mkfs.vfat -F32 -n EFI $1p1
cryptsetup --use-random luksFormat $1p2
cryptsetup luksOpen $1p2 luks


# create encrypt partitions
pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate --size 16G vg0 --name swap
lvcreate -l +100%FREE vg0 --name root

# create fs
mkfs.ext4 -L root /dev/mapper/vg0-root
mkswap /dev/mapper/vg0-swap
mount /dev/mapper/vg0-root /mnt # /mnt is the installed system
swapon /dev/mapper/vg0-swap # Not needed but a good thing to test
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# pacstrap
pacstrap /mnt base base-devel bash linux linux-firmware vim git sudo efibootmgr dialog tmux lvm2 iwd zsh intel-ucode

genfstab -pU /mnt | tee -a /mnt/etc/fstab

echo "tmpfs   /tmp	tmpfs	defaults,noatime,mode=1777	0	0" >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash

ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc --utc

echo mobiletoaster > /etc/hostname

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo LC_ALL= >> /etc/locale.conf

passwd
groupadd $2
useradd -m -g $2 -G wheel,storage,power,network,uucp -s /bin/zsh $2
passwd $2

sed -i 's/MODULES=()/MODULES=(ext4)/g' /etc/mkinitcpio.conf
sed -i 's/HOOKS=(base udev/ HOOKS=(base udev encrypt lvm2 resume /g' /etc/mkinitcpio.conf
mkinitcpio -p linux

bootctl --path=/boot install

echo default arch >> /boot/loader/loader.conf
echo timeout 5 >> /boot/loader/loader.conf

uuid=$(blkid | grep "$1p2" | cut -b 23-58)

echo 'title Arch Linux' >> /boot/loader/entries/arch.conf
echo 'linux /vmlinuz-linux' >> /boot/loader/entries/arch.conf
echo 'initrd /intel-ucode.img' >> /boot/loader/entries/arch.conf
echo 'initrd /initramfs-linux.img' >> /boot/loader/entries/arch.conf
echo 'options cryptdevice=UUID=$uuid:vg0 root=/dev/mapper/vg0-root resume=/dev/mapper/vg0-swap rw intel_pstate=no_hwp'


echo 'Install complete. Need to exit, unmount -a and reboot!'
