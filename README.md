This repository can be used to create an ArchLinuxARM image for the OrangePi
Zero board.


Dependencies
============

- `make`
- `git`
- `bsdtar` (`libarchive`)
- `python2`


Prerequisite
============

In order to build the image, you need a working ARM toolchain.

Here is a simple way to get one:

    git clone https://github.com/crosstool-ng/crosstool-ng
    cd crosstool-ng
    ./bootstrap
    ./configure --enable-local
    ./ct-ng arm-unknown-eabi
    ./ct-ng build


Preparing the files
===================

Run `make`.

This will provide:

- the ArchLinuxARM armv7 default rootfs (`ArchLinuxARM-armv7-latest.tar.gz`)
- an u-boot image compiled for the OrangePi Zero (`u-boot-sunxi-with-spl.bin`)
- a boot script (`boot.scr`) to be copied in /boot


Installing the distribution
===========================

This is similar to any other AllWinner ArchLinuxARM installation: pick any from
https://archlinuxarm.org/platforms/armv7/allwinner/.

In 4 steps:
- create and format one ext4 partition
- untar the rootfs into it
- dd the u-boot image at offset 8192
- copy the boot script in the /boot partition


Goodies
=======

If you have a serial cable and `miniterm.py` installed (`python-pyserial`),
`make serial` will open a session with the appropriate settings.


TODO
====

- Make ethernet work (tested with 4.12.4)
- remove u-boot patches when mainlined
- upstream to ArchLinuxARM


U-Boot patches status
=====================

- clock speed patch is currently in uboot-sunxi (http://git.denx.de/?p=u-boot/u-boot-sunxi.git;a=commitdiff;h=8792a64d87708139bc0cf8b48d4a580a39167473)
- Python patch is under review (http://patchwork.ozlabs.org/patch/801087/)
