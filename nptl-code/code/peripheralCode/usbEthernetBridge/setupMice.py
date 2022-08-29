#!/usr/bin/python
# -*- coding: utf-8 -*-

# encoding is necessary as some names have non-ascii characters

import sys, subprocess
from subprocess import PIPE, STDOUT
import re

def connectToTouchpads():
    # christineblabe's trackpad: "60:C5:47:82:07:7B"
    # gilja's trackpad: "60:C5:47:82:0C:85"
    hidMacs = ['60:C5:47:82:07:7B','60:C5:47:82:0C:85']
    
    # try connecting to all touchpads
    for c in hidMacs:
        callStr = 'sudo hidd --connect %s' % c
        print(callStr)
        bridgeCall = subprocess.Popen(callStr, shell=True)
        bridgeCall.communicate()



def getMice():

    candidateList = ['USB Optical Mouse',
                     'PS/2 Generic Mouse',
                     'SynPS/2 Synaptics TouchPad',
                     'christineblabe’s trackpad',
                     'gilja’s trackpad',
                     'Apple Wireless Trackpad',
                     'Razer Razer DeathAdder'
                     ]
    # is this mouse relative or absolute?
    # 1 is relative, 2 is absolute
    relAbs = [1,1,1,2,2,2,1]

    
    # now try connecting to each xinput device
    # ID=$(xinput list --id-only "Apple Wireless Trackpad")
    for idx,c in enumerate(candidateList):
        callStr = '/usr/bin/xinput list --id-only "%s"' % c
        bridgeCall = subprocess.Popen(callStr, shell=True, stdout=PIPE,stderr=PIPE)
        out, err = bridgeCall.communicate();
        if out:
            out = out[0:-1] # strip newline
            print('Mice: Found %s. ID: %s' % (c, out) )
            relAbs = relAbs[idx]
            break

    if out:   
        ## disable the device as an X input
        callStr = 'sudo xinput set-prop %s "Device Enabled" 0' % out
        bridgeCall = subprocess.Popen(callStr, shell=True, stdout=PIPE,stderr=PIPE)
        jnk, err = bridgeCall.communicate();

         ## now get the device properties
        callStr = 'xinput --list-props %s |grep "Device Node" |grep -o "/dev/input/event[0-9]*"' % out

        bridgeCall = subprocess.Popen(callStr, shell=True, stdout=PIPE,stderr=PIPE)
        out, err = bridgeCall.communicate();

        out = out[0:-1] #strip newline
    
        print('device at node: %s , using rel/abs: %i' % (out, relAbs))
        return [out, relAbs]
    else:
        return [[],[]]

## this is a python method to parse the raw output of xinput --list-props (i.e., if the greps above were not working.)
# for line in out.splitlines():
# # first look for the string "Device Node"
#     m=re.split('Device Node', line)
#     if len(m) > 1:
#         m = re.split('/dev/input/event',m[1])
#         if len(m) != 2:
#             print('error splitting %s' % m)
#         else:
#             devnode = re.findall(r'\d+',m[1])
#             print('device node is /dev/input/event%s' % devnode[0])

