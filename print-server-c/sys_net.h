/*
 * Network helper
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <sys/types.h>
#include <sys/socket.h>         /* bind(), listen(), accept()      */
#include <sys/wait.h>           /* waitpid()                       */
#include <unistd.h>             /* fork()                          */
#include <signal.h>             /* signal()                        */
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <sys/poll.h>
#include <netdb.h>
#include "cl_inline.h"
#include "estring.h"
#include "cl_task.h"
#include <sys/epoll.h>

#if defined(CONFIG_WWW_RX)
#define SYS_NET_USE_SSL
#endif

#ifdef SYS_NET_USE_SSL
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif
#include <errno.h>

#if 1
#define sys_net_debug(fmt, args...) printf("%s: " fmt, __FUNCTION__ ,## args)
#else
#define sys_net_debug(fmt, args...)
#endif

#define REPORT_ERROR(nr,fmt,args...) {ERROR_HARD(fmt, ## args); return -nr;}
//#define REPORT_ERROR(nr,fmt,args...) {return -nr;}

void sys_net_init(void);
void sys_net_destroy(void);

__fn_inline int sys_net_connect_time (int sock, struct sockaddr *addr, int size_addr, int timeout);
__fn_inline int sys_net_open_timeout(const char *target, int port, int timeout, int set_keep_alive);
__fn_inline int sys_net_open_server(const char *target, int port, int set_keep_alive);
__fn_inline void sys_net_set_user_timeout(int fd, int timeout);

__fn_inline void sys_net_close(int handle, int flush);

__fn_inline int sys_net_accept(int sock);
__fn_inline int sys_net_acceptl(int sock, struct sockaddr_in *cli_addrstr);

__fn_inline int sys_net_read(int sock, char *data, int size, int timeout);

__fn_inline void sys_net_set_NDELAY(int fd, int ndelay);
__fn_inline void sys_net_set_CORK(int fd, int cork);
__fn_inline int sys_net_setNonBlocking ( int fd );
__fn_inline int sys_net_setBlocking ( int fd );

int sys_net_get(const char *src_url, int timeout, String *http_recv_data );
int sys_net_http(const char *target, int port, int timeout, String *http_header, String *http_data, String *http_recv_data );

#ifdef SYS_NET_USE_SSL

__fn_inline SSL *sys_net_open_ssl_timeout(const char *target, int port, int timeout, int set_keep_alive);
__fn_inline void sys_net_ssl_close(SSL* ssl, int fd, int flush);
__fn_inline int sys_net_ssl_read(SSL* ssl, int sock, char *data, int size, int timeout);
int sys_net_https(const char *target, int port, int timeout, String *http_header, String *http_data, String *http_recv_data );

#endif


/*!
 * \brief Set user timeout on connected socket.
 * \param fd - socket handle,
 * \param timeout - timeout in [ms]
 */
__fn_inline void sys_net_set_user_timeout(int fd, int timeout)
{
#if defined(TCP_USER_TIMEOUT)
	setsockopt (fd, SOL_TCP, TCP_USER_TIMEOUT, (char*) &timeout, sizeof (timeout));
#endif
}
//==========================================================================================

/*!
 * \brief Set keepalive.
 * \param fd - socket fd,
 * \param set_keep_alive - configure keepalive socket parameters (0 - no keepalive, 1 - long, 2 - short).
 */
__fn_inline void sys_net_set_keepalive(int fd, int set_keep_alive)
{
	int on = 1,idle = 30,interval = 5,count = 5; /* Long keep alive */
	if (set_keep_alive == 2) {
		/* Short keep alive */
		on = 1;idle = 2;interval = 2;count = 1;
	}
	if (set_keep_alive) {
		if (setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE,(char *) &on, sizeof(on)) < 0) {ERROR_WARNING("Can not set SO_KEEPALIVE flag");}
		if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPIDLE,(char *) &idle, sizeof(idle)) < 0) {ERROR_WARNING("Can't set TCP_KEEPIDLE");}
		if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPINTVL,(char *) &interval, sizeof(interval)) < 0) {ERROR_WARNING("Can't set TCP_KEEPINTVL");}
		if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPCNT,(char *) &count, sizeof(count)) < 0) {ERROR_WARNING("Can't set TCP_KEEPCNT!\n");}
	}
}
//==========================================================================================


