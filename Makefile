#
# libgcore build script
#
# Do not build for linux or arm on a mac system
# and mac on a linux system.
#

BUILD_PATH :=
INCLUDES :=-I. -I./board -I../driver -I./lib/jsmn -I./lib/avl -I./lib/progress -I./lib/lz4 -I./lib/capnp 
CFLAGS :=-O2 -c -fPIC -Wall -pedantic
CC := gcc
LDFLAGS :=
EXEC :=
OS := $(shell uname)
PLAT :=

ifeq ($(OS),Darwin)
	PLAT := mac
	BUILD_PATH := build/macosx
	LDFLAGS += -shared -dynamiclib -Wl,-install_name,libgcore.dylib -lpthread
	EXEC += $(BUILD_PATH)/libgcore.dylib
else
ifeq ($(MAKECMDGOALS),arm)
	PLAT := arm
	BUILD_PATH := build/arm
	ARM_CFLAGS := -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
	CFLAGS := ${ARM_CFLAGS} $(CFLAGS) -D_FILE_OFFSET_BITS=64
	CC := arm-linux-gnueabihf-gcc
	LDFLAGS += -shared -Wl,-soname,libgcore.so -lpthread
	EXEC += $(BUILD_PATH)/libgcore.so
else
	PLAT := linux
	BUILD_PATH := build/linux
	LDFLAGS += -shared -Wl,-soname,libgcore.so -lpthread
	EXEC += $(BUILD_PATH)/libgcore.so
endif
endif

SRCS = $(shell find . -name '*.c')
OBJS = $(SRCS:%.c=%_$(PLAT).o)
HEADERS = $(SRCS:%.c=%.h)

#
# Don't run anything if all is given
#
all:
	@echo "error: must give a platform: mac, linux, arm"

#
# Must give target to run
#
mac: build/macosx/libgcore.dylib 
linux: build/linux/libgcore.so 
arm: build/arm/libgcore.so 

#
# Build mac, linux and arm. Must run clean before.
#
build/macosx/libgcore.dylib: $(OBJS)
	$(CC) $(INCLUDES) $(LDFLAGS) $? -o build/macosx/libgcore.dylib

build/linux/libgcore.so: $(OBJS)
	$(CC) $(INCLUDES) $(LDFLAGS) $? -o build/linux/libgcore.so

build/arm/libgcore.so: $(OBJS)
	$(CC) $(INCLUDES) $(LDFLAGS) $? -o build/arm/libgcore.so

%.c: %.h
	touch $@

%_$(PLAT).o: %.c
	mkdir -p $(BUILD_PATH)
	$(CC) $(INCLUDES) $(CFLAGS) $< -o $@

clean-mac:
	$(shell find . -name '*_mac.o' -delete)
	rm -f build/macosx/libgcore.dylib

clean-linux:
	$(shell find . -name '*_linux.o' -delete)
	rm -f build/linux/libgcore.so

clean-arm:
	$(shell find . -name '*_arm.o' -delete)
	rm -f build/arm/libgcore.so

clean:
	@echo "error: must give a platform: clean-mac, clean-linux, clean-arm"

.PHONY : all mac linux arm clean clean-mac clean-linux clean-arm
