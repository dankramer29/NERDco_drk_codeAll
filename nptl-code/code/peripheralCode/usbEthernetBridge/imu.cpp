#include <stdio.h> // standard input / output functions
#include <string.h> // string function definitions
#include <unistd.h> // UNIX standard function definitions
#include <fcntl.h> // File control definitions
#include <errno.h> // Error number definitions
#include <termios.h> // POSIX terminal control definitionss
#include <time.h>   // time calls
#include <sys/time.h>   // time calls
#include "imu.h"

int open_imu_serial_port(void)
{
	int fd; // file description for the serial port
	fd = open("/dev/ttyACM0", O_RDWR | O_NOCTTY | O_NDELAY);
	if(fd == -1) // if open is unsucessful
		printf("IMU open_port: Unable to open port. \n");
	else {
	fcntl(fd, F_SETFL, 0);
		printf("Serial port opened.\n");
	}	
	return(fd);
} //open_port


int configure_imu_serial_port(int fd)      // configure the port
{
	struct termios port_settings;      // structure to store the port settings in
    
    tcgetattr(fd, &port_settings);
    
	cfsetispeed(&port_settings, B115200);    // set baud rates
	
	port_settings.c_cflag &= ~PARENB;    // set no parity, stop bits, data bits
	port_settings.c_cflag &= ~CSTOPB;
	port_settings.c_cflag &= ~CSIZE;
	port_settings.c_cflag |= CS8;
	
	//port_settings.c_cflag &= ~(ICANON | ECHO | ECHOE | ISIG);
	
	//port_settings.c_oflag &= ~OPOST;
//added by CP, 20130903 - trying to get serial to work on shittles
char *ps; //pointer to port_settings struct
ps = (char*) &port_settings;
ps[0] = 1;
ps[1] = 0;
ps[12] = 0;
ps[13] = 0;

	
	tcsetattr(fd, TCSANOW, &port_settings);    // apply the settings to the port
	
	
	return(fd);

} //configure_port

int process_input(int fd, char * buff)   // query modem with an AT command
{
  int n;
  unsigned int i;
  char buffTmp[IMU_BUFFER_LEN];
  n = read(fd, buffTmp, IMU_BUFFER_LEN);
   //printf("%d Bytes read\n",n);
   //for (ii=0; ii<n; ++ii) {
   //  printf(" %02X", *(buff+ii));
   //}
   //printf("\n");

  for(i = 0; i < n; i++) {
	  buff[i] = buffTmp[n - 1 - i];
  }  // Reverse buffer to deal with endian issues
  
  return n;
}


int poll_serial_port(int fd, char * buff) {
	struct timeval timeout;
	char n;
//	fd_set rfds;
//	FD_ZERO(&rfds);
//	FD_SET(fd, &rfds);
	
	// initialise the timeout structure
	timeout.tv_sec = 0; // 0 seconds
	timeout.tv_usec = 10000000; // 10 ms

        int numBytes = 0;
	int count = 0;
        // do the select
        n = select(fd+1, NULL, NULL, NULL, &timeout);
	
        // check if an error has occured
        if(n < 0)
            perror("select failed\n");
        else if (n == 0)
            puts("Timeout reached with no data on the port");
        else {
		  memset(buff, 0, 50);
          numBytes = process_input(fd, buff);
  //        FD_ZERO(&rfds);
  //        FD_SET(fd, &rfds);
        }
        return numBytes;
}



int do_sync_transfer_wired(int fd, unsigned char command)
{
	char n;
        //command to start a synchronous transfer
        unsigned char send_bytes[] = {0xF7, command, command};
        unsigned char dataLength = sizeof(send_bytes) / sizeof(unsigned char);
        /* printf("Command: "); */
        /* for(n = 0; n<dataLength; ++n) */
        /*   printf("%02X ", send_bytes[n]); */
        /* printf("\n"); */
        write(fd, send_bytes, dataLength);  //Send data
	return 0;
} //do_sync_transfer_wired





int do_sync_transfer_wireless(int fd, unsigned char sensor, unsigned char command)
{
	char n;
        //command to start a synchronous transfer over wireless
        unsigned char send_bytes[] = {0xF8, sensor, command, command};
        unsigned char dataLength = sizeof(send_bytes) / sizeof(unsigned char);
        /* printf("Command: "); */
        /* for(n = 0; n<dataLength; ++n) */
        /*   printf("%02X ", send_bytes[n]); */
        /* printf("\n"); */
        write(fd, send_bytes, dataLength);  //Send data
	return 0;
} //do_sync_transfer_wireless

int get_imu_float_data(int fd, unsigned char command, float * data, int dataLen)
{
	char IMUdata[IMU_BUFFER_LEN];
	do_sync_transfer_wired(fd, command);
	int readLen = process_input(fd, IMUdata);
	if(readLen == dataLen*4) // If we receive valid data back (by length, correct number of 4 byte floats)
	{
		memcpy(data, IMUdata, dataLen*4);
	}
	else
		return -1;
	return 0;
}

int get_all_sensors(int fd, struct imuSensorData* data)
{
  	if(get_imu_float_data(fd, IMU_COMMAND_KALMAN_EULER, data->eulerAngle, 3) == -1)
		return -1;
   	if(get_imu_float_data(fd, IMU_COMMAND_CORRECTED_ACC, data->accel, 3) == -1)
		return -1;
   	if(get_imu_float_data(fd, IMU_COMMAND_SCALED_GYROS, data->gyro, 3) == -1)
		return -1;
   	if(get_imu_float_data(fd, IMU_COMMAND_CORRECTED_COMPASS, data->compass, 3) == -1)
		return -1;
}


void print_sensor(const char * sensorName, float * data, int dataLen)
{
	printf("%s : ", sensorName);
	for(int i = 0; i < dataLen; i++)
	{
		printf("%+06.2f ", data[i]);
	}
	printf("\t");
}

void print_all_sensors(struct imuSensorData* data)
{
	print_sensor("Angles", data->eulerAngle, 3);
}