/*!
 * \brief Connect to client, break if timeout occurs.
 * \param sock - client socket,
 * \param addr - server address,
 * \param size_addr - server address struct size,
 * \param timeout - connection timeout in [ms].
 */
__fn_inline int sys_net_connect_time (int sock, struct sockaddr *addr, int size_addr, int timeout)
{
	struct timeval tval;
	int flags, n, error = 0;
	fd_set rset, wset;

	errno = 0;
	if (timeout==0) return connect( sock, addr, size_addr );

	flags = fcntl (sock, F_GETFL, 0);
	fcntl (sock, F_SETFL, flags | O_NONBLOCK);      // set the socket as nonblocking IO

	FD_ZERO (&rset);
	FD_ZERO (&wset);
	FD_SET (sock, &rset);
	FD_SET (sock, &wset);
	tval.tv_sec = (timeout/1000);
	tval.tv_usec = (timeout%1000)*1000;

	if ((n = connect (sock, addr, size_addr)) < 0) {// we connect, but it will return soon
		if ( errno != EINPROGRESS ) {REPORT_ERROR(1, "ESOCK - Suck Connect");}
	}
	if ( n != 0 ) {
		if ( (n = select(sock + 1, &rset, &wset, NULL, timeout ? &tval : NULL)) == 0) {
			close ( sock );
			errno = ETIMEDOUT;
			REPORT_ERROR(1, "ESOCK - Connect Timeout");
		}
		if (FD_ISSET(sock, &rset) || FD_ISSET(sock, &wset)) {
			int len = sizeof( error );
			if (getsockopt ( sock, SOL_SOCKET, SO_ERROR, &error, &len ) < 0) {REPORT_ERROR(1, "ESOCK - getsockopt");}
		} else {
			REPORT_ERROR(1, "ESOCK - Strange bug");
		}
	}
	n = connect( sock, addr, size_addr );
	/* We change the socket options back to blocking IO */
	fcntl (sock, F_SETFL, flags);
	return n;
}
//==========================================================================================

/*!
 * \brief Connect to server using tcp/ip protocol.
 * \param target - server name,
 * \param port - port number,
 * \param timeout - timeout in [ms],
 * \param set_keep_alive - configure keepalive socket parameters (0 - no keepalive, 1 - long, 2 - short).
 * \return - socket handle, result<=0 => error.
 *
 * example:
 * \code
 *   int sock=sys_net_open_timeout("localhost",1214,1000); // open client socket (timeout=1000ms),
 *   if (sock>0) {
 *     write(sock,"ala i kot\n", 10);
 *     sys_net_close (sock);
 *   }
 * \endcode
 */
__fn_inline int sys_net_open_timeout(const char *target, int port, int timeout, int set_keep_alive)
{
	struct sockaddr_in serv_addrstr;
	struct hostent *hn;
	int serv_len, sock, maxtry = 2;

	timeout/=3;
try_to_connect_again:
	sock = socket(AF_INET, SOCK_STREAM, 0);
	if (sock < 0) REPORT_ERROR(1, "ESOCK - Can't create socket!");

	hn = gethostbyname(target);
	if (hn == NULL) REPORT_ERROR(2, "ESOCK - Can't resolve server name \"%s\"", target);

	serv_addrstr.sin_family = AF_INET;
	serv_addrstr.sin_port = htons(port);
	serv_addrstr.sin_addr = *((struct in_addr *)hn->h_addr);
	serv_len = sizeof(serv_addrstr);

	if (sys_net_connect_time(sock, (struct sockaddr *)&serv_addrstr, serv_len, timeout) == 0) {
		/* We are connected - set keepalive flags */
		sys_net_set_keepalive(sock, set_keep_alive);
		sys_net_debug("Connected sock = %d\n", sock);
		return sock;
	}
	sys_net_close(sock, 0);
	if (maxtry) {
		maxtry--;
		goto try_to_connect_again;
	}
	REPORT_ERROR(3, "ESOCK - Can't connect to host=%s port=%d!", target, port);
}
//==========================================================================================

/*!
 * \brief Close network socket.
 * \brief flush (0 - no flush, 1 - flush WR and RD, 2 - flush WR),
 */
