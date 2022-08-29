#hyperparameters to search:
#dropout, L2 weight regularization
#learning rate schedule
#number of units
#magnitude of weight initialization
#smoothing on input features
#number of time-steps per series

#objects of specific inquiry:
#number of factors on input layer, pre-solved input layer restricted to subsets of 4-component model
#training over multiple datasets & subjects; variable input layer, input layer + context key, retrain whole model
#stacking multiple recurrent layers
#vanilla vs. GRU vs. LSTM

#compare to:
#linear velocity decoder with exponential smoothing & fixed delay
#VKF with fixed delay
#Weiner filter velocity decoder
#Magnitude decoder

import argparse
import os
import errno
from rnnDecoder_c import rnnDecoder

#parse inputs
parser = argparse.ArgumentParser(description='RNN decoder with multi-dataset training')
parser.add_argument('--datasets', metavar='datasets', type=str, nargs='+',
                    help='a list of dataset numbers to include in training')
parser.add_argument('--datasetDir', metavar='datasetDir', type=str, nargs=1,
                    help='dataset directory')
parser.add_argument('--outputDir', metavar='outputDir', type=str, nargs=1,
                    help='output directory')
parser.add_argument('--mode', metavar='mode', type=str, nargs=1,
                    help='mode (train, preInitTrain, decode)')
parser.add_argument('--nInputsPerModelDataset', metavar='nInputsPerModelDataset', type=int, nargs='+',
                    help='an integer for each dataset used to train the model')
parser.add_argument('--preInitDatasetNum', metavar='preInitDatasetNum', type=int, nargs='+',
                    help='which dataset idx to use for preinitialization')
parser.add_argument('--datasetIdxForDecoding', metavar='datasetIdxForDecoding', type=int, nargs='+',
                    help='which dataset idx to use for decoding')
parser.add_argument('--loadDir', metavar='loadDir', type=str, nargs=1,
                    help='where to load the model when in preInitTrain or decode mode')

hyperParams = [['rnnType', str],
               ['device',str],
               ['nLayers', int],
               ['nDecInputFactors', int],
               ['L2Reg', float],
               ['learnRateStart',float],
               ['nEpochs',int],
               ['initWeightScale',float],
               ['useInputProj',int],
               ['nDecUnits',int],
               ['keepProbIn',float],
               ['keepProbLayer',float],
               ['nModelDatasets',int],
               ['doPlot',int],
               ['nSteps',int],
               ['nTargetDim',int],
               ['batchSize',int]]
for i in range(len(hyperParams)):
    parser.add_argument('--'+hyperParams[i][0], metavar=hyperParams[i][0], type=hyperParams[i][1], nargs=1)

args = parser.parse_args()
#args = parser.parse_args(['--datasets','t5.2016.10.03',
#                          '--datasetDir','/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/4comp_2/Fold1',
#                          '--outputDir','/Users/frankwillett/Data/Derived/gruTestOut_pit','--rnnType','RNN',
#                          '--loadDir','/Users/frankwillett/Data/Derived/gruTestOut',
#                          '--nLayers','2','--nDecInputFactors','2','--L2Reg','100','--learnRateStart','0.01','--nEpochs','100',
#                          '--initWeightScale','1.0','--nDecUnits','50','--useInputProj','0','--keepProbIn','1.0','--keepProbLayer','0.95','--device','/cpu:0',
#                          '--mode','preInitTrain','--nInputsPerModelDataset','2','--doPlot','1','--nModelDatasets','2',
#                          '--nSteps','510','--nTargetDim','2','--batchSize','32','--preInitDatasetNum','0','--datasetIdxForDecoding','0'])
argDic = vars(args)
print(argDic)

if args.outputDir[0]!=None and args.outputDir[0]!='':
    try:
        os.makedirs(args.outputDir[0])
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise
             
#initialize model
if argDic['loadDir']==None:
    loadDir = None
else:
    loadDir = argDic['loadDir'][0]
    
if argDic['preInitDatasetNum']==None:
    preInitDatasetNum = None
else:
    preInitDatasetNum = argDic['preInitDatasetNum'][0]
    
rnnDec = rnnDecoder(argDic, argDic['mode'][0], preInitDatasetNum, loadDir)        

#run model
if argDic['datasetIdxForDecoding']==None:
    datasetIdxForDecoding = None
else:
    datasetIdxForDecoding = argDic['datasetIdxForDecoding'][0]
    
rnnDec.run(argDic['datasets'], argDic['datasetDir'][0], argDic['outputDir'][0], datasetIdxForDecoding)