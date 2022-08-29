
// Windows Instructions: 
//      For mex compilation: mex udpFileWriter.cpp -Ic:\users\gilja\desktop\Pre-built.2\include ws2_32.lib -lpthreadVC2 -Lc:\users\gilja\desktop\Pre-built.2\lib\x64\ -DWIN32
//      To run and compile we need the win32-pthread library, specifically pthreadVC2 if we're using Visual Studio to compile.  To run, we copy the DLL to c:\windows\system32
//      
// Mac OSX and Linux: should just compule with: mex udpFileWriter.cpp



#include "math.h"
#include "mex.h"   //--This one is required

#include<string.h>
#include<pthread.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <ctype.h>


//Windows specific stuff
#ifdef WIN32
#include <windows.h>
#define close(s) closesocket(s)
#define s_errno WSAGetLastError()
#define EWOULDBLOCK WSAEWOULDBLOCK
#define usleep(a) Sleep((a)/1000)
#define MSG_NOSIGNAL 0
#define nonblockingsocket(s) {unsigned long ctl = 1;ioctlsocket( s, FIONBIO, &ctl );}
typedef int socklen_t;
//End windows stuff
#else
#include <arpa/inet.h>
#include <inttypes.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#define nonblockingsocket(s)  fcntl(s,F_SETFL,O_NONBLOCK)
#define Sleep(a) usleep(a*1000)
#endif

#define PORT 2000
#define PACKET_BUFFER_SIZE 20000


#define DEBUG_ON 1

#define MAX_PACKET_LENGTH 1500

#define FILE_NAME_LENGTH 20
#define FILE_PATH_LENGTH 1000
#define FILE_SIZE_LIMIT 2000000000

#define PACKET_TYPE_DATA 1
#define PACKET_TYPE_RESET_FILE 0
#define PACKET_TYPE_RESET_EXPT 2

#define MAX_FILE_HANDLES 20


///////////// PROTOTYPES /////////////


///////////// DATA TYPES DECLARATIONS /////////////
typedef uint8_t uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef unsigned long long uint64;


struct packet
{
  uint8 packetType;
  uint32 packetNum[2];
  uint8 fragNum;
  uint8 fragTotal;
  char fileName[FILE_NAME_LENGTH];
  uint16 dataLen;
  uint8 data[MAX_PACKET_LENGTH];
  uint32 crc;
};

struct fileInfo
{
  FILE * filePtr;
  uint32 packetNum[2];
  uint8 fragTotal;
  uint16 dataLen;
  int fileLength;
  char fileName[FILE_NAME_LENGTH];
  bool firstPacket;
};



///////////// GLOBALS /////////////

pthread_t fileThread;
pthread_t udpThread;

char dataDir[FILE_PATH_LENGTH + 1];

struct fileInfo fileHandles[MAX_FILE_HANDLES];
int numFileHandles = 0;
int fileNums = 0;
FILE * fnumFile = NULL; // File holding current file number
int mex_call_counter = 0; 

int sock = -1;
packet packetBuffer[PACKET_BUFFER_SIZE];
uint32 packetBufferStart=0; // Current Buffer start position
uint32 packetBufferSize=0; // Number of elements on buffer
pthread_mutex_t packetBufferMutex = PTHREAD_MUTEX_INITIALIZER;

FILE * fileLog = NULL; // log for file logger

void newFileHandle(struct packet currPacket);


int findFileHandle(struct packet currPacket)
{
  //printf("Looking for File Handle for %s  :", currPacket.fileName);
  for(int i = 0; i < numFileHandles; i++)
    {
      if(strcmp(fileHandles[i].fileName, currPacket.fileName) == 0){
	//printf("%d\n", i);
	return i;
      }
    }
      
  newFileHandle(currPacket);
  //printf("%d\n", numFileHandles-1);
  return numFileHandles-1;
  
}

void newFileHandle(struct packet currPacket)
{
  char fileName[FILE_PATH_LENGTH + FILE_NAME_LENGTH + 1];
  FILE * file;

  time_t rawtime;
  struct tm * timeinfo;

  time ( &rawtime );
  timeinfo = localtime ( &rawtime );

  if(numFileHandles >= MAX_FILE_HANDLES){
    mexPrintf("Too Many Open File Handles!!\n");
    exit(-1);
  }

  numFileHandles++;

  memcpy(fileHandles[numFileHandles-1].fileName, currPacket.fileName, FILE_NAME_LENGTH);
  fileHandles[numFileHandles-1].packetNum[0] = currPacket.packetNum[0];
  fileHandles[numFileHandles-1].packetNum[1] = currPacket.packetNum[1];
  fileHandles[numFileHandles-1].firstPacket = 1;
  fileHandles[numFileHandles-1].fileLength = 0;
  
  sprintf(fileName, "%s/%s-%08d.dat", dataDir, currPacket.fileName, fileNums);
  file = fopen(fileName, "wb");
  if(file == 0){
    mexPrintf("\aFatal File IO Error: could not open file: %s \n", fileName);
    exit(-1);
  }

  fprintf(fileLog, "New File Handle at %s for %s\n", asctime(timeinfo), fileName ); //added write file log 160927

  fileHandles[numFileHandles-1].filePtr = file;
  
}



