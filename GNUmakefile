include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Face
BUNDLE_EXTENSION = .bundle

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/GNUMail

Face_RESOURCE_FILES = *.tiff 

Face_OBJC_FILES = \
	Face.m \
	FaceController.m

Face_HEADERS = \
	Face.h \
	FaceController.h

Face_PRINCIPAL_CLASS = \
	FaceController

ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../../Framework/GNUMail
ADDITIONAL_LIB_DIRS += -L../../Framework/GNUMail/GNUMail.framework/Versions/Current/$(GNUSTEP_TARGET_LDIR)
ADDITIONAL_GUI_LIBS += -lGNUMail -lPantomime

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble
