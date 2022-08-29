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


#define MOUSE_RELATIVE 1
#define MOUSE_ABSOLUTE 2

#define LOCAL_SERVER_PORT 1001
#define CLIENT_PORT 1002
#define MAX_PACKET_LEN 1400
#define DATA_BUFFER_LEN 500


///// Globals

struct imuSensorData imuData;
unsigned short gloveData[5];
unsigned short gloveData2[5];
unsigned char gloveHighLow = 0;
unsigned char gloveHighLow2 = 0;

#define GLOVE_SERIAL_LENGTH 12
char gloveSerial[GLOVE_SERIAL_LENGTH];
char gloveSerial2[GLOVE_SERIAL_LENGTH];

int32_t mouseData[6];
int mouseMode = 0;
pthread_t imuThread;
pthread_t gloveThread;
pthread_t gloveThread2;
pthread_t mouseThread;

int mouse_fd = -1;
int imu_fd = -1;

fdGlove* pGlove = NULL;
fdGlove* pGlove2 = NULL;

pthread_mutex_t imuDataMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t gloveDataMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t gloveDataMutex2 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mouseDataMutex = PTHREAD_MUTEX_INITIALIZER;

struct timeval gloveTime, imuTime, mouseTime, gloveTime2;

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
		
			switch (gloveHighLow) {
				case 0:
					gloveData[0] = allGloveData[FD_THUMBFAR];
					gloveData[1] = allGloveData[FD_INDEXFAR];
					gloveData[2] = allGloveData[FD_MIDDLEFAR];
					gloveData[3] = allGloveData[FD_RINGFAR];
					gloveData[4] = allGloveData[FD_LITTLEFAR];
					break;
				case 1:
					gloveData[0] = allGloveData[FD_THUMBNEAR];
					gloveData[1] = allGloveData[FD_INDEXNEAR];
					gloveData[2] = allGloveData[FD_MIDDLENEAR];
					gloveData[3] = allGloveData[FD_RINGNEAR];
					gloveData[4] = allGloveData[FD_LITTLENEAR];
					break;
				case 2:
					gloveData[0] = allGloveData[FD_THUMBFAR]+allGloveData[FD_THUMBNEAR];
					gloveData[1] = allGloveData[FD_INDEXFAR]+allGloveData[FD_INDEXNEAR];
					gloveData[2] = allGloveData[FD_MIDDLEFAR]+allGloveData[FD_MIDDLENEAR];
					gloveData[3] = allGloveData[FD_RINGFAR]+allGloveData[FD_RINGNEAR];
					gloveData[4] = allGloveData[FD_LITTLEFAR]+allGloveData[FD_LITTLENEAR];
					break;
			}
			memcpy(&gloveTime, &gloveTimeTmp, sizeof(struct timeval));
		
			pthread_mutex_unlock(&gloveDataMutex);
		
			pthread_testcancel();
			usleep(500);
	}
}

