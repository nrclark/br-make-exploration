
host-ccache-build: HOST_CFLAGS += -march=native -mtune=native
host-ccache: HOST_CFLAGS += -march=native -mtune=native

include $(sort $(wildcard $(BR2_EXTERNAL_AARCH64_TOOLS_PATH)/package/*/*.mk))

.PHONY: extra-sdk
extra-sdk: prepare-sdk
sdk: extra-sdk

COMMANDS := AR AS CC CPP CXX FC LD NM OBJCOPY OBJDUMP RANLIB READELF STRIP
FLAG_VARS := CFLAGS CPPFLAGS CXXFLAGS FCFLAGS LDFLAGS

define export_target_var
$(if $(TARGET_$1),export $1="$(notdir $(TARGET_$1))",)
endef

define cmd_exports
$(foreach x,$(COMMANDS),$(call export_target_var,$(x))\n   )
endef

define flag_exports
$(foreach x,$(FLAG_VARS),$(call export_target_var,$(x))\n   )
endef

extra-sdk: $(HOST_DIR)/activate.sh
.PHONY: $(HOST_DIR)/activate.sh
$(HOST_DIR)/activate.sh:
	$(INSTALL) -m 755 $(BR2_EXTERNAL)/activate.sh $(HOST_DIR)/activate.sh
	sed -i 's/#@flag_exports@/$(call flag_exports)/g' "$(HOST_DIR)/activate.sh"
	sed -i 's/#@cmd_exports@/$(call cmd_exports)/g' "$(HOST_DIR)/activate.sh"
