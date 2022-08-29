
#define IMU_COMMAND_KALMAN_QUATERNION 0
#define IMU_COMMAND_KALMAN_EULER 0x01
#define IMU_COMMAND_CORRECTED_ACC 0x27 // returns 12 bytes (x,y,z float) scaled to G
#define IMU_COMMAND_SCALED_GYROS 0x21 // returns 12 bytes (x,y,z float) scaled to radian/sec
#define IMU_COMMAND_CORRECTED_COMPASS 0x28 // returns 12 bytes (x,y,z float) compass in gauss

#define IMU_COMMAND_CALIBRATE_GYROS 0xa5
#define IMU_COMMAND_TARE 0x60

#define IMU_BUFFER_LEN 255

int open_imu_serial_port(void);

int configure_imu_serial_port(int fd);      // configure the port

int process_input(int fd, char * buff);   // query modem with an AT command

int poll_serial_port(int fd, char * buff);

int do_sync_transfer_wired(int fd, unsigned char command);


int do_sync_transfer_wireless(int fd, unsigned char sensor, unsigned char command);

int get_imu_float_data(int fd, unsigned char command, float * data, int dataLen);

int get_all_sensors(int fd, struct imuSensorData* data);

void print_all_sensors(struct imuSensorData* data);

struct imuSensorData{
	float eulerAngle[3];
	float accel[3];
	float gyro[3];
	float compass[3];
};
