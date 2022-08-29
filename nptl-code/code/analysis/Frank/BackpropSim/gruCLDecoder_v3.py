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
nDecUnits = 100
nFMUnits = 100
nControllerUnits = 100
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
batchCIS = tf.placeholder(tf.float32, shape=[nSteps, batchSize])

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
        
    inputToControlNet = tf.concat([(useTarg - fmOut[0:2,:]), fmOut[2:4,:]],0)
    controlHidden = tf.sigmoid(tf.matmul(W_control_in, inputToControlNet) + b_control_in)
    controlVec = tf.matmul(W_control_out, controlHidden) + b_control_out
    
    #neural activity
    cvMag = tf.sqrt(tf.reduce_sum(tf.square(controlVec),axis=0,keep_dims=True)) + 1e-6
    controlVec = (controlVec / cvMag) * (tf.sigmoid(cvMag)-0.5)*2.0 #wrong
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
        newVel = tf.zeros([nCursorDim,batchSize])
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
    tf.add_to_collection('controlErr',tf.square(newPos-batchTargets[:,i,:]-tf.reduce_mean(newPos,1,keep_dims=True)))

#compute total error for training
fm_ssErr = (tf.reduce_sum(tf.add_n(tf.get_collection('fmErr'), name='fm_ssErr'))/(batchSize*nSteps*nCursorDim*2))
control_ssErr = (tf.reduce_sum(tf.add_n(tf.get_collection('controlErr'), name='control_ssErr'))/(batchSize*nSteps*nCursorDim))
rmse_control = tf.sqrt(control_ssErr)
errSummary_control = tf.summary.scalar('RMSE', rmse_control)

#prepare gradients and optimizer
learnRate = tf.Variable(1.0, trainable=False)

fmVars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES, scope='GRU_fm')
controlVars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES, scope='GRU_dec') + \
    tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES, scope='Controller') + \
    tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES, scope='ProjLayer')

grads_fm = tf.gradients(fm_ssErr, fmVars)
grads_fm, _ = tf.clip_by_global_norm(grads_fm, 200)

grads_control = tf.gradients(control_ssErr, controlVars)
grads_control, _ = tf.clip_by_global_norm(grads_control, 200)

opt = tf.train.AdamOptimizer(learnRate, beta1=0.9, beta2=0.999,
                             epsilon=1e-01)
train_op_fm = opt.apply_gradients(
    zip(grads_fm, fmVars), global_step=tf.contrib.framework.get_or_create_global_step())
train_op_control = opt.apply_gradients(
    zip(grads_control, controlVars), global_step=tf.contrib.framework.get_or_create_global_step())
new_lr = tf.placeholder(tf.float32, shape=[], name="new_learning_rate")
lr_update = tf.assign(learnRate, new_lr)

#prepare tensorboard
writer = tf.summary.FileWriter("/Users/frankwillett/Data/Derived/gruCLTest")

#prepare to save the model
saver = tf.train.Saver()
lve = np.inf

#How many parameters does this model have?
all_tvars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES)
total_params = 0
for i in range(len(all_tvars)):
  shape = all_tvars[i].get_shape().as_list()
  total_params += np.prod(shape)
print("Total model parameters: ", total_params)

sess.run(tf.global_variables_initializer())

#train RNN one batch at a time
nBatches = 200000
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
            nTargSteps = np.random.randint(300)+2
            randTarg = np.random.normal(0,1,[2,1])
            tmp = np.squeeze(np.reshape(np.tile(randTarg, [1,nTargSteps]),[2,nTargSteps,1]))
            randTargSeq = np.concatenate([randTargSeq, tmp],1)
            if randTargSeq.shape[1]>nSteps:
                break
        targetSeq[:,:,x] = randTargSeq[:,0:nSteps]
    targetSeq = targetSeq
    
    #No CIS for now
    newCIS = np.zeros([nSteps, batchSize])
    
    #prepare new noise
    newNoise = np.random.multivariate_normal(np.squeeze(np.zeros([nNeurons,1])), neuralCovariance, [batchSize, nSteps])
    newNoise = np.transpose(newNoise, [2, 1, 0])
    
    #descend gradient
    ao, tofm, tocon, err, errSumm = sess.run([lr_update, train_op_fm, train_op_control, rmse_control, errSummary_control], 
                                        feed_dict={new_lr: lr, startDecState: decStartStates, batchTargets: targetSeq,
                                                   startFMState: fmStartStates, startCursorState: cursorStartStates, tuningCoef: neuralTuning,
                                                   neuralNoise: newNoise, batchCIS: newCIS})

    #log progress
    writer.add_summary(errSumm, i)
    
    #save whenever validation error is at its lowest point so far
    if err < lve:
        lve = err
        saver.save(sess, '/Users/frankwillett/Data/Derived/gruCLTest/model.ckpt', global_step=i, write_meta_graph=False)
    
    #validation plot every once in a while
    if i%100 == 0:
        print("step %d"%(i))
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