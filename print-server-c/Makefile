#nom de l'executable
EXEC = print-server

SRC=$(wildcard *.c)
OBJ=$(SRC:.c=.o)

#-----------------------------------------------------------
#compilation :
CC = $(CROSS_COMPILE)gcc
STRIP = $(CROSS_COMPILE)strip
LIBS= -lm -lrt -lpthread

#option de debugage :
#OPT_Debug= -Wall -g -O2
OPT_Debug= 

# Set DMP FIFO rate to 20Hz to avoid overflows on 3d demo.  See comments in
# MPU6050_6Axis_MotionApps20.h for details.
# F = 200/(DDMP_FIFO_RATE + 1)
#the program is not fast enough to read DMP at 200Hz => DDMP_FIFO_RATE = 1

#CXXFLAGS = -std=c++11 
#CFLAGS += -Wall -Wextra -pedantic -std=c99

all:$(EXEC)

$(EXEC):$(OBJ)
	$(CC) $(CFLAGS) $(OPT_Debug) -o $@ $^ $(LIBS)
#	$(STRIP) $@

%.o: %.c
	$(CC) $(CFLAGS) $(OPT_Debug) -o $@ -c $^ $(LIBS)

FILE1 = /etc/default/print-server

install:
	cp -f ./print-server /usr/bin/
	cp -f ./systemd/print-server.service /etc/systemd/system/
	if test -d ${FILE1}; then \
		echo "${FILE1} already exists ..."; \
	else \
		echo "NOTE: edit /etc/default/print-server file to update paths!"; \
		cp -f ./systemd/print-server /etc/default/; \
	fi
	systemctl stop print-server
	systemctl daemon-reload
	systemctl enable print-server
	systemctl start print-server

uninstall:
	rm -f /usr/bin/print-server
	systemctl stop print-server
	systemctl disable print-server
	rm -f /etc/systemd/system/print-server.service


clean:
	rm -rf *.o *~ *.mod
	rm -rf $(EXEC)
