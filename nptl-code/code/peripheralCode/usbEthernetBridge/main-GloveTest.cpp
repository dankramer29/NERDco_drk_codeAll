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

#define LOCAL_SERVER_PORT 1001
#define CLIENT_PORT 1002
#define MAX_PACKET_LEN 1400
#define DATA_BUFFER_LEN 500


///// Globals
unsigned short gloveData[5];
pthread_t gloveThread;
fdGlove* pGlove = NULL;


pthread_mutex_t gloveDataMutex = PTHREAD_MUTEX_INITIALIZER;

struct timeval gloveTime;





void * gloveReaderThread(void *)
{
	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
	
	unsigned short allGloveData[5];
	struct timeval gloveTimeTmp;
	int updateBytes = 0;
	
	while(1)
	{
		
		gettimeofday(&gloveTimeTmp, 0);
		fdGetSensorRawAll(pGlove, allGloveData);
			pthread_mutex_lock(&gloveDataMutex);
		
			gloveData[0] = allGloveData[FD_THUMBFAR];
			gloveData[1] = allGloveData[FD_INDEXFAR];
			gloveData[2] = allGloveData[FD_MIDDLEFAR];
			gloveData[3] = allGloveData[FD_RINGFAR];
			gloveData[4] = allGloveData[FD_LITTLEFAR];

			memcpy(&gloveTime, &gloveTimeTmp, sizeof(struct timeval));
		
			pthread_mutex_unlock(&gloveDataMutex);
		
			pthread_testcancel();
			usleep(500);
	}
}


int main(int argc, char *argv[]) {
  

	// Glove Initialization
	char gloveDevice[100] = GLOVE_DEVICE;
	 if (argc>=2) {
    	printf("\nAttempting to open glove A on %s .. ", argv[1] );
		gloveDevice[15] = argv[1][0];
//    	pGlove = fdOpen(argv[1]);
    	pGlove = fdOpen(gloveDevice);
    }
    else {
    	printf("\nAttempting to open glove A on %s .. ", GLOVE_DEVICE );
    	pGlove = fdOpen(gloveDevice);
    }

	if (pGlove == NULL)
	{
		printf("glove open failed.\n");
		return 1;
	}
	printf("succeeded.\n");

	if (pGlove == NULL)
	{
		printf("glove open failed.\n");
		return 1;
	}
	printf("succeeded.\n");



   /* Spawn Glove thread */
   printf("Starting Glove Thread \n");
   int rc = pthread_create(&gloveThread, NULL, gloveReaderThread, NULL);
   if(rc)
   {
	   printf("Glove thread failed to initialize!!\n");
   }
   

  /* server infinite loop */
  while(1) {
    usleep(100);
	unsigned short meanGlove;
	meanGlove = (gloveData[0]+ gloveData[1]+ gloveData[2]+ gloveData[3]+ gloveData[4])/5;
	printf("T:%d I:%d M:%d R:%d P:%d, Mean: %d \n", gloveData[0], gloveData[1], gloveData[2], gloveData[3], gloveData[4], meanGlove);
	
   
  }
  
return 0;

}
