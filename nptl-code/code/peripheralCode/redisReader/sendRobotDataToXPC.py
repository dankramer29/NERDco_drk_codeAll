#!/usr/bin/python

# Sends robot data to Simulink Realtime where it can be written into the file logger.
# Sergey Stavisky June 17 2017

import socket
import redis
import time
import struct

DESTIP='192.168.30.255'
DESTPORT=50140
SLEEP_TIME = 0.00090; # send at just over 1000 Hz; sub-ms update without taxing the network buffers.

Zflip = -1

redisServer = redis.StrictRedis(host='localhost', port=6379, db=0)

toXPCsocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
toXPCsocket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

# netPack = struct.Struct('5f') # uint32, 4 singles: 20 bytes of data. Tells it to format inputs as 5 4-byte floats
# netBuffer = '\x00' * 10

# This part  needs to change when data sent over increases in length
# netPack = struct.Struct('6f') # uint32, 5 singles: 24 bytes of data. Tells it to format inputs as 6 4-byte floats
# netBuffer = '\x00' * 12 # 2 bytes for each of the singles above.

# time (1) + setpoint (6) + state (12) + is 19 items
netPack = struct.Struct('19f') # uint32, 18 singles: 76 bytes of data. Tells it to format inputs as 19 4-byte floats
netBuffer = '\x00' * 38 # 2 bytes for each of the singles above.

print('Starting REDIS key read and network send loop...')
# begin the loop
while True:
	# print('tic') # Dev
	# pull redis data
	armTime = redisServer.get('scl_time'); # TBD
	armSetpoint  = redisServer.get('scl::robot::kinovajaco6::log::setpoint'); # [x], [y], [z], [twist], [fan], [grip]  (note commas)
	armState = redisServer.get('scl::robot::kinovajaco6::log::state'); # [x] [y] [z] [rx] [ry] [rz] [tau1] [tau2] [tau3] [tau4] [tau5] [tau6]   (note no commas)
	
	# temporary until I get appropriate REDIS keys from Will
	armTime = '1'
	# armPos = '-1 2 -4 9'

	# format time
	armTime = float(armTime)

	# format arm setpoint  (this needs to change if data meanings/number of elemements are changed)
	firstSpace = armSetpoint.find(' ')
	secondSpace = armSetpoint.find(' ', firstSpace+1)
	thirdSpace = armSetpoint.find(' ', secondSpace+1)
	fourthSpace = armSetpoint.find(' ', thirdSpace+1)
	fifthSpace = armSetpoint.find(' ', fourthSpace+1)
	lastSpace = armSetpoint.rfind(' ')
	
	xSet = float(armSetpoint[0:firstSpace])
	ySet = float(armSetpoint[firstSpace:secondSpace])
	zSet = float(armSetpoint[secondSpace:thirdSpace])
	twistSet = float(armSetpoint[thirdSpace:fourthSpace])
	fanSet = float(armSetpoint[fourthSpace:fifthSpace])
	gripSet = float(armSetpoint[lastSpace:]) # actually a boolean but for simplicty I'm sending as a float too
	
	# print xSet, ySet, zSet, twistSet, fanSet, gripSet

	# data age - need to implement
	# dataAge = float(1)
	
	
	# format arm state (also will need to be updated if the way data is written by arm is changed)
	firstSpace = armState.find(' ')
	secondSpace = armState.find(' ', firstSpace+1)
	thirdSpace = armState.find(' ', secondSpace+1)
	fourthSpace = armState.find(' ', thirdSpace+1)
	fifthSpace = armState.find(' ', fourthSpace+1)
	sixthSpace = armState.find(' ', fifthSpace+1)
    
	seventhSpace = armState.find(' ', sixthSpace+1)
	eighthSpace = armState.find(' ', seventhSpace+1)
	ninthSpace = armState.find(' ', eighthSpace+1)
	tenthSpace = armState.find(' ', ninthSpace+1)
	eleventhSpace = armState.find(' ', tenthSpace+1)
	twelthSpace = armState.find(' ', eleventhSpace+1)
	lastSpace = armState.rfind(' ')	
	
	xPos = float(armState[0:firstSpace])
	yPos = float(armState[firstSpace:secondSpace])
	zPos = float(armState[secondSpace:thirdSpace])
	rxPos = float(armState[thirdSpace:fourthSpace])
	ryPos = float(armState[fourthSpace:fifthSpace])
	rzPos = float(armState[fifthSpace:sixthSpace])

  # SDS 17 Dec 2017. Something has changed and now armState is only 8 elements
	# tau1Pos = float(armState[sixthSpace:seventhSpace])
	# tau2Pos = float(armState[seventhSpace:eighthSpace])
	# tau3Pos = float(armState[eighthSpace:ninthSpace])
	# tau4Pos = float(armState[ninthSpace:tenthSpace])
	# tau5Pos = float(armState[tenthSpace:eleventhSpace])
	# tau6Pos = float(armState[eleventhSpace:twelthSpace])
	# counter = float(armState[lastSpace:]) # xPC counter that was recently read by Will's code and which corresonds to the xPC-sent velocities he operated on.
	tau1Pos = float(0)
	tau2Pos = float(0)
	tau3Pos = float(0)
	tau4Pos = float(0)
	tau5Pos = float(0)
	tau6Pos = float(0)
	counter = float(0)
	# Dev: print out what we're getting
	# print xPos, yPos, zPos, rxPos, ryPos, rzPos, tau1Pos, tau2Pos, tau3Pos, tau4Pos, tau5Pos, tau6Pos, counter


	netBuffer = netPack.pack(counter, xSet, ySet, zSet, twistSet, fanSet, gripSet, xPos, yPos, zPos, rxPos, ryPos, rzPos, tau1Pos, tau2Pos, tau3Pos, tau4Pos, tau5Pos, tau6Pos)

	toXPCsocket.sendto(netBuffer, (DESTIP, DESTPORT))

	time.sleep(SLEEP_TIME)
