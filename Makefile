SERIAL_DEVICE = /dev/ttyUSB0
WGET = wget
MINITERM = miniterm.py
CROSS_COMPILE ?= aarch64-unknown-elf-
PYTHON ?= python2
BLOCK_DEVICE ?= /dev/null
FIND ?= find

TRUSTED_FIRMWARE_TARBALL = allwinner.zip
TRUSTED_FIRMWARE_DIR = arm-trusted-firmware-allwinner
TRUSTED_FIRMWARE_BIN = bl31.bin

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin

ARCH_TARBALL = ArchLinuxARM-aarch64-latest.tar.gz

UBOOT_VERSION = 2018.01
UBOOT_TARBALL = u-boot-v$(UBOOT_VERSION).tar.gz
UBOOT_DIR = u-boot-$(UBOOT_VERSION)

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
define part1
/dev/$(shell basename $(shell $(FIND) /sys/block/$(shell basename $(1))/ -maxdepth 2 -name "partition" -printf "%h"))
endef

install: $(UBOOT_BIN) $(UBOOT_SCRIPT) $(ARCH_TARBALL) fdisk.cmd
ifeq ($(BLOCK_DEVICE),/dev/null)
	@echo You must set BLOCK_DEVICE option
else
	sudo dd if=/dev/zero of=$(BLOCK_DEVICE) bs=1M count=8
	sudo fdisk $(BLOCK_DEVICE) < fdisk.cmd
	sudo mkfs.ext4 $(call part1,$(BLOCK_DEVICE))
	mkdir -p $(MOUNT_POINT)
	sudo umount $(MOUNT_POINT) || true
	sudo mount $(call part1,$(BLOCK_DEVICE)) $(MOUNT_POINT)
	sudo bsdtar -xpf $(ARCH_TARBALL) -C $(MOUNT_POINT)
	sudo cp $(UBOOT_SCRIPT) $(MOUNT_POINT)/boot
	sync
	sudo umount $(MOUNT_POINT) || true
	rmdir $(MOUNT_POINT) || true
	sudo dd if=$(UBOOT_BIN) of=$(BLOCK_DEVICE) bs=1024 seek=8
endif

clean:
	$(RM) $(ALL)
	$(RM) boot.txt
	$(RM) -r $(UBOOT_DIR)

.PHONY: all serial clean install