void closeFiles(void *arg)
{

  time_t rawtime;
  struct tm * timeinfo;

  time ( &rawtime );
  timeinfo = localtime ( &rawtime );
  mexPrintf ( "\aFile Handles Closed @ %s", asctime (timeinfo) );


  for(int i = 0; i < numFileHandles; i++)
    {
      fclose(fileHandles[i].filePtr);
    }

  numFileHandles = 0;

  fileNums++;
  fseek(fnumFile, 0, SEEK_SET);
  fprintf(fnumFile, "%d", fileNums);
  fflush(fnumFile);

}

void writeDateFile()
{
  time_t rawtime;
  struct tm * timeinfo;
  char fileName[FILE_PATH_LENGTH + FILE_NAME_LENGTH + 1];
  char timeString[100];
  time( &rawtime );
  timeinfo = localtime( &rawtime );
  
  sprintf(fileName, "%s/date.txt", dataDir);
  
  FILE * dateFile = fopen(fileName, "w");
  
  if(dateFile == NULL){
    mexPrintf("FATAL ERROR: Could not open dateFile: %s \n", fileName);
    exit(-1);
  }
    
  fprintf(dateFile, "%s", asctime(timeinfo));

  fclose(dateFile);
}
    



int writePacketData(packet currPacket)
{
  static bool firstPacket=true;

  int bytesWritten=0;
  int fileHandleIdx = findFileHandle(currPacket);

  //printf("Writing Packet Data\n");
  if(firstPacket){
    writeDateFile();

    firstPacket = false;
  }


  bytesWritten = fwrite(currPacket.packetNum, sizeof(currPacket.packetNum[1]), 2, fileHandles[fileHandleIdx].filePtr);
  fileHandles[fileHandleIdx].fileLength += bytesWritten;

  bytesWritten = fwrite(&(currPacket.dataLen), sizeof(currPacket.dataLen), 1, fileHandles[fileHandleIdx].filePtr);
  fileHandles[fileHandleIdx].fileLength += bytesWritten;

  bytesWritten = fwrite(currPacket.data, 1, currPacket.dataLen, fileHandles[fileHandleIdx].filePtr);
  fileHandles[fileHandleIdx].fileLength += bytesWritten;


  if(fileHandles[fileHandleIdx].firstPacket)
    fileHandles[fileHandleIdx].firstPacket = 0;
  else
    {
      if(!(((currPacket.packetNum[1] == fileHandles[fileHandleIdx].packetNum[1]) && (currPacket.packetNum[0] == fileHandles[fileHandleIdx].packetNum[0]+1))
	   || ((currPacket.packetNum[1] == fileHandles[fileHandleIdx].packetNum[1]+1) && (currPacket.packetNum[0] == 0) && (fileHandles[fileHandleIdx].packetNum[0] == 0xFFFFFFFF))))
	{   
	  mexPrintf("\aPacket Number Error!!  Current Packet Number: %u, %u   Last Packet Number: %u, %u \n", currPacket.packetNum[0], currPacket.packetNum[1], fileHandles[fileHandleIdx].packetNum[0], fileHandles[fileHandleIdx].packetNum[1]);
	}
    }


  fileHandles[fileHandleIdx].packetNum[0] = currPacket.packetNum[0];
  fileHandles[fileHandleIdx].packetNum[1] = currPacket.packetNum[1];

  fflush(fileHandles[fileHandleIdx].filePtr); //flush the files - 160927  

  return fileHandles[fileHandleIdx].fileLength;
}

