import scipy.io
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from rnnUtils import GRU, initializeWeights

#load tuning model from MATLAB
dataDir = '/Users/frankwillett/Data/Derived/gruCLTest'
neuralModel = scipy.io.loadmat(dataDir + '/neuralModel')
neuralCovariance = neuralModel['neuralCovariance'].astype(np.float32)
neuralTuning = neuralModel['neuralTuning'].astype(np.float32)

#parameters
nCursorDim = 2
nDecFactors = 10
nDecUnits = 50
nFMUnits = 20
nControllerUnits = 20
dt = 0.02
batchSize = 16
delaySteps = 10
nSteps = 250
nNeurons = neuralTuning.shape[0]

#Start tensorflow
sess = tf.Session()

#these placeholders must be configured for each new batch
batchTargets = tf.placeholder(tf.float32, shape=[nCursorDim, nSteps, batchSize])
startDecState = tf.placeholder(tf.float32, shape=[nDecUnits, batchSize])
startFMState = tf.placeholder(tf.float32, shape=[nFMUnits, batchSize])
startCursorState = tf.placeholder(tf.float32, shape=[nCursorDim*2, batchSize])

tuningCoef = tf.placeholder(tf.float32, shape=[nNeurons, nCursorDim+2])
neuralNoise = tf.placeholder(tf.float32, shape=[nNeurons, nSteps, batchSize])
inputControlVec = tf.placeholder(tf.float32, shape=[nNeurons, nCursorDim])

inputToControlNet = tf.placeholder(tf.float32, shape=[nCursorDim*2, batchSize])
controlNetTarget = tf.placeholder(tf.float32, shape=[nCursorDim, batchSize])

#GRU networks
decNetwork = GRU(nDecUnits, nDecFactors, nCursorDim, 'GRU_dec', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf)
fmNetwork = GRU(nFMUnits, nCursorDim*2, nCursorDim*2, 'GRU_fm', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf)

#control policy
with tf.variable_scope('Controller'):
    W_control_in = tf.get_variable("W_ftarg_in", dtype=tf.float32, 
                    initializer=initializeWeights([nControllerUnits, nCursorDim*2 ], 1.0), trainable=True)
    b_control_in = tf.get_variable("b_ftarg_in", dtype=tf.float32, 
                    initializer=initializeWeights([nControllerUnits, 1 ], 1.0), trainable=True)
    W_control_out = tf.get_variable("W_ftarg_out", dtype=tf.float32, 
                    initializer=initializeWeights([nCursorDim, nControllerUnits ], 1.0), trainable=True)
    b_control_out = tf.get_variable("b_ftarg_out", dtype=tf.float32, 
                    initializer=initializeWeights([nCursorDim, 1 ], 1.0), trainable=True)
    
#create a linear projection layer from neural features -> decoder network
with tf.variable_scope('ProjLayer'):
    projW = tf.get_variable("W", dtype=tf.float32, 
            initializer=initializeWeights([nDecFactors, nNeurons ], 1.0), trainable=True)
    projB = tf.get_variable("b", [nDecFactors, 1], dtype=tf.float32, 
            initializer=tf.zeros_initializer, trainable=True)

#control policy network
controlHidden = tf.sigmoid(tf.matmul(W_control_in, inputToControlNet) + b_control_in)
controlVec = tf.matmul(W_control_out, controlHidden) + b_control_out
controlNetErr = tf.reduce_sum(tf.square(inputToControlNet - controlNetTarget))

#start states
fmStates = [startFMState]
decStates = [startDecState]
cursorStates = [startCursorState]
controllerOutputs = []
fmOutputs = []
decOutputs = []
inputFactors = []

