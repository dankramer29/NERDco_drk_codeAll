#define _WINSOCK_DEPRECATED_NO_WARNINGS

#include <tobii/tobii.h>
#include <tobii/tobii_streams.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

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

static void gaze_callback(tobii_gaze_point_t const* gaze_point, void* user_data)
{
	// Store the latest gaze point data in the supplied storage
	tobii_gaze_point_t* gaze_point_storage = (tobii_gaze_point_t*)user_data;
	*gaze_point_storage = *gaze_point;
}

static void head_callback(tobii_head_pose_t const* head_pose, void* user_data)
{
	// Store the latest head pose data in the supplied storage
	tobii_head_pose_t* head_pose_storage = (tobii_head_pose_t*)user_data;
	*head_pose_storage = *head_pose;
}

struct url_receiver_context_t
{
	char** urls;
	int capacity;
	int count;
};

static void url_receiver(char const* url, void* user_data)
{
	// The memory context is passed through the user_data void pointer
	struct url_receiver_context_t* context = (struct url_receiver_context_t*) user_data;
	// Allocate more memory if maximum capacity has been reached
	if (context->count >= context->capacity)
	{
		context->capacity *= 2;
		char** urls = (char**)realloc(context->urls, sizeof(char*) * context->capacity);
		if (!urls)
		{
			fprintf(stderr, "Allocation failed\n");
			return;
		}
		context->urls = urls;
	}
	// Copy the url string input parameter to allocated memory
	size_t url_length = strlen(url) + 1;
	context->urls[context->count] = malloc(url_length);
	if (!context->urls[context->count])
	{
		fprintf(stderr, "Allocation failed\n");
		return;
	}
	memcpy(context->urls[context->count++], url, url_length);
}


struct device_list_t
{
	char** urls;
	int count;
};

static struct device_list_t list_devices(tobii_api_t* api)
{
	struct device_list_t list = { NULL, 0 };
	// Create a memory context that can be used by the url receiver callback
	struct url_receiver_context_t url_receiver_context;
	url_receiver_context.count = 0;
	url_receiver_context.capacity = 16;
	url_receiver_context.urls = (char**)malloc(sizeof(char*) * url_receiver_context.capacity);
	if (!url_receiver_context.urls)
	{
		fprintf(stderr, "Allocation failed\n");
		return list;
	}

	// Enumerate the connected devices, connected devices will be stored in the supplied memory context
	tobii_error_t error = tobii_enumerate_local_device_urls(api, url_receiver, &url_receiver_context);
	if (error != TOBII_ERROR_NO_ERROR) fprintf(stderr, "Failed to enumerate devices.\n");

	list.urls = url_receiver_context.urls;
	list.count = url_receiver_context.count;
	return list;
}


static void free_device_list(struct device_list_t* list)
{
	for (int i = 0; i < list->count; ++i)
		free(list->urls[i]);

	free(list->urls);
}


static char const* select_device(struct device_list_t* devices)
{
	int tmp = 0, selection = 0;

	// Present the available devices and loop until user has selected a valid device
	while (selection < 1 || selection > devices->count)
	{
		printf("\nSelect a device\n\n");
		for (int i = 0; i < devices->count; ++i) printf("%d. %s\n", i + 1, devices->urls[i]);
		if (scanf_s("%d", &selection) <= 0) while ((tmp = getchar()) != '\n' && tmp != EOF);
	}

	return devices->urls[selection - 1];
}


struct thread_context_t
{
	tobii_device_t* device;
	HANDLE reconnect_event; // Used to signal that a reconnect is needed
	HANDLE timesync_event; // Timer event used to signal that time synchronization is needed
	HANDLE exit_event; // Used to signal that the background thead should exit
	volatile LONG is_reconnecting;
};


static DWORD WINAPI reconnect_and_timesync_thread(LPVOID param)
{
	struct thread_context_t* context = (struct thread_context_t*) param;

	HANDLE objects[3];
	objects[0] = context->reconnect_event;
	objects[1] = context->timesync_event;
	objects[2] = context->exit_event;

	for (; ; )
	{
		// Block here, waiting for one of the three events.
		DWORD result = WaitForMultipleObjects(3, objects, FALSE, INFINITE);
		if (result == WAIT_OBJECT_0) // Handle reconnect event
		{
			tobii_error_t error;
			// Run reconnect loop until connection succeeds or the exit event occurs
			while ((error = tobii_device_reconnect(context->device)) != TOBII_ERROR_NO_ERROR)
			{
				if (error != TOBII_ERROR_CONNECTION_FAILED)
					fprintf(stderr, "Reconnection failed: %s.\n", tobii_error_message(error));
				// Blocking waiting for exit event, timeout after 250 ms and retry reconnect
				result = WaitForSingleObject(context->exit_event, 250); // Retry every quarter of a second
				if (result == WAIT_OBJECT_0)
					return 0; // exit thread
			}
			InterlockedExchange(&context->is_reconnecting, 0L);
		}
		else if (result == WAIT_OBJECT_0 + 1) // Handle timesync event
		{
			tobii_error_t error = tobii_update_timesync(context->device);
			LARGE_INTEGER due_time;
			LONGLONG const timesync_update_interval = 300000000LL; // Time sync every 30 s
			LONGLONG const timesync_retry_interval = 1000000LL; // Retry time sync every 100 ms
			due_time.QuadPart = (error == TOBII_ERROR_NO_ERROR) ? -timesync_update_interval : -timesync_retry_interval;
			// Re-schedule timesync event
			SetWaitableTimer(context->timesync_event, &due_time, 0, NULL, NULL, FALSE);
		}
		else if (result == WAIT_OBJECT_0 + 2) // Handle exit event
		{
			// Exit requested, exiting the thread
			return 0;
		}
	}
}


