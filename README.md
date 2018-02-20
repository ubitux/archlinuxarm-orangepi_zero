This repository can be used to create an ArchLinuxARM image for the OrangePi
Zero board.


Dependencies
============

- `make`
- `gnu tar`
- `python2`
- `u-boot-tools`
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


Building with Docker
========================
Included Dockerfile will create an ubuntu container with all required build tools.
To disable building overlays for expansion card, change `EXPANSION=true` to `false` in `docker-compose.yml`
```
docker-compose up --build
```

Goodies
=======

If you have a serial cable and `miniterm.py` installed (`python-pyserial`),
`make serial` will open a session with the appropriate settings.

References
==========
https://wiki.archlinux.org/index.php/Orange_Pi
https://github.com/archlinuxarm/PKGBUILDs/blob/master/alarm/uboot-sunxi/
https://github.com/u-boot/u-boot/blob/master/doc/README.fdt-overlays


TODO
====

- upstream to ArchLinuxARM
