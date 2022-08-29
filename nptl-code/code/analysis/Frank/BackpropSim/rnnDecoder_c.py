import scipy.io
import numpy as np
import tensorflow as tf
import os
from customRnnCells import ContextGRUCell, ContextRNNCell, ContextLSTMCell, initializeWeights, makelambda

#TODO: make dropout work for intermediate RNN layers

#train on one more datasets starting from a blank model
#train on a dataset starting from a pre-initialized model
#decode on any given dataset, using any given input projection & context biases from a previous model
class rnnDecoder(object):
    def __init__(self, args, mode, preInitDatasetNum=0, modelLoadDir=[]):
        #mode = train, preInitTrain, decode
        
        #initialize the computational graph
        self.mode = mode
        self.nModelDatasets = args['nModelDatasets'][0]
        self.nInputsPerModelDataset = args['nInputsPerModelDataset']
        self.nSteps = args['nSteps'][0]
        self.nTargets = args['nTargetDim'][0]
        self.batchSize = args['batchSize'][0]
        self.useInputProj = args['useInputProj'][0]
        self.nDecInputFactors = args['nDecInputFactors'][0]
        self.nDecUnits = args['nDecUnits'][0]
        self.keepProbIn = args['keepProbIn'][0]
        self.keepProbLayer = args['keepProbLayer'][0]
        self.nLayers = args['nLayers'][0]
        self.L2Reg = args['L2Reg'][0]
        self.rnnType = args['rnnType'][0]
        self.device = args['device'][0]
        self.nEpochs = args['nEpochs'][0]
        self.learnRateStart = args['learnRateStart'][0]
        self.doPlot = args['doPlot'][0]
        
        if self.rnnType=='LSTM':
            rnnCell = ContextLSTMCell
        elif self.rnnType=='GRU':
            rnnCell = ContextGRUCell
        elif self.rnnType=='RNN':
            rnnCell = ContextRNNCell
            
        #Start tensorflow
        config = tf.ConfigProto(allow_soft_placement=True,
                      log_device_placement=False)
        self.sess = tf.Session(config=config)
        
        with tf.device(self.device):
            #these placeholders must be configured for each new batch
            self.batchTargets = tf.placeholder(tf.float32, shape=[self.batchSize, self.nSteps, self.nTargets])
            self.startDecState = tf.placeholder(tf.float32, shape=[self.nDecUnits, self.batchSize])
            self.errorMask = tf.placeholder(tf.float32, shape=[self.batchSize, self.nSteps])
            self.datasetIdx = tf.placeholder(tf.int32, shape=[])
            self.keep_prob_input = tf.placeholder(tf.float32, shape=[])
            self.keep_prob_layer = tf.placeholder(tf.float32, shape=[])
            
            #multi-layered RNN decoder
            decLayers = []
            for i in range(self.nLayers):
                if i==0:
                    nLayerInputs = self.nDecInputFactors
                    kp = tf.constant(1.0)
                else:
                    nLayerInputs = self.nDecUnits
                    kp = self.keep_prob_layer
                    
                newLayer = rnnCell(self.nDecUnits, nLayerInputs, 'RNN_layer'+str(i), self.datasetIdx, numContexts=self.nModelDatasets, reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
                               clip_value=np.inf, input_keep_prob=kp)
                decLayers.append(newLayer)
            
            #input projection
            if self.useInputProj:
                projW = []
                projB = []
                for i in range(self.nModelDatasets):
                    with tf.variable_scope('ProjLayer'):
                        projW.append(tf.get_variable("W_"+str(i), dtype=tf.float32, 
                                initializer=initializeWeights([self.nInputsPerModelDataset[i], self.nDecInputFactors ], 1.0), trainable=True))
                        projB.append(tf.get_variable("b_"+str(i), [1, self.nDecInputFactors], dtype=tf.float32, 
                                initializer=tf.zeros_initializer, trainable=True))
                    
                #project dynamically
                predW = []
                predB = []
                for i in range(self.nModelDatasets):   
                    predW.append((tf.equal(self.datasetIdx, tf.constant(i)), makelambda(projW[i])))
                    predB.append((tf.equal(self.datasetIdx, tf.constant(i)), makelambda(projB[i])))
                activeProjW = tf.case(predW, default=makelambda(projW[0]))    
                activeProjB = tf.case(predB, default=makelambda(projB[0]))    
                
                self.batchInputs = tf.placeholder(tf.float32, shape=[self.batchSize, self.nSteps, None])
                self.projectedInput = tf.matmul(self.batchInputs, tf.tile(tf.expand_dims(activeProjW,0),[self.batchSize, 1, 1])) + activeProjB
            else:
                self.batchInputs = tf.placeholder(tf.float32, shape=[self.batchSize, self.nSteps, self.nDecInputFactors])
                self.projectedInput = self.batchInputs
                
            if self.keepProbIn!=1.0:
                self.projectedInput = tf.nn.dropout(self.projectedInput, self.keep_prob_input)
            
            #unfold RNN in time
            if self.nLayers==1:
                cellToUse = decLayers[0]
            else:
                cellToUse = tf.nn.rnn_cell.MultiRNNCell(decLayers)
                
            self.decStates, lastState = tf.nn.dynamic_rnn(
                cell = cellToUse,
                dtype = tf.float32,
                inputs = self.projectedInput,
            )
                    
            #readout the target
            W_o = tf.get_variable("W_o", dtype=tf.float32, 
                            initializer=initializeWeights([self.nDecUnits, self.nTargets ], 1.0), trainable=True)
            b_o = tf.get_variable("b_o", [1, self.nTargets], dtype=tf.float32, 
                            initializer=tf.zeros_initializer, trainable=True)
            if self.keepProbLayer!=1.0:
                self.decStates = tf.nn.dropout(self.decStates, self.keep_prob_layer)
            self.decOutput = tf.matmul(self.decStates, tf.tile(tf.expand_dims(W_o,0),[self.batchSize, 1, 1])) + b_o
                        
            #training ops (error, regularization, gradients, etc)
            if self.mode in ['train','preInitTrain']:
                #error function
                err = tf.multiply(tf.reduce_sum(tf.square(self.batchTargets - self.decOutput),2), self.errorMask)
                self.totalErr = tf.sqrt(tf.reduce_mean(err))
                
                self.trainErr_ph = tf.placeholder(tf.float32, shape=[])
                self.testErr_ph = tf.placeholder(tf.float32, shape=[])
                self.trainErrSummary = tf.summary.scalar('train_RMSE', self.trainErr_ph)
                self.testErrSummary = tf.summary.scalar('test_RMSE', self.testErr_ph)
                
                #add l2 cost
                l2vars = []
                if self.useInputProj:
                    l2vars.append(activeProjW)
                l2vars.append(W_o)  
                for i in range(self.nLayers):
                    l2vars.extend(decLayers[i]._weightVariables)
                  
                self.l2cost = tf.constant(0.0)
                total_params = 0
                for i in range(len(l2vars)):
                  shape = l2vars[i].get_shape().as_list()
                  if shape[0]!=None:
                      total_params += np.prod(shape)
                  self.l2cost += tf.nn.l2_loss(l2vars[i])
                self.l2cost = self.l2cost / total_params
                self.l2cost = self.l2cost * self.L2Reg
                
                self.l2cost_ph = tf.placeholder(tf.float32, shape=[])
                self.l2costSummary = tf.summary.scalar('l2cost', self.l2cost_ph)
                
                #total cost
                self.totalCost = self.l2cost + self.totalErr
                
                #prepare gradients and optimizer
                tvars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES)
                learnRate = tf.Variable(1.0, trainable=False)
                
                grads = tf.gradients(self.totalCost, tvars)
                grads, grad_global_norm = tf.clip_by_global_norm(grads, 200)
                opt = tf.train.AdamOptimizer(learnRate, beta1=0.9, beta2=0.999,
                                             epsilon=1e-01)
                self.train_op = opt.apply_gradients(
                    zip(grads, tvars), global_step=tf.contrib.framework.get_or_create_global_step())
                    
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

            #depending on the mode, load variables from previous model
            saver = []
            if self.mode=='preInitTrain':
                #create a saver operation to initialize the decoder parameters to values from a prior model
                #first we build a dictionary of variables to load
                restoreDic = {}
                
                #first initialize dataset-specific variables (context biases and projection layer)
                for x in range(self.nModelDatasets):
                    if self.useInputProj:
                        restoreDic['ProjLayer/W_'+str(preInitDatasetNum)] = projW[x]
                        restoreDic['ProjLayer/b_'+str(preInitDatasetNum)] = projB[x]
                    for i in range(self.nLayers):
                        restoreDic['RNN_layer'+str(i)+'/cb_'+str(preInitDatasetNum)] = decLayers[i]._contextBiases[x]
                    
                #initialize RNN parameters common to all datasets
                rnnVars = []
                for i in range(self.nLayers):
                    if self.rnnType=='GRU':
                        rnnVars.extend(['W_z','U_z','b_z','W_r','U_r','b_r','W','U','b'])
                    elif self.rnnType=='RNN':
                        rnnVars.extend(['W','U'])
                    elif self.rnnType=='LSTM':
                        rnnVars.extend(['W_i','U_i','b_i','W_f','U_f','b_f','W_o','U_o','b_o','W','U'])
                
                for i in range(len(rnnVars)):
                    for x in range(self.nLayers):
                        with tf.variable_scope('RNN_layer' + str(x), reuse=True):
                            restoreDic['RNN_layer' + str(x) + '/' + rnnVars[i]] = tf.get_variable(rnnVars[i])
                    
                #initialize output projection
                restoreDic['W_o'] = W_o
                restoreDic['b_o'] = b_o
                    
                #prepare to restore using the dictionary; restores from latest checkpoint
                saver = tf.train.Saver(restoreDic)
                ckpt = tf.train.get_checkpoint_state(modelLoadDir)
                
            elif self.mode=='decode':
                #load all variables from specified model
                saver = tf.train.Saver()
                ckpt = tf.train.get_checkpoint_state(modelLoadDir)
                
            #initialize model variables
            self.sess.run(tf.global_variables_initializer())
            if saver!=[]:
                checkpoint_name = os.path.basename(os.path.normpath(ckpt.model_checkpoint_path))
                checkpoint_path = modelLoadDir + checkpoint_name
                saver.restore(self.sess, checkpoint_path)
                
    def run(self, datasets=[], datasetDir=[], outputDir=[], datasetIdxForDecoding=0):
        
        #may need to do plotting
        if self.doPlot==1:
            import matplotlib.pyplot as plt
    
        #load datasets
        inputs = []
        targets = []
        eMask = []
        
        inputsVal = []
        targetsVal = []
        eMaskVal = []
        
        inputsFinal = []
        targetsFinal = []
        eMaskFinal = []
        
        totalTrials = 0
        nDatasets = len(datasets)
        
        #first load all .mat datasets we'll need
        #if we are in decode mode, we only need to load the inputs variable
        #inputsVal and inputsFinal are optional depending on the mode (inputsFinal is always optional, inputsVal is optional for decoding mode only)
        for datasetName in datasets:
            rnnData = scipy.io.loadmat(datasetDir + '/' + datasetName + '.mat')
            
            inputs.append(rnnData['inputs'].astype(np.float32))
            if self.mode!='decode':
                targets.append(rnnData['targets'].astype(np.float32))
                eMask.append(rnnData['errMask'].astype(np.float32))
            
            if 'inputsVal' in rnnData:
                inputsVal.append(rnnData['inputsVal'].astype(np.float32))
                if self.mode!='decode':
                    targetsVal.append(rnnData['targetsVal'].astype(np.float32))
                    eMaskVal.append(rnnData['errMaskVal'].astype(np.float32))
            
            if 'inputsFinal' in rnnData:
                inputsFinal.append(rnnData['inputsFinal'].astype(np.float32))
                if self.mode!='decode':
                    targetsFinal.append(rnnData['targetsFinal'].astype(np.float32))
                    eMaskFinal.append(rnnData['errMaskFinal'].astype(np.float32))
            
            print(str(rnnData['inputs'].shape[0]) + ' trials from ' + datasetName)
            totalTrials += rnnData['inputs'].shape[0]
            
        print(str(totalTrials) + ' total trials from ' + str(nDatasets) + ' datasets')
        
        #mode-specific behavior
        if self.mode=='decode':
            #apply the decoder to the inputs matrix and return
            outputs = []
            inFac = []
            decStates = []
            
            for currentDatasetIdx in range(nDatasets):
                #targets and eMask are zeros because we don't need them to decode, just need them for training
                targets = np.zeros([inputs[currentDatasetIdx].shape[0], self.nSteps, self.nTargets])
                eMask = np.zeros([inputs[currentDatasetIdx].shape[0], self.nSteps])
                
                #run the decoder
                tOutputs, tInFac, tDecStates = self.decode(datasetIdxForDecoding, inputs[currentDatasetIdx], targets, eMask) 
                
                outputs.append(tOutputs)
                inFac.append(tInFac)
                decStates.append(tDecStates)
                
            #save results to a .mat file
            a = {}
            for currentDatasetIdx in range(nDatasets):
                a['outputs'+str(currentDatasetIdx)]=outputs[currentDatasetIdx]
                a['inFac'+str(currentDatasetIdx)]=inFac[currentDatasetIdx]
                a['decStates'+str(currentDatasetIdx)]=decStates[currentDatasetIdx]
                a['inputs'+str(currentDatasetIdx)]=inputs[currentDatasetIdx]
            scipy.io.savemat(outputDir + '/decodeOutput',a)
            
        elif self.mode in ['train','preInitTrain']:
            
            #prepare dropout probabilities
            kpi = self.keepProbIn
            kpl = self.keepProbLayer
        
            #prepare to keep a running save of the best model so far
            #at the end of training, we revert back to the best model (i.e. early stopping)
            saver = tf.train.Saver()
            lve = np.inf
                
            #prepare tensorboard
            writer = tf.summary.FileWriter(outputDir)
            
            #train RNN one batch at a time
            bestEpoch = 0
            
            #always start RNN at zeros
            startStates = np.zeros([self.nDecUnits, self.batchSize])
            
            for i in range(self.nEpochs):
                #learn rate
                lr = self.learnRateStart*(1 - i/float(self.nEpochs))
                
                #shuffle dataset order
                errListTrain = []
                datasetOrder = np.random.permutation(nDatasets)
                for currentDatasetIdx in datasetOrder:
                    nTrials = inputs[currentDatasetIdx].shape[0]
                    trialOrder = np.random.permutation(nTrials)
                    
                    nBatches = int(np.ceil(float(nTrials)/self.batchSize))
                    for batchIdx in range(nBatches):
                        selIdx = np.arange(batchIdx*self.batchSize, (batchIdx+1)*self.batchSize)
                        selIdx = selIdx[selIdx<nTrials]
                        lenSelIdx = len(selIdx)
                        if lenSelIdx<self.batchSize:
                            selIdx = np.concatenate([selIdx, np.zeros([self.batchSize-len(selIdx)])])
                            selIdx = selIdx.astype(np.int32)
                    
                        #random start state and target
                        trlIdx = trialOrder[selIdx]
                        inputSeq = inputs[currentDatasetIdx][trlIdx,:,:]
                        targSeq = targets[currentDatasetIdx][trlIdx,:,:]
                        eMaskIn = eMask[currentDatasetIdx][trlIdx,:]
                        if lenSelIdx<self.batchSize:
                            eMaskIn[0:lenSelIdx,:]=eMaskIn[0:lenSelIdx,:] * float(self.batchSize)/lenSelIdx
                            eMaskIn[lenSelIdx:,:]=0
                        
                        #descend gradient
                        ao, to, te = self.sess.run([self.lr_update, self.train_op, self.totalErr], 
                                                            feed_dict={self.new_lr: lr, self.startDecState: startStates, self.batchInputs: inputSeq, 
                                                                       self.batchTargets: targSeq, self.datasetIdx: currentDatasetIdx, self.errorMask: eMaskIn, 
                                                                       self.keep_prob_input: kpi, self.keep_prob_layer: kpl})
                        errListTrain.append(te)
            
                #track validation accuracy on a random validation batch
                errListVal = []
                for currentDatasetIdx in range(nDatasets):
                    nTrials = inputsVal[currentDatasetIdx].shape[0]
                    valIdx = np.random.choice(nTrials, self.batchSize)
                    inputSeq = inputsVal[currentDatasetIdx][valIdx,:,:]
                    targSeq = targetsVal[currentDatasetIdx][valIdx,:,:]
                    eMaskIn = eMaskVal[currentDatasetIdx][valIdx,:]
                    te, l2c = self.sess.run([self.totalErr, self.l2cost], feed_dict={self.new_lr: lr, self.startDecState: startStates, self.batchInputs: inputSeq, self.batchTargets: targSeq, 
                                               self.datasetIdx: currentDatasetIdx, self.errorMask: eMaskIn, self.keep_prob_input: 1.0, self.keep_prob_layer: 1.0})
                    errListVal.append(te)
                
                #log progress
                mnErrTrain = np.mean(errListTrain)
                mnErrVal = np.mean(errListVal)
                testSummary, trainSummary, l2cSummary = self.sess.run([self.testErrSummary, self.trainErrSummary, self.l2costSummary], 
                                                                      feed_dict={self.trainErr_ph: mnErrTrain, self.testErr_ph: mnErrVal, self.l2cost_ph: l2c})
                writer.add_summary(trainSummary, i)
                writer.add_summary(testSummary, i)
                writer.add_summary(l2cSummary, i)
                
                #save whenever validation error is at its lowest point so far
                if mnErrVal < lve:
                    bestEpoch = i
                    lve = mnErrVal
                    saver.save(self.sess, outputDir + '/model.ckpt', global_step=i, write_meta_graph=False)
                
                #validation plot every once in a while
                if i%5 == 0:
                    print('Epoch: ' + str(i) + ', trainErr: ' + str(mnErrTrain) + ', testErr: ' + str(mnErrVal))
                            
                    if self.doPlot==1:
                        plt.figure()
                        for x in range(nDatasets):
                            inputSeq = inputsVal[x][np.zeros(self.batchSize,dtype=int),:,:]
                            targSeq = targetsVal[x][np.zeros(self.batchSize,dtype=int),:,:]
                            do, inf = self.sess.run([self.decOutput, self.projectedInput], feed_dict={self.new_lr: lr, self.startDecState: startStates, self.batchInputs: inputSeq, 
                                                self.batchTargets: targSeq, self.datasetIdx: x, self.errorMask: eMask[0][0:self.batchSize,:], self.keep_prob_input: 1.0, self.keep_prob_layer: 1.0})
                            do = np.stack(do)
                            inf = np.stack(inf)
                        
                            plt.subplot(nDatasets,2,x*2+1)
                            plt.plot(targetsVal[x][0,:,0])
                            plt.plot(do[0,:,0])
                            
                            plt.subplot(nDatasets,2,x*2+2)
                            plt.plot(targetsVal[x][0,:,1])
                            plt.plot(do[0,:,1])
                        plt.show()
            
            #load the best performing variables
            ckpt = tf.train.get_checkpoint_state(outputDir)
            saver.restore(self.sess, ckpt.model_checkpoint_path)
                
            #apply to inputsFinal and return
            outputs_tr = []
            inFac_tr = []
            decoderStates_tr = []
            
            outputs_val = []
            inFac_val = []
            decoderStates_val = []
            
            outputs_final = []
            inFac_final = []
            decoderStates_final = []
            
            for currentDatasetIdx in range(nDatasets):
                otr, itr, dstr = self.decode(currentDatasetIdx, inputs[currentDatasetIdx], targets[currentDatasetIdx], eMask[currentDatasetIdx])
                outputs_tr.append(otr)
                inFac_tr.append(itr)
                decoderStates_tr.append(dstr)
                
                oval, ival, dsval = self.decode(currentDatasetIdx, inputsVal[currentDatasetIdx], targetsVal[currentDatasetIdx], eMaskVal[currentDatasetIdx])
                outputs_val.append(oval)
                inFac_val.append(ival)
                decoderStates_val.append(dsval)
                
                if inputsFinal!=[]:
                    ofinal, ifinal, dsfinal = self.decode(currentDatasetIdx, inputsFinal[currentDatasetIdx], targetsFinal[currentDatasetIdx], eMaskFinal[currentDatasetIdx])
                    outputs_final.append(ofinal)
                    inFac_final.append(ifinal)
                    decoderStates_final.append(dsfinal)
                    
            if self.doPlot==1 and inputsFinal!=[]:
                plt.figure()
                for x in range(3):
                    plt.subplot(3,2,x*2+1)
                    plt.plot(targetsFinal[0][x,:,0])
                    plt.plot(outputs_final[0][x,:,0])
                    
                    plt.subplot(3,2,x*2+2)
                    plt.plot(targetsFinal[0][x,:,1])
                    plt.plot(outputs_final[0][x,:,1])
                plt.show()
            
            a = {}
            a['bestEpoch']=bestEpoch
            for currentDatasetIdx in range(nDatasets):
                
                #a['targetsTrain'+str(currentDatasetIdx)]=targets[currentDatasetIdx]
                #a['outputsTrain'+str(currentDatasetIdx)]=outputs_tr[currentDatasetIdx]
                #a['inFacTrain'+str(currentDatasetIdx)]=inFac_tr[currentDatasetIdx]
                #a['decoderStatesTrain'+str(currentDatasetIdx)]=decoderStates_tr[currentDatasetIdx]
                
                #a['targetsVal'+str(currentDatasetIdx)]=targetsVal[currentDatasetIdx]
                #a['outputsVal'+str(currentDatasetIdx)]=outputs_val[currentDatasetIdx]
                #a['inFacVal'+str(currentDatasetIdx)]=inFac_val[currentDatasetIdx]
                #a['decoderStatesVal'+str(currentDatasetIdx)]=decoderStates_val[currentDatasetIdx]
                
                if outputs_final!=[]:
                    a['targetsFinal'+str(currentDatasetIdx)]=targetsFinal[currentDatasetIdx]
                    a['outputsFinal'+str(currentDatasetIdx)]=outputs_final[currentDatasetIdx]
                    a['inFacFinal'+str(currentDatasetIdx)]=inFac_final[currentDatasetIdx]
                    a['decoderStatesFinal'+str(currentDatasetIdx)]=decoderStates_final[currentDatasetIdx]
            
            scipy.io.savemat(outputDir + '/finalOutput',a)
        
    def decode(self, datasetIdxForDecoding, inputs, targets, eMask): 
        nTrials = inputs.shape[0]
        outputs = np.zeros(targets.shape)
        inFac = np.zeros([nTrials, self.nSteps, self.nDecInputFactors])
        decoderStates = np.zeros([nTrials, self.nSteps, self.decStates.shape[2]])
        startStates = np.zeros([self.nDecUnits, self.batchSize])
        
        nBatches = int(np.ceil(float(nTrials)/self.batchSize))
        for batchIdx in range(nBatches):
            selIdx = np.arange(batchIdx*self.batchSize, (batchIdx+1)*self.batchSize)
            selIdx = selIdx[selIdx<nTrials]
            if len(selIdx)<self.batchSize:
                selIdx = np.concatenate([selIdx, np.zeros([self.batchSize-len(selIdx)])])
                selIdx = selIdx.astype(np.int32)
        
            inputSeq = inputs[selIdx,:,:]
            targSeq = targets[selIdx,:,:]
            eMaskIn = eMask[selIdx,:]
            
            do, infa, ds = self.sess.run([self.decOutput, self.projectedInput, self.decStates], feed_dict={self.startDecState: startStates, self.batchInputs: inputSeq, 
                                                           self.batchTargets: targSeq, self.datasetIdx: datasetIdxForDecoding, self.errorMask: eMaskIn, 
                                                           self.keep_prob_input: 1.0, self.keep_prob_layer: 1.0})
        
            outputs[selIdx,:,:] = do
            inFac[selIdx,:,:] = infa
            decoderStates[selIdx,:,:] = ds
        
        return outputs, inFac, decoderStates