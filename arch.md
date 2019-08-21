# Arch Linux Installation

That's what happened on my 512G USB stick at Aug. 2019.

Aimed to create a portable Arch system on both of my Project00 desktop and Surface Pro 6.

All the sudo & su may be ignored in procedure.

## partition

```bash
# make up GPT
gdisk /sdd

# size		fstype	Name					Code
# 2 GiB		FAT32	EFI System				EF00
# 400 GiB	btrfs	Linux filesystem		8300
# 64 GiB	exfat	Microsoft Basic data	0700
# 6 GiB		swap	Linux swap				8200

# format
mkfs.fat -F32 /dev/sdd1
mkfs.btrfs -fL pool /dev/sdd2 # Force to override possible exsiting content
mkfs.exfat /dev/sdd3
mkswap /dev/sdd4

# mount btrfs pool
mkdir -p /mnt/pool
mount -o noatime,autodefrag /dev/sdd2 /mnt/pool

# create subvolume
btrfs subvolume create /mnt/pool/@
btrfs subvolume create /mnt/pool/@snapshots
btrfs subvolume create /mnt/pool/@home
btrfs subvolume create /mnt/pool/@code
```

## pacstrap

```bash
# mount root
mkdir -p /mnt/install
mount -o noatime,autodefrag,subvol=@main /dev/sdd2 /mnt/install

# install mininum
pacstrap -c /mnt/install base base-devel btrfs-progs exfat-utils ntfs-3g zsh vim
```

## fstab

```bash
# manual mount
# /mnt/install/home should has been created by pacstrap
mount -o noatime,autodefrag,subvol=@home /dev/sdd2 /mnt/install/home

mkdir /mnt/install/home/code
mount -o noatime,autodefrag,subvol=@code /dev/sdd2 /mnt/install/home/code
chattr +C /mnt/install/home/code # git controled dirs don't need CopyOnWrite

mkdir /mnt/install/efi
mount /dev/sdd1 /mnt/install/efi

mkdir /mnt/install/mnt/extra
mount /dev/sdd3 /mnt/install/mnt/extra

mkdir /mnt/install/mnt/media
mount /dev/disk/by-label/Media /mnt/install/mnt/media

genfstab -U /mnt/install >> /mnt/install/etc/fstab
vim /mnt/install/etc/fstab
# remove redundant swap info, it would automatic uploaded because of its GPT label
# switch media mount to use label for cross-base availability
# config media mount with uid=1000,gid=1000,dmask=022,fmask=133 for NTFS privilege
```

## chroot

```bash
arch-chroot /mnt/install
```

## locale

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

vim /etc/locale.gen
# uncomment en_US.UTF-8 & zh_CN.UTF-8
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
```

## network

```bash
echo vehicle > /etc/hostname
vim /etc/hosts
# 127.0.0.1       localhost
# ::1             localhost
# 127.0.1.1       vehicle.localdomain     vehicle
```

## bootloader GRUB

```bash
pacman -S grub
grub-install --target=x86_64-efi --efi-directory=/efi --removable # don't write UEFI NVRAM for cross device
grub-mkconfig -o /boot/grub/grub.cfg
```

## user

```bash
passwd

useradd -m -G wheel -s /bin/zsh alex # add to whell group for sudo
passwd alex

visudo
# %whell ALL=(ALL) ALL
```

## configs synchronization

```bash{}
# use ssh to localhost rather than mount

pacman -S openssh

scp -r alex@localhost:~{.zshrc,.vimrc,.ssh} /home/alex/
# user shall has priviledges to its configs
chown -R alex /home/alex

# install plugins used in .zshrc
pacman -S zsh-syntax-highlighting zsh-autosuggestions
```

## pacman config

```bash
vim /etc/pacman.conf

# Color
# TotalDownload
# VerbosePkgLists

# [archlinuxcn]
# Server = https://cdn.repo.archlinuxcn.org/$arch

# pacman cache clean automation
pacman -S pacman-contrib
systemctl enable paccache.timer

# update all
pacman -Syu

# keyring for archlinuxcn
pacman -S archlinuxcn-keyring
```

## proxy

```bash
pacman -S  shadowsocks-libev
scp -r alex@localhost:/etc/shadowsocks /etc/
systemctl enable shadowsocks-libev@bandwagon

pacman -S proxychains-ng
vim /etc/proxychains.conf
```

## miscellaneous

```bash
# periodic ssd trim
systemctl enable fstrim.timer

# network
pacman -S networkmanager
systemctl enable NetworkManager.service

exit
reboot
```

## yay

```bash
sudo pacman -S git
git clone https://aur.archlinux.org/yay.git
cd yay
sudo makepkg -si
```

## DE KDE

```bash
sudo pacman -S plasma-meta

sudo systemctl enable sddm.service

sudo pacman -S kde-gtk-config
sudo pacman -S konsole dolphin dolphin-plugins 
sudo pacman -S gwenview ksystemlog flameshot

yay kdeconnect
```

## DE GNOME

```bash
sudo pacman -S gnome

sudo systemctl enable gdm.service

yay -S gnome-shell-extension-gtktitlebar-git
yay -S gnome-shell-extension-gsconnect
yay -S gnome-shell-extension-vitals-git
yay -S gnome-shell-extension-openweather-git

