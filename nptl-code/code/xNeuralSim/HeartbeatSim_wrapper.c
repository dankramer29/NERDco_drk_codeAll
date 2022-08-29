/*
  *
  *   --- THIS FILE GENERATED BY S-FUNCTION BUILDER: 3.0 ---
  *
  *   This file is a wrapper S-function produced by the S-Function
  *   Builder which only recognizes certain fields.  Changes made
  *   outside these fields will be lost the next time the block is
  *   used to load, edit, and resave this file. This file will be overwritten
  *   by the S-function Builder block. If you want to edit this file by hand, 
  *   you must change it only in the area defined as:  
  *
  *        %%%-SFUNWIZ_wrapper_XXXXX_Changes_BEGIN 
  *            Your Changes go here
  *        %%%-SFUNWIZ_wrapper_XXXXXX_Changes_END
  *
  *   For better compatibility with the Simulink Coder, the
  *   "wrapper" S-function technique is used.  This is discussed
  *   in the Simulink Coder User's Manual in the Chapter titled,
  *   "Wrapper S-functions".
  *
  *   Created: Fri Mar 15 07:32:08 2013
  */


/*
 * Include Files
 *
 */
#if defined(MATLAB_MEX_FILE)
#include "tmwtypes.h"
#include "simstruc_types.h"
#else
#include "rtwtypes.h"
#endif

/* %%%-SFUNWIZ_wrapper_includes_Changes_BEGIN --- EDIT HERE TO _END */
 
/* %%%-SFUNWIZ_wrapper_includes_Changes_END --- EDIT HERE TO _BEGIN */
#define u_width 1
#define y_width 1
/*
 * Create external references here.  
 *
 */
/* %%%-SFUNWIZ_wrapper_externs_Changes_BEGIN --- EDIT HERE TO _END */
 
/* %%%-SFUNWIZ_wrapper_externs_Changes_END --- EDIT HERE TO _BEGIN */

/*
 * Output functions
 *
 */
void HeartbeatSim_Outputs_wrapper(const uint32_T *clk,
                          uint8_T *pktData,
                          real_T *pktSize)
{
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_BEGIN --- EDIT HERE TO _END */
/*
 * This code outputs a Cerebus 'heartbeat' packet every 10ms.
 *
 * N. Schmansky, March 2012
 */

#include <cbhwlib_lite.h>

static unsigned int lastPktSentClk=0;

// inputs:
unsigned int sysclk = clk[0];

// outputs:
pktSize[0] = 0; // assume no packet will be sent

if (sysclk >= (lastPktSentClk + TICKS_10MS))
{
    // 10ms has elapsed since last heartbeat packet sent, 
    // so send another one...
    cbPKT_SYSHEARTBEAT* heartbeatPkt = (cbPKT_SYSHEARTBEAT*)pktData;
    heartbeatPkt->time = sysclk;
    heartbeatPkt->chid = CEREBUS_SYSPACKET_CHANNEL;
    heartbeatPkt->type = cbPKTTYPE_SYSHEARTBEAT;
    heartbeatPkt->dlen = cbPKTDLEN_SYSHEARTBEAT;

    // output port
    pktSize[0] = (heartbeatPkt->dlen * 4) + cbPKT_HEADER_SIZE;

    lastPktSentClk = sysclk;
}
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_END --- EDIT HERE TO _BEGIN */
}
