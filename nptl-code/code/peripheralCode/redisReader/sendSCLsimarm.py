#!/usr/bin/python

import socket
import redis
import time
import struct

DESTIP='192.168.30.255'
DESTPORT=50140
SLEEP_TIME = 0.00016

POS_OFFSET_Z=-0.5 # (0,0 is at the center bottom of the simulation)
Zflip = -1
POS_SCALING=1280

redisServer = redis.StrictRedis(host='localhost', port=6379, db=0)

toXPCsocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
toXPCsocket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

netPack = struct.Struct('5f') # uint32, 4 singles: 20 bytes of data
netBuffer = '\x00' * 10

# begin the loop
while True:

	# pull redis data
	armTime = redisServer.get('scl_time');
	armPos  = redisServer.get('scl_pos_ee');

	# format time
	armTime = float(armTime)

	# format arm pos
	firstSpace = armPos.find(' ')
	secondSpace = armPos.rfind(' ')

	xPos = float(armPos[0:firstSpace])
	yPos = float(armPos[firstSpace:secondSpace])
	zPos = float(armPos[secondSpace:])

	# data age - need to implement
	dataAge = float(1)

#	netBuffer = netPack.pack(armTime, xPos, yPos, zPos, dataAge)
	netBuffer = netPack.pack(armTime, yPos*POS_SCALING, (zPos+POS_OFFSET_Z)*POS_SCALING*Zflip, xPos*POS_SCALING, dataAge)

	toXPCsocket.sendto(netBuffer, (DESTIP, DESTPORT))

	time.sleep(SLEEP_TIME)
