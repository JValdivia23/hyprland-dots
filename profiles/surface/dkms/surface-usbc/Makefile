# SPDX-License-Identifier: GPL-2.0-only
# DKMS build wrapper for Surface UCSI-over-HID + SSAM charger Artg support.
# CachyOS kernels are clang-built, so pass LLVM=1 automatically when CONFIG_CC_IS_CLANG=y.
KVERSION ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVERSION)/build
LLVM_FLAG := $(if $(shell grep -s '^CONFIG_CC_IS_CLANG=y' $(KDIR)/.config),LLVM=1,)

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src $(LLVM_FLAG) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src $(LLVM_FLAG) clean