__fn_inline void sys_net_close(int handle, int flush)
{
	fd_set s_fd;
	struct timeval tv;
	int retval;
	char buf[256];

	if (handle > -1) {
		if (flush) {
			shutdown(handle, SHUT_WR);
		}
		if (flush == 1) {
			/* Properly wait for remote to closed */
			FD_ZERO(&s_fd) ;
			FD_SET(handle, &s_fd);
			do {
				tv.tv_sec = 1;
				tv.tv_usec = 0;
				retval = select(handle + 1, &s_fd, NULL, NULL, &tv);
			} while (retval > 0 && (read(handle, buf, 255) > 0));
			shutdown(handle, SHUT_RD);
		}
		close(handle);
	}
}
//==========================================================================================

/*!
 * \brief Accept client.
 * \param sock - client socket.
 */
__fn_inline int sys_net_accept(int sock)
{
	struct sockaddr_in cli_addrstr;
	socklen_t cli_len;
	cli_len = sizeof(cli_addrstr);
	return accept(sock, (struct sockaddr *)&cli_addrstr, &cli_len);
}
//==========================================================================================

/*!
 * \brief Accept client.
 * \param sock - client socket.
 * \param cli_addrstr - pointer to address structure where to store client information.
 */
__fn_inline int sys_net_acceptl(int sock, struct sockaddr_in *cli_addrstr)
{
	socklen_t cli_len;
	int res;

	cli_len = sizeof(struct sockaddr_in);
	res = accept(sock, (struct sockaddr *)cli_addrstr, &cli_len);
	return res;
}
//==========================================================================================



/*!
 * \brief Open server socket.
 * \param target - server name (if empty - any local interface),
 * \param port - port number,
 * \param set_keep_alive - configure keepalive socket parameters.
 * \return - socket handle, result<=0 => error.
 */
__fn_inline int sys_net_open_server(const char *target, int port, int set_keep_alive)
{
	struct sockaddr_in lsocket;
	int fd, on = 1;
	/* create the socket right now */
	/* inet_addr() returns a value that is already in network order */
	memset(&lsocket, 0, sizeof(lsocket));
	lsocket.sin_family = AF_INET;
	lsocket.sin_addr.s_addr = INADDR_ANY;
	lsocket.sin_port = htons(port);
	fd = socket(AF_INET, SOCK_STREAM, 0);
	if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (void *)&on, sizeof(on)) < 0) {ERROR_WARNING("Can not set SO_REUSEADDR flag");}
	sys_net_set_keepalive(fd, set_keep_alive);
	setsockopt( fd, SOL_SOCKET, SO_REUSEADDR, (void *)&on, sizeof(on) ) ;
	bind( fd, (struct sockaddr *)&lsocket, sizeof(lsocket) );
	listen( fd, 32 );
	signal( SIGCHLD, SIG_IGN );   /* prevent zombie (defunct) processes */
	signal( SIGPIPE, SIG_IGN );
	return fd;
}
//==========================================================================================

/*!
 * \brief Read data from socket.
 * \param sock - valid socket handle,
 * \param data - buffer for data read,
 * \param timeout - timeout in ms.
 */
__fn_inline int sys_net_read(int sock, char *data, int size, int timeout)
{
	struct pollfd fds; // poll
	int bytes = 0;
	int count = 0;

	fds.fd      = sock;
	fds.events  = POLLIN;
	fds.revents = 0;

	while (poll(&fds, 1, timeout) > 0) {
		bytes = recv(sock, (data + count), (size - count), 0);
		if (bytes <= 0) {break;}
		count += bytes;
		if (count == size) return count;
		if (count > size) {ERROR_HARD("ESOCK - More data readed (readed=%d, size=%d)!!", count, size);return count;};
		fds.revents = 0;
	}
	return count;
}
//==========================================================================================

/*!
 * \brief Set NDELAY flag.
 * \param fd - socket handle,
 * \param ndelay - ndelay flag value.
 */
__fn_inline void sys_net_set_NDELAY(int fd, int ndelay)
{
	setsockopt( fd, SOL_TCP, TCP_NODELAY, (void*)&ndelay, sizeof(ndelay) );
}
//==========================================================================================

