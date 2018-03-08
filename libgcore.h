#ifndef LIBGCORE_H
#define LIBGCORE_H

// support for files larger than 2GB limit
#ifndef _LARGEFILE_SOURCE
#define _LARGEFILE_SOURCE
#endif
#ifndef _LARGEFILE64_SOURCE
#define _LARGEFILE64_SOURCE
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include "common.h"

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "lib/progress/progressbar.h"
#include "lib/progress/statusbar.h"

#include "util.h"
#include "config.h"
#include "dma.h"
#include "dots.h"
#include "profile.h"

#include "board/helper.h"
#include "board/stim.h"
#include "board/i2c.h"
#include "board/gpio.h"
#include "board/subcore.h"
#include "board/artix.h"


#ifdef __cplusplus
}
#endif
#endif

