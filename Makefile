SERIAL_DEVICE = /dev/ttyUSB0
WGET = wget
MINITERM = miniterm.py
CROSS_COMPILE ?= arm-unknown-eabi-
PYTHON ?= python2

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin

ARCH_TARBALL = ArchLinuxARM-armv7-latest.tar.gz

ALL = $(ARCH_TARBALL) $(UBOOT_BIN) $(UBOOT_SCRIPT)

all: $(ALL)

$(ARCH_TARBALL):
	$(WGET) http://archlinuxarm.org/os/$@

$(UBOOT_BIN): u-boot-build
	cd $^ && $(MAKE) orangepi_zero_defconfig && $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) PYTHON=$(PYTHON)
	cp $^/$@ .
u-boot-build: u-boot
	cp -r $^ $@
	cd $@ && git am ../patches/u-boot/*.patch
u-boot:
	git clone --depth 1 git://git.denx.de/u-boot.git

# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.txt
	mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d $^ $@
boot.txt:
	$(WGET) https://github.com/archlinuxarm/PKGBUILDs/blob/master/alarm/uboot-sunxi/$@

serial:
	$(MINITERM) --raw --eol=lf $(SERIAL_DEVICE) 115200

clean:
	$(RM) $(ALL)
	$(RM) -r u-boot-build

.PHONY: all serial clean
