#!/bin/bash
set -euo pipefail

drive=$1
steam=$2

###############################################################################
#summary
###############################################################################

whiptail --title "Installation Summary" --msgbox "System will be installed at "$drive" and you say "$steam" to steam!" 8 78

###############################################################################
#Countdown
###############################################################################

for ((i=5; i>0; i--)); do
  printf "\rPress CTRL+C to stop system installation on "$drive": %d " "$i"
  sleep 1
done
echo
echo "starting installation..."

###############################################################################
#partition and format
###############################################################################

if [[ ${drive:5:4} == "nvme" ]]; then
    drive="${drive}p"
fi

sgdisk -o "$drive"
sgdisk -n 1:2048:+512M -n 2:0:0 -t 1:ef00 "$drive"

mkfs.fat -F32 -n UEFI "$drive"1
mkfs.ext4 -L ROOT "$drive"2

mount "$drive"2 /mnt
mkdir /mnt/boot
mount "$drive"1 /mnt/boot

echo -e "\n\033[36mDrive done\033[0m"

###############################################################################
#system and package installation
###############################################################################

pacman-key —init 

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pacstrap /mnt $(< $dir/packages.txt)

genfstab -U /mnt > /mnt/etc/fstab

