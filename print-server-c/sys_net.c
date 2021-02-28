/*
 * Network helper
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#include <sys/ioctl.h>
#include <stdlib.h>
#include <math.h>
#include "sys_net.h"

// http://www.kt.agh.edu.pl/~pacyna/lectures/secure_corporate_networks/lab/lab3/pacyna-scn-lab-openssl-programming.pdf


#ifdef SYS_NET_USE_SSL

SSL_CTX* __sys_net_ssl_ctx_client;  /* Client SSL context */
/*!
 * \brief sys_net constructor.
 */
void sys_net_init(void)
{
	/* call the standard SSL init functions */
	SSL_load_error_strings();
	SSL_library_init();
	ERR_load_BIO_strings();
	OpenSSL_add_all_algorithms();

	/* Create SSL context */
	//__sys_net_ssl_ctx_client = SSL_CTX_new(TLSv1_2_client_method());
	__sys_net_ssl_ctx_client = SSL_CTX_new(SSLv23_client_method());
	if (__sys_net_ssl_ctx_client == NULL) {
		ERR_print_errors_fp(stderr);
	}
}
//====================================================================================================

/*!
 * \brief sys_net destructor.
 */
void sys_net_destroy(void)
{
	/* Free SSL context */
	if (__sys_net_ssl_ctx_client) SSL_CTX_free(__sys_net_ssl_ctx_client);
}
//====================================================================================================

#else
void sys_net_init(void) {}
void sys_net_destroy(void) {}
#endif

/*!
 * \brief Perform HTTP[S] GET request.
 * \param src_url - source url with full path (port number, user/password if needed),
 * \param timeout - operation timeout in [ms],
 * \param http_recv_data - received data,
 * \return positive number or 0 - data offset (received HTTP header size),
 *  -1 - can not connect,
 *  -2 - site redirect (http_recv_data contains new location),
 *  -3 - Bad request,
 *  -4 - Unauthorized,
 *  -5 - Not found.
 */
int sys_net_get(const char *src_url, int timeout, String *http_recv_data )
{
	char *ns, *url, *p, *sp, *host, *path, *user,*pass,*port;
	int portn,ret, use_ssl = 0;
	String http_header;
	url = strdup(src_url);
	ns = host = path = user = pass = port = strdup("");

	if (strncmp(url, "http://", 7) == 0) host=url+7; else if (strncmp(url, "https://", 8) == 0) {host=url+8;use_ssl=1;} else host=url;

	sp = strchr(host, '/');
	p = strchr(host, '?'); if (!sp || (p && sp > p)) sp = p;
	p = strchr(host, '#'); if (!sp || (p && sp > p)) sp = p;
	if (!sp) {path=ns;} else if (*sp == '/') {*sp = '\0';path = sp + 1;} else { // '#' or '?'
		memmove(host - 1, host, sp - host);
		host--;
		sp[-1] = '\0';
		path = sp;
	}
	sp = strrchr(host, '@');
	if (sp != NULL) {*sp = '\0';user = host;host = sp + 1;}
	sp = strrchr(host, ':');
	if (sp != NULL) {*sp = '\0';port = sp + 1;}
	sp = strrchr(user, ':');
	if (sp != NULL) {*sp = '\0';pass = sp + 1;}

	if (sscanf(port,"%d", &portn) != 1) {
		if (use_ssl) portn = 443;else portn = 80;
	}
	sys_net_debug("Dekodowanie URL(%s) => host=%s, port=%d, path=%s, user=%s, pass=****, SSL=%d\n", src_url, host, portn, path, user, use_ssl);

	/* Construct HTTP header */
	string_init(&http_header);
	string_prealloc(&http_header,65535);
	string_add(&http_header,"GET /", 5);
	cstring_add(&http_header,path);
	string_add(&http_header," HTTP/1.0\r\nHost: ", 17);
	cstring_add(&http_header,host);
	string_add(&http_header,"\r\n\r\n",4);

	sys_net_debug("Header: %s\n",string_c_str(&http_header));

	if (use_ssl) {
#ifdef SYS_NET_USE_SSL
		ret = sys_net_https(host, portn, timeout, &http_header, NULL, http_recv_data );
#else
		/* NO SSL support (try http) */
		ret = sys_net_http(host, portn, timeout, &http_header, NULL, http_recv_data );
#endif
	} else {
		ret = sys_net_http(host, portn, timeout, &http_header, NULL, http_recv_data );
	}
	free(ns);
	free(url);
	string_free(&http_header);
	if (ret == -2) {
		/* Page moved */
		ret = sys_net_get(string_c_str(http_recv_data), timeout, http_recv_data );
	}
	return ret;
}
//====================================================================================================


