/*
 * Strings manipulations.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */

#ifndef __ESTRING_H__
#define __ESTRING_H__
#include <stdio.h>
//#include <string.h>

#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "params.h"
#define String struct _estring_t
String;
#include "errors_log.h"
#include <string.h>
#include "cl_memory.h"


/*!
 * \file estring.h
 * \brief Strings manipulations.
 */

/*!
 * \file estring.h
 * \brief Strings manipulations.
 */
#define __fn_inline static __inline__ __attribute__((always_inline))

#define STRING_MULTIPLY 2
#define TMP_BUF_SIZE 255

#ifndef bool
#define bool int
#endif
#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif

#ifdef __cplusplus
extern "C" {
#endif

/*!
 * \brief Easy string structure.
 */
struct _estring_t
{
	char *buf;        /**< Pointer to string buffer. */
	int size;         /**< Maximum size (allocated memory size). */
	int poz;          /**< String length. */
};

#define String struct _estring_t

#define SPLIT2_DECLARE(iter) \
	int iter_idx; \
	int last_iter; \
	String iter;

/*!
 * Text splitting macro.
 */
#define eFOR_SPLIT2(str,sep,iter) { \
	iter_idx=string_find(str,sep,0); \
	if (iter_idx<0) iter_idx=(str)->poz; \
	last_iter=0;\
	while (last_iter<=iter_idx) \
{ \
	iter=string_copy(str,last_iter,iter_idx); \
	last_iter=iter_idx+1; \
	iter_idx=string_find(str,sep,last_iter); \
	if (iter_idx<0) iter_idx=(str)->poz;
#define eEND_SPLIT2(iter) string_free(&iter); }}


#define string_length(s) ((s)->poz)

//#define FAST_STRING
#define string_vsprintf(s,size,fmt, args) \
{ \
	int ss_res; \
	string_prealloc(s,size); \
	ss_res = vsnprintf((&((s)->buf[(s)->poz])),size,fmt, args); \
	if (ss_res>0) {\
	if (ss_res>size) \
	ss_res=size; \
	(s)->poz+=ss_res; \
} \
}

#define string_sprintf(s,size,fmt, args...) \
{ \
	int ss_res; \
	string_prealloc(s,size); \
	ss_res=snprintf((&((s)->buf[(s)->poz])),size,fmt,## args); \
	if (ss_res>0) {\
	if (ss_res>size) \
	ss_res=size; \
	(s)->poz+=ss_res; \
} \
}
#define sstring_add(s1,s2) string_add((s1),(s2)->buf,string_length((s2)))
#define cstring_add(s1,s2) string_add((s1),(s2),strlen((s2)))
#define string_as_int(s) str_to_int(s);

#define ALOCDEBUG(fmt, args...)
#define STRERROR(fmt, args...) ERROR_HARD(fmt,## args)

//======================================= private ===================================
#define allocate_memory(size) cl_malloc(size)
#define free_memory(buf) cl_free(buf)

//======================================= public  ===================================


__fn_inline int string_memory_allocator(String *s,int size)
{
	char *buf;
	int new_size;

	if (s->poz+size>s->size) {// reallocate memory
		buf=s->buf;
		new_size=STRING_MULTIPLY*s->size;
		if (new_size<s->poz+size)
			new_size=s->poz+size+1;
		ALOCDEBUG("Realocating memory %d\n",new_size);
		s->buf=(char *)cl_realloc(s->buf,new_size);
		if (s->buf==NULL) {
			s->buf=buf;
			STRERROR("Can't allocate memory!!\n");
			return 0;
		}
		s->size=new_size;
	}
	return 1;
}
//===========================================================================

/*!
 * \brief Free string memory, this function must be called
 * for all not empty strings!!
 * \param s - pointer to String object.
 */
__fn_inline void string_free(String *s)
{
	s->size=0;
	s->poz=0;

	if (s->buf!=NULL)
		free_memory(s->buf);
}
//===========================================================================

/*!
 * \brief Initialize new string (memory allocation, to free this object
 * use string_free function)
 * \see string_free
 * \param s - pointer to String object.
 */
__fn_inline void string_init(String *s)
{
	s->buf=NULL;
	s->size=0;
	s->poz=0;
}
//===========================================================================

/*!
 * \brief Set string to be empty string.
 * \param s - pointer to String object.
 */
__fn_inline void string_clear(String *s)
{
	s->poz=0;
}
//===========================================================================

/*!
 * \brief Preallocate memory for string.
 * \param s    - pointer to String object,
 * \param size - needed size.
 */
__fn_inline void string_prealloc(String *s,int size)
{
	string_memory_allocator(s,size);
}
//===========================================================================

/*!
 * \brief Add new characters to string.
 * \param s - pointer to String object.
 * \param cbuf - pointer to characters buffer,
 * \param size - number of characters to add.
 */
__fn_inline void string_add(String *s,const char *cbuf,int size)
{
	if ((size) && (string_memory_allocator(s,size))) {
		memcpy(&(s->buf[s->poz]),cbuf,size);
		s->poz+=size;
	}
}
//===========================================================================


/*!
 * \brief Add integer to string,
 * \param s - pointer to String object,
 * \param value - integer value to add.
 */
__fn_inline void string_add_int(String *s,int value)
{
	string_sprintf(s,1024,"%d",value);
}
//===========================================================================

/*!
 * \brief Add integer to string,
 * \param s - pointer to String object,
 * \param value - integer value to add.
 */
__fn_inline void string_add_hex(String *s,int value)
{
	string_sprintf(s,1024,"%x",value);
}
//===========================================================================

/*!
 * \brief Add float to string,
 * \param s - pointer to String object,
 * \param value - float value to add.
 */
__fn_inline void string_add_float(String *s,compute_t value)
{
	string_sprintf(s,1024,"%.5f",value);
}
//===========================================================================

/*!
 * \brief Add float to string,
 * \param s - pointer to String object,
 * \param value - float value to add.
 */
__fn_inline void string_add_float2(String *s,compute_t value)
{
	string_sprintf(s,1024,"%.2f",value);
}
//===========================================================================


#define STRING_SS_BUF_SIZE 4096
/*!
 * \brief Add data from file to string,
 * \param s    - pointer to String object,
 * \param file - file handle.
 */
__fn_inline int string_add_from_file(String *s,int file)
{
	struct stat st;

	if (fstat(file,&st)==0) {
		if (string_memory_allocator(s,(s)->poz+st.st_size)) {
			if (read(file,&((s)->buf[(s)->poz]),st.st_size)==st.st_size) {
				(s)->poz+=st.st_size;
				return 1;
			}
		}
	}
	return 0;
}

/*!
 * \brief Add data from file to string,
 * \param s    - pointer to String object,
 * \param file - file stream.
 */
__fn_inline int string_add_from_vfile(String *s,FILE *file)
{
	char buf[STRING_SS_BUF_SIZE];
	int bytes;

	bytes=fread(buf,1,STRING_SS_BUF_SIZE,file);
	while (bytes>0) {
		string_add(s,&buf[0],bytes);
		bytes=fread(buf,1,STRING_SS_BUF_SIZE,file);
	}
	return 1;
}
//===========================================================================

/*!
 * \brief Add data from file to string,
 * \param s    - pointer to String object,
 * \param file - file name.
 */
__fn_inline int string_add_from_file2(String *s,const char *file)
{
	int fd;

	fd=open(file,O_RDONLY);
	if (fd>-1) {
		struct stat st;

		if (stat(file,&st)==0) {
			if (string_memory_allocator(s,(s)->poz+st.st_size)) {
				if (read(fd,&((s)->buf[(s)->poz]),st.st_size)==st.st_size) {
					(s)->poz+=st.st_size;
					close(fd);
					return 1;
				}
			}
		}
		close(fd);
		return 0;
	}
	return 0;
}
//===========================================================================

/*!
 * \brief Add data from file to string,
 * \param s    - pointer to String object,
 * \param file - file name.
 */
__fn_inline int string_add_from_sys(String *s,const char *fname)
{
	char buf[STRING_SS_BUF_SIZE];
	int len,fd = open(fname, O_RDONLY);
	int res = 1;
	if (fd < 0) {
		res = 0;
	} else {
		len = read(fd, buf, STRING_SS_BUF_SIZE);
		if ( len <= 0) {
			res = 0;
		} else {
			string_add(s, buf, len);
		}
	}
	close(fd);
	return res;
}
//===========================================================================


/*!
 * \brief Add data from file to string,
 * \param s    - pointer to String object,
 * \param file - file name.
 */
__fn_inline int string_add_from_file3(String *s,const char *file)
{
	int fd,bytes;
	char buf[4096];

	fd=open(file,O_RDONLY);
	if (fd>-1) {
		while ((bytes=read(fd,buf,4095))>0) {
			string_add(s,buf,bytes);
		}
		close(fd);
		return 1;
	}
	return 0;
}
//===========================================================================

/*!
 * \brief Save String to file,
 * \param s    - pointer to String object,
 * \param file - file handle.
 */
__fn_inline bool string_save_to_file(String *s,int file)
{
	if (file>-1) {
		if (write(file,s->buf,string_length(s)) == string_length(s))
			return true;
	}
	return false;
}
//===========================================================================

/*!
 * \brief Save String to file,
 * \param s    - pointer to String object,
 * \param file - file stream.
 */
__fn_inline bool string_save_to_vfile(String *s,FILE *file)
{
	if (fwrite(s->buf,string_length(s),1,file)<=0) {
		return false;
	}
	return true;
}
//===========================================================================

/*!
 * \brief Save String to file,
 * \param s    - pointer to String object,
 * \param file - file name.
 */
__fn_inline int string_save_to_file2(String *s,const char *filename)
{
	int file;

	file=open(filename,O_CREAT | O_WRONLY | O_TRUNC,  S_IROTH | S_IRGRP | S_IRUSR | S_IWUSR );
	if (file>=0) {
		string_save_to_file(s,file);
		close(file);
		return 1;
	}
	return 0;
}
//===========================================================================

/*!
 * \brief Save String to file,
 * \param s    - pointer to String object,
 * \param file - file name.
 */
__fn_inline int string_save_to_file2x(String *s,const char *filename)
{
	int file;

	file=open(filename,O_CREAT | O_WRONLY | O_TRUNC,  S_IROTH | S_IRGRP | S_IRUSR | S_IWUSR
			  | S_IXUSR | S_IXGRP | S_IXOTH);
	if (file>=0) {
		string_save_to_file(s,file);
		close(file);
		return 1;
	}
	return 0;
}
//===========================================================================


/*!
 * \brief Get string as C char pointer.
 * \param s - pointer to String object.
 * \return pointer to C char array.
 */
__fn_inline char *string_c_str(String *s)
{
	string_add(s,"",1);
	s->poz--;
	return s->buf;
}
//===========================================================================

/*!
 * \brief Get string as C char pointer.
 * \param s - pointer to String object.
 * \return pointer to C char array.
 */
__fn_inline char *string_str(String *s)
{
	return s->buf;
}
//===========================================================================

// ================================ operations ===================================
/*!
 * \brief Erase part in string.
 * \param s - string structure,
 * \param start - starting character to erase,
 * \param size - characters to erase.
 */
__fn_inline int string_erase(String *s,int start,int size)
{
	int dif;
	if (s->poz<start+size)
		size=s->poz-start;
	dif=s->poz-start-size;
	if ((size>0) && (dif>0)) {
		memcpy(&s->buf[start],&s->buf[start+size],dif);
	}
	if (size>0)
		s->poz-=size;
	if (s->poz<0)
		s->poz=0;
	return size;
}
//===========================================================================

/*!
 * \brief Find character in string.
 * \param s - string structure,
 * \param c - searching character,
 * \param start - start character in string.
 * \return
 *   character position on success,
 *   -1 on not found.
 * .
 */
__fn_inline int string_find(String *s,char c,int start)
{
	int i;
	for (i=start;i<s->poz;++i)
		if (s->buf[i]==c)
			return i;
	return -1;
}
//===========================================================================

/*!
 * \brief Replace characters in string.
 * \param s - string structure,
 * \param c1 - searching character,
 * \param c2 - replace character.
 * \return replaced characters count.
 */
__fn_inline int string_replace(String *s,char c1,char c2)
{
	int i;
	int count=0;

	for (i=0;i<s->poz;++i)
		if (s->buf[i]==c1) {
			s->buf[i]=c2;
			count++;
		}
	return count;
}
//===========================================================================


/*!
 * \brief Reverse find character in string.
 * \param s - string structure,
 * \param c - searching character,
 * \param end - position where to start searching.
 * \return
 *   character position on success,
 *   -1 on not found.
 * .
 */
__fn_inline int string_rfind(String *s,char c,int end)
{
	int i;
	if (end>s->poz) end=s->poz-1;
	for (i=end;i>=0;--i)
		if (s->buf[i]==c)
			return i;
	return -1;
}
//===========================================================================

/*!
 * \brief Copy part of string to new string.
 *
 * Warning You must free memory in new created string at end of using it!!
 * \param s - pointer to string object,
 * \param start - index of starting character to copy from,
 * \param end - index of ending character.
 */
__fn_inline String string_copy(String *s,int start,int end)
{
	String ss;
	int bytes;

	string_init(&ss);
	if (start>s->poz) return ss;
	if (end>s->poz) end=s->poz;
	bytes=end-start;
	if (bytes>0) {
		ss.size=bytes+1;
		ss.poz=bytes;
		ss.buf=(char *)allocate_memory(bytes+1);
		if (ss.buf==NULL) {STRERROR("Can't allocate memory!!\n");return ss;}
		memcpy(ss.buf,&s->buf[start],bytes);
	}
	return ss;
}
//===========================================================================

/*!
 * \brief Copy part of string to new string.
 *
 * \param s - pointer to string object,
 * \param res - pointer to result string object,
 * \param start - index of starting character to copy from,
 * \param end - index of ending character.
 */
__fn_inline void string_copy2(String *s,String *res,int start,int end)
{
	int bytes;

	string_clear(res);
	if (start>s->poz) return;
	if (end>s->poz) end=s->poz;
	bytes=end-start;
	if (bytes>0) {
		string_add(res,&s->buf[start],bytes);
	}
}
//===========================================================================

/*!
 * \brief Cut repeated characters.
 * \param s - pointer to string object,
 * \param c - character code.
 *
 * Example:
 * \code
 *   string s;
 *   string_init(&s);
 *   string_add(&s,"dogs   eats  meet and   drinks  beer",36);
 *   cut_repeated_characters(&s,' ');  // new string is: "dogs eats meet and drinks beer"
 *   string_free(&s);
 * \endcode
 */
__fn_inline void cut_repeated_characters(String *s,char c)
{
	int i;
	for (i=0;i<s->poz-1;++i)
		if ((s->buf[i]==c) && (s->buf[i+1]==c)) {
			string_erase(s,i,1);
			i--;
		}
}
//===========================================================================

/*!
 * \brief Cut all characters after given character.
 * \param s - pointer to string object,
 * \param c - character code.
 *
 * Example:
 * \code
 *   String s;
 *   string_init(&s);
 *   string_add(&s,"dogs   eats  meet and   drinks  beer",36);
 *   string_cut_after_ch(&s,'s');  // new string is: "dogs"
 *   string_free(&s);
 * \endcode
 */
__fn_inline void string_cut_after_ch(String *s, char c)
{
	int poz=string_find(s,c,0);
	if (poz>-1)
		s->poz=poz;
}
//===========================================================================

/*!
 * \brief Cut all characters before given character.
 * \param s - pointer to string object,
 * \param c - character code.
 *
 * Example:
 * \code
 *   String s;
 *   string_init(&s);
 *   string_add(&s,"dogs   eats  meet and   drinks  beer",36);
 *   string_cut_before_ch(&s,'s');  // new string is: "   eats  meet and   drinks  beer"
 *   string_free(&s);
 * \endcode
 */
__fn_inline void string_cut_before_ch(String *s, char c)
{
	int i;
	int poz=string_find(s,c,0);

	if (poz>-1)  {
		poz++;
		i=0;
		while (poz<s->poz) {
			s->buf[i]=s->buf[poz];
			++poz;
			++i;
		}
		s->poz=i;
	}
}
//===========================================================================


/*!
 * \brief Cut first and last character until first and last characters differ from given character.
 * \param s - pointer to string object,
 * \param c - character code.
 *
 * Example:
 * \code
 *   String s;
 *   string_init(&s);
 *   string_add(&s,":::::item:::",12);
 *   string_cut_ears(&s,':');  // new string is: "item"
 *   string_free(&s);
 * \endcode
 */
__fn_inline void string_cut_ears(String *s, char c)
{
	int i;
	int start=0;
	int stop=string_length(s);

	if (stop<1) return;

	while ((s->buf[start]==c) && (start<s->poz)) ++start;
	while ((s->buf[stop-1]==c) && (stop>0)) --stop;

	if (stop>start) {
		for (i=start;i<stop;++i)
			s->buf[i-start]=s->buf[i];
		s->poz=stop-start;
	}
}
//===========================================================================


__fn_inline int in_table(char ch, const char *table)
{
	int i;

	i=0;
	while (table[i]!='\0') {
		if (table[i]==ch)
			return 1;
		++i;
	}
	return 0;
}
//===========================================================================

//============================== conversions ======================================
/*!
 * \brief Check for integer number
 * \param s - string to check,
 * \return 1 - if it is integer.
 */
__fn_inline int string_is_int(String *s) {
	int i;
	int count=0;
	const char valid_chars[]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','\0'};
	const char white_chars[]={'-','X',' ','\0'};

	if (string_length(s)==0)
		return 0;

	for (i=0;i<string_length(s);++i) {
		if (in_table(toupper(s->buf[i]),valid_chars)) {
			++count;
		} else if (!in_table(toupper(s->buf[i]),white_chars)) {
			return 0;
		}
	}
	if (count>0) {
		return 1;
	} else {
		return 0;
	}
}
//===========================================================================



/*!
 * \brief Check for valid ip number
 * \param s - string to check,
 * \return 1 - if it is valid ip number.
 */
__fn_inline int string_is_ip(String *s)
{
	int i,a[4];
	int count=0,wcount=0;

	const char valid_dig[]={'0','1','2','3','4','5','6','7','8','9','\0'};
	const char white_chars[]={'.','\0'};

	if (string_length(s)==0)
		return 0;

	for (i=0;i<string_length(s);++i) {
		if (in_table(s->buf[i],valid_dig)) {
			++count;
		} else if ((!in_table(s->buf[i],white_chars)) || (count==0)) {
			return 0;
		} else {
			count=0;
			++wcount;
		}
	}
	if (wcount==3) {
		sscanf(string_c_str(s),"%d.%d.%d.%d",&a[0],&a[1],&a[2],&a[3]);
		for (i=0;i<4;++i) {
			if ((a[i]<0) | (a[i]>255)) return 0;
		}
		return 1;
	} else {
		return 0;
	}
}
//===========================================================================



/*!
 * \brief Convert string to integer (in hexadecimal or decimal format).
 * \param s - string to convert,
 * \return integer.
 */
__fn_inline int str_to_int(String *s)
{
	int value=0;
	int idx;

	if (string_length(s)==0) return value;
	idx = string_find(s,'x',0);
	if (idx != -1)  {                      // decode hexadecimal
		sscanf(string_c_str(s),"%x",&value);
	} else {                               // decode decimal
		sscanf(string_c_str(s),"%d",&value);
	}
	return value;
}
//===========================================================================

/*!
 * \brief Convert string to float.
 * \param s - string to convert,
 * \return float.
 */
__fn_inline float string_as_float(String *s)
{
	float value=0.0;

	if (string_length(s)==0)
		return value;
	sscanf(string_c_str(s),"%f",&value);
	return value;
}
//===========================================================================

#define END_STR(s,x) (x>=string_length(s))
__fn_inline int getParam2(String *s,String *res)
{
	int start_param=0;
	int stop_param=0;
	bool ignore_spaces=false;
	bool end=false;
	bool ignore_next_char=false;

	string_clear(res);
	// cut white spaces
	cut_repeated_characters(s,' ');
	if (string_length(s)==0) return 0;

	while ((start_param<string_length(s)) && (s->buf[start_param]==' ')) {++start_param;}
	if (s->buf[start_param]=='"') {ignore_spaces=true; ++start_param;}

	stop_param=start_param+1;

	while ((!END_STR(s,stop_param)) && (!end))
	{
		switch (s->buf[stop_param])
		{
			case '\\':ignore_next_char=true;break;
			case '"':{
				if ((!ignore_next_char) && (ignore_spaces)) {end=true;continue;}
				ignore_next_char=false;
			} break;
			case ' ': {
				if ((!ignore_next_char) && (!ignore_spaces)) {end=true;continue;}
				ignore_next_char=false;
			} break;
			default:
			{
				ignore_next_char=false;
			}; break;
		}
		++stop_param;
	}
	string_copy2(s,res,start_param,stop_param);
	if ((ignore_spaces) && (s->buf[stop_param]=='"')) ++stop_param;
	string_erase(s,0,stop_param+1);
	return 1;
}
//===========================================================================


/*!
 * \brief Get single string parameter from command line.
 * \param s - command line,
 * \return - single parameter as String.
 *
 * Example:
 * \code
 *   String s,param;
 *   string_init(&s);
 *   string_add(&s,"12.45 dog cat 23",16);
 *   param=getParam(&s);   // param="12.45", s="dog cat 23"
 *   string_free(&param);
 *   string_free(&s);
 * \endcode
 */
__fn_inline String getParam(String *s)
{
	String res;

	string_init(&res);
	getParam2(s,&res);
	return res;
}
//===========================================================================


/*!
 * \brief Get single integer from command line (in hexadecimal or decimal format).
 * \param s - command line,
 * \return - single integer parameter;
 *
 * Example:
 * \code
 *   String s;
 *   int i;
 *   string_init(&s);
 *   string_add(&s,"12 dog cat 23",13);
 *   i=getParamInt(&s);   // i = 12, s="dog cat 23"
 *   string_free(&s);
 * \endcode
 */
__fn_inline int getParamInt(String *s)
{
	int value=0;
	String res=getParam(s);
	//printf("conv val=%s\n",string_c_str(&res));
	value=str_to_int(&res);
	string_free(&res);
	return value;
}
//===========================================================================

/*!
 * \brief Get single double from command line.
 * \param s - command line,
 * \return - single parameter converted to double.
 *
 * Example:
 * \code
 *   String s;
 *   double d;
 *   string_init(&s);
 *   string_add(&s,"12.45 dog cat 23",16);
 *   d=getParamDouble(&s);   // d = 12.45, s="dog cat 23"
 *   string_free(&s);
 * \endcode
 */
__fn_inline double getParamDouble(String *s)
{
	double value=0.0;
	String res=getParam(s);
	sscanf(string_c_str(&res),"%lf",&value);
	string_free(&res);
	return value;
}
//===========================================================================

/*!
 * \brief Get single float value from command line.
 * \param s - command line,
 * \return - single parameter converted to double.
 *
 * Example:
 * \code
 *   String s;
 *   compute_t d;
 *   string_init(&s);
 *   string_add(&s,"12.45 dog cat 23",16);
 *   d=getParamDouble(&s);   // d = 12.45, s="dog cat 23"
 *   string_free(&s);
 * \endcode
 */
__fn_inline compute_t getParamFloat(String *s)
{
	compute_t value=0.0;
	String res=getParam(s);
	sscanf(string_c_str(&res),"%f",&value);
	string_free(&res);
	return value;
}
//===========================================================================

//=============================== cmp ==================================
/*!
 * \brief Upcase all characters in string.
 * \param s - string to up case.
 */
__fn_inline void string_upcase(String *s)
{
	int i;
	for (i=0;i<s->poz;++i) s->buf[i]=toupper(s->buf[i]);
}
//===========================================================================

/*!
 * \brief Lowercase all characters in string.
 * \param s - string to lowercase.
 */
__fn_inline void string_lowcase(String *s)
{
	int i;
	for (i=0;i<s->poz;++i) s->buf[i]=tolower(s->buf[i]);
}
//===========================================================================

/*!
 * \brief Compare String and character table string.
 * \param s - string to compare,
 * \param ss - pointer to character table.
 */
__fn_inline int string_cmp_ch(const String *s,const char *ss)
{
	int i;
	int len,len1;
	int min;

	len=strlen(ss);
	len1=string_length(s);
	min=(len<len1)?len:len1;

	for (i=0;i<min;++i)
	{
		if (s->buf[i]>ss[i]) return 1;
		if (s->buf[i]<ss[i]) return -1;
	}

	if (len==len1) return 0;
	return (len<len1)?1:-1;
}
//===========================================================================

/*!
 * \brief Compare String and character table string.
 * \param s - string to compare,
 * \param ss - pointer to character table.
 */
__fn_inline int string_starts_with(const String *s,const char *ss)
{
	int i;
	int len,len1;

	len = strlen(ss);
	len1 = string_length(s);
	if (len > len1) return 0;
	for (i=0;i<len;++i) {if (s->buf[i]!=ss[i]) return 0;}
	return 1;
}
//===========================================================================

/*!
 * \brief Compare String and character table string.
 * \param s - string to compare,
 * \param ss - pointer to character table.
 */
__fn_inline int string_starts_with_offset(const String *s,const char *ss, int offset)
{
	int i;
	int len,len1;

	len = strlen(ss);
	len1 = (string_length(s) - offset);
	if (len > len1) return 0;
	for (i=0;i<len;++i) {if (s->buf[offset+i]!=ss[i]) return 0;}
	return 1;
}
//===========================================================================


/*!
 * \brief Compare Strings.
 * \param s1 - string to compare,
 * \param s2 - string to compare.
 */
__fn_inline int string_cmp(const String *s1,const String *s2)
{
	int i;
	int len,len1;
	int min;

	len=string_length(s1);
	len1=string_length(s2);
	min=(len<len1)?len:len1;

	for (i=0;i<min;++i)
	{
		if (s1->buf[i]>s2->buf[i]) return 1;
		if (s1->buf[i]<s2->buf[i]) return -1;
	}

	if (len==len1) return 0;
	return (len<len1)?1:-1;
}
//===========================================================================


/*!
 * \brief Get and delete character from string.
 * \param s - input string,
 * \param nr - character number.
 *
 * Example:
 * \code
 *   String s;
 *   char c;
 *   string_init(&s);
 *   string_add(&s,"12.45 dog cat 23",16);
 *   c=string_get_and_cut_char(&s,1);   // c='1', s="2.45 dog cat 23"
 *   string_free(&s);
 * \endcode
 */
__fn_inline char string_get_and_cut_char(String *s,int nr)
{
	int i;
	char ch='\0';
	if ((nr<s->poz) && (s->poz>0))
	{
		ch=s->buf[nr];
		for (i=nr;i<s->poz-1;++i) s->buf[i]=s->buf[i+1];
		s->poz--;
	}
	return ch;
}
//===========================================================================

/*!
 * \brief Find string in string.
 * \param query - source string,
 * \param key   - string to find to,
 * \param st    - starting character in source string.
 * \return
 *   key position in string on success,
 *   -1 can't find key in string.
 * .
 */
__fn_inline int string_sfind(String *query,const char *key,int st)
{
	int i,len,klen;
	int res;

	res=-1;
	if ((!query) || (!key))
		return res;
	len=string_length(query);
	klen=strlen(key);

	for (i=st;i<len;++i) {
		if ((query->buf[i]==key[0]) && (len-i>=klen) && (strncmp(&(query->buf[i]),key,klen)==0)) {
			// it is it
			res=i;
			break;
		}
	}
	return res;
}
//===========================================================================


/*!
 * \brief Replace key in string.
 * \param s     - source string,
 * \param key   - key to replace,
 * \param rtext - text to replace key.
 * \return New string.
 */
__fn_inline String string_sreplace(String *s,const char *key,const char *rtext)
{
	int res=0,klen,rlen,start;
	String rs;

	klen = strlen(key);
	rlen = strlen(rtext);
	string_init(&rs);

	start=0;
	while ((res = string_sfind(s,key,start))>-1) {
		string_add(&rs,&(s->buf[start]),res-start);
		string_add(&rs,rtext,rlen);
		start=res+klen;
	}
	if (start<string_length(s)) {
		string_add(&rs,&(s->buf[start]),string_length(s)-start);
	}
	return rs;
}
//===========================================================================

/*!
 * \brief Get single line from string.
 * \param s     - source string,
 * \param rs    - destination string,
 * \param m     - new line character,
 * \param start - starting character in source string.
 */
__fn_inline void string_get_line(String *s,String *rs,const char m, int *start)
{
	int res;

	string_clear(rs);
	if (*start>=string_length(s)) return;

	res = string_find(s,m,(*start));
	if (res>-1) {
		string_add(rs,&s->buf[*start],res-(*start));
		(*start)=res+1;
	} else {
		string_add(rs,&s->buf[*start],string_length(s)-(*start));
		(*start)=string_length(s);
	}
}
//===========================================================================

/*!
 * \brief Simulate raw buffer at the end of string.
 * \param s - pointer to string,
 * \param size - needed buffer size.
 * \return - pointer to buffer at the end of string.
 */
__fn_inline char *string_buf(String *s,int size)
{
	string_prealloc((s),size);
	return (char *)(&((s)->buf[(s)->poz]));
}
//===========================================================================

__fn_inline void string_buf_commit(String *s,int written)
{
	if (written>0)
		(s)->poz+=written;
}
//===========================================================================

#ifdef __cplusplus
}
#endif

#endif