static void log_func(void* log_context, tobii_log_level_t level, char const* text)
{
	CRITICAL_SECTION* log_mutex = (CRITICAL_SECTION*)log_context;

	EnterCriticalSection(log_mutex);
	if (level == TOBII_LOG_LEVEL_ERROR)
		fprintf(stderr, "Logged error: %s\n", text);
	LeaveCriticalSection(log_mutex);
}


int main(void)
{
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

	// Initialize critical section, used for thread synchronization in the log function
	static CRITICAL_SECTION log_mutex;
	InitializeCriticalSection(&log_mutex);
	tobii_custom_log_t custom_log = { &log_mutex, log_func };

	tobii_api_t* api;
	tobii_error_t error = tobii_api_create(&api, NULL, &custom_log);
	if (error != TOBII_ERROR_NO_ERROR)
	{
		fprintf(stderr, "Failed to initialize the Tobii Stream Engine API.\n");
		DeleteCriticalSection(&log_mutex);
		return 1;
	}

	struct device_list_t devices = list_devices(api);
	if (devices.count == 0)
	{
		fprintf(stderr, "No stream engine compatible device(s) found.\n");
		free_device_list(&devices);
		tobii_api_destroy(api);
		DeleteCriticalSection(&log_mutex);
		return 1;
	}
	char const* selected_device = devices.count == 1 ? devices.urls[0] : select_device(&devices);
	printf("Connecting to %s.\n", selected_device);

	tobii_device_t* device;
	error = tobii_device_create(api, selected_device, &device);
	free_device_list(&devices);
	if (error != TOBII_ERROR_NO_ERROR)
	{
		fprintf(stderr, "Failed to initialize the device with url %s.\n", selected_device);
		tobii_api_destroy(api);
		DeleteCriticalSection(&log_mutex);
		return 1;
	}

	tobii_gaze_point_t latest_gaze_point;
	latest_gaze_point.timestamp_us = 0LL;
	latest_gaze_point.validity = TOBII_VALIDITY_INVALID;
	// Start subscribing to gaze point data, in this sample we supply a tobii_gaze_point_t variable to store latest value.
	error = tobii_gaze_point_subscribe(device, gaze_callback, &latest_gaze_point);
	if (error != TOBII_ERROR_NO_ERROR)
	{
		fprintf(stderr, "Failed to subscribe to gaze stream.\n");

		tobii_device_destroy(device);
		tobii_api_destroy(api);
		DeleteCriticalSection(&log_mutex);
		return 1;
	}

	//subscribe to head pose data
	tobii_head_pose_t latest_head_pose;
	latest_head_pose.timestamp_us = 0LL;
	latest_head_pose.position_validity = TOBII_VALIDITY_INVALID;
	latest_head_pose.rotation_validity_xyz[0] = TOBII_VALIDITY_INVALID;
	latest_head_pose.rotation_validity_xyz[1] = TOBII_VALIDITY_INVALID;
	latest_head_pose.rotation_validity_xyz[2] = TOBII_VALIDITY_INVALID;
	error = tobii_head_pose_subscribe(device, head_callback, &latest_head_pose);
	if (error != TOBII_ERROR_NO_ERROR)
	{
		fprintf(stderr, "Failed to subscribe to head pose stream.\n");

		tobii_device_destroy(device);
		tobii_api_destroy(api);
		DeleteCriticalSection(&log_mutex);
		return 1;
	}

	// Create event objects used for inter thread signaling
	HANDLE reconnect_event = CreateEvent(NULL, FALSE, FALSE, NULL);
	HANDLE timesync_event = CreateWaitableTimer(NULL, TRUE, NULL);
	HANDLE exit_event = CreateEvent(NULL, FALSE, FALSE, NULL);
	if (reconnect_event == NULL || timesync_event == NULL || exit_event == NULL)
	{
		fprintf(stderr, "Failed to create event objects.\n");

		tobii_device_destroy(device);
		tobii_api_destroy(api);
		DeleteCriticalSection(&log_mutex);
		return 1;
	}

	struct thread_context_t thread_context;
	thread_context.device = device;
	thread_context.reconnect_event = reconnect_event;
	thread_context.timesync_event = timesync_event;
	thread_context.exit_event = exit_event;
	thread_context.is_reconnecting = 0;

	// Create and run the reconnect and timesync thread
	HANDLE thread_handle = CreateThread(NULL, 0U, reconnect_and_timesync_thread, &thread_context, 0U, NULL);
	if (thread_handle == NULL)
	{
		fprintf(stderr, "Failed to create reconnect_and_timesync thread.\n");

		tobii_device_destroy(device);
		tobii_api_destroy(api);
		DeleteCriticalSection(&log_mutex);
		return 1;
	}

	LARGE_INTEGER due_time;
	LONGLONG const timesync_update_interval = 300000000LL; // time sync every 30 s
	due_time.QuadPart = -timesync_update_interval;
	// Schedule the time synchronization event
	BOOL timer_error = SetWaitableTimer(thread_context.timesync_event, &due_time, 0, NULL, NULL, FALSE);
	if (timer_error == FALSE)
	{
		fprintf(stderr, "Failed to schedule timer event.\n");

		tobii_device_destroy(device);
		tobii_api_destroy(api);
		DeleteCriticalSection(&log_mutex);
		return 1;
	}

	// Main loop
	int64_t lastTimeStamp = 0;
	tobiiPacket *sendPacket = malloc(sizeof(tobiiPacket));

	while (GetAsyncKeyState(VK_ESCAPE) == 0)
	{
		//Sleep(10); // Perform work i.e game loop code here - let's emulate it with a sleep

		// Only enter the next code section if not in reconnecting state
		if (!InterlockedCompareExchange(&thread_context.is_reconnecting, 0L, 0L))
		{
			error = tobii_device_process_callbacks(device);

			if (error == TOBII_ERROR_CONNECTION_FAILED)
			{
				// Change state and signal that reconnect is needed.
				InterlockedExchange(&thread_context.is_reconnecting, 1L);
				SetEvent(thread_context.reconnect_event);
			}
			else if (error != TOBII_ERROR_NO_ERROR)
			{
				fprintf(stderr, "tobii_device_process_callbacks failed: %s.\n", tobii_error_message(error));
				break;
			}

			// if we have a new piece of data, send a packet
			if (lastTimeStamp != latest_gaze_point.timestamp_us)
			{
				lastTimeStamp = latest_gaze_point.timestamp_us;

				sendPacket->tobiiTimeCode = latest_gaze_point.timestamp_us;
				sendPacket->computerTimeCode = (unsigned long int)clock();
				sendPacket->gazeX = (float)latest_gaze_point.position_xy[0];
				sendPacket->gazeY = (float)latest_gaze_point.position_xy[1];
				sendPacket->gazeValid = (latest_gaze_point.validity == TOBII_VALIDITY_VALID);

				sendPacket->headPosX = (float)latest_head_pose.position_xyz[0];
				sendPacket->headPosY = (float)latest_head_pose.position_xyz[1];
				sendPacket->headPosZ = (float)latest_head_pose.position_xyz[2];
				sendPacket->headPosValid = (latest_head_pose.position_validity == TOBII_VALIDITY_VALID);

				sendPacket->headRotX = (float)latest_head_pose.rotation_xyz[0];
				sendPacket->headRotY = (float)latest_head_pose.rotation_xyz[1];
				sendPacket->headRotZ = (float)latest_head_pose.rotation_xyz[2];
				sendPacket->headRotValidX = (latest_head_pose.rotation_validity_xyz[0] = TOBII_VALIDITY_VALID);
				sendPacket->headRotValidY = (latest_head_pose.rotation_validity_xyz[1] = TOBII_VALIDITY_VALID);
				sendPacket->headRotValidZ = (latest_head_pose.rotation_validity_xyz[2] = TOBII_VALIDITY_VALID);

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
				if (latest_gaze_point.validity == TOBII_VALIDITY_VALID)
					printf("Gaze point: %" PRIu64 " %f, %f\n", latest_gaze_point.timestamp_us,
						latest_gaze_point.position_xy[0], latest_gaze_point.position_xy[1]);
				else
					printf("Gaze point: %" PRIu64 " INVALID\n", latest_gaze_point.timestamp_us);
			}
		}

		//Sleep(6); // Perform work which needs eye tracking data and the rest of the game loop
	}

	// Signal reconnect and timesync thread to exit and clean up event objects.
	SetEvent(thread_context.exit_event);
	WaitForSingleObject(thread_handle, INFINITE);
	CloseHandle(thread_handle);
	CloseHandle(timesync_event);
	CloseHandle(exit_event);
	CloseHandle(reconnect_event);

	error = tobii_gaze_point_unsubscribe(device);
	if (error != TOBII_ERROR_NO_ERROR)
		fprintf(stderr, "Failed to unsubscribe from gaze stream.\n");

	error = tobii_device_destroy(device);
	if (error != TOBII_ERROR_NO_ERROR)
		fprintf(stderr, "Failed to destroy device.\n");

	error = tobii_api_destroy(api);
	if (error != TOBII_ERROR_NO_ERROR)
		fprintf(stderr, "Failed to destroy API.\n");

	DeleteCriticalSection(&log_mutex);
	return 0;
}
