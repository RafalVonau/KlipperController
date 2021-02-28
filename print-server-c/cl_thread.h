/*
 * Threads wrapper
 * 
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */

#ifndef __CL_THREAD_H
#define __CL_THREAD_H
#include "cl_inline.h"
#include <pthread.h>

struct cl_thread_queue;

#define cl_mutex_init(hs,att)            pthread_mutex_init(hs,att)
#define cl_mutex_destroy(hs)             pthread_mutex_destroy(hs)
#define cl_mutex_lock(hs)                pthread_mutex_lock(hs)
#define cl_mutex_unlock(hs)              pthread_mutex_unlock(hs)
  
#define cl_cond_init(hs,attr)            pthread_cond_init(hs,attr)
#define cl_cond_destroy(hs)              pthread_cond_destroy(hs)
#define cl_cond_wait(cnd,mut)            pthread_cond_wait(cnd,mut)
#define cl_cond_timedwait(cnd,mut,tim)   pthread_cond_timedwait(cnd, mut, tim) 
  
#define cl_cond_signal(cnd)              pthread_cond_signal(cnd); 
#define cl_cond_broadcast(cnd)           pthread_cond_broadcast(cnd)  
#define cl_mutex_define(x)               pthread_mutex_t x
#define cl_mutex_define_initialized(x)   pthread_mutex_t x = PTHREAD_MUTEX_INITIALIZER
  
#define cl_cond_define(x)                pthread_cond_t x
  

/*!
 * \brief Initialize condition variable and set monotonic clock.
 * \param cond - condition variable,
 */
void cl_cond_init_monotonic( pthread_cond_t *cond );
/*!
 * \brief Wait for condition or timeout (use MONOTONIC CLOCK)
 * \param cond - condition variable,
 * \param mutex - locking mutex,
 * \param timeout - timeout in [ms].
 * \return 0 on sucess.
 */
int cl_cond_timedwait_monotonic(pthread_cond_t * cond, pthread_mutex_t *mutex, int timeout);

/*!
 * \brief Wait for condition or timeout
 * \param cond - condition variable,
 * \param mutex - locking mutex,
 * \param timeout - timeout in [ms].
 * \return 0 on sucess.
 */
int cl_cond_timedwait2(pthread_cond_t * cond, pthread_mutex_t *mutex, int timeout);
/*!
 * \brief Start new thread (arg is automaticly freed when error occurs!)
 * \param fn - thread function,
 * \param arg - thread arguments,
 * \return 0 on sucess.
 */
int cl_run_thread(int clean_data, void* (*fn)(void*),void* arg);
/*!
 * \brief Start new joinable thread
 * \param clean_data - when set arg is automaticly freed when error occurs,
 * \param fn - thread function,
 * \param arg - thread arguments,
 * \return 0 on sucess.
 */
int cl_run_joinable_thread(pthread_t *thread_id, int clean_data, void* (*fn)(void*), void* arg);
/*!
 * \brief Wait for thread end.
 * \param thread_id - thread id,
 * \return result from thread.
 */
void *cl_join_thread(pthread_t thread_id);
/*!
 * \brief Start new thread
 * \param clean_data - when set arg is automaticly freed when error occurs,
 * \param fn - thread function,
 * \param arg - thread arguments,
 * \return 0 on sucess.
 */
struct cl_thread_queue *cl_run_thread_queue(int queue_length, int threads);
/*!
 * \brief Add task to thread queue
 * \param q - pointer to queue structure,
 * \param clean_data - when set arg is automaticly freed after task execution or error,
 * \param fn - pointer to thread function,
 * \param fn - pointer to cleanup function,
 * \param arg - allocated thread parameters.
 * \return 0 on sucess.
 */
int cl_thread_queue_add(struct cl_thread_queue *q, int clean_data, void* (*fn)(void*), void* (*cleanup)(void*), void* arg);
/*!
 * \brief Remove all tasks from thread queue and add new one.
 * \param q - pointer to queue structure.
 */
void cl_clean_thread_queue_and_add(struct cl_thread_queue *q, int clean_data, void* (*fn)(void*), void* (*cleanup)(void*), void* arg);

/*!
 * \brief Destroy thread queue (NOTE: args are automaticly freed when clean_data flag is set)
 * \param q - pointer to queue structure.
 */
void cl_destroy_thread_queue(struct cl_thread_queue *q);
/*!
 * \brief Remove all tasks from thread queue.
 * \param q - pointer to queue structure.
 */
void cl_clean_thread_queue(struct cl_thread_queue *q);    

__fn_inline void cl_add_ms_to_timespec(struct timespec *a, unsigned long interval_ms, struct timespec *result);
__fn_inline void cl_add_ms_to_timespec(struct timespec *a, unsigned long interval_ms, struct timespec *result)
{
	result->tv_sec = a->tv_sec + (interval_ms / 1000);
	result->tv_nsec = a->tv_nsec + ((interval_ms % 1000) * 1000000);
	if (result->tv_nsec > 1000000000) {
		result->tv_nsec -= 1000000000;
		result->tv_sec++;
	}
}
//==========================================================================================

  /* return an integer greater than, equal to, or less than 0,
     according as the timespec a is greater than,
     equal to, or less than the timespec b. */
__fn_inline int cl_compare_timespec(struct timespec *a, struct timespec *b);
__fn_inline int cl_compare_timespec(struct timespec *a, struct timespec *b)
 {
	 if (a->tv_sec > b->tv_sec)
		 return 1;
	 else if (a->tv_sec < b->tv_sec)
		 return -1;
	 else if (a->tv_nsec > b->tv_nsec)
		 return 1;
	 else if (a->tv_nsec < b->tv_nsec)
		 return -1;
	 return 0;
}
//==========================================================================================

/* convert struct timespec to ms(milliseconds) */
__fn_inline unsigned long int cl_timespec2ms(struct timespec *a);
__fn_inline unsigned long int cl_timespec2ms(struct timespec *a)
{
	return ((a->tv_sec * 1000) + (a->tv_nsec / 1000000));
}
//==========================================================================================

/* convert ms(milliseconds) to timespec struct */
__fn_inline void cl_ms2timespec(struct timespec *result, unsigned long interval_ms);
__fn_inline void cl_ms2timespec(struct timespec *result, unsigned long interval_ms)
{
	result->tv_sec = (interval_ms / 1000);
	result->tv_nsec = ((interval_ms % 1000) * 1000000);
}
//==========================================================================================


#endif

