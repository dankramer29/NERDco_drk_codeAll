
# Derived from keras-rl
#import opensim as osim
#import numpy as np
#import sys
#
#from keras.models import Sequential, Model
#from keras.layers import Dense, Activation, Flatten, Input, concatenate
#from keras.optimizers import Adam
#
#import numpy as np
#
#from rl.agents import DDPGAgent
#from rl.memory import SequentialMemory
#from rl.random import OrnsteinUhlenbeckProcess
#
#from osim.env.arm import ArmEnv
#
#from keras.optimizers import RMSprop
#
#import argparse
#import math

import numpy
from osim.env.generic import OsimEnv

nBatch = 500
batchSize = 500
nSteps = 1000
env = OsimEnv(visualize=True)

for b in range(nBatch):
    for t in range(batchSize):
        
        observation = env.reset()
        
        minActivation = 0.05
        maxActivation = 1.0
        
        noiseScale = numpy.random.exponential(0.05)
        alpha = numpy.random.uniform(0,0.99)
        smoothActivations = numpy.zeros(6)
        newActs = numpy.random.exponential(0.5, 6)
    
        for i in range(nSteps):
            if numpy.random.uniform(0,1.0)<0.02:
                newActs = numpy.random.exponential(0.5, 6)

            smoothActivations = alpha*smoothActivations + (1-alpha)*(newActs + noiseScale*numpy.random.uniform(0,1,6))
            finalActivations = smoothActivations
            finalActivations[finalActivations<minActivation] = minActivation
            finalActivations[finalActivations>maxActivation] = maxActivation
            observation, reward, done, info = env.step(finalActivations)
        
    
    