#define HTTP_MAX_BLOCK (4094)

/*!
 * \brief Perform HTTP xfer.
 * \param target         - target host (name or ip),
 * \param port           - target port number (80 for example),
 * \param timeout        - operation timeout [ms],
 * \param http_header    - http header to send to remote host,
 * \param http_data      - http data to send to remote host,
 * \param http_recv_data - received data.
 * \return positive number or 0 - data offset (received HTTP header size),
 *  -1 - can not connect,
 *  -2 - site redirect (http_recv_data contains new location),
 *  -3 - Bad request,
 *  -4 - Unauthorized,
 *  -5 - Not found.
 */
int sys_net_http(const char *target, int port, int timeout, String *http_header, String *http_data, String *http_recv_data )
{
	int answer_code=0, bytes_left=0, offset = 0, last_line = 0, last_pos = 0, header = 0, content_length = -1, i,j,k,len, socket_fd;
	char *location = NULL,*pt;
	cl_task_time ms;

	ms = cl_task_get_stamp();

	sys_net_debug("Connecting to %s:%d\n",target,port);
	socket_fd = sys_net_open_timeout(target, port, timeout, 1);
	if (socket_fd < 0) {return -1;}
	/* Send HTTP header */
	if (http_header) {
		sys_net_debug("Write header\n");
		if (send(socket_fd, string_str(http_header), string_length(http_header),0) != string_length(http_header)) {
			ERROR_HARD("HTTP header send error");
			sys_net_close(socket_fd,0);
			return -1;
		}
	}
	/* Send HTTP data */
	if (http_data) {
		sys_net_debug("Write Data\n");
		if (send(socket_fd, string_str(http_data), string_length(http_data),0) != string_length(http_data)) {
			ERROR_HARD("HTTP data send error");
			sys_net_close(socket_fd,0);
			return -1;
		}
	}
	if (!http_recv_data) {sys_net_close(socket_fd,1);return 0;}
	/* Read data back from HTTP server */
	shutdown(socket_fd, SHUT_WR);
	sys_net_debug("Read start\n");
	string_clear(http_recv_data);
	timeout *= 2;

	for (;;) {
		if ((header == 2) && (content_length>-1)) {
			last_line = (bytes_left>HTTP_MAX_BLOCK)?HTTP_MAX_BLOCK:bytes_left;
			len = sys_net_read(socket_fd, string_buf(http_recv_data, (HTTP_MAX_BLOCK+1)), HTTP_MAX_BLOCK, timeout);
			if (len > 0) {bytes_left-=len;}
		} else {
			len = sys_net_read(socket_fd, string_buf(http_recv_data, (HTTP_MAX_BLOCK+1)), HTTP_MAX_BLOCK, timeout);
		}
		if (len <= 0) break;
		if ((cl_task_get_stamp() - ms) > timeout) {
			ERROR_HARD("HTTP operation TIMEOUT!");
			break;
		}
		string_buf_commit(http_recv_data, len );

		if (header == 0) {
			/* Detect HTTP header */
			if (string_starts_with(http_recv_data, "HTTP/")) {
				sys_net_debug("Got header :-)\n");
				header = 1;
			}
		}
		if (header == 1) {
			/* Parse HTTP header data */
			pt = string_str(http_recv_data);
			for (i = last_pos; i < string_length(http_recv_data); ++i) {
				if (pt[i] == '\r') pt[i]='\0';
				else if (pt[i] == '\n') {
					pt[i] = '\0';
					sys_net_debug("Got line <%s>\n", &pt[last_line]);
					if (pt[last_line]=='\0') {
						/* End of Header */
						header = 2;
						offset = (i + 1);
						bytes_left = content_length + offset - string_length(http_recv_data);
						sys_net_debug("End of header bytes_left = %d\n",bytes_left);
						break;
					} else if (string_starts_with_offset( http_recv_data,"Content-Length:", last_line )) {
						if (sscanf(&pt[last_line+15],"%d", &content_length)==1) {
							sys_net_debug("Got content length = %d\n", content_length);
						} else {
							content_length = -1;
						}
					} else if (string_starts_with_offset( http_recv_data,"Location:", last_line )) {
						/* Save location */
						location = &pt[last_line] + 9;
						while (isspace(*location)) location++;
						sys_net_debug("Got location = %s\n",location);
					} else if (string_starts_with_offset( http_recv_data,"HTTP/", last_line )) {
						j = last_line + 5;
						/* Get start point */
						while ((j < i) && (!isspace(pt[j]))) j++;
						/* Get end point */
						j++;
						k=j;
						while ((k < i) && (!isspace(pt[k]))) k++;
						pt[k]='\0';
						if (sscanf(&pt[j],"%d",&answer_code)!=1) answer_code=0;
						sys_net_debug("Got answer code = %d\n",answer_code);
					}
					last_line=i+1;
				}
			}
		}
		if ((header==2) && (content_length>-1) && (bytes_left == 0)) break;
	}
	sys_net_close(socket_fd,0);

	if (header) {
		/* Analize answer code */
		switch (answer_code) {
			case 307:
			case 302:
			case 301: {
				if (location) {
					pt = strdup(location);
					string_clear(http_recv_data);
					cstring_add(http_recv_data,pt);
					sys_net_debug("Page moved to <%s>\n",pt);
					free(pt);
					return -2;
				}
			} break;
			case 200: /* OK */ break;
			case 202: /* ACCEPTED */ break;
			case 204: /* No Content */   {string_clear(http_recv_data); return 0;} break;
			case 400: /* Bad request */  {string_clear(http_recv_data); return -3;} break;
			case 401: /* Unauthorized */ {string_clear(http_recv_data); return -4;} break;
			case 404: /* Not found */    {string_clear(http_recv_data); return -5;} break;
			case 0:   /* No HTTP header found - may by OK */ break;
			default: {sys_net_debug("Unimplemented HTTP code = %d\n", answer_code);} break;
		}
	}
	sys_net_debug("All done, offset = %d, time = %d [ms]\n",offset, (int)(cl_task_get_stamp() - ms));
	return offset;
}
//====================================================================================================

