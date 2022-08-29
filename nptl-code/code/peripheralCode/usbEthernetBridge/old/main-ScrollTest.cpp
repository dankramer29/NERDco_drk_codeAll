//---------------------------------------------------------------------------
// Includes
//---------------------------------------------------------------------------


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
#include <fcntl.h> // File control definitions
#include <linux/input.h>


#define GLOVE_DEVICE "/dev/usb/hiddev0"
#define MOUSE_RELATIVE 1
#define MOUSE_ABSOLUTE 2

#define LOCAL_SERVER_PORT 1001
#define CLIENT_PORT 1002
#define MAX_PACKET_LEN 1400
#define DATA_BUFFER_LEN 500


///// Globals
int imu_fd = -1;
//~ int glove_fd = -1;
struct imuSensorData imuData;
unsigned short gloveData[5];
int32_t mouseData[6];
int mouseMode = 0;
pthread_t imuThread;
pthread_t gloveThread;
pthread_t mouseThread;
fdGlove* pGlove = NULL;

int mouse_fd = -1;

pthread_mutex_t imuDataMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t gloveDataMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mouseDataMutex = PTHREAD_MUTEX_INITIALIZER;

struct timeval gloveTime, imuTime, mouseTime;

void * mouseReaderThread(void *)
{
	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);

	struct input_event ev;
	int rd = 0;
	
	
	pthread_mutex_lock(&mouseDataMutex);
	gettimeofday(&mouseTime, 0);
	pthread_mutex_unlock(&mouseDataMutex);
	
	while(1)
		{
			rd = read(mouse_fd, &ev, sizeof(struct input_event));
			if (rd < (int) sizeof(struct input_event)) {
				perror("Mouse: error reading \n");
				exit(1);
			}
			
			if(mouseMode == MOUSE_RELATIVE)
			{
				pthread_mutex_lock(&mouseDataMutex);
				
				if(ev.type == EV_REL)
					{
					 switch(ev.code) {
						case REL_X :
							mouseData[2] += ev.value;
							break;
						case REL_Y :
							mouseData[3] += ev.value;
							break;
						case REL_WHEEL :
						  // wheel sign is inverted from movement sign
							mouseData[1] -= ev.value;
							break;
						case REL_HWHEEL :
							mouseData[0] += ev.value;
							break;
						}
					}
				else if(ev.type == EV_KEY)
					{
					 switch(ev.code) {
						case BTN_LEFT :
							mouseData[4] = ev.value;
							break;
						case BTN_RIGHT :
							mouseData[5] = ev.value;
							break;
						}
					}
				pthread_mutex_unlock(&mouseDataMutex);
			}
			else if(mouseMode == MOUSE_ABSOLUTE)
			{
				pthread_mutex_lock(&mouseDataMutex);
		
				if(ev.type == EV_ABS)
					{
					 switch(ev.code) {
						case ABS_X :
							mouseData[0] = ev.value;
							break;
						case ABS_Y :
							mouseData[1] = ev.value;
							break;
						case ABS_MT_TOUCH_MAJOR :
							mouseData[2] = ev.value;
							break;
						case ABS_TOOL_WIDTH :
							mouseData[3] = ev.value;
							break;
						case ABS_MT_POSITION_X :
							mouseData[4] = ev.value;
							break;
						case ABS_MT_POSITION_Y :
							mouseData[5] = ev.value;
							break;
						}
					}
				pthread_mutex_unlock(&mouseDataMutex);
			}
		}
}


int main(int argc, char *argv[]) {
  
	int rc;
	
	// Mouse Initialization 
	if ((mouse_fd = open(argv[1], O_RDONLY)) < 0) {
		printf("Error opening mouse \n");
		return 1;
	}
	if(atoi(argv[2]) == 1)
	{
		printf("Entering RELATIVE position mode with mouse device %s\n", argv[1]);
		mouseMode= MOUSE_RELATIVE;
	}
	else if(atoi(argv[2]) == 2)
	{
		printf("Entering ABSOLUTE position mode with mouse device %s\n", argv[1]);
		mouseMode= MOUSE_ABSOLUTE;
	}	



   /* Spawn Mouse thread */
   printf("Starting Mouse Thread \n");
   rc = pthread_create(&mouseThread, NULL, mouseReaderThread, NULL);
   if(rc)
   {
	   printf("Mouse thread failed to initialize!!\n");
   }


  /* server infinite loop */
  while(1) {
    usleep(100);
	// then copy mouse data
	//pthread_mutex_lock(&mouseDataMutex);
	printf("M %d %d %d %d %d %d \n", mouseData[0], mouseData[1], mouseData[2], mouseData[3], mouseData[4], mouseData[5]);
	
   
  }
  
return 0;

}
