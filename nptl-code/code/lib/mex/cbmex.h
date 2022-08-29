/* =STS=> cbmex.h[4257].aa06   submit   SMID:7 */
//////////////////////////////////////////////////////////////////////////////
//
// (c) Copyright 2010 - 2011 Blackrock Microsystems
//
// $Workfile: cbmex.h $
// $Archive: /Cerebus/Human/WindowsApps/cbmex/cbmex.h $
// $Revision: 1 $
// $Date: 2/17/11 3:15p $
// $Author: Ehsan $
//
// $NoKeywords: $
//
//////////////////////////////////////////////////////////////////////////////
//
// PURPOSE:
//
// cbmex SDK
// This header file is distributed as part of the SDK
//

#ifndef CBMEX_H_INCLUDED
#define CBMEX_H_INCLUDED

#include "cbhwlib.h"

#ifdef CBMEX_EXPORTS
#define CBMEXAPI __declspec(dllexport)
#else
#ifndef STATIC_CBMEX_LINK
#define CBMEXAPI __declspec(dllimport)
#else
#define CBMEXAPI
#endif
#endif

/*
* library version information.
*/
typedef struct _cbMexVersion
{
    // Library version
    UINT32 major;
    UINT32 minor;
    UINT32 release;
    UINT32 beta;
    // Protocol version
    UINT32 majorp;
    UINT32 minorp;
    // NSP version
    UINT32 nspmajor;
    UINT32 nspminor;
    UINT32 nsprelease;
    UINT32 nspbeta;
} cbMexVersion;

/* cbMex return values */
typedef enum _cbMexResult
{
    CBMEXRESULT_WARNCLOSED             =     2, // Library is already closed
    CBMEXRESULT_WARNOPEN               =     1, // Library is already opened
    CBMEXRESULT_SUCCESS                =     0, // Successful operation
    CBMEXRESULT_NOTIMPLEMENTED         =    -1, // Not implemented
    CBMEXRESULT_UNKNOWN                =    -2, // Unknown error
    CBMEXRESULT_INVALIDPARAM           =    -3, // Invalid parameter
    CBMEXRESULT_CLOSED                 =    -4, // Interface is closed cannot do this operation
    CBMEXRESULT_OPEN                   =    -5, // Interface is open cannot do this operation
    CBMEXRESULT_NULLPTR                =    -6, // Null pointer
    CBMEXRESULT_ERROPENCENTRAL         =    -7, // Unable to open Central interface
    CBMEXRESULT_ERROPENUDP             =    -8, // Unable to open UDP interface (might happen if default)
    CBMEXRESULT_ERROPENUDPPORT         =    -9, // Unable to open UDP port
    CBMEXRESULT_ERRMEMORYTRIAL         =   -10, // Unable to allocate RAM for trial cache data
    CBMEXRESULT_ERROPENUDPTHREAD       =   -11, // Unable to open UDP timer thread
    CBMEXRESULT_ERROPENCENTRALTHREAD   =   -12, // Unable to open Central communication thread
    CBMEXRESULT_INVALIDCHANNEL         =   -13, // Invalid channel number
    CBMEXRESULT_INVALIDCOMMENT         =   -14, // Comment too long or invalid
    CBMEXRESULT_INVALIDFILENAME        =   -15, // Filename too long or invalid
    CBMEXRESULT_INVALIDCALLBACKTYPE    =   -16, // Invalid callback type
    CBMEXRESULT_CALLBACKREGFAILED      =   -17, // Callback register/unregister failed
    CBMEXRESULT_ERRCONFIG              =   -18, // Trying to run an unconfigured method
    CBMEXRESULT_INVALIDTRACKABLE       =   -19, // Invalid trackable id, or trackable not present
    CBMEXRESULT_INVALIDVIDEOSRC        =   -20, // Invalid video source id, or video source not present
} cbMexResult;

typedef enum _cbMexConnectionType
{
    CBMEXCONNECTION_DEFAULT = 0, // Try Central then UDP
    CBMEXCONNECTION_CENTRAL,     // Use Central
    CBMEXCONNECTION_UDP,         // Use UDP
    CBMEXCONNECTION_CLOSED // Allways the last value (Closed)
} cbMexConnectionType;

typedef enum _cbMexInstrumentType
{
    CBMEXINSTRUMENT_NSP = 0,       // NSP
    CBMEXINSTRUMENT_NPLAY,         // Local nPlay
    CBMEXINSTRUMENT_LOCALNSP,      // Local NSP
    CBMEXINSTRUMENT_REMOTENPLAY,   // Remote nPlay
    CBMEXINSTRUMENT_COUNT // Allways the last value (Invalid)
} cbMexInstrumentType;