void * fileWriterThread(void * dummy)
{
    
    struct packet currPacket;
    
    pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
    pthread_setcanceltype(PTHREAD_CANCEL_DEFERRED, NULL);
    //printf("File Writer Thread \n");
    
    pthread_cleanup_push(closeFiles, NULL);
    
    while(1){
        
        pthread_testcancel();
        
        
        while(packetBufferSize > 0){
            //printf("Packets on the Buffer: %d, Entering critical section\n", packetBufferSize);
            // Packet Buffer Critical Section
            pthread_mutex_lock(&packetBufferMutex);
            //printf("1\n");
            memcpy(&currPacket, &packetBuffer[packetBufferStart], sizeof(currPacket));
            //printf("2\n");
            packetBufferStart = (packetBufferStart+1)%PACKET_BUFFER_SIZE;
            //printf("3\n");
            packetBufferSize--;
            //printf("4\n");
            pthread_mutex_unlock(&packetBufferMutex);
            // End Critical Section
            //printf("End of critical section \n");
            
            int fileLength = 0;
            
            if(currPacket.packetType == PACKET_TYPE_DATA)
                fileLength = writePacketData(currPacket);
            if((currPacket.packetType == PACKET_TYPE_RESET_FILE) ||
                    (fileLength >= FILE_SIZE_LIMIT))
            {
                
                closeFiles(NULL);
                
            }
            else if(currPacket.packetType == PACKET_TYPE_RESET_EXPT)
            {
                
            }
            
            
        }
        
        Sleep(1);
        
    }
    
    pthread_cleanup_pop(0);
    
    
}



void bufferPacket(char *rawPacket, int packetLength)
{
  //static uint32 lastPacketNum[2]={0, 0};
  
  //printf("Enter buffer Packet \n");
  // Packet Buffer Critical Section
  pthread_mutex_lock(&packetBufferMutex);
  uint32 packetBufferNext = (packetBufferStart+packetBufferSize) % PACKET_BUFFER_SIZE;
  pthread_mutex_unlock(&packetBufferMutex);
  // END CRITICAL SECTION
  //printf("After critical section \n");
  packetBuffer[packetBufferNext].packetType = (uint8) rawPacket[0];
  packetBuffer[packetBufferNext].packetNum[0] = *((uint32*) &rawPacket[1]); 
  packetBuffer[packetBufferNext].packetNum[1] = *((uint32*) &rawPacket[5]); 
  packetBuffer[packetBufferNext].fragNum = (uint8) rawPacket[9];
  packetBuffer[packetBufferNext].fragTotal = (uint8) rawPacket[10];
  memcpy(packetBuffer[packetBufferNext].fileName, (char*) &rawPacket[11], FILE_NAME_LENGTH);
  //printf("File Name: %s \n", packetBuffer[packetBufferNext].fileName);
  packetBuffer[packetBufferNext].dataLen = *((uint16*) &rawPacket[11+FILE_NAME_LENGTH]);
  //printf("Data Length: %d \n", packetBuffer[packetBufferNext].dataLen);
  packetBuffer[packetBufferNext].crc = *((uint32*) &rawPacket[11+2+FILE_NAME_LENGTH]);
  memcpy((uint8*)&(packetBuffer[packetBufferNext].data[0]), (uint8*) &rawPacket[11+2+4+FILE_NAME_LENGTH], packetBuffer[packetBufferNext].dataLen);
  

  //printf("Next critical section \n");
  // START CRITICAL SECTION
  pthread_mutex_lock(&packetBufferMutex);
  packetBufferSize++;
  if(packetBufferSize >= PACKET_BUFFER_SIZE){
    mexPrintf("Packet Buffer OVER RUN!!\n");
    exit(1);
  }
  pthread_mutex_unlock(&packetBufferMutex);
  // END CRITICAL SECTION!!
  //printf("After critical section \n");

  //calcCrc = calculate_crc(currPacket.data, currPacket.dataLen);

  //  if(calcCrc != currPacket.crc){
  //     printf("CRC Error!!  Transmit CRC: %08x   Calc CRC: %08x \n", currPacket.crc, calcCrc);
  // }


  return;
}

void diep(const char *s)
{
  mexPrintf("Error with sockets: %s \n", s);
  perror(s);
  //exit(1);
}


void stopServer()
{
//  mexPrintf("Finishing Main\n");
  pthread_cancel(fileThread);
  pthread_join(fileThread, NULL);
  pthread_cancel(udpThread);
  pthread_join(udpThread, NULL);
  close(sock);
  fclose(fnumFile);
  fclose(fileLog);
  //exit(-1);
}

void closeSock(void * dummy)
{
    close(sock);
}


int myoptstrcmp(const char *s1,const char *s2)
{
    int val;
    while( (val= toupper(*s1) - toupper(*s2))==0 ){
        if(*s1==0 || *s2==0) return 0;
        s1++;
        s2++;
        while(*s1=='_') s1++;
        while(*s2=='_') s2++;
    }
    return val;
}

