///////////////////////////////////////////////////////////////////////////////////////////////////
//
// (c) Copyright 2002-2008 Cyberkinetics, Inc.
// (c) Copyright 2008-2011 Blackrock Microsystems
//
///////////////////////////////////////////////////////////////////////////////////////////////////

// defines the number of channels that we support
// HACK make this a configurable parameter:
#define NUM_SIM_CHANNELS 96

//  N. Schmansky - copied bare-essential defines and structs to build an NSP simulator

// the version of Blackrock's cbhwlib is selected with USE_CBHWLIB_MAJOR/MINOR
// we're not actually tied to a particular version, just whatever Central needs.
// Update! these are no longer defined here, but instead in xNeuralSim_Init.m,
// where they are set as enviro vars and read at startup.  see constant block
// input to the Configuration_packets S-Function block.
// #define USE_CBHWLIB_MAJOR /// 
// #define USE_CBHWLIB_MINOR /// 

#define UINT32 unsigned int
#define UINT16 unsigned short
#define INT32  int
#define INT16  short
#define UINT8  unsigned char

// sysClock has 30microsecond ticks, so define number of ticks in 1s
#define TICKS_1S 30000

// sysClock has 30microsecond ticks, so define number of ticks in 10ms
#define TICKS_10MS 300

// define the size of the packet header in bytes
#define cbPKT_HEADER_SIZE 8  

// This channel id identifies cerebus system packets
#define CEREBUS_SYSPACKET_CHANNEL 0x8000

// This channel id identifies group packets
#define CEREBUS_GROUPPACKET_CHANNEL 0x0000

// System Heartbeat Packet (sent every 10ms)
#define cbPKTTYPE_SYSHEARTBEAT    0x00
#define cbPKTDLEN_SYSHEARTBEAT    ((sizeof(cbPKT_SYSHEARTBEAT)/4)-2)
typedef struct
{
  unsigned int time;        // system clock timestamp
  unsigned short chid;      // 0x8000
  unsigned char type;       // 0
  unsigned char dlen;       // cbPKTDLEN_SYSHEARTBEAT
} cbPKT_SYSHEARTBEAT;

// Protocol Monitoring packet (sent periodically about every second)
#define cbPKTTYPE_SYSPROTOCOLMONITOR    0x01
#define cbPKTDLEN_SYSPROTOCOLMONITOR    ((sizeof(cbPKT_SYSPROTOCOLMONITOR)/4)-2)
typedef struct
{
  UINT32 time;        // system clock timestamp
  UINT16 chid;        // 0x8000
  UINT8  type;        // 1
  UINT8  dlen;        // cbPKTDLEN_SYSPROTOCOLMONITOR
  UINT32 sentpkts;    // Packets sent since last cbPKT_SYSPROTOCOLMONITOR (or 0 if timestamp=0);
  //  the cbPKT_SYSPROTOCOLMONITOR packets are counted as well so this must
  //  be equal to at least 1
} cbPKT_SYSPROTOCOLMONITOR;

#define cbPKTTYPE_REQCONFIGALL  0x88  // request for ALL configuration information

// Generic Cerebus packet data structure (1024 bytes total)
typedef struct
{
  UINT32 time;        // system clock timestamp
  UINT16 chid;        // channel identifier
  UINT8  type;        // packet type
  UINT8  dlen;        // length of data field in 32-bit chunks
  UINT32 data[254];   // data buffer (up to 1016 bytes)
} cbPKT_GENERIC;

