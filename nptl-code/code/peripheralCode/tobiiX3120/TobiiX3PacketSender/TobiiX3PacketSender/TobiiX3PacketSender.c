#define _WINSOCK_DEPRECATED_NO_WARNINGS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include "tobii_research_eyetracker.h"
#include "tobii_research_streams.h"

#include <WinSock2.h>
#include <time.h>

#pragma warning( push )
#pragma warning( disable: 4255 4668 )
#include <windows.h>
#pragma warning( pop )

// packet structure 
typedef struct {
	int64_t tobiiTimeCode;
	unsigned long int computerTimeCode;

	float gazeX;
	float gazeY;
	unsigned long int gazeValid;

	float headPosX;
	float headPosY;
	float headPosZ;
	unsigned long int headPosValid;

	float headRotX;
	float headRotY;
	float headRotZ;
	unsigned long int headRotValidX;
	unsigned long int headRotValidY;
	unsigned long int headRotValidZ;
} tobiiPacket;

static void sleep_ms(int time) {
	Sleep(time);
}

void gaze_data_callback(TobiiResearchGazeData* gaze_data, void* user_data) {
	memcpy(user_data, gaze_data, sizeof(*gaze_data));
}
void gaze_data_example(TobiiResearchEyeTracker* eyetracker) {
	TobiiResearchGazeData gaze_data;
	char* serial_number;
	tobii_research_get_serial_number(eyetracker, &serial_number);
	printf("Subscribing to gaze data for eye tracker with serial number %s.\n", serial_number);
	tobii_research_free_string(serial_number);
	TobiiResearchStatus status = tobii_research_subscribe_to_gaze_data(eyetracker, gaze_data_callback, &gaze_data);
	if (status != TOBII_RESEARCH_STATUS_OK)
		return;
	/* Wait while some gaze data is collected. */
	sleep_ms(2000);
	status = tobii_research_unsubscribe_from_gaze_data(eyetracker, gaze_data_callback);
	printf("Unsubscribed from gaze data with status %i.\n", status);
	printf("Last received gaze package:\n");
	printf("System time stamp: %"  PRId64 "\n", gaze_data.system_time_stamp);
	printf("Device time stamp: %"  PRId64 "\n", gaze_data.device_time_stamp);
	printf("Left eye 2D gaze point on display area: (%f, %f)\n",
		gaze_data.left_eye.gaze_point.position_on_display_area.x,
		gaze_data.left_eye.gaze_point.position_on_display_area.y);
	printf("Right eye 3d gaze origin in user coordinates (%f, %f, %f)\n",
		gaze_data.right_eye.gaze_origin.position_in_user_coordinates.x,
		gaze_data.right_eye.gaze_origin.position_in_user_coordinates.y,
		gaze_data.right_eye.gaze_origin.position_in_user_coordinates.z);
	/* Wait while some gaze data is collected. */
	sleep_ms(2000);
}

