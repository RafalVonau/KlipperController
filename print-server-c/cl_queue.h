/*
 * Simple Queue Implementation.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */


#ifndef __CL_QUEUE_H
#define __CL_QUEUE_H
#include "cl_thread.h"


#ifdef __cplusplus
    extern "C" {
#endif


struct cl_queue_struct;
typedef struct cl_queue_struct *cl_queue_t;

/*!
 * \brief Create new queue.
 * \param num_elements - number of elements in queue,
 * \return pointer to new queue structure or NULL when error.
 */
cl_queue_t cl_queue_create (int num_elements);
/*!
 * \brief Destroy queue
 * \param q - pointer to queue structure,
 */
void cl_queue_destroy (cl_queue_t q);


int cl_queue_enqueue(void *d, cl_queue_t q);
void *cl_queue_enqueue_circ(void *d, cl_queue_t q);
/*!
 * \brief Enqueue element, wait if queue is full.
 * \param d - pointer to element,
 * \param q - pointer to queue structure.
 */
void cl_queue_enqueue_special(void *d, cl_queue_t q); // can't fail
/*!
 * \brief Dequeue element from queue.
 * \param q - pointer to queue structure.
 */
void *cl_queue_dequeue (cl_queue_t q);
/*!
 * \brief Dequeue element, wait if queue is empty.
 * \param d - pointer to element,
 */
void *cl_queue_dequeue_special (cl_queue_t q);
int cl_queue_empty (cl_queue_t q);

int cl_queue_full (cl_queue_t q);

/*!
 * \brief Clear queue.
 * \param q - pointer to queue structure,
 */
void cl_queue_make_empty (cl_queue_t q);
/*!
 * \brief Get element from the front of queue.
 * \param q - pointer to queue structure.
 * \return pointer to element or NULL if queue is empty.
 */
void *cl_queue_front (cl_queue_t q);

#ifdef __cplusplus
    }
#endif



#endif
