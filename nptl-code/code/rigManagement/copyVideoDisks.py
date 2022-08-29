#!/usr/bin/python

import subprocess, os
import time

#os.chdir('/cygdrive/c/cygwin/bin/')

baseVideoDir = '/cygdrive/e/Session/Data/Video'

# call wmic to get drive info
wmicStr = 'wmic volume list brief|/bin/awk \'{print $5 "," $6 "," $7}\''
wmicCall = subprocess.Popen(wmicStr, shell=True, stdout=subprocess.PIPE)
wmicOutput = wmicCall.communicate()


# find D3200
D3200pos = wmicOutput[0].find('D3200')
if D3200pos == -1 :
    print 'Did not find D3200, skipping.'
    haveD3200 = False
else:
    haveD3200 = True
    D3200DriveLetter = wmicOutput[0][D3200pos + 6]
#    print 'drive letter %s' % D3200DriveLetter
 
# find XR550V
XR550Vpos = wmicOutput[0].find('XR550V')
if XR550Vpos == -1 :
    print 'Did not find XR550V, skipping.'
    haveXR550V = False
else:
    haveXR550V = True
    XR550VDriveLetter = wmicOutput[0][XR550Vpos + 7]
 
if not haveD3200 and not haveXR550V :
    print 'Do not have any video disks, exiting.'
        
else:
    if haveD3200 :
        print 'Copying D3200 data:'
        
        D3200Dir = '%s/D3200' % baseVideoDir
        if not os.path.exists(D3200Dir) :
            os.makedirs(D3200Dir)
            
        rsyncD3200Str = '/bin/rsync -avP /cygdrive/%s/DCIM/100D3200/ %s/' % (D3200DriveLetter.lower(), D3200Dir)
        print rsyncD3200Str
        rsyncD3200Call = subprocess.Popen(rsyncD3200Str, shell=True , stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        
    if haveXR550V :
        print 'Copying XR550V data:'
        XR550VDir = '%s/XR550V' % baseVideoDir
        if not os.path.exists(XR550VDir) :
            os.makedirs(XR550VDir)

        rsyncXR550VStr = '/bin/rsync -avP /cygdrive/%s/AVCHD/BDMV/STREAM/ %s/' % (XR550VDriveLetter.lower(), XR550VDir)
        print rsyncXR550VStr
        XR550VCall = subprocess.Popen(rsyncXR550VStr, shell=True, cwd="/usr/bin", stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        
# monitor progress
while True:
  time.sleep(10)
  if haveD3200:
    D3200output = rsyncD3200Call.stdout.readline()
  else:
    D3200output = ''
  if haveXR550V:
    XR550Voutput = XR550VCall.stdout.readline()
  else:
    XR550Voutput = ''
  if not D3200output and not XR550Voutput:
    print 'YAY!'
    print 'Video copy completed.'
    break
  if D3200output:
    print D3200output
  if XR550Voutput:
    print XR550Voutput

raw_input('Press enter to exit')