// System Condition Report Packet
#define cbPKTTYPE_SYSREP        0x10
#define cbPKTTYPE_SYSREPSPKLEN  0x11
#define cbPKTTYPE_SYSREPRUNLEV  0x12
#define cbPKTTYPE_SYSSET        0x90
#define cbPKTTYPE_SYSSETSPKLEN  0x91
#define cbPKTTYPE_SYSSETRUNLEV  0x92
#define cbPKTDLEN_SYSINFO       ((sizeof(cbPKT_SYSINFO)/4)-2)
typedef struct
{
  UINT32 time;        // system clock timestamp
  UINT16 chid;        // 0x8000
  UINT8  type;        // PKTTYPE_SYS*
  UINT8  dlen;        // cbPKT_SYSINFODLEN
  UINT32 sysfreq;     // System clock frequency in Hz
  UINT32 spikelen;    // The length of the spike events
  UINT32 spikepre;    // Spike pre-trigger samples
  UINT32 resetque;    // The channel for the reset to que on
  UINT32 runlevel;    // System runlevel
  UINT32 runflags;
} cbPKT_SYSINFO;

#define cbRUNLEVEL_STARTUP      10
#define cbRUNLEVEL_HARDRESET    20
#define cbRUNLEVEL_STANDBY      30
#define cbRUNLEVEL_RESET        40
#define cbRUNLEVEL_RUNNING      50
#define cbRUNLEVEL_STRESSED     60
#define cbRUNLEVEL_ERROR        70
#define cbRUNLEVEL_SHUTDOWN     80

// Comment annotation packet.
#define cbMAX_COMMENT  128     // cbMAX_COMMENT must be a multiple of four
#define cbPKTTYPE_COMMENTREP   0x31  /* NSP->PC response */
#define cbPKTTYPE_COMMENTSET   0xB1  /* PC->NSP request */
#define cbPKTDLEN_COMMENT  ((sizeof(cbPKT_COMMENT)/4)-2)
#define cbPKTDLEN_COMMENTSHORT (cbPKTDLEN_COMMENT - ((sizeof(UINT8)*cbMAX_COMMENT)/4))
typedef struct
{
  UINT32  time;		// System clock timestamp
  UINT16  chid;		// 0x8000
  UINT8   type;     // cbPKTTYPE_COMMENT*
  UINT8   dlen;     // cbPKTDLEN_COMMENT
  struct
  {
    UINT8   charset; // Character set (0 - ANSI, 1 - UTF16)
    UINT8   reserved[3]; // Reserved
  } info;
  UINT32  rgba;     // RGBA color code
  UINT8   comment[cbMAX_COMMENT]; // Comment
} cbPKT_COMMENT;

#define cbPKTTYPE_REPCONFIGALL  0x08  // response that NSP got your request

//  Some of the string length constants
#define cbLEN_STR_UNIT			8
#define cbLEN_STR_LABEL     	16
#define cbLEN_STR_FILT_LABEL    16
#define cbLEN_STR_IDENT			64

// Report Processor Information (duplicates the cbPROCINFO structure)
#define cbPKTTYPE_PROCREP   0x21
#define cbPKTDLEN_PROCINFO  ((sizeof(cbPKT_PROCINFO)/4)-2)
typedef struct
{
  UINT32 time;        // system clock timestamp
  UINT16 chid;        // 0x8000
  UINT8  type;        // cbPKTTYPE_PROC*
  UINT8  dlen;        // cbPKT_PROCINFODLEN
  UINT32 proc;        // index of the bank
  UINT32 idcode;      // manufacturer part and rom ID code of the Signal Processor
  char   ident[cbLEN_STR_IDENT];   // ID string with the equipment name of the Signal Processor
  UINT32 chanbase;    // lowest channel number of channel id range claimed by this processor
  UINT32 chancount;   // number of channel identifiers claimed by this processor
  UINT32 bankcount;   // number of signal banks supported by the processor
  UINT32 groupcount;  // number of sample groups supported by the processor
  UINT32 filtcount;   // number of digital filters supported by the processor
  UINT32 sortcount;   // number of channels supported for spike sorting (reserved for future)
  UINT32 unitcount;   // number of supported units for spike sorting    (reserved for future)
  UINT32 hoopcount;   // number of supported units for spike sorting    (reserved for future)
  UINT32 sortmethod;  // sort method  (0=manual, 1=automatic spike sorting)
  UINT32 version;     // current version of libraries
} cbPKT_PROCINFO;

