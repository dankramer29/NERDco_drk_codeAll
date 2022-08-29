import scipy.io
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from rnnUtils import GRU, initializeWeights

#parameters
nCursorDim = 2
nOutputFactors = 10
nDecUnits = 50
nControllerUnits = 50
dt = 0.02
batchSize = 16
delaySteps = 10
nSteps = 250

#Start tensorflow
sess = tf.Session()

#these placeholders must be configured for each new batch
batchTargets = tf.placeholder(tf.float32, shape=[nCursorDim, nSteps, batchSize])
startDecState = tf.placeholder(tf.float32, shape=[nDecUnits, batchSize])
startConState = tf.placeholder(tf.float32, shape=[nControllerUnits, batchSize])
startCursorState = tf.placeholder(tf.float32, shape=[nCursorDim*2, batchSize])
outputNoise = tf.placeholder(tf.float32, shape=[nOutputFactors, nSteps, batchSize])
batchCIS = tf.placeholder(tf.float32, shape=[nSteps, batchSize])

#GRU networks
decNetwork = GRU(nDecUnits, nOutputFactors, nCursorDim, 'GRU_dec', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf)
conNetwork = GRU(nControllerUnits, nCursorDim*2, nOutputFactors, 'GRU_con', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf)
    
#start states
conStates = [startConState]
decStates = [startDecState]
cursorStates = [startCursorState]
conOutputs = []
decOutputs = []
inputFactors = []

for i in range(nSteps):   
    #controller
    if i < delaySteps:
        inState = cursorStates[0][0:nCursorDim]
        useTarg = batchTargets[:,0,:]
    else:
        inState = cursorStates[i-delaySteps][0:nCursorDim]
        useTarg = batchTargets[:,i-delaySteps,:]
        
    inputToController = tf.concat([inState, useTarg],0)
    newConState, conOut, _, _ = conNetwork(inputToController, conStates[i])
    
    #constrain magnitude of output factors
    cvMag = tf.sqrt(tf.reduce_sum(tf.square(conOut),axis=0,keep_dims=True)) + 1e-6
    conOut = (conOut / cvMag) * (tf.sigmoid(cvMag)-0.5)*2.0 #wrong
    
    #noise
    noisyOutput = conOut + outputNoise[:,i,:]
        
    #decoder
    newDecState, decOut, _, _ = decNetwork(noisyOutput, decStates[i])
    
    newPos = decOut
    if i==0:
        newVel = tf.zeros([2,16])
    else:
        newVel = (decOut - decOutputs[i-1])/dt
    newCursorState = tf.concat([newPos, newVel],0)
    
    #append state & output to the chain
    conStates.append(newConState)
    decStates.append(newDecState)
    cursorStates.append(newCursorState)
    conOutputs.append(conOut)
    decOutputs.append(decOut)
          
    #control error
    tf.add_to_collection('controlErr',tf.square(newPos-batchTargets[:,i,:]))

#compute total error for training
control_ssErr = (tf.reduce_sum(tf.add_n(tf.get_collection('controlErr'), name='control_ssErr'))/(batchSize*nSteps*nCursorDim))
rmse_control = tf.sqrt(control_ssErr)
errSummary_control = tf.summary.scalar('RMSE', rmse_control)

#prepare gradients and optimizer
learnRate = tf.Variable(1.0, trainable=False)

tvars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES)
grads_control = tf.gradients(control_ssErr, tvars)
grads_control, _ = tf.clip_by_global_norm(grads_control, 200)

opt = tf.train.AdamOptimizer(learnRate, beta1=0.9, beta2=0.999,
                             epsilon=1e-01)
train_op_control = opt.apply_gradients(
    zip(grads_control, tvars), global_step=tf.contrib.framework.get_or_create_global_step())
new_lr = tf.placeholder(tf.float32, shape=[], name="new_learning_rate")
lr_update = tf.assign(learnRate, new_lr)

#prepare tensorboard
writer = tf.summary.FileWriter("/Users/frankwillett/Data/Derived/gruCLTest_free")

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
conStartStates = np.zeros([nControllerUnits, batchSize])
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
    
    #prepare new noise
    newNoise = np.random.multivariate_normal(np.squeeze(np.zeros([nOutputFactors,1])), np.identity(nOutputFactors), [batchSize, nSteps])
    newNoise = np.transpose(newNoise, [2, 1, 0])
    
    #descend gradient
    ao, to, err, errSumm = sess.run([lr_update, train_op_control, rmse_control, errSummary_control], 
                                        feed_dict={new_lr: lr, startDecState: decStartStates, batchTargets: targetSeq,
                                                   startConState: conStartStates, startCursorState: cursorStartStates,
                                                   outputNoise: newNoise})

    #log progress
    writer.add_summary(errSumm, i)
    
    #save whenever validation error is at its lowest point so far
    if err < lve:
        lve = err
        saver.save(sess, '/Users/frankwillett/Data/Derived/gruCLTest_free/model.ckpt', global_step=i, write_meta_graph=False)
    
    #validation plot every once in a while
    if i%100 == 0:
        print("step %d"%(i))
        cs, con, do = sess.run([cursorStates, conOutputs, decOutputs],
                               feed_dict={new_lr: lr, startDecState: decStartStates, batchTargets: targetSeq,
                                                   startConState: conStartStates, startCursorState: cursorStartStates,
                                                   outputNoise: newNoise})
        cs = np.squeeze(np.stack(cs))
        con = np.squeeze(np.stack(con))
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
        
        plt.figure()
        for x in range(3):
            plt.subplot(3,2,x*2+1)
            plt.plot(targetSeq[0,:,x])
            plt.plot(con[:,0,x])
            
            plt.subplot(3,2,x*2+2)
            plt.plot(targetSeq[1,:,x])
            plt.plot(con[:,1,x])
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