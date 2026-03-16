This repository can be used to create an ArchLinuxARM image for the NanoPi Neo2
board.


## Dependencies

- `make`
- `bsdtar` (`libarchive`)
- `uboot-tools`
- `swig`
- `sudo`
- `aarch64-linux-gnu-gcc`


## Setup

```sh
# Pull the Archlinux rootfs, trusted firmware, u-boot, and builds everything
make -j$(nproc)
# Install on a microSD
make install BLOCK_DEVICE=/dev/sdX
```

## Goodies

If you have a serial cable and `python-pyserial` installed, `make serial` will
open a session with the appropriate settings.


## TODO

- upstream to ArchLinuxARM