/*!
 * \brief Set CORK (1 - set, 0 - end of data).
 * \param fd - socket handle,
 * \param cork - cork flag value.
 */
__fn_inline void sys_net_set_CORK(int fd, int cork)
{
	setsockopt( fd, IPPROTO_TCP, TCP_CORK, (void*)&cork, sizeof(cork) );
}
//==========================================================================================

/*!
 * \brief Set socket NONBLOCK flag.
 * \param fd - file descriptor.
 */
__fn_inline int sys_net_setNonBlocking ( int fd )
{
	int flags;
	if ( -1 == ( flags = fcntl ( fd, F_GETFL, 0 ) ) ) flags = 0;
	return fcntl ( fd, F_SETFL, flags | O_NONBLOCK | O_NDELAY );
}
//====================================================================================================

/*!
 * \brief Clear socket NONBLOCK flag.
 * \param fd - file descriptor.
 */
__fn_inline int sys_net_setBlocking ( int fd )
{
	int flags;
	if ( -1 == ( flags = fcntl ( fd, F_GETFL, 0 ) ) ) flags = 0;
	return fcntl ( fd, F_SETFL, flags & ( ~O_NONBLOCK ) );
}
//====================================================================================================


#ifdef SYS_NET_USE_SSL

extern SSL_CTX* __sys_net_ssl_ctx_client;  /* Client SSL context */

/*!
 * \brief Connect to server using tcp/ip and SSL protocol.
 * \param target - server name,
 * \param port - port number.
 * \return - pointer to SSL structure.
 *
 * example:
 * \code
 *   SSL *ssl=sys_net_open_ssl_timeout("localhost",1214,1000); // open client socket (timeout=1000ms),
 *   if (ssl) {
 *     SSL_write(ssl,"ala i kot\n", 10);
 *     sys_net_ssl_close(ssl, SSL_get_fd(ssl));
 *   }
 * \endcode
 */
__fn_inline SSL *sys_net_open_ssl_timeout(const char *target, int port, int timeout, int set_keep_alive)
{
	int ret, socket_fd;
	SSL *ssl;

	socket_fd = sys_net_open_timeout(target, port, timeout, set_keep_alive);
	if (socket_fd < 0) {return NULL;}

	/* Create SSL */
	ssl = SSL_new( __sys_net_ssl_ctx_client );
	if (!ssl) {
		ERROR_HARD("SSL_new error");
		sys_net_close(socket_fd, 0);
		return NULL;
	}
	SSL_set_fd(ssl, socket_fd);
	SSL_set_tlsext_host_name(ssl, "argos.wroc.pl");
	ret = SSL_connect(ssl);
	if (ret !=1 ) {
		ERROR_HARD("SSL_connect error (%d)",ret);
		sys_net_ssl_close(ssl, socket_fd, 0);
		return NULL;
	}
	return ssl;
}
//====================================================================================================

/*!
 * \brief Flush and close SSL socket
 * \param ssl - pinter to SSL structure,
 * \param fd - socket handle.
 */
__fn_inline void sys_net_ssl_close(SSL* ssl, int fd, int flush)
{
	SSL_shutdown(ssl);
	SSL_free(ssl);
	sys_net_close(fd, flush);
}
//====================================================================================================

/*!
 * \brief Read data from SSL socket.
 * \param ssl - pinter to SSL structure,
 * \param sock - valid socket handle,
 * \param data - buffer for data read,
 * \param timeout - timeout in ms.
 */
__fn_inline int sys_net_ssl_read(SSL* ssl, int sock, char *data, int size, int timeout)
{
	struct pollfd fds; // poll
	int bytes = 0;
	int count = 0;

	fds.fd      = sock;
	fds.events  = POLLIN;
	fds.revents = 0;

	while ((SSL_pending(ssl)>0) || (poll(&fds, 1, timeout) > 0)) {
		bytes = SSL_read(ssl, (data + count), size - count);
		if (bytes <= 0) {break;}
		count += bytes;
		if (count == size) return count;
		if (count > size) {ERROR_HARD("ESOCK - More data readed (readed=%d, size=%d)!!", count, size);return count;};
		fds.revents = 0;
	}
	return count;
}
//==========================================================================================

#endif
