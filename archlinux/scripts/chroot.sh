#!/bin/bash

set -e

DEVICE=${DEVICE:-/dev/sda}
[ -b $DEVICE ] || DEVICE="/dev/vda"
[ -b $DEVICE ] || {
    echo "Could not find root device. Exiting."
    exit 1
}

echo "Running in chroot"
pacman -Syy

echo "Setting hostname"
echo "archlinux" > /etc/hostname

echo "Setting local time zone"
ln -vsf /usr/share/zoneinfo/UTC /etc/localtime

echo "Generating locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen

echo 'LANG=de_DE.utf8' > /etc/locale.conf

echo "KEYMAP=de-latin1-nodeadkeys" > /etc/vconsole.conf

echo "Installing sshd"
pacman -S --noconfirm openssh rsync sudo

sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*//g" /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

systemctl enable sshd

echo "Installing kernel and syslinux"

pacman -S --noconfirm linux grub

echo "Installing grub on $DEVICE"
grub-install --force $DEVICE
grub-mkconfig -o /boot/grub/grub.cfg


echo "Setting up root user"
echo "root:packer" | chpasswd


echo "Configuring network interfaces"

pacman -S --noconfirm net-tools

systemctl enable systemd-networkd.service

cat <<EOF > /etc/systemd/network/dhcp.network
[Match]
Name=e*
[Network]
DHCP=yes
[DHCPv4]
UseHostname=false
EOF

pacman -S --noconfirm btrfs-progs
sed -i 's/filesystems/filesystems btrfs/g' /etc/mkinitcpio.conf
/usr/bin/mkinitcpio -p linux
RESULT=$?
echo "mkinitcpio finished with code $RESULT"

echo "Create vagrant folder /vagrant"
mkdir -p /vagrant

exit 0