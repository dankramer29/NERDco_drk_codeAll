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
nFMUnits = 50
nFTargUnits = 10
nFVelUnits = 10
dt = 0.02
batchSize = 32
delaySteps = 10
nSteps = 500
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
batchCIS = tf.placeholder(tf.float32, shape=[nSteps, batchSize])

#GRU networks
decNetwork = GRU(nDecUnits, nDecFactors, nCursorDim, 'GRU_dec', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf)
fmNetwork = GRU(nFMUnits, nCursorDim*2, nCursorDim*2, 'GRU_fm', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf)

#control policy
with tf.variable_scope('Controller'):
    W_ftarg_in = tf.get_variable("W_ftarg_in", dtype=tf.float32, 
                    initializer=initializeWeights([nFTargUnits, 1 ], 1.0), trainable=True)
    b_ftarg_in = tf.get_variable("b_ftarg_in", dtype=tf.float32, 
                    initializer=initializeWeights([nFTargUnits, 1 ], 1.0), trainable=True)
    W_ftarg_out = tf.get_variable("W_ftarg_out", dtype=tf.float32, 
                    initializer=initializeWeights([1, nFTargUnits ], 1.0), trainable=True)
    b_ftarg_out = tf.get_variable("b_ftarg_out", dtype=tf.float32, 
                    initializer=initializeWeights([1, 1 ], 1.0), trainable=True)
    
    W_fvel_in = tf.get_variable("W_fvel_in", dtype=tf.float32, 
                    initializer=initializeWeights([nFVelUnits, 1 ], 1.0), trainable=True)
    b_fvel_in = tf.get_variable("b_fvel_in", dtype=tf.float32, 
                    initializer=initializeWeights([nFVelUnits, 1 ], 1.0), trainable=True)
    W_fvel_out = tf.get_variable("W_fvel_out", dtype=tf.float32, 
                    initializer=initializeWeights([1, nFVelUnits ], 1.0), trainable=True)
    b_fvel_out = tf.get_variable("b_fvel_out", dtype=tf.float32, 
                    initializer=initializeWeights([1, 1 ], 1.0), trainable=True)

#create a linear projection layer from neural features -> decoder network
with tf.variable_scope('ProjLayer'):
    projW = tf.get_variable("W", dtype=tf.float32, 
            initializer=initializeWeights([nDecFactors, nNeurons ], 1.0), trainable=True)
    projB = tf.get_variable("b", [nDecFactors, 1], dtype=tf.float32, 
            initializer=tf.zeros_initializer, trainable=True)

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
    if i < delaySteps:
        inState = cursorStates[0]
    else:
        inState = cursorStates[i-delaySteps]
    newFMState, fmOut, _, _ = fmNetwork(inState, fmStates[i])
    
    #controller
    if i < delaySteps:
        useTarg = batchTargets[:,0,:]
    else:
        useTarg = batchTargets[:,i,:]
        
    atTargVec = (useTarg - fmOut[0:2,:])
    targDist = tf.sqrt(tf.reduce_sum(tf.square(atTargVec),axis=0,keep_dims=True))
    atTargVec = atTargVec / (targDist+1e-6)
    
    headingVec = fmOut[2:4,:]
    speed = tf.sqrt(tf.reduce_sum(tf.square(headingVec),axis=0,keep_dims=True))
    headingVec = headingVec / (speed+1e-6)
    
    distInner = tf.sigmoid(tf.multiply(W_ftarg_in, targDist) + b_ftarg_in)
    distOut = tf.matmul(W_ftarg_out, distInner) + b_ftarg_out
    speedInner = tf.sigmoid(tf.multiply(W_fvel_in, speed) + b_fvel_in)
    speedOut = tf.matmul(W_fvel_out, speedInner) + b_fvel_out
    
    #neural activity
    controlVec = atTargVec * distOut + headingVec * speedOut
    cvMag = tf.sqrt(tf.reduce_sum(tf.square(controlVec),axis=0,keep_dims=True)) + 1e-6
    controlVec = (controlVec / cvMag) * tf.sigmoid(cvMag)
    neuralMeans = tf.matmul(tuningCoef[:,0:2], controlVec) + tf.matmul(tuningCoef[:,2,None], cvMag) + \
        tf.matmul(tuningCoef[:,3,None], batchCIS[None,i,:])
    neuralFeatures = neuralMeans + neuralNoise[:,i,:]
    
    #decoder
    inputProj = tf.matmul(projW, neuralFeatures) + projB
    newDecState, decOut, _, _ = decNetwork(inputProj, decStates[i])
    
    #cursor
    newPos = cursorStates[i][0:2,:] + decOut * dt
    newCursorState = tf.concat([newPos, decOut],0)
    
    #append state & output to the chain
    fmStates.append(newFMState)
    decStates.append(newDecState)
    cursorStates.append(newCursorState)
    controllerOutputs.append(controlVec)
    fmOutputs.append(fmOut)
    decOutputs.append(decOut)
      
    #compute error for time steps greater than som burn-in time
    tf.add_to_collection('SquaredErr',tf.square(newPos-batchTargets[:,i,:]))