# resolve their confilts with IDEA's Ctrl + Alt + Left/Right Arrow Key
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['']"
```

## numlock

```bash
# TTY
yay -S systemd-numlockontty
sudo systemctl enable numLockOnTty.service

# sddm
sudo vim /etc/sddm.conf
# [General]
# Numlock=on
```

## linux surface kernel

```bash
# use dmhacker's
su
git clone https://github.com/dmhacker/arch-linux-surface
cd arch-linux-surface
# modify *.sh by insert proxychain before every git if download speed is slow
sudo sh setup.sh
sh configure.sh 
cd build-[VERSION]
MAKEFLAGS="-j[NPROC]" makepkg -sc
cd ..
chown -R [USER] build-[VERSION]
exit

cd build-[VERSION]
sudo pacman -U linux-surface-*
```



## bootloader REFIND

```bash
# uninstall GRUB
yay -Rs grub
sudo rm -r /efi/EFI

yay -S shim-signed sbsigntools refind-efi
sudo refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys --usedefault /dev/sdd1

sudo vim /efi/EFI/BOOT/refind.conf
# timeout 2
# use_nvram false
# enable_touch
# enable_mouse
# scanfor manual
# and menuentry in the following content

sudo mkdir -p /etc/pacman.d/hooks
sudo vim /etc/pacman.d/hooks/800-sign_kernel_for_secureboot.hook
# When = PostTransaction
# Exec = /usr/bin/find /boot/ -maxdepth 1 -name 'vmlinuz-*' -exec /usr/bin/sh -c 'if ! /usr/bin/sbverify --list {} 2>/dev/null | /usr/bin/grep -q "signature certificates"; then /usr/bin/sbsign --key /etc/refind.d/keys/refind_local.key --cert /etc/refind.d/keys/refind_local.crt --output {} {}; fi' ;
# Depends = sbsigntools
# Depends = findutils
# Depends = grep

mkinitcpio -p linux
```

The following content include arch-surface kernel and resume modifications.

use `lsblk -f` and `blkid /dev/...`to confirm the correct PARTUUID and UUID.

```
menuentry "Arch Linux Surface" {
    icon     /EFI/BOOT/icons/os_legacy.png
    volume   pool
    loader   @/boot/vmlinuz-linux-surface
    initrd   @/boot/initramfs-linux-surface.img
    options  "root=PARTUUID={pool's PARTUUID} resume=UUID={pool's UUID} rw rootflags=subvol=@ add_efi_memmap"
    submenuentry "Boot using fallback initramfs" {
        initrd @/boot/initramfs-linux-fallback-surface.img
    }
    submenuentry "Boot to terminal" {
        add_options "systemd.unit=multi-user.target"
    }
}

menuentry "Arch Linux" 
    icon     /EFI/BOOT/icons/os_arch.png
    volume   pool
    loader   @/boot/vmlinuz-linux
    initrd   @/boot/initramfs-linux.img
    options  "root=PARTUUID={pool's PARTUUID} resume=UUID={pool's UUID} rw rootflags=subvol=@ add_efi_memmap"
    submenuentry "Boot using fallback initramfs" {
        initrd @/boot/initramfs-linux-fallback.img
    }
    submenuentry "Boot to terminal" {
        add_options "systemd.unit=multi-user.target"
    }
}
```

## fonts

```bash
yay -S noto-fonts-cjk ttf-inconsolata
```

## IME fcitx

```bash
# for KDE
yay -S fcitx-im fcitx-libpinyin fcitx-cloudpinyin kcm-fcitx fcitx-skin-material

cat >> ~/.pam_environment
[Return]
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
[Ctrl+D]
```

## IME IBUS

```bash
# for GNOME
yay -S ibus-rime

# synchronize configs through mount local disk
sudo mount /dev/mapper/VolGroup00-main /mnt/base
cp -r /mnt/base/home/alex/.config/ibus/rime ~/.config/ibus/
```

## IDEs

```bash
yay IDEA
yay jdk

yay python
yay PyCharm

yay Clion

yay Goland
yay go

yay Visual Studio Code
yay node
```

## applications

```bash
yay typora
yay netease cloud music
yay telegram
```

## fix shadowsocks problem

If use server with domain name rather than IP address, a name resolution error would occur, which fails its bootstrap and make `sudo systemctl enable shadowsocks-libev@...` a must. 

Because despite its configuration, the shadowsocks service starts before network is ready.

```bash
yay wait-online-git 
```

## hibernate

```bash
# for surface, undo some job setup.sh done,
# use kernel later than 5.0, suspend & hibernate are all okay.
sudo ln -sf /lib/systemd/system/suspend.target /etc/systemd/system/suspend.target
sudo ln -sf /lib/systemd/system/systemd-suspend.service /etc/systemd/system/systemd-suspend.service

sudo vim /etc/mkinitcpio.conf
# HOOKS=(... +resume)

sudo vim /efi/EFI/BOOT/refind.conf
# options "... +resume=UUID={swap_uuid}"
```

## onedrive

```bash
yay onedrive
echo 'Notes' > ~/.config/onedrive/sync_list
echo 'Sync' >> ~/.config/onedrive/sync_list
echo 'skip_dotfiles = "true"' > ~/.config/onedrive/config
onedrive --synchronize --verbose --dry-run
systemctl --user enable onedrive
```