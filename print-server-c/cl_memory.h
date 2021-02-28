/*
 * Memory primitives.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */

#ifndef CL_MEMORY_H
#define CL_MEMORY_H
#include <stdlib.h>
#include "cl_inline.h"

#ifdef __cplusplus
    extern "C" {
#endif

#define cl_malloc(size)              malloc(size)
#define cl_calloc(nmemb, size)       calloc(nmemb, size)
#define cl_realloc(v,size)           realloc(v,size)
#define cl_free(size)                free(size)
#undef MTRACE


#ifdef __cplusplus
    }
#endif

#endif

