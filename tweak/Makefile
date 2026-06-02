export THEOS := /opt/theos
export THEOS_SDK_DIR := /opt/theos/sdks

TARGET = iphone:clang:14.5:11.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DomainRedirect

DomainRedirect_FILES = Tweak.xm
DomainRedirect_CFLAGS = -fobjc-arc
DomainRedirect_FRAMEWORKS = Foundation
DomainRedirect_PRIVATE_FRAMEWORKS = 

include $(THEOS_MAKE_FILES)/tweak.mk