int main(void) {

	//socket
	//Initialize socket
	//socket stuff
	WORD wVersionRequested;
	WSADATA wsaData;
	wVersionRequested = MAKEWORD(2, 2);
	WSAStartup(wVersionRequested, &wsaData);

	SOCKET _SendingSocket;
	_SendingSocket = socket(AF_INET, SOCK_DGRAM, 0);// IPPROTO_UDP);
	if (_SendingSocket == INVALID_SOCKET)
	{
		char errString[256];
		sprintf_s(errString, "Socket creation error %ld", WSAGetLastError());
		fprintf(stderr, errString);
		return 1;
	}

	int status;
	boolean broadcastVal = 1;
	status = setsockopt(_SendingSocket, SOL_SOCKET, SO_BROADCAST, (char *)&broadcastVal, sizeof(broadcastVal));
	if (status < 0) {
		char errString[256];
		sprintf_s(errString, "Broadcast setting error %ld", WSAGetLastError());
		fprintf(stderr, errString);
		return 1;
	}

	struct sockaddr_in LocalAddr;
	LocalAddr.sin_family = AF_INET;
	LocalAddr.sin_port = htons(17000);
	LocalAddr.sin_addr.s_addr = inet_addr("192.168.30.1");

	// Bind the local send socket.
	struct sockaddr* local = (struct sockaddr *) &LocalAddr;
	if (bind(_SendingSocket, local, sizeof(struct sockaddr_in)) == SOCKET_ERROR)
	{
		char errString[256];
		sprintf_s(errString, "Binding error %ld", WSAGetLastError());
		fprintf(stderr, errString);
		return 1;
	}

	//connect to eye trackers
	TobiiResearchEyeTrackers* eyetrackers = NULL;
	TobiiResearchStatus result;
	size_t i = 0;
	result = tobii_research_find_all_eyetrackers(&eyetrackers);
	if (result != TOBII_RESEARCH_STATUS_OK) {
		printf("Finding trackers failed. Error: %d\n", result);
		return result;
	}
	for (i = 0; i < eyetrackers->count; i++) {
		TobiiResearchEyeTracker* eyetracker = eyetrackers->eyetrackers[i];
		char* address;
		char* serial_number;
		char* device_name;
		tobii_research_get_address(eyetracker, &address);
		tobii_research_get_serial_number(eyetracker, &serial_number);
		tobii_research_get_device_name(eyetracker, &device_name);
		printf("%s\t%s\t%s\n", address, serial_number, device_name);
		tobii_research_free_string(address);
		tobii_research_free_string(serial_number);
		tobii_research_free_string(device_name);
	}
	printf("Found %d Eye Trackers \n\n", (int)eyetrackers->count);

	if ((int)eyetrackers->count == 0)
		return;

	//subscribe to gaze stream
	TobiiResearchGazeData gaze_data;
	char* serial_number;
	tobii_research_get_serial_number(eyetrackers->eyetrackers[0], &serial_number);
	printf("Subscribing to gaze data for eye tracker with serial number %s.\n", serial_number);
	tobii_research_free_string(serial_number);
	TobiiResearchStatus tobiiRStat = tobii_research_subscribe_to_gaze_data(eyetrackers->eyetrackers[0], gaze_data_callback, &gaze_data);
	if (tobiiRStat != TOBII_RESEARCH_STATUS_OK)
		return;

	// Main loop
	int64_t lastTimeStamp = 0;
	tobiiPacket *sendPacket = malloc(sizeof(tobiiPacket));
	
	while (GetAsyncKeyState(VK_ESCAPE) == 0)
	{
		// if we have a new piece of data, send a packet
		if (lastTimeStamp != gaze_data.device_time_stamp)
		{
			lastTimeStamp = gaze_data.device_time_stamp;

			sendPacket->tobiiTimeCode = gaze_data.device_time_stamp;
			sendPacket->computerTimeCode = (unsigned long int)clock();
			sendPacket->gazeX = (float)gaze_data.left_eye.gaze_point.position_on_display_area.x;
			sendPacket->gazeY = (float)gaze_data.left_eye.gaze_point.position_on_display_area.y;
			sendPacket->gazeValid = (gaze_data.left_eye.gaze_point.validity == TOBII_RESEARCH_VALIDITY_VALID);

			sendPacket->headPosX = (float)gaze_data.right_eye.gaze_point.position_on_display_area.x;
			sendPacket->headPosY = (float)gaze_data.right_eye.gaze_point.position_on_display_area.y;
			sendPacket->headPosZ = (float)0;
			sendPacket->headPosValid = (gaze_data.right_eye.gaze_point.validity == TOBII_RESEARCH_VALIDITY_VALID);

			sendPacket->headRotX = (float)gaze_data.right_eye.gaze_point.position_on_display_area.x;
			sendPacket->headRotY = (float)gaze_data.right_eye.gaze_point.position_on_display_area.y;
			sendPacket->headRotZ = (float)0;
			sendPacket->headRotValidX = (gaze_data.right_eye.gaze_point.validity == TOBII_RESEARCH_VALIDITY_VALID);
			sendPacket->headRotValidY = 0;
			sendPacket->headRotValidZ = 0;

			// create remote address struct
			struct sockaddr_in RemoteAddr;
			RemoteAddr.sin_family = AF_INET;
			RemoteAddr.sin_port = htons(50141);
			RemoteAddr.sin_addr.s_addr = inet_addr("192.168.30.255");
			struct sockaddr* remote = (struct sockaddr *) &RemoteAddr;

			// send packet
			if (sendto(_SendingSocket, (char*)sendPacket, sizeof(tobiiPacket), 0, (SOCKADDR *)&RemoteAddr, sizeof(RemoteAddr)) == SOCKET_ERROR)
			{
				char errString[256];
				sprintf_s(errString, "UDP Send Error %ld", WSAGetLastError());
				fprintf(stderr, errString);
				break;
			}

			//print gaze point
			if (gaze_data.left_eye.gaze_point.validity == TOBII_RESEARCH_VALIDITY_VALID)
				printf("Left eye 2D gaze point on display area: (%f, %f)\n",
					gaze_data.left_eye.gaze_point.position_on_display_area.x,
					gaze_data.left_eye.gaze_point.position_on_display_area.y);
			else
				printf("Gaze point INVALID");
		}
	}

	tobii_research_free_eyetrackers(eyetrackers);
	return 1;
}