// Report Bank Information (duplicates the cbBANKINFO structure)
#define cbPKTTYPE_BANKREP   0x22
#define cbPKTDLEN_BANKINFO  ((sizeof(cbPKT_BANKINFO)/4)-2)
typedef struct
{
  UINT32 time;        // system clock timestamp
  UINT16 chid;        // 0x8000
  UINT8  type;        // cbPKTTYPE_BANK*
  UINT8  dlen;        // cbPKT_BANKINFODLEN
  UINT32 proc;        // the address of the processor on which the bank resides
  UINT32 bank;        // the address of the bank reported by the packet
  UINT32 idcode;      // manufacturer part and rom ID code of the module addressed to this bank
  char   ident[cbLEN_STR_IDENT];   // ID string with the equipment name of the Signal Bank hardware module
  char   label[cbLEN_STR_LABEL];   // Label on the instrument for the signal bank, eg "Analog In"
  UINT32 chanbase;    // lowest channel number of channel id range claimed by this bank
  UINT32 chancount;   // number of channel identifiers claimed by this bank
} cbPKT_BANKINFO;

// Filter (FILT) Information Packets
#define cbPKTTYPE_FILTREP   0x23
#define cbPKTDLEN_FILTINFO  ((sizeof(cbPKT_FILTINFO)/4)-2)
typedef struct
{
  UINT32  time;       // system clock timestamp
  UINT16  chid;       // 0x8000
  UINT8   type;       // cbPKTTYPE_GROUP*
  UINT8   dlen;       // packet length equal to length of list + 6 quadlets
  UINT32  proc;       //
  UINT32  filt;       //
  char    label[cbLEN_STR_FILT_LABEL];  //
  UINT32  hpfreq;     // high-pass corner frequency in milliHertz
  UINT32  hporder;    // high-pass filter order
  UINT32  hptype;     // high-pass filter type
  UINT32  lpfreq;     // low-pass frequency in milliHertz
  UINT32  lporder;    // low-pass filter order
  UINT32  lptype;     // low-pass filter type
} cbPKT_FILTINFO;

#define cbNUM_ANALOG_CHANS    144

// Sample Group (GROUP) Information Packets
#define cbPKTTYPE_GROUPREP      0x30    // (lower 7bits=ppppggg)
#define cbPKTTYPE_GROUPSET      0xB0
#define cbPKTDLEN_GROUPINFOEMP  8       // basic length without list
typedef struct
{
  UINT32  time;       // system clock timestamp
  UINT16  chid;       // 0x8000
  UINT8   type;       // cbPKTTYPE_GROUP*
  UINT8   dlen;       // packet length equal to length of list + 6 quadlets
  UINT32  proc;       //
  UINT32  group;      //
  char    label[cbLEN_STR_LABEL];  // sampling group label
  UINT32  period;     // sampling period for the group
  UINT32  length;     //
  UINT32  list[cbNUM_ANALOG_CHANS];   // variable length list. The max size is
  // the total number of analog channels
} cbPKT_GROUPINFO;

#define cbMAXUNITS  5
#define cbMAXHOOPS  4

typedef struct
{
  INT16   digmin;     // digital value that cooresponds with the anamin value
  INT16   digmax;     // digital value that cooresponds with the anamax value
  INT32   anamin;     // the minimum analog value present in the signal
  INT32   anamax;     // the maximum analog value present in the signal
  INT32   anagain;    // the gain applied to the default analog values to get the analog values
  char    anaunit[cbLEN_STR_UNIT]; // the unit for the analog signal (eg, "uV" or "MPa")
} cbSCALING;

typedef struct
{
  char    label[cbLEN_STR_FILT_LABEL];
  UINT32  hpfreq;     // high-pass corner frequency in milliHertz
  UINT32  hporder;    // high-pass filter order
  UINT32  hptype;     // high-pass filter type
  UINT32  lpfreq;     // low-pass frequency in milliHertz
  UINT32  lporder;    // low-pass filter order
  UINT32  lptype;     // low-pass filter type
} cbFILTDESC;

