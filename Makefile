ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Porthole
Porthole_FILES = Tweak.xm PHLog.m PHPrefs.m PHSceneHost.m PHWindow.m PHDock.m PHManager.m
Porthole_CFLAGS = -fobjc-arc -I. -Wno-deprecated-declarations -Wno-unused-function
Porthole_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