void * gloveReaderThread2(void *)
{
	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
	
	unsigned short allGloveData[5];
	struct timeval gloveTimeTmp;
	int updateBytes = 0;
	
	while(1)
	{
		
		gettimeofday(&gloveTimeTmp, 0);
		fdGetSensorRawAll(pGlove2, allGloveData);
			pthread_mutex_lock(&gloveDataMutex2);
		
			switch (gloveHighLow2) {
				case 0:
					gloveData2[0] = allGloveData[FD_THUMBFAR];
					gloveData2[1] = allGloveData[FD_INDEXFAR];
					gloveData2[2] = allGloveData[FD_MIDDLEFAR];
					gloveData2[3] = allGloveData[FD_RINGFAR];
					gloveData2[4] = allGloveData[FD_LITTLEFAR];
					break;
				case 1:
					gloveData2[0] = allGloveData[FD_THUMBNEAR];
					gloveData2[1] = allGloveData[FD_INDEXNEAR];
					gloveData2[2] = allGloveData[FD_MIDDLENEAR];
					gloveData2[3] = allGloveData[FD_RINGNEAR];
					gloveData2[4] = allGloveData[FD_LITTLENEAR];
					break;
				case 2:
					gloveData2[0] = allGloveData[FD_THUMBFAR]+allGloveData[FD_THUMBNEAR];
					gloveData2[1] = allGloveData[FD_INDEXFAR]+allGloveData[FD_INDEXNEAR];
					gloveData2[2] = allGloveData[FD_MIDDLEFAR]+allGloveData[FD_MIDDLENEAR];
					gloveData2[3] = allGloveData[FD_RINGFAR]+allGloveData[FD_RINGNEAR];
					gloveData2[4] = allGloveData[FD_LITTLEFAR]+allGloveData[FD_LITTLENEAR];
					break;
			}

			memcpy(&gloveTime2, &gloveTimeTmp, sizeof(struct timeval));
		
			pthread_mutex_unlock(&gloveDataMutex2);
		
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

	memset(outputPacket,0,MAX_PACKET_LEN);
	memset(gloveSerial,0,GLOVE_SERIAL_LENGTH);
	memset(gloveSerial2,0,GLOVE_SERIAL_LENGTH);

	if(argc < 10)
	{
		printf("usbEthernetBridge: Arguments: <program> <mouse device> <mouse-relative or absolute (1 or 2) > <glove device 1> <glove serial 1> <glove 1 highLow (0:Far, 1:Near, 2: Sum)>  <glove device 2> <glove serial 2> <glove 2 highLow> <use IMU (1 or 0)>\n");
		return 1;
	}

	// Glove Initialization
	char gloveDevice[100];
	char gloveDevice2[100];
	
	// attempt to open the first glove device (fourth argument)
	if (strlen(argv[3])>1) {
		printf("\nAttempting to open glove 1 on %s .. \n", argv[3] );
		pGlove = fdOpen(argv[3]);
		// log the serial number of the first glove device (fifth argument)
		memcpy(gloveSerial, argv[4], strlen(argv[4]));
		gloveHighLow = atoi(argv[5]);
		printf("\nSetting glove 1 gloveHighLow to %i .. \n", gloveHighLow );
	}
	else {
		pGlove = NULL;
	}

	// attempt to open the second glove device (sixth argument)
	if (strlen(argv[6])>1) {
		printf("\nAttempting to open glove 2 on %s .. \n", argv[6] );
		pGlove2 = fdOpen(argv[6]);
		// log the serial number of the second glove device (seventh argument)
		memcpy(gloveSerial2, argv[7], strlen(argv[7]));
		gloveHighLow2 = atoi(argv[8]);
		printf("\nSetting glove 2 gloveHighLow to %i .. \n", gloveHighLow2 );
	}
	else {
		pGlove2 = NULL;
	}
	
	if (pGlove == NULL)
	{
		printf("Didn't find glove1.\n");
	}
	if (pGlove2 == NULL)
	{
		printf("Didn't find glove2.\n");
	}

	if (atoi(argv[9]) == 1) {
		// IMU Initialization
		imu_fd = open_imu_serial_port();
	}
	else {
		printf("No IMU Used.\n");
		imu_fd = -1; 
	}		
	
	
	// Mouse Initialization 
	if (strlen(argv[1])>1) {
		printf("\nAttempting to open mouse on %s .. ", argv[1] );
		mouse_fd = open(argv[1], O_RDONLY);
		if (mouse_fd < 0) {
			printf("Error opening mouse \n");
		}
		else {
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
		}
	}

	printf("NOT RUNNING YET. Press ENTER to continue.\n");
	getchar();

	// set up the IMU if it's selected
	if (imu_fd != -1) {
		configure_imu_serial_port(imu_fd);	
		unsigned char command = 0xa5; // calibration command  
		
		// calibrate gyroscopes
		printf("Calibrating Gyroscopes, please keep IMU(s) still. Press enter when ready.\n");
		getchar();
		do_sync_transfer_wired(imu_fd, IMU_COMMAND_CALIBRATE_GYROS);
		printf("Calibration complete. Press enter to start data collection.  Angles will be tared.\n");
		getchar();
		
		do_sync_transfer_wired(imu_fd, IMU_COMMAND_TARE);
	}


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
		printf("%s: cannot bind port number %d \n", argv[0], LOCAL_SERVER_PORT);
		exit(1);
	}

	int broadcastPermission = 1;
	if (setsockopt(sd, SOL_SOCKET, SO_BROADCAST, (void *) &broadcastPermission, sizeof(broadcastPermission)) < 0)
	{
		printf("setsockopt() failed");
		exit(1);	
	}
	printf("%s: waiting for data on port UDP %u\n", argv[0],LOCAL_SERVER_PORT);


	flags = 0;

	if (imu_fd != -1) {
		/* Spawn IMU thread */
		printf("Starting IMU Thread \n");
		rc = pthread_create(&imuThread, NULL, imuReaderThread, NULL);
		if(rc)
		{
			printf("IMU thread failed to initialize!!\n");
		}
	}

	if (pGlove != NULL) {
		/* Spawn Glove thread */
		printf("Starting Glove 1 Thread \n");
		rc = pthread_create(&gloveThread, NULL, gloveReaderThread, NULL);
		if(rc)
		{
			printf("Glove 1 thread failed to initialize!!\n");
		}
	}

	if (pGlove2 != NULL) {	
		/* Spawn Glove 2 thread */
		printf("Starting Glove 2 Thread \n");
		rc = pthread_create(&gloveThread2, NULL, gloveReaderThread2, NULL);
		if(rc)
		{
			printf("Glove 2 thread failed to initialize!!\n");
		}
	}   
	
	if (mouse_fd != -1) {
		/* Spawn Mouse thread */
		printf("Starting Mouse Thread \n");
		rc = pthread_create(&mouseThread, NULL, mouseReaderThread, NULL);
		if(rc)
		{
			printf("Mouse thread failed to initialize!!\n");
		}
	}

	printf("\n--STARTING NOW--\n");
	struct timeval packetWriteTime;
	void * outputPacketPointer;
	uint16_t packetCount =0;
	uint16_t packetOffset;
	/* server infinite loop */
	while(1) {
		
		/* init buffer */
		memset(inputPacket,0x0,MAX_PACKET_LEN);

		/* receive message */
		cliLen = sizeof(cliAddr);
		n = recvfrom(sd, inputPacket, MAX_PACKET_LEN, flags, (struct sockaddr *) &cliAddr, &cliLen);
		++packetCount;
		packetOffset = 0;

		if(n<0) {
			printf("%s: cannot receive data \n",argv[0]);
			continue;
		}
		
		uint32_t * xpcClock;
		xpcClock = (uint32_t *)inputPacket;
		
		//print received message
		// printf("%s: from %s:UDP%u : %d \n", argv[0],inet_ntoa(cliAddr.sin_addr), ntohs(cliAddr.sin_port),*xpcClock);
		// Copy xpc time to packet
		outputPacketPointer = outputPacket;
		memcpy(outputPacket, inputPacket, sizeof(uint32_t));
		packetOffset += sizeof(uint32_t);
		outputPacketPointer = outputPacket+packetOffset;
		//outputPacketPointer += sizeof(uint32_t);

		float dataAge;
		
		if (imu_fd != -1) {
			// then copy imu data
			pthread_mutex_lock(&imuDataMutex);
			memcpy(outputPacketPointer, &imuData, sizeof(imuData));
			packetOffset += sizeof(imuData);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer+= sizeof(imuData);
			
			gettimeofday(&packetWriteTime, 0);
			dataAge = (float(packetWriteTime.tv_sec - imuTime.tv_sec)) * 1000 + (float(packetWriteTime.tv_usec - imuTime.tv_usec))/1000;
			memcpy(outputPacketPointer, &dataAge, sizeof(dataAge));
			packetOffset += sizeof(dataAge);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer+= sizeof(dataAge);
			
			pthread_mutex_unlock(&imuDataMutex);
		} else {
		  //outputPacketPointer+= sizeof(imuData);
		  //outputPacketPointer+= sizeof(dataAge);
			packetOffset += sizeof(imuData);
			packetOffset += sizeof(dataAge);
			outputPacketPointer = outputPacket+packetOffset;
		}

		
		if (pGlove != NULL) {
			// then copy glove 1 data
			pthread_mutex_lock(&gloveDataMutex);
			memcpy(outputPacketPointer, gloveData, 5*sizeof(unsigned short));
			packetOffset += 5*sizeof(unsigned short);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer += 5*sizeof(unsigned short);
			
			gettimeofday(&packetWriteTime, 0);
			dataAge = (float(packetWriteTime.tv_sec - gloveTime.tv_sec)) * 1000 + (float(packetWriteTime.tv_usec - gloveTime.tv_usec))/1000;
			memcpy(outputPacketPointer, &dataAge, sizeof(dataAge));
			packetOffset += sizeof(dataAge);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer+= sizeof(dataAge);
			
			pthread_mutex_unlock(&gloveDataMutex);
			
			//copy glove 1 serial number
			memcpy(outputPacketPointer, gloveSerial, GLOVE_SERIAL_LENGTH);
			packetOffset += GLOVE_SERIAL_LENGTH;
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer+= GLOVE_SERIAL_LENGTH;
		}
		else {
		  //outputPacketPointer += 5*sizeof(unsigned short);
		  //outputPacketPointer+= sizeof(dataAge);
		  //outputPacketPointer+= GLOVE_SERIAL_LENGTH;
		  packetOffset += 5*sizeof(unsigned short);
		  packetOffset += sizeof(dataAge);
		  packetOffset += GLOVE_SERIAL_LENGTH;
		  outputPacketPointer = outputPacket+packetOffset;
		}
		
		
		if (pGlove2 != NULL) {
			// then copy glove 2 data
			pthread_mutex_lock(&gloveDataMutex2);
			memcpy(outputPacketPointer, gloveData2, 5*sizeof(unsigned short));
			packetOffset += 5*sizeof(unsigned short);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer += 5*sizeof(unsigned short);
			
			gettimeofday(&packetWriteTime, 0);
			dataAge = (float(packetWriteTime.tv_sec - gloveTime2.tv_sec)) * 1000 + (float(packetWriteTime.tv_usec - gloveTime2.tv_usec))/1000;
			memcpy(outputPacketPointer, &dataAge, sizeof(dataAge));
			packetOffset += sizeof(dataAge);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer+= sizeof(dataAge);
			
			pthread_mutex_unlock(&gloveDataMutex2);
			
			//copy glove 1 serial number
			memcpy(outputPacketPointer, gloveSerial2, GLOVE_SERIAL_LENGTH);
			packetOffset += GLOVE_SERIAL_LENGTH;
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer+= GLOVE_SERIAL_LENGTH;
		}
		else {
		  //outputPacketPointer += 5*sizeof(unsigned short);
		  //outputPacketPointer += sizeof(dataAge);
		  //outputPacketPointer += GLOVE_SERIAL_LENGTH;
			packetOffset += 5*sizeof(unsigned short);
			packetOffset += sizeof(dataAge);
			packetOffset += GLOVE_SERIAL_LENGTH;
			outputPacketPointer = outputPacket+packetOffset;
		}
			
			
		if (mouse_fd  != -1) {
			// then copy mouse data
			pthread_mutex_lock(&mouseDataMutex);
			memcpy(outputPacketPointer, mouseData, 6*sizeof(int32_t));
			packetOffset += 6*sizeof(int32_t);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer += 6*sizeof(int32_t);
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
			packetOffset += sizeof(dataAge);
			outputPacketPointer = outputPacket+packetOffset;
			//outputPacketPointer+= sizeof(dataAge);

			memcpy(&mouseTime, &packetWriteTime, sizeof(struct timeval));
			
			pthread_mutex_unlock(&mouseDataMutex);

		} else {
		  //outputPacketPointer += 6*sizeof(int32_t);
		  //outputPacketPointer+= sizeof(dataAge);
			packetOffset += 6*sizeof(int32_t);
			packetOffset += sizeof(dataAge);
			outputPacketPointer = outputPacket+packetOffset;
		}
		


		// get laptop time
		gettimeofday(&packetWriteTime, 0);
		memcpy(outputPacketPointer, &packetWriteTime, sizeof(struct timeval));
		packetOffset += sizeof(struct timeval);
		outputPacketPointer = outputPacket+packetOffset;
		//outputPacketPointer+= sizeof(struct timeval);

		
		
		cliAddr.sin_port = htons(CLIENT_PORT);
		inet_aton("192.168.30.255", &cliAddr.sin_addr);
		n = sendto(sd,outputPacket,n,flags,(struct sockaddr *)&cliAddr,cliLen);
		if ((packetCount % 100) == 0) 
		  printf("%10i, Sendto returned %d , %4i\n", packetCount, n, packetOffset);
		
	}

	return 0;

}
