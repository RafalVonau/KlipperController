/*
 * Universal parameters support
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */
 
#ifndef PARAMS_H
#define PARAMS_H

/**
 * \file params.h
 * \brief Structures and fefinitions for parameters. 
 */
 
#include <assert.h>
#include <syslog.h>
#include "libtypes.h"

#ifndef __cplusplus
#ifndef bool
  #define bool int
#endif
#ifndef true
  #define true 1
#endif
#ifndef false
  #define false 0
#endif
#endif
 
#define pt_enum_value(x) (((pt_enum_type_t *)x)->enum_table[*((pt_enum_type_t *)x)->value]) 
 
struct pt_enum_type_t
{
  int nr;
  int *value;
  const char *enum_table[];
};
typedef struct pt_enum_type_t pt_enum_type_t;

struct pt_string_type_t
{
  char *buf;
  int limit;
};
typedef struct pt_string_type_t pt_string_type_t;

// parameters
typedef enum
{
  pt_string=0,         /**! it is string  */
  pt_int=1,            /**! it is integer */
  pt_float=2,          /**! it is float   */
  
  pt_intp=3,           /**! it is integer (limitas as pointers) */
  pt_floatp=4,         /**! it is float   (limitas as pointers) */
  
  pt_enum=5            /**! it is enumerate */
} pt_type_t;

typedef enum
{
  pt_rw=0,             /**! can read and write */
  pt_ro=1,             /**! can read */
  pt_wo=2              /**! can write */
} pt_mode_t;

typedef union {
  compute_t asfloat;
  int asint;
  int *asintp;
  compute_t *asfloatp;
  pt_enum_type_t *asenum;
} value_t;

struct parameter_vt
{
  const char *name;      /**! parameter name          */
  const char *unit;      /**! parameter unit          */
  pt_type_t type;        /**! parameter type          */
  value_t min;           /**! minimum value           */
  value_t max;           /**! maximum value           */
  value_t step;          /**! step size (0 - no step) */
  void *val;             /**! pointer to value        */
  pt_mode_t mode;        /**! parameter mode          */
};



#ifndef NULL
  # define NULL 0
#endif
  
#endif

