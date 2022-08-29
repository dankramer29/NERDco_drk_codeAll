#include <libusb.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h> /* close() */
#include <string.h> /* memset() */
#include <pthread.h>
#include "imu.h"
#include <fglove.h>
#include <sys/time.h>


int init_dataglove() {

	libusb_context *ctx = NULL;
	libusb_device **devs;
	int initval = libusb_init(&ctx);
	if (initval!=0) {
		printf("init error\n");
	}
	
	return 1;
}