typedef enum _cbMexPktType
{
    cbMexPkt_PACKETLOST = 0, // packet lost event (will be received only by the first registered callback)
    cbMexPkt_SPIKE,
    cbMexPkt_DIGITAL,
    cbMexPkt_SERIAL,
    cbMexPkt_CONTINUOUS,
    cbMexPkt_TRACKING,
    cbMexPkt_COMMENT,
    cbMexPkt_GROUPINFO,
    cbMexPkt_CHANINFO,
    //////////////////////////////////////////////
    cbMexPkt_FILECFG,
    cbMexPkt_IMPEDANCE,
    cbMexPkt_POLL,
    cbMexPkt_PATIENTINFO,
    //////////////////////////////////////////////
    cbMexPkt_SYNCH,
    cbMexPkt_NM,
    cbMexPkt_COUNT // Allways the last value
} cbMexPktType;

typedef enum _cbMexCallbackType
{
    CBMEXCALLBACK_ALL = 0,      // Monitor all events
    CBMEXCALLBACK_SPIKE,        // Monitor spike events
    CBMEXCALLBACK_DIGITAL,      // Monitor digital input events
    CBMEXCALLBACK_SERIAL,       // Monitor serial input events
    CBMEXCALLBACK_CONTINUOUS,   // Monitor continuous events
    CBMEXCALLBACK_TRACKING,     // Monitor video tracking events
    CBMEXCALLBACK_COMMENT,      // Monitor comment or custom events
    CBMEXCALLBACK_GROUPINFO,    // Monitor channel group info events
    CBMEXCALLBACK_CHANINFO,     // Monitor channel info events
    CBMEXCALLBACK_POLL,         // respond to poll
    CBMEXCALLBACK_SYNCH,        // Monitor video synchronizarion events
    CBMEXCALLBACK_NM,           // Monitor NeuroMotive events
    CBMEXCALLBACK_COUNT  // Always the last value
} cbMexCallbackType;

typedef enum _cbMexTrialType
{
    CBMEXTRIAL_CONTINUOUS,
    CBMEXTRIAL_EVENTS,
    CBMEXTRIAL_COMMETNS,
    CBMEXTRIAL_TRACKING,
} cbMexTrialType;

typedef void (* cbMexCallback)(const cbMexPktType type, const void* pEventData, void* pCallbackData);
// pEventData points to a cbPkt_* structure depending on the type
// pCallbackData is what is used to register the callback

/// The default number of continuous samples that will be stored per channel in the trial buffer
#define cbMex_CONTINUOUS_DATA_SAMPLES 102400 // multiple of 4096
/// The default number of events that will be stored per channel in the trial buffer
#define cbMex_EVENT_DATA_SAMPLES (2 * 8192) // multiple of 4096
/// The number of seconds corresponding to one cb clock tick
#define cbMex_TICKS_PER_SECOND  30000.0
#define cbMex_SECONDS_PER_TICK  (1.0 / cbMex_TICKS_PER_SECOND)

// Trial spike events
typedef struct _cbMexTrialEvent
{
    UINT16 count; // Number of valid channels in this trial (up to cbNUM_ANALOG_CHANS+2)
    UINT16 chan[cbNUM_ANALOG_CHANS + 2]; // channel numbers (1-based)
    UINT32 num_samples[cbNUM_ANALOG_CHANS + 2][cbMAXUNITS + 1]; // number of samples
    void * timestamps[cbNUM_ANALOG_CHANS + 2][cbMAXUNITS + 1];   // Buffer to hold time stamps
    void * waveforms[cbNUM_ANALOG_CHANS + 2]; // Buffer to hold waveforms or digital values
} cbMexTrialEvent;

// Trial continuous data
typedef struct _cbMexTrialCont
{
    UINT16 count; // Number of valid channels in this trial (up to cbNUM_ANALOG_CHANS)
    UINT16 chan[cbNUM_ANALOG_CHANS]; // channel numbers (1-based)
    UINT16 sample_rates[cbNUM_ANALOG_CHANS]; // current sample rate (samples per second)
    UINT32 num_samples[cbNUM_ANALOG_CHANS]; // number of samples
    UINT32 time;  // start time for trial continuous data
    void * samples[cbNUM_ANALOG_CHANS]; // Buffer to hold sample vectors
} cbMexTrialCont;

// Trial comment data
typedef struct _cbMexTrialComment
{
    UINT16 num_samples; // Number of comments
    UINT8 * charsets;   // Buffer to hold character sets
    UINT32 * rgbas;     // Buffer to hold rgba values
    UINT8 * * comments; // Pointer to comments
    void * timestamps;  // Buffer to hold time stamps
} cbMexTrialComment;

