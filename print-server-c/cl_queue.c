/*
 * Simple Queue Implementation.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include "cl_queue.h"
#include "cl_memory.h"
#include <stdlib.h>
#include "assert.h"
#include "errors_log.h"
#include "cl_inline.h"

struct cl_queue_struct 
{
	int capacity;
	int front;
	int rear;
	int size;
	void **array;
	cl_mutex_define(access_mutex);
	cl_cond_define(full_cond);
	cl_cond_define(empty_cond);
};
//===========================================================================

/*!
 * \brief Create new queue.
 * \param num_elements - number of elements in queue,
 * \return pointer to new queue structure or NULL when error.
 */
cl_queue_t cl_queue_create (int num_elements)
{
	cl_queue_t q;

	q = cl_malloc (sizeof (struct cl_queue_struct));
	if (q == NULL) {
		return (NULL);
	}
	q->array = cl_malloc(sizeof (void *) * num_elements);
	if (q->array == NULL) {
		free(q);
		return (NULL);
	}
	q->capacity = num_elements;
	cl_mutex_init(&q->access_mutex,NULL);
	cl_cond_init(&q->full_cond,NULL);
	cl_cond_init(&q->empty_cond,NULL);
	cl_queue_make_empty (q);
	return q;
}
//===========================================================================

/*!
 * \brief Destroy queue
 * \param q - pointer to queue structure,
 */
void cl_queue_destroy (cl_queue_t q)
{
  if (q != NULL) {
    if (q->array!=NULL)
      cl_free (q->array);   
    cl_cond_destroy(&q->full_cond);
    cl_cond_destroy(&q->empty_cond);
    cl_mutex_destroy(&q->access_mutex);
    cl_free (q);
  }
}
//===========================================================================


__fn_inline int cl_queue_empty_int(cl_queue_t q)
{
  assert(q!=NULL);
  return (q->size == 0);
}
//===========================================================================

__fn_inline int cl_queue_full_int(cl_queue_t q)
{
  assert(q!=NULL);
  return (q->size == q->capacity);
}
//===========================================================================

/*!
 * \brief Check for queue empty.
 * \param q - pointer to queue structure.
 * \return
 *   - 1 when queue is empty,
 *   - 0 when queue is not empty.
 */
int cl_queue_empty(cl_queue_t q)
{
  int res;
  assert(q!=NULL);
  cl_mutex_lock(&q->access_mutex);
  res=cl_queue_empty_int(q);
  cl_mutex_unlock(&q->access_mutex);
  return res;
}
//===========================================================================

/*!
 * \brief Check for queue full.
 * \param q - pointer to queue structure,
 * \return
 *   - 1 when queue is full,
 *   - 0 when queue is not full.
 */
int cl_queue_full(cl_queue_t q)
{
  int res;
  assert(q!=NULL);
  cl_mutex_lock(&q->access_mutex);
  res=cl_queue_full_int(q);
  cl_mutex_unlock(&q->access_mutex);
  return res;
}
//===========================================================================


/*!
 * \brief Clear queue.
 * \param q - pointer to queue structure,
 */
void cl_queue_make_empty (cl_queue_t q)
{
  assert(q!=NULL);
  cl_mutex_lock(&q->access_mutex);
  q->size = 0;
  q->front = 1;
  q->rear = 0;
  cl_cond_signal(&q->full_cond);
  cl_mutex_unlock(&q->access_mutex);
}
//===========================================================================

/*!
 * \brief Compute next element position in queue.
 * \param q - pointer to queue structure,
 * \return next element position.
 */
__fn_inline int next_position (int v, cl_queue_t q)
{
  assert(q!=NULL);
  if (++v >= q->capacity) {
    v = 0;
  }

  return v;
}
//===========================================================================

/*!
 * \brief Enqueue element.
 * \param d - pointer to element,
 * \param q - pointer to queue structure.
 * \return
 *   - 0 - success,
 *   - -1 - queue is full.
 * .
 */