void * udpReaderThread(void * dummy)
{
    pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);

    struct sockaddr_in si_other;

    char rawPacket[MAX_PACKET_LENGTH];
    
    socklen_t slen=sizeof(si_other);
    
        
    while(1)
    {        
        // Read
        int bytesRead = recvfrom(sock, rawPacket, MAX_PACKET_LENGTH, 0, (struct sockaddr*)&si_other, &slen);
        if(bytesRead > -1)
        {
           bufferPacket(rawPacket, bytesRead);
        }
        else
        {
             Sleep(1);
        }
         pthread_testcancel();
         
    }
   
}

void startServer()
{
    char fileName[FILE_PATH_LENGTH + FILE_NAME_LENGTH + 1];
    struct sockaddr_in si_me;

    // Reset File Handles
    numFileHandles = 0;
    fileNums = 0;
    fnumFile = NULL; 
    
    // Reset Packet Buffering and Network Handles
    sock= -1;
    packetBufferStart=0; // Current Buffer start position
    packetBufferSize=0; // Number of elements on buffer
    
    // Open Handle for file count file
    sprintf(fileName, "%s/fnum.txt", dataDir);
    fnumFile = fopen(fileName, "w");
    if(fnumFile == NULL){
        mexPrintf("FATAL ERROR: Could not open fnumFile: %s \n", fileName);
        return;
    }
    fprintf(fnumFile, "%d", 0);
    fflush(fnumFile);
    
    // open file log
    sprintf(fileName, "%s/fileLog.txt", dataDir);
    fileLog = fopen(fileName, "w");
    if(fileLog == NULL){
        mexPrintf("FATAL ERROR: Could not open fileLog: %s \n", fileName);
        return;
    }
    fprintf(fileLog, "File Logger started\n");
    fflush(fileLog);
    
    
    //mexPrintf("Setting up socket\n");
    if ((sock=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1)
        diep("socket");
    
    int a = 1024*1024; // Set socket buffer size to avoid dropped packets
    if (setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (char*)&a, sizeof(int)) == -1) {
        fprintf(stderr, "Error setting socket receive buffer size \n");
    }
    
    
    // Setup Local Socket on specified port to accept from any address
    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;
    si_me.sin_port = htons(PORT);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(sock,(struct sockaddr*) &si_me, sizeof(si_me))==-1)
        diep("bind");
    nonblockingsocket(sock);
    
    //Start File Writer Thread
    //mexPrintf("Starting File Writer Thread\n");
    int rc = pthread_create(&fileThread, NULL, fileWriterThread, NULL);
    if (rc) {
        mexPrintf("ERROR!  Return code from pthread_create() is %d\n", rc);
        exit(-1);
    }
    
    //mexPrintf("Starting UDP Thread \n");
    rc = pthread_create(&udpThread, NULL, udpReaderThread, NULL);
    if (rc) {
        mexPrintf("ERROR!  Return code from pthread_create() is %d\n", rc);
        exit(-1);
    }
    
}


void mexFunction(
        int           nlhs,           /* number of expected outputs */
        mxArray       *plhs[],        /* array of pointers to output arguments */
        int           nrhs,           /* number of inputs */
        const mxArray *prhs[]         /* array of pointers to input arguments */
        )
{
    char fun[80+1];
    //mexPrintf("ENTER_MEX with %d arguments\n", nrhs);
    
    if(mex_call_counter==0)
    {
#ifdef WIN32
        WORD wVersionRequested;
        WSADATA wsaData;
        int wsa_err;
        wVersionRequested = MAKEWORD( 2, 0 );
        wsa_err = WSAStartup( wVersionRequested, &wsaData );
        if (wsa_err)
            mexErrMsgTxt("Error starting WINSOCK32.");
#endif
       
    }
    mex_call_counter++;
    
    if((nrhs == 2) && mxIsChar(prhs[0]) && mxIsChar(prhs[1])){
        // GET FIRST ARGUMENT -- The "function" name 
        mxGetString(prhs[0],fun,80);
        mxGetString(prhs[1],dataDir,FILE_PATH_LENGTH);
        if(mexIsLocked())
        {
            mexPrintf("udpFileWriter: UDP Server already Started!\n");
        }
        else if(myoptstrcmp(fun,"START")==0){
            //mexPrintf("udpFileWriter: Starting UDP Server\n");
            mexLock();
            startServer();
            return;
        }
    }
    
    else if((nrhs == 1) && mxIsChar(prhs[0])){
        // GET FIRST ARGUMENT -- The "function" name 
        mxGetString(prhs[0],fun,80);
    
        if((myoptstrcmp(fun,"STOP")==0) && mexIsLocked()){
            mexPrintf("Stopping UDP Server\n");
            stopServer();
            mexUnlock();
            return;
        }
    }
    else
        mexPrintf("Invalid Syntax!!\n"); 
    
    return;
}
