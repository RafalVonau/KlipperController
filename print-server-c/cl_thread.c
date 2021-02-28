/*
 * Threads wrapper
 * 
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#include <sys/time.h>
#include "cl_memory.h"
#include "cl_thread.h"
#include "cl_queue.h"
#include "cl_inline.h"

static pthread_attr_t cl_thread_attr;
volatile int cl_thread_initialized = 0;


typedef struct cl_thread_task 
{
	void *(*fn)(void *);      /*!< Task main function          */
	void *(*cleanup)(void *); /*!< Cleanup function            */
	void *params;             /*!< Task parameters             */
} cl_thread_task_t;
//===========================================================================

struct cl_thread_queue
{
	int threads;              /*!< Number of threads           */
	int capacity;             /*!< Queue capacity              */
	int front;                /*!< Front element number        */
	int rear;                 /*!< Rear element number         */
	int size;                 /*!< Number of elements in queue */
	
	cl_thread_task_t *tasks;  /*!< Tasks array                 */
	pthread_t *thread_id;     /*!< Queue thread id array       */
	
	cl_mutex_define(access_mutex);
	cl_cond_define(full_cond);
	cl_cond_define(empty_cond);	
	volatile int stop;        /*!< threads stop request flag   */
};
//===========================================================================


__fn_inline int next_position (int v, struct cl_thread_queue *q)
{
	if (++v >= q->capacity) {
		v = 0;
	}
	return v;
}
//===========================================================================

/*!
 * \brief Task queue thread function,
 */
void* cl_thread_queue_function (void* arg);
void* cl_thread_queue_function (void* arg)
{
	struct cl_thread_queue *q = (struct cl_thread_queue *)arg;
	struct cl_thread_task ptask;

	while (!q->stop) {
		/* Get task from queue */
		cl_mutex_lock(&q->access_mutex);
		while (q->size == 0) {
			cl_cond_wait(&q->empty_cond, &q->access_mutex);
		}
		ptask = q->tasks[q->front];
		//printf("Executing task %d\n",q->front);
		q->size--;
		q->front = next_position (q->front, q);
		cl_cond_signal(&q->full_cond);
		cl_mutex_unlock(&q->access_mutex);
		
		/* Execute task */
		ptask.fn(ptask.params);
		/* Cleanup */
		if (ptask.cleanup) {
			ptask.cleanup(ptask.params);
		}
	}
	return NULL;
}
//===========================================================================

void* cl_thread_queue_function_null (void* arg);
void* cl_thread_queue_function_null (void* arg)
{
	UNUSED(arg);
	return NULL;
}
//===========================================================================

void* cl_thread_queue_function_cleanup (void* arg);
void* cl_thread_queue_function_cleanup (void* arg)
{
	cl_free(arg);
	return NULL;
}
//===========================================================================

/*!
 * \brief Start new thread
 * \param clean_data - when set arg is automaticly freed when error occurs,
 * \param fn - thread function,
 * \param arg - thread arguments,
 * \return 0 on sucess.
 */
int cl_run_thread(int clean_data, void* (*fn)(void*),void* arg)
{
	pthread_t thread_id;
	int res;
	if (!cl_thread_initialized) {
	    // Create thread attributes
    	if (pthread_attr_init (&cl_thread_attr) != 0) {
    		if ((clean_data) && (arg)) {
    			cl_free(arg);
    		}
            return -2;
    	}
        if ((pthread_attr_setdetachstate (&cl_thread_attr, PTHREAD_CREATE_DETACHED)) != 0) {
            pthread_attr_destroy (&cl_thread_attr);
    		if ((clean_data) && (arg)) {
    			cl_free(arg);
    		}
            return -3;
        }
        cl_thread_initialized = 1;
	}
	res = pthread_create(&thread_id, &cl_thread_attr, fn, arg);
	if ((res != 0) && (clean_data) && (arg)) {
		cl_free(arg);
	}
	return res;
}
//===========================================================================

/*!
 * \brief Start new joinable thread
 * \param thread_id - pointer to thread_id variable,
 * \param clean_data - when set arg is automaticly freed when error occurs,
 * \param fn - thread function,
 * \param arg - thread arguments,
 * \return 0 on sucess.
 */
int cl_run_joinable_thread(pthread_t *thread_id, int clean_data, void* (*fn)(void*), void* arg)
{
	int res;
	res = pthread_create(thread_id, NULL, fn, arg);
	if ((res != 0) && (clean_data) && (arg)) {
		cl_free(arg);
	}
	return res;
}
//===========================================================================
/*!
 * \brief Wait for thread end.
 * \param thread_id - thread id,
 * \return result from thread.
 */
