#ifndef ERRORS_LOG_H
#define ERRORS_LOG_H

#include <stdarg.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#if 1
#define ERROR_HARD(fmt, args...)    printf("%s: " fmt "\n", __FUNCTION__ ,## args)
#define ERROR_WARNING(fmt, args...) printf("%s: " fmt "\n", __FUNCTION__ ,## args)
#define DEBUGMSG(fmt, args...)      printf("%s: " fmt "\n", __FUNCTION__ ,## args)
#define DEBUGMSG1(fmt, args...)     printf("%s: " fmt "\n", __FUNCTION__ ,## args)
#define PRINT(fmt, args...)         printf("%s: " fmt "\n", __FUNCTION__ ,## args)
#define LOGMSG(fmt, args...)        printf("%s: " fmt "\n", __FUNCTION__ ,## args)
#else
#define ERROR_HARD(fmt, args...)
#define ERROR_WARNING(fmt, args...)
#define DEBUGMSG(fmt, args...)
#define DEBUGMSG1(fmt, args...)
#define PRINT(fmt, args...)
#define LOGMSG(fmt, args...)
#endif

#ifdef __cplusplus
}
#endif

#endif

