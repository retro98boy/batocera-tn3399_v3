################################################################################
#
# rtl8188eu
#
################################################################################

# batocera (update)
RTL8188EU_VERSION = 775137f273ed75bd092b281470accb827a3e1355
RTL8188EU_SITE = $(call github,lwfinger,rtl8188eu,$(RTL8188EU_VERSION))
RTL8188EU_LICENSE = GPL-2.0, proprietary (rtl8188eufw.bin firmware blob)
RTL8188EU_LICENSE_FILES = COPYING
RTL8188EU_MODULE_MAKE_OPTS = CONFIG_RTL8188EU=m

define RTL8188EU_INSTALL_FIRMWARE
	$(INSTALL) -D -m 644 $(@D)/rtl8188eufw.bin \
		$(TARGET_DIR)/lib/firmware/rtlwifi/rtl8188eufw.bin
endef
RTL8188EU_POST_INSTALL_TARGET_HOOKS += RTL8188EU_INSTALL_FIRMWARE

$(eval $(kernel-module))
$(eval $(generic-package))
