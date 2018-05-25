include $(THEOS)/makefiles/common.mk
TWEAKNAMEPREFS_LIBRARIES = colorpicker

BUNDLE_NAME = LeadMeHome
LeadMeHome_FILES = $(wildcard *.m) $(wildcard *.x)
LeadMeHome_INSTALL_PATH = /Library/PreferenceBundles
LeadMeHome_FRAMEWORKS = UIKit
LeadMeHome_PRIVATE_FRAMEWORKS = Preferences
LeadMeHome_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/LeadMeHome.plist$(ECHO_END)
