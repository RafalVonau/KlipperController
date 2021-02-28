#ifndef __CL_INLINE_H__
#define __CL_INLINE_H__

#define UNUSED(x) (void)x
#define __fn_inline static __inline__ __attribute__((always_inline))

#if __GNUC_MINOR__ >= 5
#define __compiler_offsetof(a,b) __builtin_offsetof(a,b)
#endif 

#ifdef __compiler_offsetof
#define offsetof(TYPE,MEMBER) __compiler_offsetof(TYPE,MEMBER)
#else
#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#endif

#define container_of(ptr, type, member) ({                      \
         const typeof( ((type *)0)->member ) *__mptr = (ptr);    \
         (type *)( (char *)__mptr - offsetof(type,member) );})




#endif
