#ifndef LIBTYPES_H
#define LIBTYPES_H

#include <sys/types.h>
#include <asm/byteorder.h>


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
 
#ifndef NULL
  # define NULL 0
#endif
  
typedef int BOOL;
typedef __u8 CHAR;
typedef __s8 SIGNEDCHAR;
typedef __u8 BYTE;
typedef __s16 SHORT;
typedef __u16 WORD;
typedef __s32 LONG;
typedef __s64 LONG64;  
typedef __u32 DWORD;
typedef __u64 DWORD64;
typedef float FLOAT;
typedef double DOUBLE;

typedef float compute_t;

#endif

