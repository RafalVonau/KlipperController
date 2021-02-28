/*
 * Task operations.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */

#ifndef __CL_TASK_H_
#define __CL_TASK_H_

#include <linux/types.h>

typedef __u64 cl_task_time;

struct cl_task_s;

typedef struct cl_task_s
{
	cl_task_time execution_time;
	void (*taskfn)(struct cl_task_s *t);
	void *arg0;
	void *arg1;
	int to_remove;
} cl_task_t;

/*!
 * \brief Create new task.
 * \param taskfn - task function,
 * \param arg0 - function argument 0,
 * \param arg1 - function argument 1,
 * \param execution_time - execution time.
 * \return pointer to task structure.
 */
cl_task_t *cl_task_create( void (*taskfn)(struct cl_task_s *t), void *arg0, void *arg1, cl_task_time execution_time );

/*!
 * \bief Free task.
 * \param t - pointer to task structure.
 */
void cl_task_free( cl_task_t *t );

/*!
 * \bief Execute task.
 * \param t - pointer to task structure.
 */
void cl_task_execute( cl_task_t * );

/*!
 * \brief Get current time stamp.
 * \return time stamp in ms.
 */
cl_task_time cl_task_get_stamp( void );


#endif
