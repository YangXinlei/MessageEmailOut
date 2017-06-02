THEOS_DEVICE_IP=192.168.2.4
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = sbMSM
sbMSM_FILES = Tweak.xm
sbMSM_FRAMEWORKS = UIKit, MessageUI

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
