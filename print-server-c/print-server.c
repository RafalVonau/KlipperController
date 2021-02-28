/*
 * Server to controll 3D printer.
 *
 * Author: Rafal Vonau <rafal.vonau@gmail.com>
 #
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#include "sys_net.h"
#include <dlfcn.h>
#include <sys/types.h>
#include <dirent.h>
#include <termios.h>
#include <fcntl.h>
#include "errors_log.h"
#include "string.h"
#include "cl_memory.h"
#include "estring.h"
#include <unistd.h>
#include "timer.h"

#define BUFFER_SIZE (4095)
#define BUFFER_HALF (BUFFER_SIZE/2)

int __enable_debug = 0;

#define msg_error(fmt, args...) fprintf(stderr,"ERROR(%s):" fmt "\n", __FUNCTION__ ,## args);
#if 1
#define relay_debug(fmt, args...) if (__enable_debug) fprintf(stderr,"DEBUG(%s):" fmt "\n", __FUNCTION__ ,## args);
#else
#define relay_debug(fmt, args...)
#endif


typedef struct {
    int fd;                     /*!< Socket file handle.                                    */
    int epfd;                   /*!< Epoll file handle.                                     */
    int pos_wr;                 /*!< Write pointer.                                         */
    int pos_rd;                 /*!< Read pointer.                                          */
    char buf[BUFFER_SIZE+1];    /*!< Data buffer.                                           */
} sys_eth_relay_client_t;
//=====================================================================================================================

static int __printer_fd = -1;
static char *__uploads_dir;
static char *__klipper_cfg;
static char *__klipper_log;

/*!
 * \brief Free sys_eth_relay_client_t structure.
 * \param c - pointer to sys_eth_relay_client_t.
 */
__fn_inline void __sys_eth_relay_client_free(sys_eth_relay_client_t *c);
__fn_inline void __sys_eth_relay_client_free(sys_eth_relay_client_t *c)
{
	if (c) {
		cl_free(c);
	}
}
//=====================================================================================================================

/*!
 * \brief Close network socket.
 */
void sys_eth_relay_close_socket(sys_eth_relay_client_t *c);
void sys_eth_relay_close_socket(sys_eth_relay_client_t *c)
{
	if (!c) return;
	relay_debug("Socket is dead (fd: %d)", c->fd);
	epoll_ctl(c->epfd, EPOLL_CTL_DEL, c->fd, NULL);
	//shutdown ( c->fd, SD_SEND ); /* Flush data            */
	close( c->fd );
	__sys_eth_relay_client_free(c);
}
//=====================================================================================================================

/*!
 * \brief Send data to remote host.
 * \param c - pointer to sys_eth_relay_client_t.,
 * \param buf - data buffer,
 * \param len  - data count.
 * \return 1 - success, 0 - error.
 */
int sys_eth_relay_send(sys_eth_relay_client_t *c, const char *buf, int len);
int sys_eth_relay_send(sys_eth_relay_client_t *c, const char *buf, int len)
{
	return (send(c->fd,buf,len,0)==len)?1:0;
}
//==========================================================================================

/*!
 * \brief Delete file from filesystem.
 * \param n - pointer to file name.
 */
void unlink_file(const char *n)
{
	char buf[4096];
	sprintf(buf, "%s/%s",__uploads_dir,n);
	unlink(buf);
}
//==========================================================================================

/*!
 * \brief Get list of gcode files in JSON format.
 */
void construct_gcode_list(String *s, const char *dir)
{
	DIR *dirptr;
	struct dirent *dirent;
	int files, len, first = 1;

	// just calculate files in directory
	files = 0;
	string_clear(s);
	cstring_add(s, "{ \"list\":[");
	dirptr = opendir(dir);
	if (dirptr) {
		while ((dirent = readdir( dirptr )) != NULL ) {
			if ((dirent->d_type == DT_REG) && (strcmp(dirent->d_name, ".") != 0) && (strcmp(dirent->d_name, "..") != 0)) {
				len = strlen(dirent->d_name);
				if ((len > 6) &&
						(dirent->d_name[len-1] == 'e') && (dirent->d_name[len-2] == 'd') && (dirent->d_name[len-3] == 'o') &&
						(dirent->d_name[len-4] == 'c') && (dirent->d_name[len-5] == 'g') && (dirent->d_name[len-6] == '.')) {
					if (!first) cstring_add(s,","); else {first = 0;}
					cstring_add(s,"\"");
					string_add(s, dirent->d_name, len);
					cstring_add(s,"\"");
					files++;
				}
			}
		}
		closedir(dirptr);
	}
	cstring_add(s, "] }\n");
}
//==========================================================================================

