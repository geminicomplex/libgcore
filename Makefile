#
# libgcore build script
#
# Do not build for linux or arm on a mac system
# and mac on a linux system.
#

INCLUDES :=-I. -I./board -I./lib/jsmn -I./lib/avl -I./lib/slog -I./lib/fe -I./lib/lz4 -I./lib/capnp -I./lib/uthash
CFLAGS :=-O2 -fPIC -Wall -funwind-tables -g -ggdb -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
LDFLAGS := -fPIC -lm -ldl 
PLAT :=

OS := $(shell uname)
ifeq ($(OS),Darwin)
	PLAT := mac
	BUILD_PATH := build/mac
	LDFLAGS += -shared -dynamiclib -Wl,-install_name,libgcore.dylib -lpthread -lsqlite3
	EXEC := $(BUILD_PATH)/libgcore.dylib
	CC := gcc
else
ifeq ($(MAKECMDGOALS),arm)
	PLAT := arm
	BUILD_PATH := build/arm
	LDFLAGS += -shared -Wl,-soname,libgcore.so -lpthread
	LDFLAGS += -L../../../tmp/sqlite/out/usr/lib -lsqlite3
	LDFLAGS += -L../../../tmp/zlib-1.2.11/out/lib -lz -L../../../tmp/openssl/out/usr/lib
	ARM_CFLAGS := -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
	CFLAGS := ${ARM_CFLAGS} $(CFLAGS) -D_FILE_OFFSET_BITS=64
	CFLAGS += -I../../../tmp/zlib-1.2.11/out/include -I../../../tmp/openssl/out/usr/include
	EXEC := $(BUILD_PATH)/libgcore.so
	CC := arm-linux-gnueabihf-gcc
else
	PLAT := linux
	BUILD_PATH := build/linux
	LDFLAGS += -shared -Wl,-soname,libgcore.so -lpthread -lsqlite3
	EXEC := $(BUILD_PATH)/libgcore.so
	CC := gcc
endif
endif

SRCS := common.c dots.c util.c board/gpio.c board/artix.c board/i2c.c \
	   board/helper.c board/dma.c board/subcore.c board/dev.c subvec.c \
	   serialize/stim_serdes.capnp.c config.c lib/capnp/capn.c lib/capnp/capn-malloc.c \
	   lib/capnp/capn-stream.c lib/lz4/lz4hc.c lib/lz4/lz4frame.c lib/lz4/xxhash.c \
	   lib/lz4/lz4.c lib/jsmn/jsmn.c lib/avl/avl.c lib/slog/slog.c lib/fe/fe.c \
	   db.c profile.c stim.c prgm.c

HEADERS := profile.h stim.h config.h board/dma.h board/helper.h board/subcore.h board/dev.h \
		board/gpio.h board/artix.h board/i2c.h serialize/stim_serdes.capnp.h dots.h common.h \
		subvec.h util.h lib/capnp/capnp_priv.h lib/capnp/capnp_c.h lib/lz4/xxhash.h lib/lz4/lz4.h \
		lib/lz4/lz4frame_static.h lib/lz4/lz4hc.h lib/lz4/lz4frame.h lib/jsmn/jsmn.h \
		lib/avl/avl.h lib/slog/slog.h lib/fe/fe.h \
		sql.h db.h prgm.h libgcore.h

#
# Don't run anything if all is given
#
all:
	@echo "error: must give a platform: mac, linux, arm"

#
# Must give target to run
#
mac: build/mac/libgcore.dylib 
linux: build/linux/libgcore.so 
arm: build/arm/libgcore.so 

#
# Build mac, linux and arm. Must run clean before.
#
build/mac/libgcore.dylib: $(SRCS) $(HEADERS)
	mkdir -p build/mac
	$(CC) $(INCLUDES) $(CFLAGS) $(LDFLAGS) $(SRCS) -o build/mac/libgcore.dylib

build/linux/libgcore.so: $(SRCS) $(HEADERS)
	mkdir -p build/linux
	$(CC) $(INCLUDES) $(CFLAGS) $(LDFLAGS) $(SRCS) -o build/linux/libgcore.so

build/arm/libgcore.so: $(SRCS) $(HEADERS)
	mkdir -p build/arm
	$(CC) $(INCLUDES) $(CFLAGS) $(LDFLAGS) $(SRCS) -o build/arm/libgcore.so

%.c: %.h
	touch $@

clean-mac:
	$(shell find . -name '*_mac.o' -delete)
	rm -f build/mac/libgcore.dylib

clean-linux:
	$(shell find . -name '*_linux.o' -delete)
	rm -f build/linux/libgcore.so

clean-arm:
	$(shell find . -name '*_arm.o' -delete)
	rm -f build/arm/libgcore.so

clean: clean-mac clean-linux clean-arm
	rm -rf build

.PHONY : all mac linux arm clean clean-mac clean-linux clean-arm
