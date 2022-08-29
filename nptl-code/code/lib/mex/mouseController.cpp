
// Windows Instructions: 
//      For mex compilation on linux: mex mouseController.cpp -lXtst -lX11



#include "math.h"
#include "mex.h"   //--This one is required

#include<pthread.h>
#include <unistd.h>
#include<X11/Xlib.h>
#include<X11/extensions/XTest.h>
#include <stdio.h>

// 
// #include<string.h>
// #include <stdint.h>
// #include <stdlib.h>
#include <ctype.h>
// 
// 
// #include <arpa/inet.h>
#include <inttypes.h>
// #include <netdb.h>
// #include <sys/types.h>
// #include <sys/socket.h>
// #include <netinet/in.h>
// #include <arpa/inet.h>
// #include <fcntl.h>
// #define nonblockingsocket(s)  fcntl(s,F_SETFL,O_NONBLOCK)
// #define Sleep(a) usleep(a*1000)
// #endif


///////////// DATA TYPES DECLARATIONS /////////////
typedef uint8_t uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef unsigned long long uint64;


struct jnk {
    uint32 x;
    uint32 y;
} packetSwitch;

///////////// GLOBALS /////////////

pthread_t mouseThread;
Display *dpy;

int mex_call_counter = 0; 


pthread_mutex_t packetDataMutex = PTHREAD_MUTEX_INITIALIZER;



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


void diep(const char *s)
{
  mexPrintf("Error with sockets: %s \n", s);
  perror(s);
  //exit(1);
}

void setDesiredPosition(uint32 x, uint32 y) {
  // Packet Buffer Critical Section
  pthread_mutex_lock(&packetDataMutex);
  packetSwitch.x = x;
  packetSwitch.y = y;
  pthread_mutex_unlock(&packetDataMutex);
    
}

void getDesiredPosition(uint32 *x, uint32 *y) {
  pthread_mutex_lock(&packetDataMutex);
  *x = packetSwitch.x;
  *y = packetSwitch.y;
  pthread_mutex_unlock(&packetDataMutex);
}

int setCurrentPosition(uint32 x, uint32 y) {
    return XTestFakeMotionEvent(dpy,0,x,y,0);
}

void stopServer()
{
  mexPrintf("Finishing Mouse Receive\n");
  XCloseDisplay(dpy);
  pthread_cancel(mouseThread);
  pthread_join(mouseThread, NULL);
}


void * mouseReceiverThread(void * dummy)
{
    pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
    uint32 x,y;
        
    while(1)
    {        
        // Read
        getDesiredPosition(&x,&y);
        if (!setCurrentPosition(x,y)) {
            mexPrintf("Problem Setting Position!\n");
        }
    }
   
}

void startServer()
{
    
    mexPrintf("Starting mouse receive Thread \n");
    int rc = pthread_create(&mouseThread, NULL, mouseReceiverThread, NULL);
    mexPrintf("Created Thread\n");
    if (rc) {
        mexPrintf("ERROR!  Return code from pthread_create() is %d\n", rc);
        exit(-1);
    }
    else {
        mexPrintf("Opening Display!\n");
        dpy = XOpenDisplay(NULL);
        mexPrintf("Going to sleep\n");
        sleep(5);
    }
    mexPrintf("Returning from start server\n");
    
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
        mex_call_counter++;
    }
    
    if((nrhs == 1) && mxIsChar(prhs[0])){
        // GET FIRST ARGUMENT -- The "function" name 
        mxGetString(prhs[0],fun,80);
        
        
        if(myoptstrcmp(fun,"START")==0){
            if(mexIsLocked())
            {
                mexPrintf("Mouse Receiver already Started!\n");
            }
            else
            {
                mexPrintf("Starting Mouse Receiver\n");
                mexLock();
                startServer();
                mexPrintf("Start server returned!\n");
                
                return;
            }
        }
    
        else if((myoptstrcmp(fun,"STOP")==0) && mexIsLocked()){
            mexPrintf("Stopping Mouse Receiver\n");
            stopServer();
            mexUnlock();
            return;
        }
        else
            mexPrintf("Invalid Syntax!!\n");
    }
    else if((nrhs == 1) && (nlhs == 0) && (mxGetClassID(prhs[0]) == mxUINT32_CLASS))
    {
        
    }
    else
        mexPrintf("Invalid Syntax!!\n"); 
    
    return;
    }
