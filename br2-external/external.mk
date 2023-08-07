
host-ccache-build: HOST_CFLAGS += -march=native -mtune=native
host-ccache: HOST_CFLAGS += -march=native -mtune=native

include $(sort $(wildcard $(BR2_EXTERNAL_AARCH64_TOOLS_PATH)/package/*/*.mk))

.PHONY: extra-sdk
extra-sdk: prepare-sdk
sdk: extra-sdk

extra-sdk:
	$(INSTALL) -m 755 $(BR2_EXTERNAL)/activate.sh $(HOST_DIR)/activate.sh