for i in range(nSteps):   
    #forward model
    newFMState, fmOut, _, _ = fmNetwork(inState, fmStates[i])
    
    #neural activity
    neuralMeans = tf.matmul(tuningCoef[:,0:2], controlVec) + tf.matmul(tuningCoef[:,2,None], cvMag) + \
        tf.matmul(tuningCoef[:,3,None], batchCIS[None,i,:])
    neuralFeatures = neuralMeans + neuralNoise[:,i,:]
    
    #decoder
    inputProj = tf.matmul(projW, neuralFeatures) + projB
    newDecState, decOut, _, _ = decNetwork(inputProj, decStates[i])
    
    #cursor
    #newPos = cursorStates[i][0:2,:] + decOut * dt
    #newCursorState = tf.concat([newPos, decOut],0)
    
    newPos = decOut
    if i==0:
        newVel = tf.zeros([2,16])
    else:
        newVel = (decOut - decOutputs[i-1])/dt
    newCursorState = tf.concat([newPos, newVel],0)
    
    #append state & output to the chain
    fmStates.append(newFMState)
    decStates.append(newDecState)
    cursorStates.append(newCursorState)
    controllerOutputs.append(controlVec)
    fmOutputs.append(fmOut)
    decOutputs.append(decOut)
      
    #forward model error
    tf.add_to_collection('fmErr',tf.square(fmOut-newCursorState))
    
    #control error
    tf.add_to_collection('controlErr',tf.square(newPos-batchTargets[:,i,:]))
    
##load the best performing variables
#ckpt = tf.train.get_checkpoint_state('/Users/frankwillett/Data/Derived/gruTest/')
#saver.restore(sess, ckpt.model_checkpoint_path)
#
##apply to inputsFinal and return
#finalIdx = np.array(range(batchSize))
#outputs = []
#inFac = []
#zList = []
#rList = []
#dsList = []
#while True:
#    finalIdx = finalIdx[finalIdx<inputsFinal.shape[0]]
#    if len(finalIdx)==0:
#        break
#    if len(finalIdx)<batchSize:
#        finalIdx = np.concatenate((finalIdx, np.zeros([batchSize-len(finalIdx)])+finalIdx[-1])).astype(np.int32)
#    inputSeq = np.transpose(inputsFinal[finalIdx,:,:], (2,1,0))
#    targSeq = np.transpose(targetsFinal[finalIdx,:,:], (2,1,0))
#
#    do, infc, ds, zg, rg = sess.run([decOutputs, inputFactors, decStates, zGates, rGates], feed_dict={new_lr: lr, startDecState: prevStartStates, batchInputs: inputSeq, batchTargets: targSeq})
#    outputs.append(np.stack(do))
#    inFac.append(np.stack(infc))
#    dsList.append(np.stack(ds))
#    zList.append(np.stack(zg))
#    rList.append(np.stack(rg))
#    finalIdx = finalIdx+batchSize
#
#inputSeq = np.transpose(inputsFinal[range(batchSize),:,:], (2,1,0))
#targSeq = np.transpose(targetsFinal[range(batchSize),:,:], (2,1,0))
#do = sess.run(decOutputs, feed_dict={new_lr: lr, startDecState: prevStartStates, batchInputs: inputSeq, batchTargets: targSeq})
#do = np.stack(do)
#
#plt.figure()
#for x in range(3):
#    plt.subplot(3,2,x*2+1)
#    plt.plot(targetsFinal[x,:,0])
#    plt.plot(do[:,0,x])
#    
#    plt.subplot(3,2,x*2+2)
#    plt.plot(targetsFinal[x,:,1])
#    plt.plot(do[:,1,x])
#plt.show()
#
#outputsFinal = np.concatenate(outputs,2)
#outputsFinal = outputsFinal[:,:,range(inputsFinal.shape[0])]
#outputsFinal = np.transpose(outputsFinal, [2, 0, 1])
#
#inFacFinal = np.concatenate(inFac,2)
#inFacFinal = inFacFinal[:,:,range(inputsFinal.shape[0])]
#inFacFinal = np.transpose(inFacFinal, [2, 0, 1])
#
#dsFinal = np.concatenate(dsList,2)
#dsFinal = dsFinal[:,:,range(inputsFinal.shape[0])]
#dsFinal = np.transpose(dsFinal, [2, 0, 1])
#
#zFinal = np.concatenate(zList,2)
#zFinal = zFinal[:,:,range(inputsFinal.shape[0])]
#zFinal = np.transpose(zFinal, [2, 0, 1])
#
#rFinal = np.concatenate(rList,2)
#rFinal = rFinal[:,:,range(inputsFinal.shape[0])]
#rFinal = np.transpose(rFinal, [2, 0, 1])
#                
#a = {}
#a['targetsFinal']=targetsFinal
#a['outputsFinal']=outputsFinal
#a['inFacFinal']=inFacFinal
#a['dsFinal']=dsFinal
#a['zFinal']=zFinal
#a['rFinal']=rFinal
#scipy.io.savemat('/Users/frankwillett/Data/Derived/gruTest/gruResults',a)