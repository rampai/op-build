################################################################################
#
# ultravisor
#
################################################################################

ULTRAVISOR_VERSION = $(call qstrip,$(BR2_ULTRAVISOR_VERSION))

ifeq ($(BR2_ULTRAVISOR_CUSTOM_GIT),y)
ULTRAVISOR_SITE = $(call qstrip,$(BR2_ULTRAVISOR_CUSTOM_REPO_URL))
ULTRAVISOR_SITE_METHOD = git
else
ULTRAVISOR_SITE = $(call github,open-power,ultravisor,$(ULTRAVISOR_VERSION))
endif

ULTRAVISOR_LICENSE = GPLv2
ULTRAVISOR_LICENSE_FILES = LICENCE
ULTRAVISOR_INSTALL_IMAGES = YES
ULTRAVISOR_GIT_SUBMODULES = YES
ULTRAVISOR_INSTALL_TARGET = NO

ULTRAVISOR_MAKE_OPTS += CC="$(TARGET_CC)" LD="$(TARGET_LD)" \
		     AS="$(TARGET_AS)" AR="$(TARGET_AR)" NM="$(TARGET_NM)" \
		     OBJCOPY="$(TARGET_OBJCOPY)" OBJDUMP="$(TARGET_OBJDUMP)" \
		     SIZE="$(TARGET_CROSS)size"

define ULTRAVISOR_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) ULTRAVISOR_VERSION=`cat $(ULTRAVISOR_VERSION_FILE)` \
		$(MAKE) $(ULTRAVISOR_MAKE_OPTS) -C $(@D) all
endef

define ULTRAVISOR_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 755 $(@D)/ultra.lid $(BINARIES_DIR)
	$(INSTALL) -D -m 755 $(@D)/ultra.lid.xz $(BINARIES_DIR)
endef

$(eval $(generic-package))
