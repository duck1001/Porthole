ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PortholePrefs
PortholePrefs_FILES = PHPrefsRootController.m PHChoiceController.m PHAppPickerController.m PHLogViewController.m
PortholePrefs_INSTALL_PATH = /Library/PreferenceBundles
PortholePrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-function
PortholePrefs_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/bundle.mk
