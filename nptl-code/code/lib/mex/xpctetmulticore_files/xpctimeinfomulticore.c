/* $Revision: 1.3.4.4 $ $Date: 2009/11/07 21:19:25 $ */
/* xpctimeinfo.c - xPC Target, non-inlined S-function driver for xPC kernel
   timing information */
/* Copyright 1996-2009 The MathWorks, Inc.
 */

#define         S_FUNCTION_LEVEL        2
#undef          S_FUNCTION_NAME
#define         S_FUNCTION_NAME         xpctimeinfomulticore

#include        <stddef.h>
#include        <stdlib.h>

#include        "simstruc.h"

#ifdef          MATLAB_MEX_FILE
#include        "mex.h"
#endif

#include        <windows.h>
#include        "xpcimports.h"



/* Input Arguments */
#define NUMBER_OF_ARGS          (2)
#define FUNCTION_ARG            ssGetSFcnParam(S,0)
#define SAMP_TIME_ARG           ssGetSFcnParam(S,1)


#define SAMP_TIME_IND           (0)
#define BASE_ADDR_IND           (0)

#define NO_I_WORKS              (0)

#define NO_R_WORKS              (0)


static char_T msg[256];

static void mdlInitializeSizes(SimStruct *S)
{

    int i;

    ssSetNumSFcnParams(S, NUMBER_OF_ARGS);
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
        sprintf(msg,"Wrong number of input arguments passed.\n%d arguments are expected\n",NUMBER_OF_ARGS);
        ssSetErrorStatus(S,msg);
        return;
    }

    ssSetNumContStates(S, 0);
    ssSetNumDiscStates(S, 0);

    if (!ssSetNumOutputPorts(S, 1)) return;
    ssSetOutputPortWidth(S, 0, 1);

    if (!ssSetNumInputPorts(S, 0)) return;

    ssSetNumSampleTimes(S, 1);

    ssSetNumRWork(S, NO_R_WORKS);
    ssSetNumIWork(S, NO_I_WORKS);
    ssSetNumPWork(S, 0);

    ssSetNumModes(S, 0);
    ssSetNumNonsampledZCs(S, 0);

    for( i = 0 ; i < NUMBER_OF_ARGS; i++ )
    {
        ssSetSFcnParamTunable(S,i,0);  /* None of the parameters are tunable */
    }

    ssSetOptions(S, SS_OPTION_DISALLOW_CONSTANT_SAMPLE_TIME |
                 SS_OPTION_EXCEPTION_FREE_CODE | SS_OPTION_WORKS_WITH_CODE_REUSE);

	ssSupportsMultipleExecInstances(S, true);

	ssSetSimStateCompliance( S, HAS_NO_SIM_STATE);
}

// #define MDL_SET_WORK_WIDTHS
// static void mdlSetWorkWidths(SimStruct *S)
// {
// }

static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, mxGetPr(SAMP_TIME_ARG)[SAMP_TIME_IND]);
    ssSetOffsetTime(S, 0, 0.0);
}

double (XPCCALLCONV * xpceGetTET2)           (void);

#define GETPROC2(addr, name) \
  addr = (void *)GetProcAddress(GetModuleHandle(NULL), #name); \
  if (addr == NULL) { printf(#name " not found\n"); }

#define GETPROC(name) GETPROC2(name, name)


static void mdlOutputs(SimStruct *S, int_T tid)
{

    real_T *y;
    GETPROC(xpceGetTET2);

    y=ssGetOutputPortSignal(S,0);
	if (xpceGetTET2 != NULL) {
		y[0] = xpceGetTET2();
		}
	else {
		y[0] = 0.1;
	}
    // switch ((int_T)mxGetPr(FUNCTION_ARG)[0]) {
      // case 1:  // TET in seconds
        // break;
      // case 2:  // time since reboot in ticks
        // y[0] = rl32eGetTicksDouble();
        // break;
      // case 3:  // time since reboot in seconds
        // y[0] = xpcGetElapsedTime( (xpcTime *)NULL );
        // break;
    // }
}

static void mdlTerminate(SimStruct *S)
{
}

#ifdef MATLAB_MEX_FILE  /* Is this file being compiled as a MEX-file? */
#include "simulink.c"   /* Mex glue */
#else
#include "cg_sfun.h"    /* Code generation glue */
#endif
