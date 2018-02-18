This repository can be used to create an ArchLinuxARM image for the OrangePi
Zero board.


Dependencies
============

- `make`
- `bsdtar` (`libarchive`)
- `python2`
- `uboot-tools`
- `device-tree-compiler` >1.4.0 (1.4.5)
- `sudo`
- `fdisk`


Prerequisite
============

In order to build the image, you need a working ARM toolchain.

Here is a simple way to get one:
    sudo apt-get install make autoconf gcc gperf bison flex texinfo help2man libncurses5-dev
    git clone https://github.com/crosstool-ng/crosstool-ng
    cd crosstool-ng
    ./bootstrap
    ./configure --enable-local
    make
    ./ct-ng arm-unknown-eabi
    ./ct-ng build


Preparing the files
===================

Run `make` (specifying jobs with `-jX` is supported and recommended).

This will provide:

- the ArchLinuxARM armv7 default rootfs (`ArchLinuxARM-armv7-latest.tar.gz`)
- an u-boot image compiled for the OrangePi Zero (`u-boot-sunxi-with-spl.bin`)
- device tree blobs for enabling USB ports on expansion board
- a boot script (`boot.scr`) to be copied in `/boot`


Installing the distribution
===========================

Run `make install BLOCK_DEVICE=/dev/mmcblk0` with the appropriate value for
`BLOCK_DEVICE`.

This is running commands similar to [any other AllWinner ArchLinuxARM
installation][alarm-allwinner].

[alarm-allwinner]: https://archlinuxarm.org/platforms/armv7/allwinner/.


Building on Ubuntu 18.04
========================
Using gcc-arm-linux-gnueabi, there is no need to use crosstool-ng to build the toolchain
```
sudo apt-get install make bsdtar python python-dev uboot-tools swig bc device-tree-compiler gcc-arm-linux-gnueabi 
```

Ethernet
========

In order to get ethernet working, you will need to downgrade to the 4.13-rc7
since the network support has been [reverted in 54f70f52e3][sunxi-revert]. You
can install the package with `pacman -U
/root/linux-armv7-rc-4.13.rc7-1-armv7h.pkg.tar.xz` using the [serial
interface][opiz-serial].

[sunxi-revert]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=54f70f52e3b3a26164220d98a712a274bd28502f
[opiz-serial]: http://linux-sunxi.org/Xunlong_Orange_Pi_Zero#Locating_the_UART


Goodies
=======

If you have a serial cable and `miniterm.py` installed (`python-pyserial`),
`make serial` will open a session with the appropriate settings.


TODO
====

- upstream to ArchLinuxARM
