# Arch Linux installation guide notes

_dev_ is the device you are installing Arch onto

## Steps

1. Disable "Secure Boot" in the BIOS.
1. Boot into Arch Linux live installation media. Make sure that you know which disk is used for your
   installation. We'll assume it's `/dev/sda`, but if you use M.2, it's likely `/dev/nvmenX`.  You can use `blkid` to list block devices.
1. If you're using Wifi, launch `iwctl`.
1. If wired, you should be good. If not, use `ip` and `dmesg` to debug.
1. Partition your disk:
   1. Run `cfdisk ` _dev_ for partitioning
   1. Choose GPT partitioning (if you don't get the option to choose ,please run `cfdisk -z`)
   1. Create a 1GB EFI boot partition. Set its type to `EFI System`. 
   1. Create a swap partition. 16GiB will probably do. If you have over 32GB RAM, probably not needed. Set its type to `Linux Swap`
   1. Create a partition for the rest of the drive.
   1. `mkswap /dev/sda2`
   1. `swapon /dev/sda2`
   1. `mkfs.vfat -F32 /dev/sda1`
   1. `mkfs.ext4 /dev/sda3`
   1. `mount /dev/sda3 /mnt`
   1. `mkdir /mnt/boot`
   1. `mount /dev/sda1 /mnt/boot`
1. `pacstrap /mnt base sudo linux linux-firmware vim dev`
1. `genfstab -U /mnt >> /mnt/etc/fstab`
1. `arch-chroot /mnt`
1. `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime` (you can see all the options in [wiki timezones list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))
1. Uncomment `en_US.UTF-8`and other needed localizations in `/etc/locale.gen`
1. `locale-gen`
1. Edit `/etc/locale.conf` and write `LANG=en_US.UTF-8`
1. Networking - Use [NetworkManager](https://wiki.archlinux.org/index.php/NetworkManager)
   1. `pacman -S networkmanager`
   1. `systemctl enable NetworkManager`
   1. Once you have a GUI environment set up - configure the network using the GUI
1. `echo [YOUR HOSTNAME] > /etc/hostname`
1. `passwd` - Set the root password
1. `useradd -m <your_username>`
1. `usermod -G wheel -a <your_username>`
1. `passwd <your_username>` - Set the user password
1. `EDITOR=vim visudo` - Uncomment the line containing the `wheel` group
1. Install the bootloader - [systemd-boot](https://wiki.archlinux.org/index.php/Systemd-boot)
    1. `bootctl --path=/boot install`
    1. Edit `/etc/pacman.d/hooks/systemd-boot.hook`:
       ```
       [Trigger]
       Type = Package
       Operation = Upgrade
       Target = systemd

       [Action]
       Description = Updating systemd-boot...
       When = PostTransaction
       Exec = /usr/bin/bootctl update
       ```
    1. Edit `/boot/loader/loader.conf`:
       ```
       timeout  4
       default  arch
       ```
    1. Figure out your root partition's UUID By running `blkid`. This should probably be the UUID of /dev/sda3
    1. Create `/boot/loader/entries/arch.conf`. Replace `<PUUID>` (**NOT** `<UUID>`) with the PARTUUID that you got from
    running `blkid`. Note that the UUID is case sensitive.
       ```
       title          Arch Linux
       linux          /vmlinuz-linux
       initrd         /intel-ucode.img
       initrd         /initramfs-linux.img
       options        root=PARTUUID=<PUUID> rw
       ```
1. Leave chroot - `exit`
1. If this is a server installation you might want to enable SSH before rebooting. See the
   instructions at the bottom.
1. Reboot - `systemctl reboot`
1. Once your system is up activate NTP by running `timedatectl set-ntp on`
1. If needed, connect to wifi by running `nmcli device wifi connect <SSID> password <password>`

## Extras
### Yay
Building packages from AUR isn't possible to do as root. In order to install Yay you have to
configure sudo and run these commands as a regular user.

1. `sudo pacman -S --needed base-devel git`
1. `cd /tmp`
1. `git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -i && cd - && rm -rf yay-bin`

### GNOME
```pacman -S gnome && systemctl enable --now gdm```

### KDE
```pacman -S sddm plasma-meta kdebase-meta kdeutils-meta kdegraphics-meta && systemctl enable --now sddm```

### Setting up an SSH server
```pacman -S openssh && systemctl enable --now sshd.socket```
