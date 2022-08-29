import argparse
import os
import errno
from clDecoderSim_free import clDecoderSim

parser = argparse.ArgumentParser(description='Closed-loop RNN controller + decoder')
hyperParams = [['device', str],
               ['targSeqFile', str],
               ['outputDir', str],
               ['nCursorDim',int],
               ['nOutputFactors', int],
               ['nDecUnits', int],
               ['nControllerUnits', int],
               ['dt',float],
               ['batchSize',int],
               ['nSteps',int],
               ['doPlot',int],
               ['nDelaySteps',int],
               ['learnRateStart',float],
               ['nTrainIterations',int]]
for i in range(len(hyperParams)):
    parser.add_argument('--'+hyperParams[i][0], metavar=hyperParams[i][0], type=hyperParams[i][1], nargs=1)

args = parser.parse_args()
#args = parser.parse_args(['--device','/cpu:0','--targSeqFile','/Users/frankwillett/Data/Derived/gruCLTest_free/trackSeq.mat',
#                          '--outputDir','/Users/frankwillett/Data/Derived/gruCLTest_free',
#                          '--nCursorDim','2','--nOutputFactors','2','--nDecUnits','50','--nControllerUnits','50',
#                          '--dt','0.02','--batchSize','16','--nSteps','250','--nDelaySteps','10','--learnRateStart','0.01',
#                          '--nTrainIterations','10000','--doPlot','1'])

argDic = vars(args)
print(argDic)

try:
    os.makedirs(args.outputDir[0])
except OSError as exception:
    if exception.errno != errno.EEXIST:
        raise
             
decSim = clDecoderSim(argDic)        
decSim.run(argDic['outputDir'][0], argDic['targSeqFile'][0])