#ifdef SYS_NET_USE_SSL

/*!
 * \brief Perform HTTPS xfer.
 * \param target         - target host (name or ip),
 * \param port           - target port number (80 for example),
 * \param timeout        - operation timeout [ms],
 * \param http_header    - http header to send to remote host,
 * \param http_data      - http data to send to remote host,
 * \param http_recv_data - received data.
 * \return positive number or 0 - data offset (received HTTP header size),
 *  -1 - can not connect,
 *  -2 - site redirect (http_recv_data contains new location),
 *  -3 - Bad request,
 *  -4 - Unauthorized,
 *  -5 - Not found.
 */
int sys_net_https(const char *target, int port, int timeout, String *http_header, String *http_data, String *http_recv_data )
{
	int answer_code=0, bytes_left=0, offset=0, last_line=0, last_pos=0, header=0, content_length=-1, i,j,k,len, socket_fd;
	char *location = NULL,*pt;
	cl_task_time ms;
	SSL* ssl;

	ms = cl_task_get_stamp();

	/* Connect to host */
	sys_net_debug("Connecting to %s:%d\n",target,port);
	ssl = sys_net_open_ssl_timeout(target, port, timeout, 1);
	if (!ssl) {return -1;}
	socket_fd = SSL_get_fd(ssl);

	/* Send HTTP header */
	if (http_header) {
		sys_net_debug("Write header\n");
		if (SSL_write(ssl, string_str(http_header), string_length(http_header)) != string_length(http_header)) {
			ERROR_HARD("HTTPS header send error");
			sys_net_ssl_close(ssl,socket_fd, 0);
			return -1;
		}
	}
	/* Send HTTP data */
	if (http_data) {
		sys_net_debug("Write data\n");
		if (SSL_write(ssl, string_str(http_data), string_length(http_data)) != string_length(http_data)) {
			ERROR_HARD("HTTP data send error");
			sys_net_ssl_close(ssl,socket_fd, 0);
			return -1;
		}
	}
	if (!http_recv_data) {sys_net_ssl_close(ssl,socket_fd,1);return 0;}
	/* Read data back from HTTP server */
	shutdown(socket_fd, SHUT_WR);
	string_clear(http_recv_data);
	timeout *= 2;

	for (;;) {
		if ((header == 2) && (content_length>-1)) {
			last_line = (bytes_left>HTTP_MAX_BLOCK)?HTTP_MAX_BLOCK:bytes_left;
			len = sys_net_ssl_read(ssl, socket_fd, string_buf(http_recv_data, (HTTP_MAX_BLOCK+1)), HTTP_MAX_BLOCK, timeout);
			if (len > 0) {bytes_left-=len;}
		} else {
			len = sys_net_ssl_read(ssl, socket_fd, string_buf(http_recv_data, (HTTP_MAX_BLOCK+1)), HTTP_MAX_BLOCK, timeout);
		}
		if (len <= 0) break;
		if ((cl_task_get_stamp() - ms) > timeout) {
			ERROR_HARD("HTTP operation TIMEOUT!");
			break;
		}

		/* Got some data - process data */
		string_buf_commit(http_recv_data, len );

		if (header == 0) {
			/* Detect HTTP header */
			if (string_starts_with(http_recv_data, "HTTP/")) {
				sys_net_debug("Got header :-)\n");
				header = 1;
			}
		}
		if (header == 1) {
			/* Parse HTTP header data */
			pt = string_str(http_recv_data);
			for (i = last_pos; i < string_length(http_recv_data); ++i) {
				if (pt[i] == '\r') pt[i]='\0';
				else if (pt[i] == '\n') {
					pt[i] = '\0';
					sys_net_debug("Got line <%s>\n", &pt[last_line]);
					if (pt[last_line]=='\0') {
						/* End of Header */
						header = 2;
						offset = (i + 1);
						bytes_left = content_length + offset - string_length(http_recv_data);
						sys_net_debug("End of header bytes_left = %d\n",bytes_left);
						break;
					} else if (string_starts_with_offset( http_recv_data,"Content-Length:", last_line )) {
						if (sscanf(&pt[last_line+15],"%d", &content_length)==1) {
							sys_net_debug("Got content length = %d\n", content_length);
						} else {
							content_length = -1;
						}
					} else if (string_starts_with_offset( http_recv_data,"Location:", last_line )) {
						/* Save location */
						location = &pt[last_line] + 9;
						while (isspace(*location)) location++;
						sys_net_debug("Got location = %s\n",location);
					} else if (string_starts_with_offset( http_recv_data,"HTTP/", last_line )) {
						j = last_line + 5;
						/* Get start point */
						while ((j < i) && (!isspace(pt[j]))) j++;
						/* Get end point */
						j++;
						k=j;
						while ((k < i) && (!isspace(pt[k]))) k++;
						pt[k]='\0';
						if (sscanf(&pt[j],"%d",&answer_code)!=1) answer_code=0;
						sys_net_debug("Got answer code = %d\n",answer_code);
					}
					last_line=i+1;
				}
			}
		}
		if ((header==2) && (content_length>-1) && (bytes_left == 0)) break;
	}
	sys_net_ssl_close(ssl,socket_fd, 1);

	if (header) {
		/* Analize answer code */
		switch (answer_code) {
			case 307:
			case 302:
			case 301: {
				if (location) {
					pt = strdup(location);
					string_clear(http_recv_data);
					cstring_add(http_recv_data,pt);
					sys_net_debug("Page moved to <%s>\n",pt);
					free(pt);
					return -2;
				}
			} break;
			case 200: /* OK */ break;
			case 202: /* ACCEPTED */ break;
			case 204: /* No Content */   {string_clear(http_recv_data); return 0;} break;
			case 400: /* Bad request */  {string_clear(http_recv_data); return -3;} break;
			case 401: /* Unauthorized */ {string_clear(http_recv_data); return -4;} break;
			case 404: /* Not found */    {string_clear(http_recv_data); return -5;} break;
			case 0:   /* No HTTP header found - may by OK */ break;
			default: {sys_net_debug("Unimplemented HTTP code = %d\n", answer_code);} break;
		}
	}
	sys_net_debug("All done, offset = %d, time = %d [ms]\n",offset, (int)(cl_task_get_stamp() - ms));
	return offset;
}
//====================================================================================================

#endif