typedef struct
{
  INT16       nOverride;
  INT16       afOrigin[3];
  INT16       afShape[3][3];
  INT16       aPhi;
  UINT32      bValid; // is this unit in use at this time?
  // BOOL implemented as UINT32 - for structure alignment at paragraph boundary
} cbMANUALUNITMAPPING;

typedef struct
{
  UINT16 valid; // 0=undefined, 1 for valid
  INT16  time;  // time offset into spike window
  INT16  min;   // minimum value for the hoop window
  INT16  max;   // maximum value for the hoop window
} cbHOOP;

#define cbCHAN_EXISTS       0x00000001  // Channel id is allocated
#define cbCHAN_CONNECTED    0x00000002  // Channel is connected and mapped and ready to use
#define cbCHAN_ISOLATED     0x00000004  // Channel is electrically isolated
#define cbCHAN_AINP         0x00000100  // Channel has analog input capabilities
#define cbCHAN_AOUT         0x00000200  // Channel has analog output capabilities
#define cbCHAN_DINP         0x00000400  // Channel has digital input capabilities
#define cbCHAN_DOUT         0x00000800  // Channel has digital output capabilities

// Analog Input (AINP) Information Packets
#define cbPKTTYPE_CHANREP                   0x40
#define cbPKTTYPE_CHANREPLABEL              0x41
#define cbPKTTYPE_CHANREPSCALE              0x42
#define cbPKTTYPE_CHANREPDOUT               0x43
#define cbPKTTYPE_CHANREPDINP               0x44
#define cbPKTTYPE_CHANREPAOUT               0x45
#define cbPKTTYPE_CHANREPDISP               0x46
#define cbPKTTYPE_CHANREPAINP               0x47
#define cbPKTTYPE_CHANREPSMP                0x48
#define cbPKTTYPE_CHANREPSPK                0x49
#define cbPKTTYPE_CHANREPSPKTHR             0x4A
#define cbPKTTYPE_CHANREPSPKHPS             0x4B
#define cbPKTTYPE_CHANREPUNITOVERRIDES      0x4C
#define cbPKTTYPE_CHANREPNTRODEGROUP        0x4D
#define cbPKTTYPE_CHANREPREJECTAMPLITUDE    0x4E
#define cbPKTTYPE_CHANREPAUTOTHRESHOLD      0x4F
#define cbPKTTYPE_CHANSET                   0xC0
#define cbPKTTYPE_CHANSETLABEL              0xC1
#define cbPKTTYPE_CHANSETSCALE              0xC2
#define cbPKTTYPE_CHANSETDOUT               0xC3
#define cbPKTTYPE_CHANSETDINP               0xC4
#define cbPKTTYPE_CHANSETAOUT               0xC5
#define cbPKTTYPE_CHANSETDISP               0xC6
#define cbPKTTYPE_CHANSETAINP               0xC7
#define cbPKTTYPE_CHANSETSMP                0xC8
#define cbPKTTYPE_CHANSETSPK                0xC9
#define cbPKTTYPE_CHANSETSPKTHR             0xCA
#define cbPKTTYPE_CHANSETSPKHPS             0xCB
#define cbPKTTYPE_CHANSETUNITOVERRIDES      0xCC
#define cbPKTTYPE_CHANSETNTRODEGROUP        0xCD
#define cbPKTTYPE_CHANSETREJECTAMPLITUDE    0xCE
#define cbPKTTYPE_CHANSETAUTOTHRESHOLD  0xCF
#define cbPKTDLEN_CHANINFO      ((sizeof(cbPKT_CHANINFO)/4)-2)
#define cbPKTDLEN_CHANINFOSHORT (cbPKTDLEN_CHANINFO - ((sizeof(cbHOOP)*cbMAXUNITS*cbMAXHOOPS)/4))
typedef struct
{
  UINT32              time;           // system clock timestamp
  UINT16              chid;           // 0x8000
  UINT8               type;           // cbPKTTYPE_AINP*
  UINT8               dlen;           // cbPKT_DLENCHANINFO
  UINT32              chan;	        // actual channel id of the channel being configured
  UINT32              proc;           // the address of the processor on which the channel resides
  UINT32              bank;           // the address of the bank on which the channel resides
  UINT32              term;           // the terminal number of the channel within it's bank
  UINT32              chancaps;       // general channel capablities (given by cbCHAN_* flags)
  UINT32              doutcaps;       // digital output capablities (composed of cbDOUT_* flags)
  UINT32              dinpcaps;       // digital input capablities (composed of cbDINP_* flags)
  UINT32              aoutcaps;       // analog output capablities (composed of cbAOUT_* flags)
  UINT32              ainpcaps;       // analog input capablities (composed of cbAINP_* flags)
  UINT32              spkcaps;        // spike processing capabilities
  cbSCALING           physcalin;      // physical channel scaling information
  cbFILTDESC          phyfiltin;      // physical channel filter definition
  cbSCALING           physcalout;     // physical channel scaling information
  cbFILTDESC          phyfiltout;     // physical channel filter definition
  char                label[cbLEN_STR_LABEL];   // Label of the channel (null terminated if <16 characters)
  UINT32              userflags;      // User flags for the channel state
  INT32               position[4];    // reserved for future position information
  cbSCALING           scalin;         // user-defined scaling information for AINP
  cbSCALING           scalout;        // user-defined scaling information for AOUT
  UINT32              doutopts;       // digital output options (composed of cbDOUT_* flags)
  UINT32              dinpopts;       // digital input options (composed of cbDINP_* flags)
  UINT32              aoutopts;       // analog output options
  UINT32              eopchar;        // digital input capablities (given by cbDINP_* flags)
  union
  {
    struct
    {
      UINT32              monsource;      // address of channel to monitor
      INT32               outvalue;       // output value
    };
    struct
    {
      UINT16              lowsamples;     // address of channel to monitor
      UINT16              highsamples;    // address of channel to monitor
      INT32               offset;         // output value
    };
  };
  UINT32              ainpopts;       // analog input options (composed of cbAINP* flags)
  UINT32              lncrate;          // line noise cancellation filter adaptation rate
  UINT32              smpfilter;        // continuous-time pathway filter id
  UINT32              smpgroup;         // continuous-time pathway sample group
  INT32               smpdispmin;       // continuous-time pathway display factor
  INT32               smpdispmax;       // continuous-time pathway display factor
  UINT32              spkfilter;        // spike pathway filter id
  INT32               spkdispmax;       // spike pathway display factor
  INT32               lncdispmax;       // Line Noise pathway display factor
  UINT32              spkopts;          // spike processing options
  INT32               spkthrlevel;      // spike threshold level
  INT32               spkthrlimit;      //
  UINT32              spkgroup;         // NTrodeGroup this electrode belongs to - 0 is single unit, non-0 indicates a multi-trode grouping
  INT16               amplrejpos;       // Amplitude rejection positive value
  INT16               amplrejneg;       // Amplitude rejection negative value
  UINT32              refelecchan;      // Software reference electrode channel
  cbMANUALUNITMAPPING unitmapping[cbMAXUNITS];            // manual unit mapping
  cbHOOP              spkhoops[cbMAXUNITS][cbMAXHOOPS];   // spike hoop sorting set
} cbPKT_CHANINFO;