void *cl_join_thread(pthread_t thread_id)
{	
	void *res;
	pthread_join(thread_id, &res);
	return res;
}
//===========================================================================

/*!
 * \brief Start new thread queue.
 * \param queue_length - queue length,
 * \param threads - number of queue threads (defaut 1); 
 * \return NULL when error.
 */
struct cl_thread_queue *cl_run_thread_queue(int queue_length, int threads)
{
	struct cl_thread_queue *queue = NULL;
	int res,i;

	/* The queue structure */
	queue = (struct cl_thread_queue *)cl_malloc(sizeof (struct cl_thread_queue));
	if (queue == NULL)
		return NULL;
	/* Array for tasks */
	queue->tasks = cl_malloc(sizeof(cl_thread_task_t) * queue_length);
	if (queue->tasks == NULL) {
		free(queue);
		return NULL;
	}
	/* Queue pointers */
	queue->capacity = queue_length;
	queue->size = 0;
  	queue->front = 1;
  	queue->rear = 0;
	
	/* Threads array */
	queue->stop = 0;
	queue->threads = threads;
	queue->thread_id = (pthread_t *)cl_malloc (threads * sizeof(pthread_t));
	if (queue->thread_id == NULL) {
		cl_free(queue->tasks);
		cl_free(queue);
		return NULL;
	}
	/* Locks */
	cl_mutex_init(&queue->access_mutex,NULL);
	cl_cond_init(&queue->full_cond,NULL);
	cl_cond_init(&queue->empty_cond,NULL);
	/* Create threads */
	for (i = 0; i<threads; i++) {
		res = pthread_create(&(queue->thread_id[i]), NULL, cl_thread_queue_function, (void *)queue);
		if (res != 0) {
			queue->threads = i + 1;
			cl_destroy_thread_queue(queue);
			return NULL;
		}
	}
	/* All done */
	return queue;
}
//===========================================================================

/*!
 * \brief Destroy thread queue (NOTE: args are automaticly freed when clean_data flag is set)
 * \param q - pointer to queue structure.
 */
void cl_destroy_thread_queue(struct cl_thread_queue *q)
{
	cl_thread_task_t* ptask;
	int i;
	if (q) {
		q->stop = 1;
		/* Wait for all threads to stop */
		for (i = 0; i < q->threads; i++) {
    		cl_thread_queue_add(q, 0, cl_thread_queue_function_null, cl_thread_queue_function_null, NULL);
		}
		for (i = 0; i < q->threads; i++) {
    		pthread_join(q->thread_id[i],NULL);
		}
		
		/* Clear memory */
    	if (q) {
			if (q->tasks) {
				while (q->size > 0) {
					ptask = &q->tasks[q->front];
					q->size--;
					q->front = next_position (q->front, q);
					/* Cleanup */
					if (ptask->cleanup) {
						ptask->cleanup(ptask->params);
					}
				}
      			cl_free (q->tasks);
			}   
			cl_cond_destroy(&q->full_cond);
			cl_cond_destroy(&q->empty_cond);
			cl_mutex_destroy(&q->access_mutex);
			/* Clear thread id array */
			cl_free(q->thread_id);
			/* Clear queue */
			cl_free (q);
		}
	}
}
//===========================================================================

/*!
 * \brief Add task to thread queue
 * \param q - pointer to queue structure,
 * \param clean_data - when set arg is automaticly freed after task execution or error,
 * \param fn - pointer to thread function,
 * \param fn - pointer to cleanup function,
 * \param arg - allocated thread parameters.
 * \return 0 on sucess.
 */
int cl_thread_queue_add(struct cl_thread_queue *q, int clean_data, void* (*fn)(void*), void* (*cleanup)(void*), void* arg)
{
	cl_thread_task_t *t;
	if (q) {
		cl_mutex_lock(&q->access_mutex);
		/* Wait for empty space in thread queue */ 
		while (q->size == q->capacity) {
    		cl_cond_wait(&q->full_cond, &q->access_mutex);
  		}
  		q->size++;
		q->rear = next_position (q->rear, q);
		t = &q->tasks[q->rear];
		/* Fill task data */
		t->fn = fn;
		t->cleanup = cleanup;
		if (!cleanup) {
			if (clean_data) {
				t->cleanup = cl_thread_queue_function_cleanup;
			} else {
				t->cleanup = cl_thread_queue_function_null;
			}
		}
		t->params = arg;
		/* Commit */		
		cl_cond_signal(&q->empty_cond);
		cl_mutex_unlock(&q->access_mutex);
		return 0;
	} else {
		if ((clean_data) || (cleanup)) {
			if (!cleanup) {
				if (clean_data)
					cl_free(arg);
			} else {
				cleanup(arg);
			}
		}
	}
	return -2;
}
//===========================================================================