/*!
 * \brief Configure RS port.
 * \param fd - file handle,
 * \param cfg - configuration structure.
 */
void configureRS1(int fd);
void configureRS1(int fd)
{
	struct termios options;

	/*Get the current options for the port*/
	tcgetattr(fd, &options);
	/*Set Baud rate*/
	cfsetispeed(&options, B4000000);
	cfsetospeed(&options, B4000000);

	/*Enable received and set local mode*/
	options.c_cflag |= (CLOCAL | CREAD);
	/*Set new options for port*/
	tcsetattr( fd, TCSANOW, &options );

	/*Set data bits*/
	options.c_cflag &= ~CSIZE;                   /* Mask the character size bits */
	options.c_cflag |= CS8;          /* Select 8 data bits */

	// Set parity
	options.c_cflag &= ~PARENB; // Disable parity
	// Set Stop bits
	options.c_cflag &= ~(CSTOPB);
	//options.c_cflag |= CSTOPB;

	/*Set RAW input*/
	options.c_lflag &= ~(ICANON | ECHO | ISIG);
	options.c_cflag &= ~CRTSCTS;
	/*Set Raw output*/
	options.c_oflag &= ~OPOST;
	/* RTS CTS controll */
	//options.c_cflag |= CRTSCTS;


	/*Set timeout to 1,5 sec*/

	//don't map CR LF
	options.c_iflag &= ~(INLCR | ICRNL | IGNBRK | IGNCR | IXON | IXOFF | IXANY);
	options.c_cc[VMIN] = 0;
	options.c_cc[VTIME] = 15;
	tcflush (fd, TCIFLUSH);
	// Set the new options for the port...
	tcsetattr(fd, TCSANOW, &options);
}
//==========================================================================================

/*!
 * \brief Read data from socket.
 * \param sock - valid socket handle,
 * \param data - buffer for data read,
 * \param timeout - timeout in ms.
 */
__fn_inline int printer_read(int sock, char *data, int size, int timeout)
{
	struct pollfd fds; // poll
	int count = 0;

	fds.fd      = sock;
	fds.events  = POLLIN;
	fds.revents = 0;

	if (poll(&fds, 1, timeout) > 0) {
		count = read(sock, (data + count), (size - count));
	}
	return count;
}
//==========================================================================================


/*!
 * \brief Execute printer commands.
 */
void execute_printer_commands(String *s, const char *cmd, const char *arg, const char *cmd2 )
{
	int count, len;
	char buf[4096];

	cstring_add(s, "{");
	if (__printer_fd < 0) {
		__printer_fd = open("/tmp/printer",O_RDWR | O_NOCTTY );
		if (__printer_fd < 0) goto cn_error;
		configureRS1(__printer_fd);
	}
	/* Prepare command */
	if (arg) {
		len = sprintf(buf, "%s %s\n",cmd,arg);
	} else {
		len = sprintf(buf, "%s\n",cmd);
	}
	/* Write command */
	tcflush (__printer_fd, TCIFLUSH);
	count = write(__printer_fd, buf, len);
	if (count != len) {
		/* Ponowne połączenie */
		close(__printer_fd);
		__printer_fd = open("/tmp/printer",O_RDWR | O_NOCTTY );
		if (__printer_fd < 0) goto cn_error;
		configureRS1(__printer_fd);
		tcflush (__printer_fd, TCIFLUSH);
		count = write(__printer_fd, cmd, len);
	}
	if (count != len) goto cn_error;
	/* Czytaj odpowiedź z drukarki */
	count = printer_read(__printer_fd, buf, 4095, 1000 );
	if (count < 2) goto cn_error;
	if (buf[count-1] == '\n') count--;
	string_add(s, buf, count);
	if (cmd2) {
		len = sprintf(buf, "%s\n",cmd2);
		tcflush (__printer_fd, TCIFLUSH);
		count = write(__printer_fd, buf, len);
		if (count != len) goto cn_error;
		count = printer_read(__printer_fd, buf, 4095, 1000 );
		if (count > 1) {
			if (buf[count-1] == '\n') count--;
			cstring_add(s, "},{");
			string_add(s, buf, count);
		}
	}
	cstring_add(s, "}\n");
	return;
cn_error:
	cstring_add(s, "ERROR}\n");
	if (__printer_fd > -1) close(__printer_fd);
	__printer_fd = -1;
}
//==========================================================================================

/*!
 * \brief Parsuj pojedynczą komendę (linię).
 */
