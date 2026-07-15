#!/bin/bash
set -euo pipefail

#final_disk=variable with disk for installation
#steaminstall=variable if steam should be installed

###############################################################################
#Welcome Message
###############################################################################

whiptail --title "Greetings Summoner" --msgbox "This is a Beta. Everything on your Disk can or will be deleted. Handle with care" 8 78


###############################################################################
#Choose Disk for Installation
###############################################################################

#list all drives 
mapfile -t lines < <(lsblk -dno NAME,MODEL,TYPE)
#save as line
options=()
for i in "${!lines[@]}"; do
  options+=("$((i+1))" "${lines[$i]}")
done
#build whiptail menu
choice=$(whiptail --title "Choose Disk" --menu "Choose Disk" 15 70 8 \
  "${options[@]}" \
  3>&1 1>&2 2>&3)

raw_disk="${lines[$((choice-1))]}"
final_disk="/dev/${raw_disk%% *}" #generate path for partioning and formating

#checking
#echo "Du hast gewählt: $final_disk"

###############################################################################
#Steam installation
###############################################################################

if whiptail --title "Steam" --yesno "Install Steam?" 8 40; then
  steaminstall=yes
else
  steaminstall=no
fi

#echo "$steaminstall"

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$dir/installer.sh" $final_disk $steaminstall

cp "$dir/configurator.sh" /mnt
arch-chroot /mnt ./configurator.sh $steaminstall

rm /mnt/configurator.sh
umount /mnt/boot
umount /mnt
reboot

