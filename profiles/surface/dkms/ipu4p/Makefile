# SPDX-License-Identifier: GPL-2.0-only
# DKMS build wrapper for Intel IPU4P + Surface Book 3 / Pro 7 camera sensors.
# CachyOS kernels are clang-built, so pass LLVM=1 automatically when CONFIG_CC_IS_CLANG=y.
KVERSION ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVERSION)/build
LLVM_FLAG := $(if $(shell grep -s '^CONFIG_CC_IS_CLANG=y' $(KDIR)/.config),LLVM=1,)

KBUILD_MOD_OPTS := \
	CONFIG_VIDEO_INTEL_IPU6=m \
	CONFIG_VIDEO_OV7251=m \
	CONFIG_VIDEO_OV5693=m \
	CONFIG_VIDEO_DW9719=m

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src $(KBUILD_MOD_OPTS) $(LLVM_FLAG) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src $(KBUILD_MOD_OPTS) $(LLVM_FLAG) clean
