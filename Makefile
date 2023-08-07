DEFCONFIG ?= aarch64_toolchain_defconfig

BUILD_COMMON := workdir/build
BOARD_NAME = $(patsubst %_defconfig,%,$(notdir $(DEFCONFIG)))
BUILD_DIR = $(BUILD_COMMON)/$(BOARD_NAME)

ifeq ($(HOSTCC),)
HOST_GCC_VERSION := $(strip $(shell /bin/bash -c 'compgen -c' | grep -F gcc | \
                      sort | uniq | grep -Ei '^gcc-[0-9+]' | sed 's/gcc-//g' | \
                      sort -g | tail -n1))
export HOSTCC := gcc-$(HOST_GCC_VERSION)
export HOSTCXX := g++-$(HOST_GCC_VERSION)
endif

default all: sdk

submodules: .submodules.done
.submodules.done:
	git submodule init
	git submodule update
	touch $@

defconfig: $(BUILD_DIR)/.config
$(BUILD_DIR)/.config: br2-external/configs/$(DEFCONFIG) .submodules.done
	$(MAKE) --no-print-directory -C buildroot \
	    BR2_EXTERNAL=$(abspath br2-external) \
	    O=$(abspath $(BUILD_DIR)) $(DEFCONFIG)

getvar-%: | $(BUILD_DIR)/.config
# Wildcard rule for getting the value of a single Buildroot variable. Can be
# used to interrogate Buildroot for the value of any single variable.
	@$(BR_MAKE) --no-print-directory -s printvars VARS=$* | sed 's/^$*=//g'

getvar-: | $(BUILD_DIR)/.config
	@echo "This target can be used to print a single Buildroot variable."
	@echo "Use it with the following syntax:"
	@echo "    make getvar-VAR_NAME"

printvars: | $(BUILD_DIR)/.config
# Call Buildroot's printvars target for printing internal Buildroot variables.
# The VARS variable can be used to specify a GNU Make %-based patsubst pattern.
# If it's not set, Buildroot will dump every variable that it knows about.
	@$(BR_MAKE) --no-print-directory -s printvars \
	    VARS=$(if $(VARS),$(VARS),%) \
	    $(if $(RAW_VARS),RAW_VARS=$(RAW_VARS))

busybox-menuconfig: | $(BUILD_DIR)/.config
# Run Busybox's menuconfig. On successful completion, export the defconfig and
# copy it back onto the source file. Buildroot doesn't have any equivalent to
# a savedefconfig, so the .config is just copied manually and all comments are
# stripped out.
	$(BR_MAKE) busybox-menuconfig
	BR2_PACKAGE_BUSYBOX_CONFIG=$$(make -s getvar-BR2_PACKAGE_BUSYBOX_CONFIG | \
	                              sed 's/"//g') && \
	BUSYBOX_SRCDIR=$$(make -s getvar-BUSYBOX_SRCDIR | sed 's/"//g') && \
	cd buildroot && cp "$$BUSYBOX_SRCDIR/.config" "$$BR2_PACKAGE_BUSYBOX_CONFIG" && \
	sed -i -E '/^#[ \t]*[a-zA-Z]+[ \t]+.*[ \t]+[0-9]+[ \t]*$$/d' \
	    "$$BR2_PACKAGE_BUSYBOX_CONFIG"

#---------------------------- Buildroot Passthrough ---------------------------#

BR_MAKE = $(strip $(MAKE) --no-print-directory -C $(BUILD_DIR) \
            BR2_EXTERNAL=$(abspath br2-external) DEFCONFIG=$(DEFCONFIG))

br-: | $(BUILD_DIR)/.config
	@echo "This target can be used to run a Buildroot submake."
	@echo "Use it with the following syntax:"
	@echo "    make br-TARGET"

br-%: private SHELL := /bin/bash
br-%: | $(BUILD_DIR)/.config
# Asks Buildroot to build %, whatever that might be.
	$(BR_MAKE) $*

#------------------------------------------------------------------------------#

build: private SHELL := /bin/bash
build: .submodules.done
	$(MAKE) --no-print-directory defconfig DEFCONFIG=$(DEFCONFIG)
	$(BR_MAKE) all

menuconfig: | $(BUILD_DIR)/.config
# Run Buildroot's menuconfig. On successful completion, export the defconfig
# back over the source file.
	$(MAKE) --no-print-directory DEFCONFIG=$(DEFCONFIG) defconfig
	$(BR_MAKE) menuconfig
	$(BR_MAKE) savedefconfig
	if [ -e buildroot/$(DEFCONFIG) ]; then \
	    if ! diff -q buildroot/$(DEFCONFIG) br2-external/configs/$(DEFCONFIG) >/dev/null; then \
	        mv buildroot/$(DEFCONFIG) br2-external/configs/$(DEFCONFIG); \
	    fi; \
	fi
	touch -c $(BUILD_DIR)/.config

SDK_NAME := aarch64-buildroot-linux-gnu_sdk-buildroot.tar.gz
$(BUILD_COMMON)/$(BOARD_NAME)/images/$(SDK_NAME): $(shell find br2-external -type f)
	$(BR_MAKE) sdk

output/$(SDK_NAME): $(BUILD_COMMON)/$(BOARD_NAME)/images/$(SDK_NAME)
	mkdir -p $(dir $@)
	cp $< $@

sdk: output/$(SDK_NAME)

install-sdk: output/$(SDK_NAME)
	rm -rf sdk
	mkdir sdk
	cd sdk && tar xf $(abspath output/$(SDK_NAME))
	cd sdk/$(patsubst %.tar.gz,%,$(SDK_NAME)) && ./activate.sh

sdk-shell:
	cd sdk/$(patsubst %.tar.gz,%,$(SDK_NAME)) && ./activate.sh && exec bash

clean:
	rm -rf $(BUILD_COMMON)/$(BOARD_NAME)
	rm -f output

distclean:
	rm -rf workdir
