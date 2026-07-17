#!/bin/bash
set -euo pipefail

steam=$1
#passtext=$2

###############################################################################
#host name
###############################################################################

echo bigscreenos > /etc/hostname

###############################################################################
#set locale to en_US 
###############################################################################

echo "en_US.UTF-8" >> /etc/locale.gen
locale-gen

###############################################################################
#hosts
###############################################################################

echo "#<ip-address>	<hostname.domain.org>	<hostname>"
echo "127.0.0.1	localhost.localdomain	localhost"
echo "::1		localhost.localdomain	localhost" 

###############################################################################
#initramfs
###############################################################################

mkinitcpio -p linux

###############################################################################
#bootloader
###############################################################################

bootctl install
chmod 700 /boot
chmod 700 /boot/loader
chmod 600 /boot/loader/random-seed

echo "title    BigScreenOS" > /boot/loader/entries/arch-uefi.conf
echo "linux    /vmlinuz-linux" >> /boot/loader/entries/arch-uefi.conf
echo "initrd   /initramfs-linux.img" >> /boot/loader/entries/arch-uefi.conf
echo "options  root=LABEL=ROOT rw lang=en init=/usr/lib/systemd/systemd locale=en_US.UTF-8" >> /boot/loader/entries/arch-uefi.conf

echo "title    BigScreenOS Fallback" > /boot/loader/entries/arch-uefi-fallback.conf
echo "linux    /vmlinuz-linux" >> /boot/loader/entries/arch-uefi-fallback.conf
echo "initrd   /initramfs-linux-fallback.img" >> /boot/loader/entries/arch-uefi-fallback.conf
echo "options  root=LABEL=ROOT rw lang=en init=/usr/lib/systemd/systemd locale=en_US.UTF-8" >> /boot/loader/entries/arch-uefi-fallback.conf

echo "default   arch-uefi.conf" > /boot/loader/loader.conf
echo "timeout   1" >> /boot/loader/loader.conf

bootctl update

###############################################################################
#activate multilib
###############################################################################

echo "[multilib]" >> /etc/pacman.conf
echo "SigLevel = PackageRequired TrustedOnly" >> /etc/pacman.conf
echo  "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

###############################################################################
#stea and 32bit drivers
###############################################################################
systemctl start reflector.services
pacman -Sy

pacman -S --noconfirm lib32-vulkan-radeon lib32-vulkan-intel lib32-nvidia-utils lib32-mesa

if [[ "$steam" == "yes" ]]; then
    pacman -S --noconfirm steam
fi

###############################################################################
#user creation and password and sudo
###############################################################################
#echo -e "$passtext\n$passtext" | passwd

useradd -m -s /bin/bash bigscreenuser
#echo -e "$passtext\n$passtext" | passwd bigscreenuser

mkdir -p /etc/sudoers.d/
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/99-wheel
chmod 0440 /etc/sudoers.d/99-wheel

gpasswd -a bigscreenuser wheel
gpasswd -a bigscreenuser users
gpasswd -a bigscreenuser audio
gpasswd -a bigscreenuser video
gpasswd -a bigscreenuser games
gpasswd -a bigscreenuser power

###############################################################################
#desktop
###############################################################################

mkdir -p /etc/plasmalogin.conf.d/
echo "[Autologin]" > /etc/plasmalogin.conf.d/autologin.conf
echo "User=bigscreenuser" >> /etc/plasmalogin.conf.d/autologin.conf
echo "Session=plasma-bigscreen-wayland.desktop" >> /etc/plasmalogin.conf.d/autologin.conf

###############################################################################
#services
###############################################################################

systemctl enable reflector.service
systemctl enable --now fstrim.timer
systemctl enable --now systemd-timesyncd.service
systemctl enable NetworkManager.service
systemctl enable acpid
systemctl enable avahi-daemon
systemctl enable cups.service
systemctl enable plasmalogin.service

exit