int sys_eth_relay_parse_line(sys_eth_relay_client_t *c, char *line, int len);
int sys_eth_relay_parse_line(sys_eth_relay_client_t *c, char *line, int len)
{
	String s;
    char *ntab[16];
    int i, n, file, e, cnt;
    __u32 start, stop;

	string_init(&s);

    relay_debug("Got single line <%s>",line);
	ntab[0]=line;n=1;

	/* Podziel części oddzielone znakiem ':' */
	for (i=0;i<len; ++i) {if (line[i] == ':') {line[i] = '\0';if (n<15) {ntab[n++] = &line[i+1];}}}
    relay_debug("Parts = %d",n);

	if (n == 1) {
		if (!strcmp(ntab[0],"list")) {
            relay_debug("Generating file list.");
			construct_gcode_list(&s, __uploads_dir);
			sys_eth_relay_send(c, s.buf, s.poz);
			shutdown ( c->fd, 1 ); /* Flush data            */
			goto close_con_and_exit;
		} else if (!strcmp(ntab[0],"exit")) {
            relay_debug("Ending connection.");
			sys_eth_relay_send(c, "exit\n", 5);
			shutdown ( c->fd, 1 ); /* Flush data            */
			goto close_con_and_exit;
		} else if (!strcmp(ntab[0],"gettemp")) {
			string_clear(&s);
            relay_debug("Get information about temperatures.");
			cstring_add(&s,"gettemp:");
			execute_printer_commands(&s, "M105", NULL, NULL);
			sys_eth_relay_send(c, s.buf, s.poz);
		} else if (!strcmp(ntab[0],"printstatus")) {
			string_clear(&s);
            relay_debug("Get SD print status (M27).");
			cstring_add(&s,"printstatus:");
			execute_printer_commands(&s, "M27", NULL, NULL);
			sys_eth_relay_send(c, s.buf, s.poz);
		} else if (!strcmp(ntab[0],"status")) {
			string_clear(&s);
            relay_debug("Get info about temperatures and SD prin status (M105 M27).");
			cstring_add(&s,"status:");
			execute_printer_commands(&s, "M105", NULL, "M27");
			//cstring_add(&s,"status:{ok T:100.0/225.0 B:98.0 /110.0 T0:228.0/220.0 T1:150.0/185},{ok}\n");
			sys_eth_relay_send(c, s.buf, s.poz);
		} else if (!strcmp(ntab[0],"getlog")) {
			string_clear(&s);
            relay_debug("Get Klipper log file");
			string_add_from_file2(&s, __klipper_log);
			sys_eth_relay_send(c, s.buf, s.poz);
			goto close_con_and_exit;
		} else if (!strcmp(ntab[0],"getcfg")) {
			string_clear(&s);
            relay_debug("Get Klipper config file.");
			string_add_from_file2(&s, __klipper_cfg);
			sys_eth_relay_send(c, s.buf, s.poz);
			goto close_con_and_exit;
		} else if (!strcmp(ntab[0],"putcfg")) {
            relay_debug("Put Klipper config file.");
			string_clear(&s);
			/* Pobieranie danych  - najpierw zapisz dane z bufora jeśli są */
			len++;c->pos_rd += len;line += len;
			if (c->pos_rd < c->pos_wr) {
				string_add(&s, line, c->pos_wr - c->pos_rd);
			}
			/* Pobierz resztę pliku */
			i = recv(c->fd, c->buf,BUFFER_SIZE, 0);
			while (i > 0) {
				string_add(&s, c->buf, i);
				i = recv(c->fd, c->buf,BUFFER_SIZE, 0);
			}
			/* Zapisz plik na dysku */
            relay_debug("Save data to file <%s>, file size = %d", __klipper_cfg, string_length(&s));
			string_save_to_file2(&s, __klipper_cfg);
			goto close_con_and_exit;
		}
	} else if (n == 2) {
		if (!strcmp(ntab[0],"download")) {
            relay_debug("Downloading file <%s>", ntab[1]);
            start = timer_get_time();
			string_clear(&s);
            string_sprintf(&s, 4095, "%s/%s",__uploads_dir, ntab[1]);
			/* Pobieranie danych  - najpierw zapisz dane z bufora jeśli są */
            file=open(string_c_str(&s),O_CREAT | O_WRONLY | O_TRUNC,  S_IROTH | S_IRGRP | S_IRUSR | S_IWUSR );
            if (file < 0) {
                msg_error("File open error !\n");
                file = 1;
            }
            len++;c->pos_rd += len;line += len;e=0;
			if (c->pos_rd < c->pos_wr) {
                cnt = c->pos_wr - c->pos_rd;
                e = write(file, line, cnt);
                if (e != cnt) {msg_error("Write to file error!\n");}

			}
			/* Pobierz resztę pliku */
			i = recv(c->fd, c->buf,BUFFER_SIZE, 0);
			while (i > 0) {
                cnt = write(file, c->buf, i);
                if (i != cnt) {msg_error("Write to file error!\n");}
                e += cnt;
                i = recv(c->fd, c->buf, BUFFER_SIZE, 0);
			}
			/* Zapisz plik na dysku */
            stop = timer_get_time();
            relay_debug("Write data to file <%s>, file size = %d, elapsed = %d [ms]", string_c_str(&s), e, timer_get_elapsed(stop,start));
            close(file);
			goto close_con_and_exit;
		} else if (!strcmp(ntab[0],"print")) {
			string_clear(&s);
            relay_debug("Printing file <%s>", ntab[1]);
			cstring_add(&s,"print:");
			execute_printer_commands(&s, "M23", ntab[1], "M24");
			sys_eth_relay_send(c, s.buf, s.poz);
		} else if (!strcmp(ntab[0],"gcode")) {
			string_clear(&s);
            relay_debug("Execute gcode <%s>",ntab[1]);
			cstring_add(&s,"gcode:");
			execute_printer_commands(&s, ntab[1], NULL, NULL);
			sys_eth_relay_send(c, s.buf, s.poz);
		} else if (!strcmp(ntab[0],"unlink")) {
			string_clear(&s);
            relay_debug("Delete file <%s>", ntab[1]);
			cstring_add(&s,"unlink: ok\n");
			unlink_file(ntab[1]);
			sys_eth_relay_send(c, s.buf, s.poz);
		}
	} else if (n == 3) {
		if (!strcmp(ntab[0],"gcode")) {
			string_clear(&s);
            relay_debug("Execute gcode <%s> <%s>",ntab[1], ntab[2]);
			cstring_add(&s,"gcode:");
			execute_printer_commands(&s, ntab[1], ntab[2], NULL);
			sys_eth_relay_send(c, s.buf, s.poz);
		}
	}
	string_free(&s);
	return 1;
close_con_and_exit:
	sys_eth_relay_close_socket(c);
	string_free(&s);
	return 0;
}
//==========================================================================================