// Trial video tracking data
typedef struct _cbMexTrialTracking
{
    UINT16 count; // Number of valid trackable objects (up to cbMAXTRACKOBJ)
    UINT16 ids[cbMAXTRACKOBJ];   // Node IDs (holds count elements)
    UINT16 max_point_counts[cbMAXTRACKOBJ];   // Maximum point counts (holds count elements)
    UINT16 types[cbMAXTRACKOBJ];   // Node types (can be cbTRACKOBJ_TYPE_* and determines coordinate counts) (holds count elements)
    UINT8  names[cbMAXTRACKOBJ][cbLEN_STR_LABEL + 1];   // Node names (holds count elements)
    UINT16 num_samples[cbMAXTRACKOBJ]; // Number of samples
    UINT16 * point_counts[cbMAXTRACKOBJ];  // Buffer to hold number of valid points (up to max_point_counts) (holds count*num_samples elements)
    UINT16 * * coords[cbMAXTRACKOBJ] ;     // Buffer to hold tracking points (holds count*num_samples tarackables, each of max_point_counts points
    UINT32 * synch_frame_numbers[cbMAXTRACKOBJ]; // Buffer to hold synch frame numbers (holds count*num_samples elements)
    UINT32 * synch_timestamps[cbMAXTRACKOBJ];    // Buffer to hold synchronized tracking time stamps (in milliseconds) (holds count*num_samples elements)
    void  * timestamps[cbMAXTRACKOBJ];          // Buffer to hold tracking time stamps (holds count*num_samples elements)
} cbMexTrialTracking;

CBMEXAPI    cbMexResult cbMexGetVersion(cbMexVersion * version); // Get the library version (and nsp version if library is open)

CBMEXAPI    cbMexResult cbMexOpen(cbMexConnectionType conType, UINT32 thread_id);
#ifdef __cplusplus
CBMEXAPI    cbMexResult cbMexOpen(cbMexConnectionType conType = CBMEXCONNECTION_DEFAULT); // Open the library
#else
CBMEXAPI    cbMexResult cbMexOpen(cbMexConnectionType conType); // Open the library
#endif

CBMEXAPI    cbMexResult cbMexGetType(cbMexConnectionType * conType, cbMexInstrumentType * instType); // Get connection and instrument type

CBMEXAPI    cbMexResult cbMexClose(); // Close the library

CBMEXAPI    cbMexResult cbMexGetTime(UINT32 * cbtime); // Get the instrument sample clock time

// Setup a trial
#ifdef __cplusplus
CBMEXAPI    cbMexResult cbMexSetTrialConfig(UINT32 bActive, UINT16 begchan = 0, UINT32 begmask = 0, UINT32 begval = 0,
                                         UINT16 endchan = 0, UINT32 endmask = 0, UINT32 endval = 0, bool bDouble = false,
                                         UINT32 uWaveforms = 0, UINT32 uConts = cbMex_CONTINUOUS_DATA_SAMPLES, UINT32 uEvents = cbMex_EVENT_DATA_SAMPLES,
                                         UINT32 uComments = 0, UINT32 uTrackings = 0); // Configure a data collection trial
#else
CBMEXAPI    cbMexResult cbMexSetTrialConfig(UINT32 bActive, UINT16 begchan, UINT32 begmask, UINT32 begval,
                                         UINT16 endchan, UINT32 endmask, UINT32 endval, bool bDouble,
                                         UINT32 uWaveforms, UINT32 uConts, UINT32 uEvents
                                         UINT32 uComments, UINT32 uTrackings); // Configure a data collection trial
#endif
// begchan - first channel number (1-based), zero means all
// endchan - last channel number (1-based), zero means all

// Close given trial if configured
CBMEXAPI    cbMexResult cbMexUnsetTrialConfig(cbMexTrialType type);

CBMEXAPI    cbMexResult cbMexGetChannelLabel(UINT16 channel, UINT32 bValid[6], char label[32], UINT32 * userflags, INT32 position[4]); // Get channel label
CBMEXAPI    cbMexResult cbMexSetChannelLabel(UINT16 channel, char label[32], UINT32 userflags, INT32 position[4]); // Set channel label

// Retrieve data of a trial (NULL means ignore), user should allocate enough buffers beforehand, and trial should not be closed during this call
CBMEXAPI    cbMexResult cbMexGetTrialData(UINT32 bActive, cbMexTrialEvent * trialevent, cbMexTrialCont * trialcont,
                                          cbMexTrialComment * trialcomment, cbMexTrialTracking * trialtracking);

