echo "Beginning Part one of the install Script"

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
pacstrap /mnt base base-devel bash linux linux-firmware vim git sudo efibootmgr dialog tmux lvm2 iwd zsh
read  -n 1
genfstab -pU /mnt | tee -a /mnt/etc/fstab
read  -n 1
echo "tmpfs   /tmp	tmpfs	defaults,noatime,mode=1777	0	0" >> /mnt/etc/fstab

sed -i 's/relatime/noatime/g' /mnt/etc/fstab

curl 'https://raw.githubusercontent.com/coldhardcache/dotfiles/main/archinstall/second-stage.sh' > /mnt/root/second-stage.sh
read  -n 1
chmod +x /mnt/root/second-stage.sh

arch-chroot /mnt /bin/bash /root/second-stage.sh $1 $2

rm /mnt/root/second-stage.sh

umount -R /mnt

swapoff -a

reboot
