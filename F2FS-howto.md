Updated Makefile to use latest uboot and installed toolchain.

To install using f2fs:

- Correct `boot.txt` by removing `\boot\` path from the u-boot screen, to get a result similar to the following
```
load mmc 0:1 ${loadaddr} /Image
load mmc 0:1 ${dtb_loadaddr} /dtbs/meson64_odroidec2.dtb
load mmc 0:1 ${initrd_loadaddr} /initramfs-linux.img
```
- Remove setenv dtbfile from u-boot script
- Recompilate u-boot script with `make boot.scr`

    lsblk

    sudo fdisk /dev/sdX

clear partitions on the drive (o)

create first partition (n, p, 1, enter, +100M, t, c)

create second partition (n, p, 2, enter, enter), then write and exit (w)

    sudo mkfs.vfat /dev/sdX1

    sudo mkdir /mnt/boot

    sudo mount /dev/sdX1 /mnt/boot

(you need to install f2fs-tools)

    sudo mkfs.f2fs /dev/sdX2

    sudo mkdir /mnt/root

    sudo mount -t f2fs /dev/sdX2 /mnt/root

    wget http://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz

    there is ArchLinuxARM-rpi-2-latest.tar.gz and ArchLinuxARM-rpi-3-latest.tar.gz exist, both work for pi 3, the latter one have a 64-bit kernel and aarch64 rootfs, but the 
performance seems not good as the first one, so I will still use ArchLinuxARM-rpi-2-latest.tar.gz

    sudo su

    you need to install bsdtar instead of gnu tar

    bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C /mnt/root

    sync

    mv /mnt/root/boot/* /mnt/boot
