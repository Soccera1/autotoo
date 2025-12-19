#!/bin/bash

die() {
  local status=$?
  local msg=$1

  if [ "$status" -ne 0 ]; then
    echo "FATAL: $msg" >&2
    echo "Exit code: $status" >&2
    exit "$status"
  fi
}

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
die "EFI partition failed"
mkfs.xfs -f "$disk"2
die "root partition failed"

mkdir -p /mnt/gentoo
mount "$disk"2 /mnt/gentoo
die "mounting root failed"
mkdir /mnt/gentoo/efi
mount "$disk"1 /mnt/gentoo/efi
die "mounting efi failed"

cd /mnt/gentoo
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20251214T164554Z/stage3-amd64-openrc-20251214T164554Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
die "extracting stage3 failed"

cat > /mnt/gentoo/etc/portage/make.conf << MAKECONF
COMMON_FLAGS="-march=native -O2 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
RUSTFLAGS="-C target-cpu=native"
MAKEOPTS="-j$(nproc)"
USE="dist-kernel"
MAKECONF
die "make.conf could not be written to"

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
die "chroot failed"
mount --types proc /proc /mnt/gentoo/proc
die "chroot failed"
mount --rbind /sys /mnt/gentoo/sys
die "chroot failed"
mount --make-rslave /mnt/gentoo/sys
die "chroot failed"
mount --rbind /dev /mnt/gentoo/dev
die "chroot failed"
mount --make-rslave /mnt/gentoo/dev
die "chroot failed"
mount --bind /run /mnt/gentoo/run
die "chroot failed"
mount --make-slave /mnt/gentoo/run
die "chroot failed"

cat > /mnt/gentoo/tmp/chroot.sh << 'CHROOTEOF'
die() {
  local status=$?
  local msg=$1

  if [ "$status" -ne 0 ]; then
    echo "FATAL: $msg" >&2
    echo "Exit code: $status" >&2
    exit "$status"
  fi
}

echo "Enter disk again"
read disk
mount "$disk"1 /efi
die "EFI mount failed"

emerge-webrsync
die "portage sync failed"

eselect profile set 1
die "profile could not be set"

emerge -1q app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
die "cpuflags could not be set"

echo -e "en_US.UTF-8 UTF-8\nC.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
die "locale could not be generated"

cat > /etc/env.d/02locale << LOCALEEOF
LANG="en_US.UTF-8"
LC_COLLATE="C.UTF-8"
LOCALEEOF
die "locale could not be set"

echo "sys-kernel/installkernel grub dracut" > /etc/portage/package.use/installkernel
die "installkernel flags could not be set"

emerge -q sys-kernel/gentoo-kernel-bin
die "kernel could not be installed"
emerge -1q sys-fs/genfstab
die "genfstab could not be installed"
genfstab -U / > /etc/fstab
die "fstab could not be created"

echo tux > /etc/hostname
die "hostname could not be set"

emerge -q net-misc/dhcpcd
rc-update add dhcpcd default
die "dhcpcd could not be enabled"

echo "Please set a root password!"
passwd
die "root password was not set"

emerge -q app-admin/sysklogd
rc-update add sysklogd default
die "sysklogd could not be enabled"

emerge -q sys-process/cronie
rc-update add cronie default
die "cronie could not be enabled"

emerge -q sys-apps/mlocate
die "mlocate could not be installed"

rc-update add sshd default
die "sshd could not be enabled"

emerge -q app-shells/bash-completion
die "bash completion could not be enabled"

emerge -q net-misc/chrony
rc-update add chronyd default
die "chrony could not be enabled"

emerge -q sys-fs/xfsprogs sys-fs/dosfstools
die "filesystem tools could not be installed"

echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
emerge -q sys-boot/grub
grub-install --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg
die "grub could not be installed"

exit
CHROOTEOF
die "script could not be written"

chmod +x /mnt/gentoo/tmp/chroot.sh
die "script cannot be executed"
chroot /mnt/gentoo /tmp/chroot.sh
die "chroot failed"
rm /mnt/gentoo/tmp/chroot.sh

echo "Rebooting. Press C-c to abort"
sleep 10
reboot
die "reboot failed"
