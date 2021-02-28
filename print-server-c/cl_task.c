/*
 * Task operations.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#include "cl_memory.h"
#include "cl_task.h"
#include "cl_thread.h"
/*!
 * \brief Create new task.
 * \param taskfn - task function,
 * \param arg0 - function argument 0,
 * \param arg1 - function argument 1,
 * \param execution_time - execution time.
 * \return pointer to task structure.
 */
cl_task_t *cl_task_create( void (*taskfn)(struct cl_task_s *t), void *arg0, void *arg1, cl_task_time execution_time )
{
	cl_task_t *t;

	t = (cl_task_t *)cl_malloc( sizeof(cl_task_t) );
	if (!t) return t;
	t->execution_time = execution_time;
	t->taskfn = taskfn;
	t->arg0 = arg0;
	t->arg1 = arg1;
	return t;
}
//==========================================================================================

/*!
 * \bief Free task.
 * \param t - pointer to task structure.
 */
void cl_task_free( cl_task_t *t)
{
	if ( t ) {
		cl_free( t );
	}
}
//==========================================================================================

/*!
 * \bief Execute task.
 * \param t - pointer to task structure.
 */
void cl_task_execute( cl_task_t *t )
{
	if (t) {
		t->taskfn( t );
	}
}
//==========================================================================================

#define cst(x) ((cl_task_time)(x))
/*!
 * \brief Get current time stamp.
 * \return time stamp.
 */
cl_task_time cl_task_get_stamp( void )
{
	struct timespec ts;
	clock_gettime( CLOCK_MONOTONIC, &ts );
	return cst(cst(ts.tv_sec) * cst(1000) + cst(ts.tv_nsec/1000000));
}
//==========================================================================================
