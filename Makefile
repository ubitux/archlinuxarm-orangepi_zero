# User configuration
SERIAL_DEVICE = /dev/ttyUSB0
WGET = wget
MINITERM = miniterm.py
#CROSS_COMPILE ?= arm-unknown-eabi-
CROSS_COMPILE ?= arm-linux-gnueabi-
PYTHON ?= python2
BLOCK_DEVICE ?= /dev/null
FIND ?= find

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin

ARCH_TARBALL = ArchLinuxARM-armv7-latest.tar.gz

WORKING_KERNEL = linux-armv7-rc-4.16.rc1-1-armv7h.pkg.tar.xz

UBOOT_VERSION = 2018.01
UBOOT_TARBALL = u-boot-v$(UBOOT_VERSION).tar.gz
UBOOT_DIR = u-boot-$(UBOOT_VERSION)

DTB = sun8i-h3-usbhost2 sun8i-h3-usbhost3

MOUNT_POINT = mnt

ALL = $(ARCH_TARBALL) $(UBOOT_BIN) $(UBOOT_SCRIPT) $(DTB) $(WORKING_KERNEL)

all: $(ALL)

$(UBOOT_TARBALL):
	$(WGET) -nc https://github.com/u-boot/u-boot/archive/v$(UBOOT_VERSION).tar.gz -O $@
$(UBOOT_DIR): $(UBOOT_TARBALL)
	tar xf $<

$(ARCH_TARBALL):
	$(WGET) http://archlinuxarm.org/os/$@

$(UBOOT_BIN): $(UBOOT_DIR)
	cd $< && grep -q -F 'CONFIG_OF_LIBFDT_OVERLAY' configs/orangepi_zero_defconfig || echo 'CONFIG_OF_LIBFDT_OVERLAY=y' >> configs/orangepi_zero_defconfig
	cd $< && $(MAKE) orangepi_zero_defconfig && $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) PYTHON=$(PYTHON)
	cp $</$@ .

# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.txt
	mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d $< $@

$(DTB):
	wget -nc https://raw.githubusercontent.com/armbian/sunxi-DT-overlays/master/sun8i-h3/$@.dts
	dtc -I dts -O dtb -o $@.dtb $@.dts

$(WORKING_KERNEL):
	$(WGET) http://archlinuxarm.org/armv7h/core/$@

define part1
/dev/$(shell basename $(shell $(FIND) /sys/block/$(shell basename $(1))/ -maxdepth 2 -name "partition" -printf "%h"))
endef

install: $(ALL) fdisk.cmd
ifeq ($(BLOCK_DEVICE),/dev/null)
	@echo You must set BLOCK_DEVICE option
else
	sudo dd if=/dev/zero of=$(BLOCK_DEVICE) bs=1M count=8
	sudo fdisk $(BLOCK_DEVICE) < fdisk.cmd
	sync
	sudo mkfs.ext4 $(call part1,$(BLOCK_DEVICE))
	mkdir -p $(MOUNT_POINT)
	sudo umount $(MOUNT_POINT) || true
	sudo mount $(call part1,$(BLOCK_DEVICE)) $(MOUNT_POINT)
	sudo tar --warning=no-unknown-keyword -xpf $(ARCH_TARBALL) -C $(MOUNT_POINT)
	sudo cp $(UBOOT_SCRIPT) $(MOUNT_POINT)/boot
	sudo cp $(WORKING_KERNEL) $(MOUNT_POINT)/root
	sudo mkdir $(MOUNT_POINT)/boot/dtbs/overlay
	sudo cp $(addsuffix .dtb, $(DTB)) $(MOUNT_POINT)/boot/dtbs/overlay
	sync
	sudo umount $(MOUNT_POINT) || true
	rmdir $(MOUNT_POINT) || true
	sudo dd if=$(UBOOT_BIN) of=$(BLOCK_DEVICE) bs=1024 seek=8
endif

serial:
	$(MINITERM) --raw --eol=lf $(SERIAL_DEVICE) 115200

clean:
	$(RM) $(ALL)
	$(RM) -r $(UBOOT_DIR)

.PHONY: all serial clean install
