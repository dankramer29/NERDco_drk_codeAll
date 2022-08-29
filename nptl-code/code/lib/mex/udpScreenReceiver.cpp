
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
//#include <windows.h>
#include <winsock2.h>
#include <WS2tcpip.h>
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

//#define DATA_PORT 50114

#define MAX_PACKET_LENGTH 1500
//#define SRV_IP "192.168.30.4"

#define XSTR(x) STR(x)
#define STR(x) #x
#pragma message "the value of SRV_IP: " XSTR(SRV_IP1)
#define SRV_IP XSTR(SRV_IP1)

///////////// PROTOTYPES /////////////


///////////// DATA TYPES DECLARATIONS /////////////
typedef uint8_t uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef unsigned long long uint64;



///////////// GLOBALS /////////////

pthread_t udpThread;

int mex_call_counter = 0; 

int sock = -1;
struct sockaddr_in si_other; // address for writing responses 

int packetSwitch = -1;
uint8 packetData0[MAX_PACKET_LENGTH];
uint8 packetData1[MAX_PACKET_LENGTH];
int packetLength0;
int packetLength1;

pthread_mutex_t packetDataMutex = PTHREAD_MUTEX_INITIALIZER;





void bufferPacket(char *rawPacket, int packetLength)
{
    int packetSwitchTMP = -1;
    if( (packetSwitch == -1) || (packetSwitch == 1) )
    {
        memcpy(packetData0, rawPacket, packetLength);
        packetLength0 = packetLength;
        packetSwitchTMP = 0;
    }
    else
    {
        memcpy(packetData1, rawPacket, packetLength);
        packetLength1 = packetLength;
        packetSwitchTMP = 1;
    }
    
  // Packet Buffer Critical Section
  pthread_mutex_lock(&packetDataMutex);
  packetSwitch = packetSwitchTMP;
  pthread_mutex_unlock(&packetDataMutex);
  // END CRITICAL SECTION

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
  mexPrintf("Finishing Main\n");
  pthread_cancel(udpThread);
  pthread_join(udpThread, NULL);
  close(sock);
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

void * udpReceiverThread(void * dummy)
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
       
         pthread_testcancel();
         
    }
   
}

void startServer()
{
    struct sockaddr_in si_me;

    
    // Reset Packet Buffering and Network Handles
    sock = -1;
    packetSwitch = -1;

    
    
    mexPrintf("Setting up socket\n");
    if ((sock=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1)
        diep("socket");
    
    int a = MAX_PACKET_LENGTH*5; // Set socket buffer size to avoid dropped packets, so we can grab the most recent one?
    if (setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (char*)&a, sizeof(int)) == -1) {
        fprintf(stderr, "Error setting socket receive buffer size \n");
    }
    
    
    // Setup Local Socket on specified port to accept from any address
    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;
    si_me.sin_port = htons(DATA_PORT);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(sock,(struct sockaddr*) &si_me, sizeof(si_me))==-1)
        diep("bind");
    //nonblockingsocket(sock);
    
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    si_other.sin_port = htons(DATA_PORT);
    
     
//#ifdef WIN32
    if (inet_pton(AF_INET, SRV_IP, &si_other.sin_addr)==0) {
        diep("inet_pton() failed");
    }
/*#else
    if (inet_aton(SRV_IP, &si_other.sin_addr)==0) {
         diep("inet_aton() failed");
    }
#endif*/
    
    mexPrintf("Starting UDP Thread \n");
    int rc = pthread_create(&udpThread, NULL, udpReceiverThread, NULL);
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
    uint8 * packetDataOut; // Pointer for dynamic array in matlab space
    int packetLengthOut = 0;
    
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
    mex_call_counter++;
       
    }
    
    if((nrhs == 1) && mxIsChar(prhs[0])){
        // GET FIRST ARGUMENT -- The "function" name 
        mxGetString(prhs[0],fun,80);
        
        
        if(myoptstrcmp(fun,"START")==0){
            if(mexIsLocked())
            {
                mexPrintf("UDP Screen Receiver already Started!\n");
            }
            else
            {
                mexPrintf("Starting UDP Server\n");
                mexLock();
                startServer();
                return;
            }
        }
    
        else if((myoptstrcmp(fun,"STOP")==0) && mexIsLocked()){
            mexPrintf("Stopping UDP Server\n");
            stopServer();
            mexUnlock();
            return;
        }
        else
            mexPrintf("Invalid Syntax!!\n");
    }
    else if((nrhs == 1) && (nlhs == 1) && (mxGetClassID(prhs[0]) == mxUINT32_CLASS))
    {
        plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT8_CLASS, mxREAL);
        packetLengthOut = 0;
        if(mexIsLocked()) // If listening to port, then write to it
        {
            sendto(sock, (char *) mxGetData(prhs[0]), sizeof(UINT32_T), 0, (sockaddr *)&si_other, sizeof(si_other));
        }
        // Begin Critical Section, reading from locked packet data
        pthread_mutex_lock(&packetDataMutex);
        if( packetSwitch == 1 )
        {
            packetDataOut = (uint8 *) mxCalloc(packetLength1, sizeof(UINT8_T));
            memcpy(packetDataOut, packetData1, packetLength1);
            packetLengthOut = packetLength1;
        }
        else if( packetSwitch == 0 )
        {
            packetDataOut = (uint8 *) mxCalloc(packetLength0, sizeof(UINT8_T));
            memcpy(packetDataOut, packetData0, packetLength0);
            packetLengthOut = packetLength0;
        }
        else
        {
            packetDataOut = (uint8 *) mxCalloc(0, sizeof(UINT8_T));
        }
        pthread_mutex_unlock(&packetDataMutex);
        //End Critical Section 
        
        
        
        mxSetData(plhs[0], packetDataOut);
        mxSetM(plhs[0], 1);
        mxSetN(plhs[0], packetLengthOut);
        
    }
    else
        mexPrintf("Invalid Syntax!!\n"); 
    
    return;
    }
