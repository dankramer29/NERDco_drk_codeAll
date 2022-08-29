#!/usr/bin/python

import sys, subprocess
import fiveDT as g
import setupMice

callStrHead = 'sudo nice -n -20 ./usbEthernetBridge.out'

# mouse/imu params
useIMU = '1'

[mousePath, mouseRel] = setupMice.getMice()
if mousePath:
	mosueRel = str(mouseRel)
	print('mousepath %s, mouseRel %s' %( mousePath, mouseRel))
else:
	mousePath = '/dev/mouse'
	mouseRel = '1'
	print('mousepath %s, mouseRel %s' %( mousePath, mouseRel))

# find gloves
gloveIDs = g.findGloves()

glove1Str = '0 0 0';
glove2Str = '0 0 0';

if len(gloveIDs)==0:
	# badness
	print('No gloves detected')

if len(gloveIDs) >= 1:
	# at least one glove
	serial = g.pullGloveSerialNumber(gloveIDs[0])
	if serial[:4] == 'DG05':
		runHighLow = 0;
	elif serial[:4] == 'DG14':
		runHighLow = 2;
	else:
		print "I don't recognize this glove: %s." % serial[:3]
		sys.exit(1);
	glove1Str = '/dev/usb/hiddev0 %s %s' % (serial, runHighLow)

if len(gloveIDs) >= 2:
	# two gloves
	serial = g.pullGloveSerialNumber(gloveIDs[1]);
	if serial[:4] == 'DG05':
		runHighLow = 0;
	elif serial[:4] == 'DG14':
		runHighLow = 2;
	else:
		print "I don't recognize this glove: %s." % serial[:3]
		sys.exit(1);
	glove2Str = '/dev/usb/hiddev1 %s %s' % (serial, runHighLow)


callStrGlove = '%s %s' % (glove1Str, glove2Str)
	
	
callStr = '%s %s %s %s %s' % (callStrHead, mousePath, mouseRel, callStrGlove, useIMU)

print(callStr)

bridgeCall = subprocess.Popen(callStr, shell=True)

bridgeCall.communicate()
