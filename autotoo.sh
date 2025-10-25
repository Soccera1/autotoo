#!/bin/bash

echo "Welcome to Autotoo!"
echo ""
echo "Enter name of disk to be partitioned"
read disk
echo "The disk to be partitioned is $disk. Is this correct?"
echo "Press return to continue or C-c to exit"
read

sfdisk "$disk" << DISKEOF
label: gpt
unit: sectors
${disk}1 : size=512MiB, type=uefi
${disk}2 : type=linux
DISKEOF

mkfs.vfat -F 32 "$disk"1
mkfs.xfs "$disk"2

mkdir -p /mnt/gentoo
mount "$disk"2 /mnt/gentoo
mkdir /mnt/gentoo/efi
mount "$disk"1 /mnt/gentoo/efi

cd /mnt/gentoo
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20251019T170404Z/stage3-amd64-openrc-20251019T170404Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

cat > /mnt/gentoo/etc/portage/make.conf << MAKECONF
COMMON_FLAGS="-march=native -O2 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
RUSTFLAGS="-C target-cpu=native"
MAKEOPTS="-j$(nproc)"
USE="dist-kernel"
MAKECONF

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

cat > /mnt/gentoo/tmp/chroot.sh << CHROOTEOF

mount "$disk"1 /efi

emerge-webrsync
emerge --sync

eselect profile set 1

emerge -1 app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

echo -e "en_US.UTF-8 UTF-8\nC.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

cat > /etc/env.d/02locale << LOCALEEOF
LANG="en_US.UTF-8"
LC_COLLATE="C.UTF-8"
LOCALEEOF

echo "sys-kernel/installkernel grub dracut" > /etc/portage/package.use/installkernel

emerge sys-kernel/gentoo-kernel-bin

emerge -1 sys-fs/genfstab
genfstab -U / > /etc/fstab

echo tux > /etc/hostname

emerge net-misc/dhcpcd
rc-update add dhcpcd default

echo "Please set a root password!"
passwd

emerge app-admin/sysklogd
rc-update add sysklogd default

emerge sys-process/cronie
rc-update add cronie default

emerge sys-apps/mlocate

rc-update add sshd default

emerge app-shells/bash-completion

emerge net-misc/chrony
rc-update add chronyd default

emerge sys-fs/xfsprogs sys-fs/dosfstools

echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
emerge sys-boot/grub
grub-install --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg

exit
CHROOTEOF

chmod +x /mnt/gentoo/tmp/chroot.sh
chroot /mnt/gentoo /tmp/chroot.sh
rm /mnt/gentoo/tmp/chroot.sh

echo "Rebooting. Press C-c to abort"
sleep 10
reboot
