# Autotoo - Automated Gentoo Linux Installation Script

An automated installation script for Gentoo Linux that streamlines the setup process from disk partitioning through to a bootable system.

## Overview

Autotoo is a bash script that automates the Gentoo Linux installation process. It handles disk partitioning, filesystem creation, stage3 extraction, system configuration, and bootloader installation with minimal user interaction.

## Features

- **Automated disk partitioning** with GPT layout (512MB EFI partition + Linux root)
- **Filesystem setup** using XFS for root and FAT32 for EFI
- **Stage3 installation** with automatic download and extraction
- **Optimized compiler flags** using native CPU detection
- **Kernel installation** via gentoo-kernel-bin for faster setup
- **Essential system packages** including network management, logging, and scheduling
- **GRUB bootloader** configuration with EFI support
- **Service initialization** with OpenRC

## Prerequisites

- Boot from a Gentoo LiveCD/LiveUSB or similar Linux environment
- Active internet connection
- Target disk for installation (all data will be erased)
- Root privileges

## Usage

1. Boot into a live Linux environment
2. Download the script:
   ```bash
   git clone https://github.com/soccera1/autotoo.git
   cd autotoo
   chmod +x autotoo.sh
   ```
3. Run the script:
   ```bash
   ./autotoo.sh
   ```
4. When prompted, enter the disk device (e.g., `/dev/sda` or `/dev/nvme0n1`)
5. Confirm the disk selection
6. Set a root password when prompted
7. Wait for the installation to complete (the system will reboot automatically)

## What Gets Installed

### System Configuration
- Locale: en_US.UTF-8 and C.UTF-8
- Hostname: tux
- Profile: Default/linux/amd64/23.0 (profile 1)

### Packages
- **Kernel**: sys-kernel/gentoo-kernel-bin (binary kernel for faster installation)
- **Bootloader**: sys-boot/grub (EFI mode)
- **Networking**: net-misc/dhcpcd
- **Time sync**: net-misc/chrony
- **Logging**: app-admin/sysklogd
- **Scheduling**: sys-process/cronie
- **File indexing**: sys-apps/mlocate
- **Filesystem tools**: sys-fs/xfsprogs, sys-fs/dosfstools
- **Shell utilities**: app-shells/bash-completion

### Services (enabled at boot)
- dhcpcd (network management)
- sshd (SSH server)
- sysklogd (system logging)
- cronie (cron daemon)
- chronyd (time synchronization)

## Disk Layout

| Partition | Size | Type | Filesystem | Mount Point |
|-----------|------|------|------------|-------------|
| 1 | 512 MB | EFI System | FAT32 | /efi |
| 2 | Remaining | Linux | XFS | / |

## Important Notes

- **This script will erase all data on the selected disk** - ensure you select the correct device
- The script downloads a specific stage3 tarball (dated 20251019T170404Z) - you may want to update this URL to the latest version
- Root password must be set manually during installation
- The system will automatically reboot after installation completes (10 second countdown)
- No swap partition is created by default

## Customization

You can modify the script to customize:
- Compiler optimization flags in `make.conf`
- USE flags
- Additional packages to install
- Partition sizes
- Hostname (default: "tux")
- System locale settings

## Post-Installation

After the system reboots:
1. Log in as root with the password you set
2. Create a regular user account
3. Configure any additional services
4. Update the system: `emerge --sync && emerge -uDN @world`
5. Customize your Gentoo installation as needed

## Troubleshooting

- **Script fails at disk partitioning**: Verify the disk device path is correct and the disk is not mounted
- **Network issues in chroot**: Check that `/etc/resolv.conf` was copied correctly
- **GRUB installation fails**: Ensure the EFI partition is properly mounted at `/efi`
- **System won't boot**: Boot from live media and check GRUB configuration and EFI variables

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Contributing

Contributions are welcome! Please ensure any modifications maintain compatibility with current Gentoo installation procedures.

## Disclaimer

This script is provided as-is for educational and convenience purposes. Always review scripts that perform system-level operations before running them. The authors are not responsible for data loss or system damage resulting from the use of this script.

## Resources

- [Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:Main_Page)
- [Gentoo Forums](https://forums.gentoo.org/)
- [Gentoo Wiki](https://wiki.gentoo.org/)
