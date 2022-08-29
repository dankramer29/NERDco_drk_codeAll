#parameter sweep
#save multiple models
#save suite of responses to example trials for each saved model
#save performance as a function of iteration
#load model and subject to suite of example trials

import scipy.io
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from rnnUtils import GRU

class clDecoderSim(object):
    def __init__(self, args):
        #parameters
        self.nCursorDim = args['nCursorDim'][0]
        self.nOutputFactors = args['nOutputFactors'][0]
        self.nDecUnits = args['nDecUnits'][0]
        self.nControllerUnits = args['nControllerUnits'][0]
        self.dt = args['dt'][0]
        self.batchSize = args['batchSize'][0]
        self.nSteps = args['nSteps'][0]
        self.nDelaySteps = args['nDelaySteps'][0]
        self.learnRateStart = args['learnRateStart'][0]
        self.nIterations = args['nTrainIterations'][0]
        self.doPlot = args['doPlot'][0]
        
        #Start tensorflow
        self.sess = tf.Session()
        
        #these placeholders must be configured for each new batch
        self.batchTargets = tf.placeholder(tf.float32, shape=[self.nCursorDim, self.nSteps, self.batchSize])
        self.startDecState = tf.placeholder(tf.float32, shape=[self.nDecUnits, self.batchSize])
        self.startConState = tf.placeholder(tf.float32, shape=[self.nControllerUnits, self.batchSize])
        self.startCursorState = tf.placeholder(tf.float32, shape=[self.nCursorDim*2, self.batchSize])
        self.outputNoise = tf.placeholder(tf.float32, shape=[self.nOutputFactors, self.nSteps, self.batchSize])
        
        #GRU networks
        decNetwork = GRU(self.nDecUnits, self.nOutputFactors, self.nCursorDim, 'GRU_dec', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
                       clip_value=np.inf)
        conNetwork = GRU(self.nControllerUnits, self.nCursorDim*2, self.nOutputFactors, 'GRU_con', reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
                       clip_value=np.inf)
            
        #start states
        self.conStates = [self.startConState]
        self.decStates = [self.startDecState]
        self.cursorStates = [self.startCursorState]
        self.conOutputs = []
        self.decOutputs = []
        self.inputFactors = []
        
        for i in range(self.nSteps):   
            #controller
            if i < self.nDelaySteps:
                inState = self.cursorStates[0][0:self.nCursorDim]
                useTarg = self.batchTargets[:,0,:]
            else:
                inState = self.cursorStates[i-self.nDelaySteps][0:self.nCursorDim]
                useTarg = self.batchTargets[:,i-self.nDelaySteps,:]
                
            inputToController = tf.concat([inState, useTarg],0)
            newConState, conOut, _, _ = conNetwork(inputToController, self.conStates[i])
            
            #constrain magnitude of output factors
            cvMag = tf.sqrt(tf.reduce_sum(tf.square(conOut),axis=0,keep_dims=True)) + 1e-6
            conOut = (conOut / cvMag) * (tf.sigmoid(cvMag)-0.5)*2.0 #wrong
            
            #noise
            noisyOutput = conOut + self.outputNoise[:,i,:]
                
            #decoder
            newDecState, decOut, _, _ = decNetwork(noisyOutput, self.decStates[i])
            
            newPos = decOut
            if i==0:
                newVel = tf.zeros([self.nCursorDim,self.batchSize])
            else:
                newVel = (decOut - self.decOutputs[i-1])/self.dt
            newCursorState = tf.concat([newPos, newVel],0)
            
            #append state & output to the chain
            self.conStates.append(newConState)
            self.decStates.append(newDecState)
            self.cursorStates.append(newCursorState)
            self.conOutputs.append(conOut)
            self.decOutputs.append(decOut)
                  
            #control error
            tf.add_to_collection('controlErr',tf.square(newPos-self.batchTargets[:,i,:]))
        
        #compute total error for training
        self.control_ssErr = (tf.reduce_sum(tf.add_n(tf.get_collection('controlErr'), name='control_ssErr'))/(self.batchSize*self.nSteps*self.nCursorDim))
        self.rmse_control = tf.sqrt(self.control_ssErr)
        self.errSummary_control = tf.summary.scalar('RMSE', self.rmse_control)
        
        #prepare gradients and optimizer
        learnRate = tf.Variable(1.0, trainable=False)
        
        tvars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES)
        grads_control = tf.gradients(self.control_ssErr, tvars)
        grads_control, _ = tf.clip_by_global_norm(grads_control, 200)
        
        opt = tf.train.AdamOptimizer(learnRate, beta1=0.9, beta2=0.999,
                                     epsilon=1e-01)
        self.train_op_control = opt.apply_gradients(
            zip(grads_control, tvars), global_step=tf.contrib.framework.get_or_create_global_step())
        self.new_lr = tf.placeholder(tf.float32, shape=[], name="new_learning_rate")
        self.lr_update = tf.assign(learnRate, self.new_lr)
                
        #How many parameters does this model have?
        total_params = 0
        for i in range(len(tvars)):
          shape = tvars[i].get_shape().as_list()
          nParams = np.prod(shape)
          print(tvars[i].name + ': ' + str(nParams))
          total_params += nParams
        print("Total model parameters: ", total_params)
        
        #initialize variables
        self.sess.run(tf.global_variables_initializer())
        
    def run(self, outputDir, trackingTargSeqFile):

        #prepare to save the model
        saver = tf.train.Saver(max_to_keep=None)
        lve = np.inf
        lastSavedIteration = -100000
        
        #load tracking sequences
        trackSeqFile = scipy.io.loadmat(trackingTargSeqFile)
        trackTargSeq = trackSeqFile['targSeq'].astype(np.float32)
        trackNoiseSeq = trackSeqFile['noiseSeq'].astype(np.float32)
                
        #train RNN one batch at a time
        decStartStates = np.zeros([self.nDecUnits, self.batchSize])
        conStartStates = np.zeros([self.nControllerUnits, self.batchSize])
        cursorStartStates = np.zeros([self.nCursorDim*2, self.batchSize])
        
        #prepare tensorboard
        self.writer = tf.summary.FileWriter(outputDir)
        
        for i in range(self.nIterations):
            #learn rate
            lr = self.learnRateStart*(1 - i/float(self.nIterations))
            
            #randomly generate a target sequence within a 4 x 4 square centered at (0,0)
            targetSeq = np.zeros([self.nCursorDim, self.nSteps, self.batchSize])
            for x in range(self.batchSize):
                randTargSeq = np.zeros([self.nCursorDim, 0])
                currentIdx= 0
                while True:
                    nTargSteps = np.random.randint(300)+2
                    
                    randTarg = np.random.normal(0,1,[self.nCursorDim,1])
                    while np.any(abs(randTarg)>2):
                        randTarg = np.random.normal(0,1,[self.nCursorDim,1])
                    
                    tmp = np.squeeze(np.reshape(np.tile(randTarg, [1,nTargSteps]),[self.nCursorDim,nTargSteps,1]))
                    randTargSeq = np.concatenate([randTargSeq, tmp],1)
                    currentIdx = currentIdx + 1
                    if randTargSeq.shape[1]>self.nSteps:
                        break
                targetSeq[:,:,x] = randTargSeq[:,0:self.nSteps]
            targetSeq = targetSeq
            
            #prepare new noise
            newNoise = np.random.multivariate_normal(np.squeeze(np.zeros([self.nOutputFactors,1])), np.identity(self.nOutputFactors), [self.batchSize, self.nSteps])
            newNoise = np.transpose(newNoise, [2, 1, 0])
            
            #descend gradient
            ao, to, err, errSumm = self.sess.run([self.lr_update, self.train_op_control, self.rmse_control, self.errSummary_control], 
                                                feed_dict={self.new_lr: lr, self.startDecState: decStartStates, self.batchTargets: targetSeq,
                                                           self.startConState: conStartStates, self.startCursorState: cursorStartStates,
                                                           self.outputNoise: newNoise})
        
            #log progress
            self.writer.add_summary(errSumm, i)
            
            #save whenever validation error is at its lowest point so far
            if err < lve and i-lastSavedIteration>50:
                lastSavedIteration = i
                lve = err
                saver.save(self.sess, outputDir + '/model.ckpt', global_step=i, write_meta_graph=False)
                
                #evaluate on a constant set of target sequences, so we can track model progress on these same sequences throughout training
                nTrials = trackTargSeq.shape[2]
                csOut = np.zeros([self.nSteps+1, self.nCursorDim*2, nTrials])
                commandsOut = np.zeros([self.nSteps, self.nOutputFactors, nTrials])
                
                nBatches = int(np.ceil(float(nTrials)/self.batchSize))
                for batchIdx in range(nBatches):
                    selIdx = np.arange(batchIdx*self.batchSize, (batchIdx+1)*self.batchSize)
                    selIdx = selIdx[selIdx<nTrials]
                    if len(selIdx)<self.batchSize:
                        selIdx = np.concatenate([selIdx, np.zeros([self.batchSize-len(selIdx)])])
                        selIdx = selIdx.astype(np.int32)
                
                    inputTarg = trackTargSeq[:,:,selIdx]
                    inputNoise = trackNoiseSeq[0:self.nOutputFactors,:,selIdx]
                    
                    cs, con, do = self.sess.run([self.cursorStates, self.conOutputs, self.decOutputs],
                                                        feed_dict={self.new_lr: lr, self.startDecState: decStartStates, self.batchTargets: inputTarg,
                                                                   self.startConState: conStartStates, self.startCursorState: cursorStartStates,
                                                                   self.outputNoise: inputNoise})
                
                    csOut[:,:,selIdx] = np.squeeze(np.stack(cs))
                    commandsOut[:,:,selIdx] = np.squeeze(np.stack(con))
                
                #save results to a .mat file
                a = {}
                a['cursorState']=csOut
                a['controllerOutput']=commandsOut
                scipy.io.savemat(outputDir + '/trackSeqOutput_' + str(i),a)
        
            #validation plot every once in a while
            if i%100 == 0:
                cs, con, do, err = self.sess.run([self.cursorStates, self.conOutputs, self.decOutputs, self.rmse_control],
                                                        feed_dict={self.new_lr: lr, self.startDecState: decStartStates, self.batchTargets: inputTarg,
                                                                   self.startConState: conStartStates, self.startCursorState: cursorStartStates,
                                                                   self.outputNoise: inputNoise})
                
                print('Iteration: ' + str(i) + ', err: ' + str(err))
                
                if self.doPlot == 1:
                    cs = np.squeeze(np.stack(cs))
                    con = np.squeeze(np.stack(con))
                    do = np.squeeze(np.stack(do))
                
                    plt.figure()
                    for x in range(3):
                        plt.subplot(3,2,x*2+1)
                        plt.plot(inputTarg[0,:,x])
                        plt.plot(cs[:,0,x])
                        
                        plt.subplot(3,2,x*2+2)
                        plt.plot(inputTarg[1,:,x])
                        plt.plot(cs[:,1,x])
                    plt.show()
                    
                    plt.figure()
                    for x in range(3):
                        plt.subplot(3,2,x*2+1)
                        plt.plot(inputTarg[0,:,x])
                        plt.plot(con[:,0,x])
                        
                        plt.subplot(3,2,x*2+2)
                        plt.plot(inputTarg[1,:,x])
                        plt.plot(con[:,1,x])
                    plt.show()
        