// Sample Group data packet
typedef struct
{
  UINT32  time;       // system clock timestamp
  UINT16  chid;       // 0x0000
  UINT8   type;       // sample group ID (1-127)
  UINT8   dlen;       // packet length equal
  INT16   data[252];  // variable length address list
} cbPKT_GROUP;

// chaninfo ainpcaps
#define  cbAINP_RAWPREVIEW          0x00000001      // Generate scrolling preview data for the raw channel
#define  cbAINP_LNC                 0x00000002      // Line Noise Cancellation
#define  cbAINP_LNCPREVIEW          0x00000004      // Retrieve the LNC correction waveform
#define  cbAINP_SMPSTREAM           0x00000010      // stream the analog input stream directly to disk
#define  cbAINP_SMPFILTER           0x00000020      // Digitally filter the analog input stream
#define  cbAINP_RAWSTREAM			0x00000040		// send raw data stream
#define  cbAINP_SPKSTREAM           0x00000100      // Spike Stream is available
#define  cbAINP_SPKFILTER           0x00000200      // Selectable Filters
#define  cbAINP_SPKPREVIEW          0x00000400      // Generate scrolling preview of the spike channel
#define  cbAINP_SPKPROC             0x00000800      // Channel is able to do online spike processing
#define  cbAINP_OFFSET_CORRECT_CAP  0x00001000      // Offset correction mode (0-disabled 1-enabled)

