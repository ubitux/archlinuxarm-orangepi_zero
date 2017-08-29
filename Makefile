SERIAL_DEVICE = /dev/ttyUSB0
WGET = wget
MINITERM = miniterm.py
CROSS_COMPILE ?= arm-unknown-eabi-
PYTHON ?= python2

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin

ARCH_TARBALL = ArchLinuxARM-armv7-latest.tar.gz

UBOOT_VERSION = 2017.09-rc2
UBOOT_TARBALL = u-boot-v$(UBOOT_VERSION).tar.gz
UBOOT_DIR = u-boot-$(UBOOT_VERSION)

ALL = $(ARCH_TARBALL) $(UBOOT_BIN) $(UBOOT_SCRIPT)

all: $(ALL)

$(UBOOT_TARBALL):
	$(WGET) https://github.com/u-boot/u-boot/archive/v$(UBOOT_VERSION).tar.gz -O $@
$(UBOOT_DIR): $(UBOOT_TARBALL)
	tar xf $<
	cd $@ && \
		patch -p1 < ../patches/u-boot/0001-Makefile-honor-PYTHON-configuration-properly.patch && \
		patch -p1 < ../patches/u-boot/0002-sunxi-reduce-Orange-Pi-Zero-DRAM-clock-speed.patch

$(ARCH_TARBALL):
	$(WGET) http://archlinuxarm.org/os/$@

$(UBOOT_BIN): $(UBOOT_DIR)
	cd $< && $(MAKE) orangepi_zero_defconfig && $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) PYTHON=$(PYTHON)
	cp $</$@ .

# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.txt
	mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d $< $@
boot.txt:
	$(WGET) https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/alarm/uboot-sunxi/$@

serial:
	$(MINITERM) --raw --eol=lf $(SERIAL_DEVICE) 115200

clean:
	$(RM) $(ALL)
	$(RM) -r $(UBOOT_DIR)

.PHONY: all serial clean
