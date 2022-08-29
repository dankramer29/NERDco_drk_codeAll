% test analysis code for multiclick 
% some specific to multiclick, some for comparison across paradigms
% % Success rate: compare
% % % always on target, number of mis-clicks. 
% % confusion matrix of click decoding: 
% % % total: all bins that were move or clicks (both tasks)- metric of false positive clicks
% % % on the target: multiclick only- numClicks x numClicks, don't count move? or do
% % Time to taget: 
% % % time to the start of the successful click 
% % Bit rate? Using time to target ^ 
% % % The Paul version: 
% % % bitRate = log2(N-1)*max(numSelections -2*numErrors, 0)/totalTime
%% stream and R struct: R = [R{:}]; % eliminates block boundaries
%% closedLoop Sessions
clmcDates       = {'2019.09.04',    '2019.09.04',   '2019.09.04',   '2019.09.09',   '2019.09.09',   '2019.09.09',   '2019.09.09',...
                    '2019.09.11',   '2019.09.11',   '2019.09.11',   '2019.09.16',   '2019.09.16',   '2019.09.16',   '2019.09.16',...
                    '2019.09.18',   '2019.09.18',   '2019.09.18',   '2019.09.23',   '2019.09.23',   '2019.09.23',   '2019.09.23', '2019.09.23',...
                    };
olmcBlocks      = { [1],             [10],           [18],           [2],            [4],            [8],            [17]        ,...
                    [2],             [11],           [18],           [3],            [13],           [21],           [29]        ,...
                    [6],             [15],           [23],           [1],            [10],           [18],           [27],   [35],...
                    };
clmcBlocks      = { [4:8 ],          [11:17],        [19:23],        [3],            [ 5:7],        [ 9:15],        [18:20]     ,...
                    [3:9 ],          [12:17],        [19:21,23:27],  [5:10],         [15:20],       [23:28],        [31:36]     ,...
                    [9:14],          [17:22],        [25:30],        [3, 5:9],       [12:17],       [20:25],        [29:34],  [37:40],...
                    };
numClickStates  = [ 4,               4,               4,              4,              4,              4,              4         ,...
                    1,               2,               2,              1,              2,              1,              2         ,...
                    4,               3,               1,              2,              1,              2,              1,       4,...
                    ];
descriptorIdx   = [  1,               1,              2,              3,              3,              2,              3         ,...
                     4,               5,              6,              7,              8,              7,              8         ,...
                    10,               9,              7,              8,              7,              8,              7,      10,...
                    ];
clickSets ={    [ 'Index', 'Middle', 'Ring', 'Pinky'], ['Index', 'Middle', 'Thumb', 'Pinky'], ['RightHand', 'RightFoot', 'LeftFoot', 'LeftHand'],...
                                        ['RightHand'], ['RightHand', 'RightFoot'],            ['RightFoot', 'LeftHand']                         ,...
                                        ['Left Hand'], ['LeftHand', 'RightFoot'], ['LeftHand, LeftFoot', 'RightHand']                           ,...
    ['LeftHand', 'RightFoot', 'LeftFoot', 'RightHand']};

filtOpts.filtFields = [];%{'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
curThresh = 0.5; 
%% make R structs
% filtOpts.filtFields = {'rigidBodyPosXYZ'};
% filtOpts.filtCutoff = 10/500; 
for sesh = 1:length(clmcBlocks) 
    streams = [];
    [ R, streams] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', clmcDates{sesh}, '/'], clmcBlocks{sesh}, -3.5, clmcBlocks{sesh}(1), filtOpts);
    [res(sesh).BR] = bitRateMC(R, numClickStates(sesh)); % this needs the block dividers in the R struct
    R = [R{:}];                   % after bitRateMC, no need for block dividers   
   % R([R.clickTarget] == 0) = []; %eliminate center targets from next analyses 
   % [res.CLL, figh] = stateLikelihoodCompare(R([R.isSuccessful]), [], [],numClickStates(sesh)+1, 0.5); %with the above line, this would have made the function only take in successful peripheral targets
   % only plot peripheral targets:  
   [res(sesh).CLL, ~] = stateLikelihoodCompare(R([R.clickTarget] > 0), [], [], numClickStates(sesh)+1, curThresh); 
    
   %save(['Users/sharlene/CachedData/t5.', clmcDates{sesh}, '/', 'RstreamCLL_targSet', num2str(descriptorIdx(sesh)), '.mat'], 'R', 'streams', 'res', '-v7.3');
end

%% success rate: 




