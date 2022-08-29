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

//default glove device, overriden by argv[4]
#define GLOVE_DEVICE "/dev/usb/hiddev0"
//#define MOUSE_DEVICE "/dev/input/by-id/usb-0461_USB_Optical_Mouse-event-mouse"
#define MOUSE_DEVICE "/dev/input/by-id/usb-Razer_Razer_DeathAdder-event-mouse"
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

void * imuReaderThread(void *)
{
	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
	
	struct imuSensorData imuDataTmp;
	struct timeval imuTimeTmp;
	
	while(1)
	{
	    gettimeofday(&imuTimeTmp, 0);
		if(get_all_sensors(imu_fd, &imuDataTmp) == -1)
		{
			printf("IMU Thread: Error reading sensors\n");
			exit(1);
		}
		pthread_mutex_lock(&imuDataMutex);
		memcpy(&imuData, &imuDataTmp, sizeof(imuData));
		memcpy(&imuTime, &imuTimeTmp, sizeof(struct timeval));
		pthread_mutex_unlock(&imuDataMutex);
		pthread_testcancel();
		
		
	}
}




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
							mouseData[0] += ev.value;
							break;
						case REL_Y :
							mouseData[1] += ev.value;
							break;
						case REL_WHEEL :
							mouseData[2] += ev.value;
							break;
						}
					}
				else if(ev.type == EV_KEY)
					{
					 switch(ev.code) {
						case BTN_LEFT :
							mouseData[3] = ev.value;
							break;
						case BTN_MIDDLE :
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
  
  int sd, rc, n, flags;
  unsigned int cliLen;
  struct sockaddr_in cliAddr, servAddr;
  char inputPacket[MAX_PACKET_LEN];
  char outputPacket[MAX_PACKET_LEN];

	if(argc != 3 && argc != 4)
	{
		printf("Please call this program with 2 or 3 arguments: <program> <mouse device> <1 for relative pos / 2 for absolute pos>\n");
		return 1;
	}

	// Glove Initialization
	char gloveDevice[100] = GLOVE_DEVICE;
    if (argc>=4) {
    	printf("\nAttempting to open glove A on %s .. ", argv[3] );
    	pGlove = fdOpen(argv[3]);
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


	/*// IMU Initialization
	imu_fd = open_imu_serial_port();

	if(imu_fd == -1)
		return 1;
		
	
	configure_imu_serial_port(imu_fd);
	
	unsigned char command = 0xa5; // calibration command  
	*/
	
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


	// calibrate gyroscopes
	/*printf("Calibrating Gyroscopes, please keep IMU(s) still. Press enter when ready.\n");
	getchar();
	do_sync_transfer_wired(imu_fd, IMU_COMMAND_CALIBRATE_GYROS);
	printf("Calibration complete. Press enter to start data collection.  Angles will be tared.\n");
	getchar();
	
	do_sync_transfer_wired(imu_fd, IMU_COMMAND_TARE);*/



  /* socket creation */
  sd=socket(AF_INET, SOCK_DGRAM, 0);
  if(sd<0) {
    printf("%s: cannot open socket \n",argv[0]);
    exit(1);
  }

  /* bind local server port */
  servAddr.sin_family = AF_INET;
  servAddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servAddr.sin_port = htons(LOCAL_SERVER_PORT);
  rc = bind (sd, (struct sockaddr *) &servAddr,sizeof(servAddr));
  if(rc<0) {
    printf("%s: cannot bind port number %d \n", 
	   argv[0], LOCAL_SERVER_PORT);
    exit(1);
  }

	int broadcastPermission = 1;
    if (setsockopt(sd, SOL_SOCKET, SO_BROADCAST, (void *) &broadcastPermission, sizeof(broadcastPermission)) < 0)
    {
        printf("setsockopt() failed");
        exit(1);	
	}
  printf("%s: waiting for data on port UDP %u\n", 
	   argv[0],LOCAL_SERVER_PORT);


  flags = 0;

   /* Spawn IMU thread */
   /*printf("Starting IMU Thread \n");
   rc = pthread_create(&imuThread, NULL, imuReaderThread, NULL);
   if(rc)
   {
	   printf("IMU thread failed to initialize!!\n");
   }*/

   /* Spawn Glove thread */
   printf("Starting Glove Thread \n");
   rc = pthread_create(&gloveThread, NULL, gloveReaderThread, NULL);
   if(rc)
   {
	   printf("Glove thread failed to initialize!!\n");
   }
   
   /* Spawn Mouse thread */
   printf("Starting Mouse Thread \n");
   rc = pthread_create(&mouseThread, NULL, mouseReaderThread, NULL);
   if(rc)
   {
	   printf("Mouse thread failed to initialize!!\n");
   }

  struct timeval packetWriteTime;
  void * outputPacketPointer;
  /* server infinite loop */
  while(1) {
    
    /* init buffer */
    memset(inputPacket,0x0,MAX_PACKET_LEN);

    /* receive message */
    cliLen = sizeof(cliAddr);
    n = recvfrom(sd, inputPacket, MAX_PACKET_LEN, flags,
		 (struct sockaddr *) &cliAddr, &cliLen);

    if(n<0) {
      printf("%s: cannot receive data \n",argv[0]);
      continue;
    }
    
    uint32_t * xpcClock;
    xpcClock = (uint32_t *)inputPacket;
    
       
    /* print received message */
    /*printf("%s: from %s:UDP%u : %d \n", 
	   argv[0],inet_ntoa(cliAddr.sin_addr),
	   ntohs(cliAddr.sin_port),*xpcClock);
	*/
	// Copy xpc time to packet
	outputPacketPointer = outputPacket;
	memcpy(outputPacket, inputPacket, sizeof(uint32_t));
	outputPacketPointer+= sizeof(uint32_t);
	
	// then copy imu data
	pthread_mutex_lock(&imuDataMutex);
	memcpy(outputPacketPointer, &imuData, sizeof(imuData));
	outputPacketPointer+= sizeof(imuData);
	
	gettimeofday(&packetWriteTime, 0);
	float dataAge = (float(packetWriteTime.tv_sec - imuTime.tv_sec)) * 1000 + (float(packetWriteTime.tv_usec - imuTime.tv_usec))/1000;
	memcpy(outputPacketPointer, &dataAge, sizeof(dataAge));
	outputPacketPointer+= sizeof(dataAge);
	
	pthread_mutex_unlock(&imuDataMutex);

	

	// then copy glove data
	pthread_mutex_lock(&gloveDataMutex);
	memcpy(outputPacketPointer, gloveData, 5*sizeof(unsigned short));
	outputPacketPointer += 5*sizeof(unsigned short);
	
	gettimeofday(&packetWriteTime, 0);
	dataAge = (float(packetWriteTime.tv_sec - gloveTime.tv_sec)) * 1000 + (float(packetWriteTime.tv_usec - gloveTime.tv_usec))/1000;
	memcpy(outputPacketPointer, &dataAge, sizeof(dataAge));
	outputPacketPointer+= sizeof(dataAge);
    
	pthread_mutex_unlock(&gloveDataMutex);

    // then copy mouse data
	pthread_mutex_lock(&mouseDataMutex);
	memcpy(outputPacketPointer, mouseData, 6*sizeof(int32_t));
	outputPacketPointer += 6*sizeof(int32_t);
	printf("M %d %d %d %d %d %d      G %d %d %d %d %d       I %2.2f %2.2f %2.2f\n", mouseData[0], mouseData[1], mouseData[2], mouseData[3], mouseData[4], mouseData[5], gloveData[0], gloveData[1], gloveData[2], gloveData[3], gloveData[4], imuData.accel[0], imuData.accel[1], imuData.accel[2]);
	
	if(mouseMode == MOUSE_RELATIVE)
	{
		mouseData[0] = 0;
		mouseData[1] = 0;
		mouseData[2] = 0;
	}
	
	gettimeofday(&packetWriteTime, 0);
	dataAge = (float(packetWriteTime.tv_sec - mouseTime.tv_sec)) * 1000 + (float(packetWriteTime.tv_usec - mouseTime.tv_usec))/1000;
	memcpy(outputPacketPointer, &dataAge, sizeof(dataAge));
	outputPacketPointer+= sizeof(dataAge);

    memcpy(&mouseTime, &packetWriteTime, sizeof(struct timeval));
    
	pthread_mutex_unlock(&mouseDataMutex);



    // get laptop time
	gettimeofday(&packetWriteTime, 0);
	memcpy(outputPacketPointer, &packetWriteTime, sizeof(struct timeval));
	outputPacketPointer+= sizeof(struct timeval);

	
	
	cliAddr.sin_port = htons(CLIENT_PORT);
	inet_aton("192.168.30.255", &cliAddr.sin_addr);
    n = sendto(sd,outputPacket,n,flags,(struct sockaddr *)&cliAddr,cliLen);
	//printf("Sendto returned %d \n", n);
    
  }
  
return 0;

}
