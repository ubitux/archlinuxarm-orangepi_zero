SERIAL_DEVICE = /dev/ttyUSB0
CROSS_COMPILE ?= aarch64-linux-gnu-
BLOCK_DEVICE ?= /dev/null

TRUSTED_FIRMWARE_VERSION = 2.14.0
TRUSTED_FIRMWARE_TARBALL = arm-trusted-firmware-v$(TRUSTED_FIRMWARE_VERSION).tar.gz
TRUSTED_FIRMWARE_DIR = arm-trusted-firmware-$(TRUSTED_FIRMWARE_VERSION)
TRUSTED_FIRMWARE_BIN = bl31.bin

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin

ARCH_TARBALL = ArchLinuxARM-aarch64-latest.tar.gz

UBOOT_VERSION = 2026.01
UBOOT_TARBALL = u-boot-v$(UBOOT_VERSION).tar.gz
UBOOT_DIR = u-boot-$(UBOOT_VERSION)

MOUNT_POINT = mnt

ALL = $(ARCH_TARBALL) $(UBOOT_BIN) $(UBOOT_SCRIPT)

all: $(ALL)

$(TRUSTED_FIRMWARE_TARBALL):
	curl -L https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/v$(TRUSTED_FIRMWARE_VERSION).tar.gz -o $@
$(TRUSTED_FIRMWARE_DIR): $(TRUSTED_FIRMWARE_TARBALL)
	tar xf $<
$(TRUSTED_FIRMWARE_BIN): $(TRUSTED_FIRMWARE_DIR)
	cd $< && make PLAT=sun50i_a64 DEBUG=1 bl31 CROSS_COMPILE=$(CROSS_COMPILE)
	cp $</build/sun50i_a64/debug/$@ .

$(UBOOT_TARBALL):
	curl -L https://github.com/u-boot/u-boot/archive/refs/tags/v$(UBOOT_VERSION).tar.gz -o $@
$(UBOOT_DIR): $(UBOOT_TARBALL)
	tar xf $<
$(UBOOT_BIN): $(UBOOT_DIR) $(TRUSTED_FIRMWARE_BIN)
	cd $< && $(MAKE) nanopi_neo2_defconfig && $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) BL31=../$(TRUSTED_FIRMWARE_BIN)
	cp $(UBOOT_DIR)/$@ $@
# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.txt
	mkimage -A arm64 -O linux -T script -C none -n "U-Boot boot script" -d $< $@

$(ARCH_TARBALL):
	curl -L http://archlinuxarm.org/os/$@ -o $@

serial:
	pyserial-miniterm --raw --eol=lf $(SERIAL_DEVICE) 115200

define part1
$$(lsblk -ln -o PATH $(1) | tail -n1)
endef

install: $(ALL)
ifeq ($(BLOCK_DEVICE),/dev/null)
	@echo You must set BLOCK_DEVICE option
else
	sudo dd if=/dev/zero of=$(BLOCK_DEVICE) bs=1M count=8 conv=fsync
	echo ';' | sudo sfdisk --label dos $(BLOCK_DEVICE)
	sudo mkfs.ext4 $(call part1,$(BLOCK_DEVICE))
	mkdir -p $(MOUNT_POINT)
	sudo umount $(MOUNT_POINT) || true
	sudo mount $(call part1,$(BLOCK_DEVICE)) $(MOUNT_POINT)
	sudo bsdtar -xpf $(ARCH_TARBALL) -C $(MOUNT_POINT)
	sudo cp $(UBOOT_SCRIPT) $(MOUNT_POINT)/boot
	sync
	sudo umount $(MOUNT_POINT) || true
	rmdir $(MOUNT_POINT) || true
	sudo dd if=$(UBOOT_BIN) of=$(BLOCK_DEVICE) bs=1M seek=8 conv=fsync
endif

clean:
	$(RM) -r $(UBOOT_DIR) $(UBOOT_BIN) $(UBOOT_SCRIPT)
	$(RM) -r $(TRUSTED_FIRMWARE_DIR) $(TRUSTED_FIRMWARE_BIN)

distclean: clean
	$(RM) $(ARCH_TARBALL)
	$(RM) $(UBOOT_TARBALL)
	$(RM) $(TRUSTED_FIRMWARE_TARBALL)

.PHONY: all serial clean distclean install
