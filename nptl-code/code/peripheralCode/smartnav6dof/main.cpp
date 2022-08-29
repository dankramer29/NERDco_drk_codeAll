
//=================================================================================-----
//== NaturalPoint 2010
//== Camera Library SDK Sample
//==
//== This sample brings up a connected camera and displays it's output frames.
//=================================================================================-----

#include "supportcode.h"       //== Boiler-plate code for application window init ===---
#include "cameralibrary.h"     //== Camera Library header file ======================---
#include "modulevector.h"
#include "modulevectorprocessing.h"
#include "coremath.h"
#include "timebase.h"

#include <gl/glu.h>

#include <iostream>
#include <WinSock2.h>

using namespace CameraLibrary; 

// packet structure 
typedef struct {
	float time;      
	float X;
	float Y;
	float Z;
	float Yaw;
	float Pitch;
	float Roll;
} sixDPacket;

int main(int argc, char* argv[])
{
	  
	printf("hi");

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
		sprintf(errString,"%ld", WSAGetLastError());
		MessageBox(0, errString, "Socket Creation Error", MB_OK);
		return 1;
	}

	int status;
	bool broadcastVal = true;
	status = setsockopt(_SendingSocket, SOL_SOCKET, SO_BROADCAST, (char *)&broadcastVal, sizeof(broadcastVal));
	if (status < 0) {
		char errString[256];
		sprintf(errString, "%ld", WSAGetLastError());
		MessageBox(0, errString, "Broadcast setting error", MB_OK);
		return 1;
	}

	struct sockaddr_in LocalAddr;
	LocalAddr.sin_family = AF_INET;
	LocalAddr.sin_port = htons(17000);
	LocalAddr.sin_addr.s_addr = inet_addr("192.168.30.1");

	//-----------------------------------------------
	// Bind the local send socket. I think this is necessary for PCs with multiple NSPs.
	struct sockaddr* local = (struct sockaddr *) &LocalAddr;
	if (bind(_SendingSocket, local, sizeof(struct sockaddr_in)) == SOCKET_ERROR)
	{
		char errString[256];
		sprintf(errString, "%ld", WSAGetLastError());
		MessageBox(0, errString, "Binding error", MB_OK);
		return 1;
	}

	//== For OptiTrack Ethernet cameras, it's important to enable development mode if you
	//== want to stop execution for an extended time while debugging without disconnecting
	//== the Ethernet devices.  Lets do that now:

    CameraLibrary_EnableDevelopment();

	//== Initialize Camera SDK ==--

	CameraLibrary::CameraManager::X();

	//== At this point the Camera SDK is actively looking for all connected cameras and will initialize
	//== them on it's own.

	//== Now, lets pop a dialog that will persist until there is at least one camera that is initialized
	//== or until canceled.

	PopWaitingDialog();

    //== Get a connected camera ================----

    Camera *camera = CameraManager::X().GetCamera();

    //== If no device connected, pop a message box and exit ==--

    if(camera==0)
    {
        MessageBox(0,"Please connect a camera","No Device Connected", MB_OK);
        return 1;
    }

	//== Determine camera resolution to size application window ==----
	
    int cameraWidth  = camera->Width();
    int cameraHeight = camera->Height();

    int WindowWidth = 800;
    int WindowHeight = 450;

	double X = 0;
	double Y = 0;
	double Z = 0;
	double Yaw = 0;
	double Pitch = 0;
	double Roll = 0;

 	//== Open the application window =============================----
		
    if (!CreateAppWindow("Camera Library SDK - Single Camera Tracking Sample",WindowWidth,WindowHeight,32,gFullscreen))
	    return 0;

    //== Create a texture to push the rasterized camera image ====----

    //== We're using textures because it's an easy & cpu light 
    //== way to utilize the 3D hardware to display camera
    //== imagery at high frame rates

    Surface  Texture(cameraWidth, cameraHeight);
    Bitmap * framebuffer = new Bitmap(cameraWidth, cameraHeight, Texture.PixelSpan()*4,
                               Bitmap::ThirtyTwoBit, Texture.GetBuffer());

    //== Set Video Mode ==--

    //== We set the camera to Segment Mode here.  This mode is support by all of our products.
    //== Depending on what device you have connected you might want to consider a different
    //== video mode to achieve the best possible tracking quality.  All devices that support a
    //== mode that will achieve a better quality output with a mode other than Segment Mode are
    //== listed here along with what mode you should use if you're looking for the best head
    //== tracking:
    //==
    //==     V100:R1/R2    Precision Mode
    //==     TrackIR 5     Bit-Packed Precision Mode
    //==     V120          Precision Mode
    //==     TBar          Precision Mode
    //==     S250e         Precision Mode
    //==
    //== If you have questions about a new device that might be conspicuously missing here or
    //== have any questions about head tracking, email support or participate in our forums.

    camera->SetVideoType(Core::PrecisionMode); //maybe better than SegmentMode?
    
    //== Start camera output ==--

    camera->Start();

    //== Turn on some overlay text so it's clear things are     ===---
    //== working even if there is nothing in the camera's view. ===---

    camera->SetTextOverlay(false);

    cModuleVector *vec = cModuleVector::Create();
	cModuleVectorProcessing *vecprocessor = cModuleVectorProcessing::Create();

    Core::DistortionModel lensDistortion;

    camera->GetDistortionModel(lensDistortion);

    //== Plug distortion into vector module ==--

    cVectorSettings vectorSettings;
    vectorSettings = *vec->Settings();

    vectorSettings.Arrangement = cVectorSettings::VectorClip;
    vectorSettings.Enabled     = true;
    
    cVectorProcessingSettings vectorProcessorSettings;

    vectorProcessorSettings = *vecprocessor->Settings();

    vectorProcessorSettings.Arrangement = cVectorSettings::VectorClip;
    vectorProcessorSettings.ShowPivotPoint = false;
    vectorProcessorSettings.ShowProcessed  = false;

    vecprocessor->SetSettings(vectorProcessorSettings);

    //== Plug in focal length in (mm) by converting it from pixels -> mm

    vectorSettings.ImagerFocalLength =  (lensDistortion.HorizontalFocalLength/((float) camera->PhysicalPixelWidth()))*camera->ImagerWidth();

    vectorSettings.ImagerHeight = camera->ImagerHeight();
    vectorSettings.ImagerWidth  = camera->ImagerWidth();

    vectorSettings.PrincipalX   = camera->PhysicalPixelWidth()/2;
    vectorSettings.PrincipalY   = camera->PhysicalPixelHeight()/2;

    vectorSettings.PixelWidth   = camera->PhysicalPixelWidth();
    vectorSettings.PixelHeight  = camera->PhysicalPixelHeight();

    vec->SetSettings(vectorSettings);

    //== Ok, start main loop.  This loop fetches and displays   ===---
    //== camera frames.                                         ===---
	cPrecisionTimeBase timer;
	double prevTime = timer.Elapsed();

    while(1)
    {
        //== Fetch a new frame from the camera ===---

        Frame *frame = camera->GetFrame();

        if(frame)
        {
            //== Ok, we've received a new frame, lets do something
            //== with it.

            //== Lets have the Camera Library raster the camera's
            //== image into our texture.

            frame->Rasterize(framebuffer);

            vec->BeginFrame();

            for(int i=0; i<frame->ObjectCount(); i++)
            {
                cObject *obj = frame->Object(i);

                float x = obj->X();
                float y = obj->Y();

                Core::Undistort2DPoint(lensDistortion,x,y);

                vec->PushMarkerData(x, y, obj->Area(), obj->Width(), obj->Height());
            }
            vec->Calculate();
            vecprocessor->PushData(vec);
            
			//get position and orientation
			vecprocessor->GetPosition(X, Y, Z);
			vecprocessor->GetOrientation(Yaw, Pitch, Roll);

			//display as a sanity check
			char st[80];
			sprintf_s(st, 80, "Pos X %.1f", X);
			framebuffer->PrintLarge(100, 100, st);

			//get time elapsed since last frame
			double timeNow = timer.Elapsed();
			double timeDiff = timeNow - prevTime;
			prevTime = timeNow;

			//send packet
			
			sixDPacket *sendPacket = new sixDPacket();
			sendPacket->time = timeDiff;
			sendPacket->X = (float)X;
			sendPacket->Y = (float)Y;
			sendPacket->Z = (float)Z;
			sendPacket->Yaw = (float)Yaw;
			sendPacket->Pitch = (float)Pitch;
			sendPacket->Roll = (float)Roll;

			// create remote address struct
			struct sockaddr_in RemoteAddr;
			RemoteAddr.sin_family = AF_INET;
			RemoteAddr.sin_port = htons(50140);
			RemoteAddr.sin_addr.s_addr = inet_addr("192.168.30.255");
			struct sockaddr* remote = (struct sockaddr *) &RemoteAddr;

			// send packet
			if (sendto(_SendingSocket, (char*)sendPacket, sizeof(sixDPacket), 0, (SOCKADDR *)&RemoteAddr, sizeof(RemoteAddr)) == SOCKET_ERROR)
			{
				char errString[256];
				sprintf(errString, "%ld", WSAGetLastError());
				MessageBox(0, errString, "UDP Send Error", MB_OK);
				return 1;
			}
			
            StartScene();

            glEnable(GL_BLEND);
            glColor4f(1,1,1,0.3f);
            glBegin(GL_LINES);
            glVertex3f(10,0,0);glVertex3f(-10, 0,0);
            glVertex3f(0,10,0);glVertex3f( 0,-10,0);
            glVertex3f(0,0,10);glVertex3f( 0, 0,-10);
            glEnd();

            if(vecprocessor->MarkerCount()>0)
            {
                glColor3f(0,1,1);
                glBegin(GL_LINES);
                
                for(int i=0; i<vecprocessor->MarkerCount(); i++)
                    for(int j=0; j<vecprocessor->MarkerCount(); j++)
                    {
                        if(i!=j)
                        {
                            float x,y,z;
                            vecprocessor->GetResult(i,x,y,z);
                            glVertex3f(x/200,y/200,z/200);
                            vecprocessor->GetResult(j,x,y,z);
                            glVertex3f(x/200,y/200,z/200);

                        }
                    }

                glEnd();

            }

            //== Display Camera Image ============--

            if(!DrawGLScene(&Texture))  
                break;

            //== Escape key to exit application ==--

            if (keys[VK_ESCAPE])
                break;

            //== Release frame =========--

            frame->Release();
        }

	    //Sleep(2);

        //== Service Windows Message System ==--

        if(!PumpMessages())
            break;
    }

    //== Close window ==--

    CloseWindow();

    //== Release camera ==--

    camera->Release();

    //== Shutdown Camera Library ==--

    CameraManager::X().Shutdown();

	//Shutdown sockets
	WSACleanup();

    //== Exit the application.  Simple! ==--

	return 1;
}