/*!
 * \brief Otrzymano nowe dane - parsuj je.
 */
void sys_eth_relay_parse_data(sys_eth_relay_client_t *c);
void sys_eth_relay_parse_data(sys_eth_relay_client_t *c)
{
	int i, len;
	/* Wyodrębnij całe linie kończące się na znaku '\n' */
	for (i=c->pos_rd;i<c->pos_wr; ++i) {
		if (c->buf[i] == '\n') {
			/* Got new line */
			c->buf[i] = '\0';
			if (!sys_eth_relay_parse_line(c, &c->buf[c->pos_rd], (i - c->pos_rd))) return;
			c->pos_rd = i+1;
		}
	}
	/* Kompaktuj wskaźniki jeśli trzeba */
	if (c->pos_rd >= c->pos_wr) {
		/* Całe dane zostały przetworzone - zeruj wskaźniki */
        relay_debug("All data consumed - clear pointers");
		c->pos_rd = 0;
		c->pos_wr = 0;
	} else {
		if ((c->pos_wr > BUFFER_HALF) && (c->pos_rd)) {
			/* Ponad połowa bufora zajęta - przenieś pozostałe dane na początek bufora */
			len = (c->pos_wr - c->pos_rd);
            relay_debug("Move data to the front (from %d size %d)",c->pos_rd, len);
			for (i=0;i<len;++i) {c->buf[i] = c->buf[c->pos_rd+i];}
			c->pos_rd = 0;
			c->pos_wr = len;
		}
	}
}
//==========================================================================================


/*!
 * \brief Wątek mostu przekaźnikowego.
 */
