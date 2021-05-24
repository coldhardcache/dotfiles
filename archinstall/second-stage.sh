# $1 is the device (e.g. /dev/nvme0n1
# $2 is the username 

ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc --utc

echo mobiletoaster > /etc/hostname

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo LC_ALL= >> /etc/locale.conf

sed -i -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

echo 'This prompt is for ROOT PASSWORD'
passwd
groupadd $2
useradd -m -g $2 -G wheel,storage,power,network,uucp -s /bin/zsh $2
echo 'This prompt is for the user $2'
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
# echo 'initrd /intel-ucode.img' >> /boot/loader/entries/arch.conf
echo 'initrd /initramfs-linux.img' >> /boot/loader/entries/arch.conf
echo options cryptdevice=UUID=$uuid:vg0 root=/dev/mapper/vg0-root resume=/dev/mapper/vg0-swap rw intel_pstate=no_hwp >> /boot/loader/entries/arch.conf


echo 'Install complete. At next boot, start ricing?'
sleep 5