// Initialize the structures (and fill with information about active channels, comment pointers and samples in the buffer)
CBMEXAPI    cbMexResult cbMexInitTrialData(cbMexTrialEvent * trialevent, cbMexTrialCont * trialcont,
                                           cbMexTrialComment * trialcomment, cbMexTrialTracking * trialtracking);

#ifdef __cplusplus
CBMEXAPI    cbMexResult cbMexSetFileConfig(const char * filename, const char * comment, UINT32 bStart, UINT32 options = cbFILECFG_OPT_NONE); // Start file recording
#else
CBMEXAPI    cbMexResult cbMexSetFileConfig(const char * filename, const char * comment, UINT32 bStart, UINT32 options); // Start file recording
#endif

CBMEXAPI    cbMexResult cbMexSetPatientInfo(const char * ID, const char * firstname, const char * lastname, UINT32 DOBMonth, UINT32 DOBDay, UINT32 DOBYear);

CBMEXAPI    cbMexResult cbMexInitiateImpedance();

CBMEXAPI    cbMexResult cbMexSendPoll(const char* appname, UINT32 mode, UINT32 flags, UINT32 extra);

// This sends an arbitrary packet without any validation, please use with care or it might break the system
CBMEXAPI    cbMexResult cbMexSendPacket(void * ppckt);

CBMEXAPI    cbMexResult cbMexSetSystemRunLevel( UINT32 runlevel, UINT32 locked, UINT32 resetque);

CBMEXAPI    cbMexResult cbMexSetDigitalOutput(UINT16 channel, UINT16 value); // Send a digital output command

CBMEXAPI    cbMexResult cbMexSetAnalogOutput(UINT16 channel, cbWaveformData * wf); // Send a analog output waveform

CBMEXAPI    cbMexResult cbMexSetChannelMask(UINT16 channel, UINT32 bActive); // Mask channels (for both trial and callback)
// channel - channel number (1-based), zero means all channels

#ifdef __cplusplus
CBMEXAPI    cbMexResult cbMexSetComment(UINT32 rgba, UINT8 charset, const char * comment = NULL); // Send a comment or custom event
#else
CBMEXAPI    cbMexResult cbMexSetComment(UINT32 rgba, UINT8 charset, const char * comment); // Send a comment or custom event
#endif

CBMEXAPI    cbMexResult cbMexSetChannelConfig(UINT16 channel, cbPKT_CHANINFO * chaninfo); // Send a full channel configuration packet
CBMEXAPI    cbMexResult cbMexGetChannelConfig(UINT16 channel, cbPKT_CHANINFO * chaninfo); // Get a full channel configuration packet

// Get filter description (proc = 1 for now)
CBMEXAPI    cbMexResult cbMexGetFilterDesc(UINT32 proc, UINT32 filt, cbFILTDESC * filtdesc);

// Get sample group list (proc = 1 for now)
CBMEXAPI    cbMexResult cbMexGetSampleGroupList(UINT32 proc, UINT32 group, UINT32 *length, UINT32 *list);

// Get information about given trackable object
// id   - trackable ID (1 to cbMAXTRACKOBJ)
// name - string of length cbLEN_STR_LABEL
CBMEXAPI    cbMexResult cbMexGetTrackObj(char *name, UINT16 *type, UINT16 *pointCount, UINT32 id);

// Get video source information
// id   - video source ID (1 to cbMAXVIDEOSOURCE)
// name - string of length cbLEN_STR_LABEL
CBMEXAPI    cbMexResult cbMexGetVideoSource(char *name, float *fps, UINT32 id);

CBMEXAPI    cbMexResult cbMexSetSpikeConfig(UINT32 spklength, UINT32 spkpretrig); // Send global spike configuration

#ifdef __cplusplus
CBMEXAPI    cbMexResult cbMexGetSysConfig(UINT32 * spklength, UINT32 * spkpretrig = NULL, UINT32 * sysfreq = NULL); // Get global system configuration
#else
CBMEXAPI    cbMexResult cbMexGetSysConfig(UINT32 * spklength, UINT32 * spkpretrig, UINT32 * sysfreq); // Get global system configuration
#endif

CBMEXAPI    cbMexResult cbMexRegisterCallback(cbMexCallbackType callbacktype, cbMexCallback pCallbackFn, void* pCallbackData);
CBMEXAPI    cbMexResult cbMexUnRegisterCallback(cbMexCallbackType callbacktype);
// At most one callback per each callback type per each connection

#endif /* CBMEX_H_INCLUDED */