int main(int argc, char *argv[])
{
	struct epoll_event Edgvent;
	struct epoll_event *events;
	int i, fd_new, n,len, toRead, epfd, serverfd;
	socklen_t addr_size = sizeof(struct sockaddr_in);
	struct sockaddr_in remote_addr;
	sys_eth_relay_client_t *c, *nc;
	const int cnt = 100;
	__uploads_dir = "/home/pi/uploads";
	__klipper_cfg = "/home/pi/printer.cfg";
	__klipper_log = "/tmp/klippy.log";
    while ((i = getopt(argc, argv, "u:c:l:vh")) != -1)
		switch (i) {
		case 'u': __uploads_dir = strdup(optarg);break;
		case 'c': __klipper_cfg = strdup(optarg);break;
		case 'l': __klipper_log = strdup(optarg);break;
        case 'v': __enable_debug=1; break;
        case 'h': printf("print-server [-u upload_dir] [-c klipper_config_file] [-l klipper_log_file] [-v]\n\t-v - verbose mode.\n\n");return 0;break;
		default:break;
		}

	nc = (sys_eth_relay_client_t *)cl_malloc(sizeof(sys_eth_relay_client_t));
	if (!nc) {
        msg_error("Memory allocation error!");
		return -1;
	}

	/* Tworzenie listy epoll */
	epfd = epoll_create(cnt);
	events = calloc((cnt+1), sizeof(struct epoll_event));
	if (!events) {
        msg_error("Can not allocate memory for epoll!");
		close(epfd);
		cl_free(nc);
		return -1;
	}

	/* Twożenie gniazdka serwera */
	serverfd   = sys_net_open_server("127.0.0.1", 55555, 2);
	nc->fd     = serverfd;
	nc->epfd   = epfd;
	Edgvent.events   = EPOLLIN | EPOLLERR | EPOLLHUP; // | EPOLLET;
	Edgvent.data.ptr = nc;
	if (epoll_ctl((int)epfd, EPOLL_CTL_ADD, serverfd, &Edgvent) != 0) {
        msg_error("Can not add server socket to epoll!!\n");
		free(events);
		close(epfd);
		cl_free(nc);
		return -1;
	}
	printf("3D Printer server (up=<%s>, cfg=<%s> log=<%s>)\n",__uploads_dir, __klipper_cfg,__klipper_log);

	/* Pętla serwera */
	for (;;) {
		relay_debug("EPOLL wait");
		n = epoll_wait(epfd, events, (cnt+1), -1);
		relay_debug("Got events %d",n);
		for (i = 0; i < n; ++i) {
			relay_debug("Parse event %d, events = %d",i, events[i].events);
			c = (sys_eth_relay_client_t *)events[i].data.ptr;
			if (!c) continue;
			/* Case 1: Error condition */
			if (events[i].events & (EPOLLHUP | EPOLLERR)) {
				relay_debug("EPOLLHUP | EPOLLERR %d",c->fd);
				sys_eth_relay_close_socket(c);
				continue;
			}
			// Case 2: Server is receiving a connection request
			if (c->fd == serverfd) {
				fd_new = accept(serverfd, (struct sockaddr*)&remote_addr, &addr_size);
                relay_debug("New connection (address: %s, sock_fd: %d)", inet_ntoa(remote_addr.sin_addr), fd_new);
				if (fd_new < 0)  {
                    if (errno != EAGAIN && errno != EWOULDBLOCK) {msg_error("Error during accept!!");}
					continue;
				}
				nc = (sys_eth_relay_client_t *)cl_malloc(sizeof(sys_eth_relay_client_t));
				if (!nc) {
                    msg_error("Memeory allocation error (client structure)!");
					close(fd_new);
				} else {
					nc->fd     = fd_new;
					nc->epfd   = epfd;
					nc->pos_wr = 0;
					nc->pos_rd = 0;
					Edgvent.events   = EPOLLIN | EPOLLERR | EPOLLHUP;
					Edgvent.data.ptr = nc;
					sys_net_set_keepalive(fd_new, 2);
					if (epoll_ctl(epfd, EPOLL_CTL_ADD, fd_new, &Edgvent) == -1) {
                        msg_error("Can not add client socket to epoll (fd: %d)",fd_new);
						close(fd_new);
						if (nc) cl_free(nc);
					}
				}
				continue;
			}
			/* Case 3: One of the sockets has read data */
			if (events[i].events & (EPOLLIN)) {
				relay_debug("READ %d",c->fd);
				toRead = BUFFER_SIZE - c->pos_wr;
				if (toRead < 10) {
					c->pos_wr = 0;
					c->pos_rd = 0;
					toRead    = BUFFER_SIZE;
				}
				relay_debug("To read = %d",toRead);
				len = recv(c->fd, &c->buf[c->pos_wr], toRead, 0);
				relay_debug("Got = %d",len);
				if (len > 0) {
					c->pos_wr += len;
					sys_eth_relay_parse_data(c);
				} else {
					relay_debug("READ ERROR %d",c->fd);
					sys_eth_relay_close_socket(c);
				}
			}
		}
	}
	return 0;
}
//=====================================================================================================================
