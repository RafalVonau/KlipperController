/*
 * Timer operations.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */

#ifndef __CL_TIMER_H
#define __CL_TIMER_H

#ifdef __cplusplus
    extern "C" {
#endif

#include <sys/types.h>
#include <linux/types.h>

__u32 timer_get_time( void );
__u32 timer_get_elapsed( __u32 last, __u32 now );


#endif