#compute total error for training
sumSquaredErr = (tf.reduce_sum(tf.add_n(tf.get_collection('SquaredErr'), name='total_err'))/(batchSize*nSteps*nCursorDim))
rmse = tf.sqrt(sumSquaredErr)
errSummary = tf.summary.scalar('RMSE', rmse)

#total cost
totalCost = sumSquaredErr

#prepare gradients and optimizer
tvars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES)
learnRate = tf.Variable(1.0, trainable=False)

grads = tf.gradients(totalCost, tvars)
grads, grad_global_norm = tf.clip_by_global_norm(grads, 200)
opt = tf.train.AdamOptimizer(learnRate, beta1=0.9, beta2=0.999,
                             epsilon=1e-01)
train_op = opt.apply_gradients(
    zip(grads, tvars), global_step=tf.contrib.framework.get_or_create_global_step())
    
new_lr = tf.placeholder(tf.float32, shape=[], name="new_learning_rate")
lr_update = tf.assign(learnRate, new_lr)

#prepare tensorboard
writer = tf.summary.FileWriter("/Users/frankwillett/Data/Derived/gruCLTest")

#prepare to save the model
saver = tf.train.Saver()
lve = np.inf

#How many parameters does this model have?
total_params = 0
for i in range(len(tvars)):
  shape = tvars[i].get_shape().as_list()
  total_params += np.prod(shape)
print("Total model parameters: ", total_params)

sess.run(tf.global_variables_initializer())

#train RNN one batch at a time
nBatches = 2000
decStartStates = np.zeros([nDecUnits, batchSize])
fmStartStates = np.zeros([nFMUnits, batchSize])
cursorStartStates = np.zeros([nCursorDim*2, batchSize])

for i in range(nBatches):
    #learn rate
    lr = 0.01*(1 - i/float(nBatches))
    
    #prepare to insert inputs and targets from randomly selected trials
    targetSeq = np.zeros([nCursorDim, nSteps, batchSize])
    for x in range(batchSize):
        randTargSeq = np.zeros([2,0])
        while True:
            nTargSteps = np.random.randint(300)+1
            randTarg = np.random.normal(0,1,[2,1])
            tmp = np.squeeze(np.reshape(np.tile(randTarg, [1,nTargSteps]),[2,nTargSteps,1]))
            randTargSeq = np.concatenate([randTargSeq, tmp],1)
            if randTargSeq.shape[1]>500:
                break
        targetSeq[:,:,x] = randTargSeq[:,0:nSteps]
    targetSeq = targetSeq
    
    #No CIS for now
    newCIS = np.zeros([nSteps, batchSize])
    
    #prepare new noise
    newNoise = np.random.multivariate_normal(np.squeeze(np.zeros([nNeurons,1])), neuralCovariance, [batchSize, nSteps])
    newNoise = np.transpose(newNoise, [2, 1, 0])
    
    #descend gradient
    ao, to, err, errSummary = sess.run([lr_update, train_op, rmse, errSummary], 
                                        feed_dict={new_lr: lr, startDecState: decStartStates, batchTargets: targetSeq,
                                                   startFMState: fmStartStates, startCursorState: cursorStartStates, tuningCoef: neuralTuning,
                                                   neuralNoise: newNoise, batchCIS: newCIS})

    #log progress
    writer.add_summary(errSummary, i)
        
    #save whenever validation error is at its lowest point so far
    if err < lve:
        lve = err
        saver.save(sess, '/Users/frankwillett/Data/Derived/gruCLTest/model.ckpt', global_step=i, write_meta_graph=False)
    
    #validation plot every once in a while
    if i%100 == 0:
        print("step %d"%(i))
        g = sess.run([grads], feed_dict={new_lr: lr, startDecState: decStartStates, batchTargets: targetSeq,
                                                               startFMState: fmStartStates, startCursorState: cursorStartStates, tuningCoef: neuralTuning,
                                                               neuralNoise: newNoise, batchCIS: newCIS})
        cs, fm, do, fms = sess.run([cursorStates, fmOutputs, decOutputs, fmStates], feed_dict={new_lr: lr, startDecState: decStartStates, batchTargets: targetSeq,
                                                       startFMState: fmStartStates, startCursorState: cursorStartStates, tuningCoef: neuralTuning,
                                                       neuralNoise: newNoise, batchCIS: newCIS})
        cs = np.squeeze(np.stack(cs))
        fm = np.squeeze(np.stack(fm))
        fms = np.squeeze(np.stack(fms))
        do = np.squeeze(np.stack(do))
        
        plt.figure()
        for x in range(3):
            plt.subplot(3,2,x*2+1)
            plt.plot(targetSeq[0,:,x])
            plt.plot(cs[:,0,x])
            
            plt.subplot(3,2,x*2+2)
            plt.plot(targetSeq[1,:,x])
            plt.plot(cs[:,1,x])
        plt.show()
        
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