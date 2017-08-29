SERIAL_DEVICE = /dev/ttyUSB0
WGET = wget
MINITERM = miniterm.py
CROSS_COMPILE ?= aarch64-unknown-elf-
PYTHON ?= python2
BLOCK_DEVICE ?= /dev/null

TRUSTED_FIRMWARE_TARBALL = allwinner.zip
TRUSTED_FIRMWARE_DIR = arm-trusted-firmware-allwinner
TRUSTED_FIRMWARE_BIN = bl31.bin

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin

ARCH_TARBALL = ArchLinuxARM-aarch64-latest.tar.gz

UBOOT_VERSION = 2017.09-rc3
UBOOT_TARBALL = u-boot-v$(UBOOT_VERSION).tar.gz
UBOOT_DIR = u-boot-$(UBOOT_VERSION)

KERNEL_TARBALL = linux-aarch64-4.13.0-2-aarch64.pkg.tar.xz
KERNEL_HEADERS_TARBALL = linux-aarch64-headers-4.13.0-2-aarch64.pkg.tar.xz

MOUNT_POINT = mnt

ALL = $(ARCH_TARBALL) $(UBOOT_BIN) $(UBOOT_SCRIPT)

all: $(ALL)

$(TRUSTED_FIRMWARE_TARBALL):
	$(WGET)  https://github.com/apritzel/arm-trusted-firmware/archive/$@
$(TRUSTED_FIRMWARE_DIR): $(TRUSTED_FIRMWARE_TARBALL)
	unzip $<
$(TRUSTED_FIRMWARE_BIN): $(TRUSTED_FIRMWARE_DIR)
	cd $< && \
		make PLAT=sun50iw1p1 DEBUG=1 bl31 CROSS_COMPILE=$(CROSS_COMPILE)
	cp $</build/sun50iw1p1/debug/$@ .

$(UBOOT_TARBALL):
	$(WGET) https://github.com/u-boot/u-boot/archive/v$(UBOOT_VERSION).tar.gz -O $@
$(UBOOT_DIR): $(UBOOT_TARBALL)
	tar xf $<

$(ARCH_TARBALL):
	$(WGET) http://archlinuxarm.org/os/$@

$(KERNEL_TARBALL):
	$(WGET) http://mirror.archlinuxarm.org/aarch64/core/$@

$(UBOOT_BIN): $(UBOOT_DIR) $(TRUSTED_FIRMWARE_BIN)
	cd $< && $(MAKE) nanopi_neo2_defconfig && $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) PYTHON=$(PYTHON) BL31=../$(TRUSTED_FIRMWARE_BIN)
	cat $(UBOOT_DIR)/spl/sunxi-spl.bin $(UBOOT_DIR)/u-boot.itb > $@

# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.txt
	mkimage -A arm64 -O linux -T script -C none -n "U-Boot boot script" -d $< $@
boot.txt:
	$(WGET) https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/alarm/uboot-pine64/$@

serial:
	$(MINITERM) --raw --eol=lf $(SERIAL_DEVICE) 115200

install: $(UBOOT_BIN) $(UBOOT_SCRIPT) $(ARCH_TARBALL) $(KERNEL_TARBALL) fdisk.cmd
	sudo dd if=/dev/zero of=$(BLOCK_DEVICE) bs=1M count=8
	sudo fdisk $(BLOCK_DEVICE) < fdisk.cmd
	sudo mkfs.ext4 $(BLOCK_DEVICE)p1
	mkdir -p $(MOUNT_POINT)
	sudo umount $(MOUNT_POINT) || true
	sudo mount $(BLOCK_DEVICE)p1 $(MOUNT_POINT)
	sudo bsdtar -xpf $(ARCH_TARBALL) -C $(MOUNT_POINT)
	sudo cp $(UBOOT_SCRIPT) $(MOUNT_POINT)/boot
	sudo pacman --arch aarch64 -r mnt -U $(KERNEL_TARBALL)
	sync
	sudo umount $(MOUNT_POINT) || true
	rmdir $(MOUNT_POINT) || true
	sudo dd if=$(UBOOT_BIN) of=$(BLOCK_DEVICE) bs=1024 seek=8

clean:
	$(RM) $(ALL)
	$(RM) boot.txt
	$(RM) -r $(UBOOT_DIR)

.PHONY: all serial clean install
