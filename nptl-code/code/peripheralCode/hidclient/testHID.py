#!/usr/bin/python

import numpy
import math
import time

# input event format from linux/input.h
# struct input_event {
#   struct timeval time;
#   __u16 type;
#   __u16 code;
#   __s32 value;
# };

# byte representation:
# first 16 bytes are time (ignored by hidclient)
# then 2 bytes for type: set to EV_REL 0x02
# then 2 bytes for code: needs to be either ABS_X (0) ABS_Y (1) or ABS_Z (2)
# then 4 bytes value to move

# open file

# initialize
evTime = numpy.uint64([0, 0])	# dummy time bytes
evType = numpy.uint16(2)	# event type, must be EV_REL (mouse, relative movement)
evCodeX = numpy.uint16(0)	# code for X movement (ABS_X) - absolute X movement relative to last position, akin to velocity
evCodeY = numpy.uint16(1)	# code for Y movement (ABS_Y)
evVal  = numpy.int32(60)	# value to move

f = open('/tmp/hidMouse', 'a');

#for i in range(0, 3):
#
#	evTime.tofile(f)
#	evType.tofile(f)
#	evCodeY.tofile(f)
#	evVal.tofile(f)
#
#	f.flush()

sleepTime = 0.05
startPoint = -3*math.pi/2
steps = numpy.linspace(startPoint, startPoint + 2*math.pi, 100)


for mirror in [1, -1] :
	for i in range(len(steps) - 1):


		if mirror == 1:
			theta = steps[i]
		else:
			theta = 2*math.pi - steps[i]
			
		evValX = numpy.int32(mirror*math.cos(theta)*10)
		evValY = numpy.int32(mirror*math.sin(theta)*10)

		evTime.tofile(f)
		evType.tofile(f)
		evCodeX.tofile(f)
		evValX.tofile(f)

		evTime.tofile(f)
		evType.tofile(f)
		evCodeY.tofile(f)
		evValY.tofile(f)

		f.flush()

		time.sleep(sleepTime)

f.close()
