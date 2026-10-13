# SPDX-License-Identifier: GPL-2.0-or-later
# DKMS build wrapper for IPTS. CachyOS kernels are clang-built, so pass LLVM=1
# automatically when the target kernel config says so (gcc rejects clang flags).
KVERSION ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVERSION)/build
LLVM_FLAG := $(if $(shell grep -s '^CONFIG_CC_IS_CLANG=y' $(KDIR)/.config),LLVM=1,)

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src CONFIG_HID_IPTS=m $(LLVM_FLAG) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src CONFIG_HID_IPTS=m $(LLVM_FLAG) clean
