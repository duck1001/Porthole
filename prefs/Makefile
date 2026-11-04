ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PortholePrefs
PortholePrefs_FILES = PHPrefsRootListController.m PHChoiceController.m PHAppListController.m PHLogController.m
PortholePrefs_INSTALL_PATH = /Library/PreferenceBundles
PortholePrefs_CFLAGS = -fobjc-arc -I.. -Wno-deprecated-declarations
PortholePrefs_FRAMEWORKS = UIKit Foundation
PortholePrefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
