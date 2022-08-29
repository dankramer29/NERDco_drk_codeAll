# commented out stuff is for processing things of bus/device ID

def findGloves():

	import os, sys, subprocess
	import array

#	VENDOR = "5d70"

	if not os.path.isdir("/dev/usb"):
		print('No gloves plugged in')
	

#	callStr = "lsusb | grep -i %s | awk '{print  $2 $4}'" % VENDOR
	callStr = "ls -l /dev/usb/|tail -n +2 |awk '{print $10}'"
	gloveLSUSBCall = subprocess.Popen(callStr, shell=True, stdout=subprocess.PIPE)

	gloveIDs = []
	for l in gloveLSUSBCall.stdout.readlines():
#		gloveIDs.append( [ l[0:3], l[3:6] ] )
		gloveIDs.append( l[0:7] )

	return gloveIDs

	# gloveID is an array of found devices

	# old gloveIDs is a 2D array
	#	number of rows is number of gloves
	#	col 1 is busID, col2 is device ID


def pullGloveSerialNumber(gloveID):

	import subprocess
	import re

#	serialRE = re.compile("ID_SERIAL_SHORT=")
	serialRE = re.compile("serial\}==\"DG")

#	callStr = "udevadm info --query=property --name=/dev/bus/usb/%s/%s" % (gloveID[0], gloveID[1])
	callStr = "udevadm info --query=property --attribute-walk --name=/dev/usb/%s | grep serial | grep DG" % gloveID
	udevCall = subprocess.Popen(callStr, shell=True, stdout=subprocess.PIPE)

#	serialNumber = ['not found']
#	for l in udevCall.stdout.readlines():
#		if serialRE.match(l):
#			serialNumber = l[16:27]

	outStr = udevCall.stdout.readlines()

	return outStr[0][20:31]