/*!
 * \brief Remove all tasks from thread queue.
 * \param q - pointer to queue structure.
 */
void cl_clean_thread_queue(struct cl_thread_queue *q)
{
	cl_thread_task_t* ptask;

	if (q) {
		cl_mutex_lock(&q->access_mutex);
		/* Clear memory */
		if (q->tasks) {
			while (q->size > 0) {
				ptask = &q->tasks[q->front];
				q->size--;
				q->front = next_position (q->front, q);
				/* Cleanup */
				if (ptask->cleanup) {
					ptask->cleanup(ptask->params);
				}
			}
			cl_cond_signal(&q->full_cond);
		}
		q->size = 0;
  		q->front = 1;
  		q->rear = 0;
		cl_mutex_unlock(&q->access_mutex);
	}
}
//===========================================================================

/*!
 * \brief Remove all tasks from thread queue and add new one.
 * \param q - pointer to queue structure.
 */
void cl_clean_thread_queue_and_add(struct cl_thread_queue *q, int clean_data, void* (*fn)(void*), void* (*cleanup)(void*), void* arg)
{
	cl_thread_task_t* ptask;
	cl_thread_task_t *t;
	
	if (q) {
		cl_mutex_lock(&q->access_mutex);
		/* Clear memory */
		if (q->tasks) {
			while (q->size > 0) {
				ptask = &q->tasks[q->front];
				q->size--;
				q->front = next_position (q->front, q);
				/* Cleanup */
				if (ptask->cleanup) {
					ptask->cleanup(ptask->params);
				}
			}
			cl_cond_signal(&q->full_cond);
		}
		q->size = 0;
		q->front = 1;
		q->rear = 0;
		/* Add new task to queue */
		q->size++;
		q->rear = next_position (q->rear, q);
		t = &q->tasks[q->rear];
		/* Fill task data */
		t->fn = fn;
		t->cleanup = cleanup;
		if (!cleanup) {
			if (clean_data) {
				t->cleanup = cl_thread_queue_function_cleanup;
			} else {
				t->cleanup = cl_thread_queue_function_null;
			}
		}
		t->params = arg;
		/* Commit */		
		cl_cond_signal(&q->empty_cond);
		cl_mutex_unlock(&q->access_mutex);
	} else {
		if ((clean_data) || (cleanup)) {
			if (!cleanup) {
				if (clean_data)
					cl_free(arg);
			} else {
				cleanup(arg);
			}
		}
	}
}
//===========================================================================


int cl_cond_timedwait2(pthread_cond_t *cond, pthread_mutex_t *mutex, int timeout)
{
	struct timeval now;
	struct timespec ts;
	
	gettimeofday(&now, NULL);
	ts.tv_sec = now.tv_sec;
	ts.tv_nsec = now.tv_usec*1000;
	ts.tv_sec += timeout / 1000;
	ts.tv_nsec += timeout % 1000 * 1000000;
	if (ts.tv_nsec > 999999999){
		ts.tv_sec++;
		ts.tv_nsec = ts.tv_nsec % 1000000000;
	}
	return cl_cond_timedwait(cond, mutex, &ts);
}
//===========================================================================


void cl_cond_init_monotonic( pthread_cond_t *cond )
{
	pthread_condattr_t attr;

	pthread_condattr_init( &attr );
	pthread_condattr_setclock( &attr, CLOCK_MONOTONIC );
	pthread_cond_init( cond, &attr );
	pthread_condattr_destroy( &attr );
}
//===========================================================================


int cl_cond_timedwait_monotonic(pthread_cond_t * cond, pthread_mutex_t *mutex, int timeout)
{
	struct timespec ts;

	clock_gettime( CLOCK_MONOTONIC, &ts );
	ts.tv_sec += timeout / 1000;
	ts.tv_nsec += timeout % 1000 * 1000000;
	if (ts.tv_nsec > 999999999){
		ts.tv_sec++;
		ts.tv_nsec = ts.tv_nsec % 1000000000;
	}
	return cl_cond_timedwait(cond, mutex, &ts);
}
//===========================================================================