int cl_queue_enqueue(void *d, cl_queue_t q)
{
  assert(q!=NULL);
  
  cl_mutex_lock(&q->access_mutex);
  
  if (cl_queue_full_int(q)) {
    cl_mutex_unlock(&q->access_mutex);
    return -1;
  }
  
  assert(q->array!=NULL);
  q->size++;
  q->rear = next_position (q->rear, q);
  q->array[q->rear] = d;
  
  cl_cond_signal(&q->empty_cond);
  cl_mutex_unlock(&q->access_mutex);
  return 0;
}
//===========================================================================


/*!
 * \brief Enqueue element in circular fasion.
 * \param d - pointer to element,
 * \param q - pointer to queue structure.
 * \return NULL or pointer to removed first element.
 */
void *cl_queue_enqueue_circ(void *d, cl_queue_t q)
{
	void *res = NULL;
	assert(q!=NULL);
	cl_mutex_lock(&q->access_mutex);
  
	if (cl_queue_full_int(q)) {
		/* Remove first element */
		res=q->array [q->front];
		q->size--;
		q->front = next_position (q->front, q);
	}
	assert(q->array!=NULL);
	q->size++;
	q->rear = next_position (q->rear, q);
	q->array[q->rear] = d;
	cl_cond_signal(&q->empty_cond);
	cl_mutex_unlock(&q->access_mutex);
	return res;
}
//===========================================================================


/*!
 * \brief Enqueue element, wait if queue is full.
 * \param d - pointer to element,
 * \param q - pointer to queue structure.
 */
void cl_queue_enqueue_special(void *d, cl_queue_t q)
{
  assert(q!=NULL);
  assert(q->array!=NULL);
  
  cl_mutex_lock(&q->access_mutex);
  
  while (cl_queue_full_int(q)) {
    cl_cond_wait( &q->full_cond, &q->access_mutex );
  }
  
  q->size++;
  q->rear = next_position (q->rear, q);
  q->array[q->rear] = d;
  cl_cond_signal(&q->empty_cond);
  cl_mutex_unlock(&q->access_mutex);
}
//===========================================================================

/*!
 * \brief Get element from the front of queue.
 * \param q - pointer to queue structure.
 * \return pointer to element or NULL if queue is empty.
 */
void *cl_queue_front (cl_queue_t q)
{
  void *res=NULL;
  
  assert(q!=NULL);
  assert(q->array!=NULL);
  
  cl_mutex_lock(&q->access_mutex);
  
  if (!cl_queue_empty_int(q))
    res=q->array [q->front];

  cl_mutex_unlock(&q->access_mutex);
  return res;
}
//===========================================================================

/*!
 * \brief Dequeue element from queue.
 * \param q - pointer to queue structure.
 */
void *cl_queue_dequeue (cl_queue_t q)
{
  void *res=NULL;
  assert(q!=NULL);
  
  cl_mutex_lock(&q->access_mutex);
  if (!(cl_queue_empty_int(q))) {
    res=q->array [q->front];
    q->size--;
    q->front = next_position (q->front, q);
    cl_cond_signal(&q->full_cond);
  }
  cl_mutex_unlock(&q->access_mutex);
  return res;
}
//===========================================================================

/*!
 * \brief Dequeue element from queue.
 * \param q - pointer to queue structure.
 */
void *cl_queue_dequeue_special (cl_queue_t q)
{
  void *res=NULL;
  assert(q!=NULL);
  
  
  cl_mutex_lock(&q->access_mutex);
  while (cl_queue_empty_int(q)) {
    cl_cond_wait(&q->empty_cond,&q->access_mutex);
  }
  res=q->array [q->front];
  q->size--;
  q->front = next_position (q->front, q);
  cl_cond_signal(&q->full_cond);
  
  cl_mutex_unlock(&q->access_mutex);
  return res;
}
//===========================================================================

