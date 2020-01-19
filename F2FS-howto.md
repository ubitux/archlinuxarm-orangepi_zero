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

- Zero the beginning of the SD card

    dd if=/dev/zero of=/dev/sdX bs=1M count=8

- Partition the SD card

    lsblk

    sudo fdisk /dev/sdX

clear partitions on the drive (o)

create first partition (n, p, 1, enter, +128M, t, c)

create second partition (n, p, 2, enter, enter), then write and exit (w)

    sudo mkfs.vfat /dev/mmcblk0p1

(you need to install f2fs-tools)

    sudo mkfs.f2fs /dev/mmcblk0p2

    sudo mkdir /mnt/sd

    sudo mount /dev/mmcblk0p2 /mnt/sd

    sudo mkdir /mnt/sd/boot

    sudo mount /dev/mmcblk0p1 /mnt/sd/boot

you need to install bsdtar instead of gnu tar

    sudo bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C /mnt/sd

    sync

    sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/mmcblk0 bs=1024 seek=8
