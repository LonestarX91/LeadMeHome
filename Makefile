TARGET = iphone:11.2:10.0

DEBUG=0
FINALPACKAGE=1
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LeadMeHome
LeadMeHome_FILES = Tweak.xm
LeadMeHome_LIBRARIES = colorpicker
LeadMeHome_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += leadmehome
include $(THEOS_MAKE_PATH)/aggregate.mk