// chaninfo spkopts
#define  cbAINPSPK_EXTRACT      0x00000001  // Time-stamp and packet to first superthreshold peak
#define  cbAINPSPK_REJART       0x00000002  // Reject around clipped signals on multiple channels
#define  cbAINPSPK_REJCLIP      0x00000004  // Reject clipped signals on the channel
#define  cbAINPSPK_ALIGNPK      0x00000008  //
#define  cbAINPSPK_REJAMPL      0x00000010  // Reject based on amplitude
#define  cbAINPSPK_THRLEVEL     0x00000100  // Analog level threshold detection
#define  cbAINPSPK_THRENERGY    0x00000200  // Energy threshold detection
#define  cbAINPSPK_THRAUTO      0x00000400  // Auto threshold detection
#define  cbAINPSPK_SPREADSORT   0x00001000  // Enable Auto spread Sorting
#define  cbAINPSPK_CORRSORT     0x00002000  // Enable Auto Histogram Correlation Sorting
#define  cbAINPSPK_PEAKMAJSORT  0x00004000  // Enable Auto Histogram Peak Major Sorting
#define  cbAINPSPK_PEAKFISHSORT 0x00008000  // Enable Auto Histogram Peak Fisher Sorting
#define  cbAINPSPK_HOOPSORT     0x00010000  // Enable Manual Hoop Sorting
#define  cbAINPSPK_PCAMANSORT   0x00020000  // Enable Manual PCA Sorting
#define  cbAINPSPK_AUTOSORT     (cbAINPSPK_SPREADSORT | cbAINPSPK_CORRSORT | cbAINPSPK_PEAKMAJSORT | cbAINPSPK_PEAKFISHSORT) // old auto sorting methods
#define  cbAINPSPK_NOSORT       0x00000000  // No sorting
#define  cbAINPSPK_ALLSORT      (cbAINPSPK_AUTOSORT | cbAINPSPK_HOOPSORT | cbAINPSPK_PCAMANSORT)  // All sorting algorithms

// Spike packet
#define cbMAX_PNTS  128 // make large enough to track longest possible - spike width in samples
#define cbPKTDLEN_SPK   ((sizeof(cbPKT_SPK)/4)-2)
#define cbPKTDLEN_SPKSHORT (cbPKTDLEN_SPK - ((sizeof(INT16)*cbMAX_PNTS)/4))
typedef struct {
    UINT32 time;                // system clock timestamp
    UINT16 chid;                // channel identifier
    UINT8  unit;                // unit identification (0=unclassified, 31=artifact, 30=background)
    UINT8  dlen;                // length of what follows ... always  cbPKTDLEN_SPK
    float  fPattern[3];         // values of the pattern space (Normal uses only 2, PCA uses third)
    INT16  nPeak;
    INT16  nValley;
    // wave must be the last item in the structure because it can be variable length to a max of cbMAX_PNTS
    INT16  wave[cbMAX_PNTS];    // Room for all possible points collected
} cbPKT_SPK;

