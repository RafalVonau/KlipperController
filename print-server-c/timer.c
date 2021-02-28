/*
 * Timer operations.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h> 
#include <sys/wait.h>
#include <sys/time.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include "timer.h"
#include <stddef.h>
#include <stdio.h>
#include <time.h>
#include <sys/sysinfo.h>

/*!
 * Get time in ms.
*/
__u32 timer_get_time( void )
{
	struct timespec ts;
	__u32 ret;
	clock_gettime( CLOCK_MONOTONIC, &ts );
	
	ret = ts.tv_sec * 1000;
	ret += (ts.tv_nsec/1000000);
	return ret;
}
//===========================================================================

__u32 timer_get_elapsed( __u32 last, __u32 now )
{
	return (last - now);
}
//===========================================================================