% Introduction to NPTL human typing data. This script points to where data
% is located on NPSL /net/share, and it demonstrates the key fields of the 
% NPTL R structs.
%       The data here are all grid task. Note that these same days do have a
% roughlyu comparably quantity of keyboard typing data, but Grid is perhaps 
% easier to work with at first. For the keyboard task, we'd need a bit more
% processing to determine which trials are successful and which are
% failures (very doable though).
%
% Sergey Stavisky 7 October 2016

clear
% NPTL server:
dataDir = '/net/home/sstavisk/16outcomeError/giveToNir/'; % Grid Data
% dataDir = '/net/home/sstavisk/16outcomeError/giveToNir/typing/'; % Typing Data


% Datasets currently packaged up and ready to go.

% T6:
% I recommend starting with 't6.2014.07.02', it has the most data.
% datasets = {...
%     't6.2014.06.30'; 
%     't6.2014.07.02'; 
%     't6.2014.07.07';
%     't6.2014.07.18';
%     't6.2014.07.21';
%     };

% Dwell only
% datasets = {...
%     't6.2014.12.17'; 
%     };

% % T5: (warning, much larger file sizes, will be slower to load)
datasets = {...
    't5.2016.10.12';
    't5.2016.10.13'; % grid only
    't5.2016.10.24';
    't5.2016.10.26'; % typing only, and very few trials.
    't5.2016.12.15';
    };
% % T5 without click grid
% datasets = {...
%     't5.2016.09.28';
%     't5.2016.10.03'; 
%     };

clickOnly = true;
dwellOnly = false;

%% Load in an example dataset
dataset = datasets{5}; % choosing second dataset for this example.
fprintf( 'Loading %s...\n', [dataDir dataset '.mat'] );
in = load( [dataDir dataset '.mat'] ); % Load in the dataset

% Data is organized in blocks. I've only kept the blocks that match the
% grid task we're interested in. Let's combine. 
R = [];
for iBlock = 1 : numel( in.keepBlocks );
    myR = in.keepBlocks{iBlock}.R;
    
    myKeyboard = in.keepBlocks{iBlock}.keyboardType;
    switch myKeyboard
        case 3
            keyboardName = '6x6';
        case 6
            keyboardName = '9x9';
        case 20
            keyboardName = 'KEYBOARD_QABCD';
        case 30
            keyboardName = 'OPTIII';
        otherwise
            keyboardName = 'other keyboard'; % got lazy and didn't want to write them all
    end
    fprintf('Block #%i: gridtype %s, %i trials\n', in.keepBlocks{iBlock}.blockNum, keyboardName, numel( myR ) );
    R = [R,myR];
end

% Unlike rigC monkey data, here there are two selection modes: dwell and
% "click", which is when the HMM decodes the user intends to click
% (participant imagines squeezing their ipsilateral-to-array(s) hand). While it may 
% be powerful to show that the error signal is orthogonal to the click
% signal and thus can be decoded regardless, for now let's make life easier
% and just look at one of them.

% Once ina  while there's a trial where the .clicked field is nan, which is
% odd but let's just ignore those
R(isnan( [R.clicked])) = [];

numClick = nnz([R.clicked]);
numDwell = nnz(~[R.clicked]);
fprintf('%s\n', dataset );
fprintf('%i click and %i dwell trials. ', ...
    numClick, numDwell );
if clickOnly    
    R = R(logical( [R.clicked] ));
    fprintf(' Keeping click only\n')
elseif dwellOnly
     R = R(logical( ~[R.clicked] ));
     fprintf(' Keeping dwell only\n')
else
    fprintf('Keeping both\n')
end


% Add .timeSelection
for iTrial = 1 : numel( R )
    if R(iTrial).clicked
        % It's not exactly obvious when the final click (that determined success or
        % failure) happened. Let's add a new .timeSelection field.
        % Only do this extra pre-processing on click trials -- for dwell trials it
        % doesn't make sense.
        
        % It needs to go into state 4 (click I'm guessing) for longer than a
        % minimum perido (set in R(iTrial).startTrialParams.clickHoldTime I
        % think). So find the last state == 4 before the end of the trial.
        last4 = find( R(iTrial).state == 4, 1, 'last');
        backBy = find( R(iTrial).state(last4:-1:1)~=4,1,'first');
        if isempty( last4 ) || isempty( backBy )
            fprintf(2,'iTrial=%i\n', iTrial)
        end
        R(iTrial).timeSelection = last4 - backBy+2;
        % also add '.timeEnd' which is the end of the trial's ms-wise data.
        R(iTrial).timeEnd = numel( R(iTrial).state );
    else
        R(iTrial).timeSelection = numel( R(iTrial).state ); % success hold is end of trial
         % also add '.timeEnd' which is the end of the trial's ms-wise data.
        R(iTrial).timeEnd = numel( R(iTrial).state );
    end
end


% Divide into success and failures
% With keyboard data there will also be nans which we want to ignore
nanTrials = find( isnan( [R.isSuccessful] ) );
if numel( nanTrials ) > 1
    fprintf('%i trials are neither success or failure. This only makes sense for typing data. Ignoring these.\n', ...
        numel( nanTrials ) );
    R(nanTrials) = [];
end

data.Rsuccess = R( logical([R.isSuccessful]) );
data.Rfail = R( ~logical([R.isSuccessful]) );
fprintf('%i Successful trials, %i Failed trials\n', numel( data.Rsuccess ), numel( data.Rfail ) );

%% Assemble successful and fail trials' data aligned to selection.
% I do the same thing for both success, and fail, so do it in a loop. 

% doing alignment manually (not using fancy functions that you may not
% have). Definitelyc an be done more easily with my
% AlignedMultitrialDataMatrix.m or Dan's TrialData or similar.
alignEvent = 'timeSelection';
msBefore = 300;
msAfter = 499; % can't actually go much further without onerous looking at next trial's R struct.
t = -msBefore:msAfter; % aligned to the event.

for iGroup = 1 : 2
    switch iGroup
        case 1
            group = 'Rsuccess';
            write = 'processedSuccess'; % creates this field in data.
        case 2
            group = 'Rfail';
            write = 'processedFail';
    end
    
    myR = data.(group);
    numTrials = numel( myR );
    numChans = size( myR(1).minAcausSpikeBand,  1 ); % 96 for T6
    % preallocate data matrices
    data.(write).spikes = nan( numChans, numel(t), numTrials ); % channel x time x trial
    data.(write).lfp = nan( numChans, numel(t), numTrials ); % channel x time x trial
    data.(write).hlfp = nan( numChans, numel(t), numTrials ); % channel x time x trial
    % Unlike rigC, the spikes data is unthresholded voltage. You could play
    % around with the voltage to maximize performacne, but I'm just going
    % to use the threshold used for closed-loop decoding.
    % [DON'T actually optimize this. For the new participant the
    % threhsolding is very different, and there's no use optimizing for
    % past performance. We just want a proof of feasibility here.[
    threshold = in.keepBlocks{1}.thresholds;  
    % FYI, I happen to know ahead of time that the threshold wasn't changed during
    % the experiments. Hence I'm getting it from just one block.
    
    badTrials = [];
    for iTrial = 1 : numel( myR )
        % get my neural spike band data, including appending post-trial data
        mySpikeBand = [myR(iTrial).minAcausSpikeBand, myR(iTrial).postTrial.minAcausSpikeBand];
        % make this into rasters.
        myRasters = mySpikeBand < repmat( threshold', 1, size( mySpikeBand, 2 ) );
        % 10 ms smoothing
        smoothMS = 10;
        myRastersSmoothed = nan( size( myRasters ) );
        for iChan = 1 : numChans 
            myRastersSmoothed(iChan,:) = conv( double( myRasters(iChan,:) )', repmat(1000/smoothMS,1,smoothMS), 'same')'; % also converts to Hz
        end
        myAlign = myR(iTrial).(alignEvent);
        data.(write).spikes(:,:,iTrial) = myRastersSmoothed(:,myAlign-msBefore:myAlign+msAfter);
        
        % get lfp data
        try
            myLFP = [myR(iTrial).LFP, myR(iTrial).postTrial.LFP];
            data.(write).lfp(:,:,iTrial) = myLFP(:,myAlign-msBefore:myAlign+msAfter);
            
            % get high frequency lfp data
            myHLFP = [myR(iTrial).HLFP, myR(iTrial).postTrial.HLFP];
            data.(write).hlfp(:,:,iTrial) = myHLFP(:,myAlign-msBefore:myAlign+msAfter);
        catch
            % in t6.2014.07.07 I found some trials without LFP data, so
            % just ignore this trial
            badTrials(end+1) = iTrial;
        end
    end
    if~isempty( badTrials )
        fprintf('Had to remove %i trials for not having LFP or HF-LFP', numel( badTrials ));
        data.(write).lfp(:,:,badTrials) = [];
        data.(write).hlfp(:,:,badTrials) = [];
    end
end

% Visualize data: let's look at trial-averaged firing rate differences.
trialAvgFRsuccess = squeeze( mean( data.processedSuccess.spikes, 3 ) ); % chans x time
trialAvgFRfail = squeeze( mean( data.processedFail.spikes, 3 ) ); % chans x time
trialAvgFRdiff = trialAvgFRfail - trialAvgFRsuccess;
figh = figure; 
imagesc( t, 1:numChans, trialAvgFRdiff );
xlabel( sprintf('MS relative to %s', alignEvent ) );
ylabel('Electrode');
titlestr = 'Trial Avg Fail - Success Firing Rate';
title( titlestr ); figh.Name = titlestr;
% grand average across electordes
aggFRdiff = mean( trialAvgFRfail, 1 ) - mean( trialAvgFRsuccess, 1 );
figh = figure; 
plot( t, aggFRdiff );
xlabel( sprintf('MS relative to %s', alignEvent ) );
ylabel('FR Diff');
titlestr = 'Across Electrodes Trial Avg Fail - Success Firing Rate';
title( titlestr ); figh.Name = titlestr;


% Visualize LFP (raw lfp, dominated by low frequency components)
trialAvgLFPsuccess = squeeze( mean( data.processedSuccess.lfp, 3 ) ); % chans x time
trialAvgLFPfail = squeeze( mean( data.processedFail.lfp, 3 ) ); % chans x time
trialAvgLFPdiff = trialAvgLFPfail - trialAvgLFPsuccess;
figh = figure; 
imagesc( t, 1:numChans, trialAvgLFPdiff );
xlabel( sprintf('MS relative to %s', alignEvent ) );
ylabel('Electrode');
titlestr = 'Trial Avg Fail - Success LFP';
title( titlestr ); figh.Name = titlestr;



% Visualize HLFP (high frequency LFP)
trialAvgHLFPsuccess = squeeze( mean( data.processedSuccess.hlfp, 3 ) ); % chans x time
trialAvgHLFPfail = squeeze( mean( data.processedFail.hlfp, 3 ) ); % chans x time
trialAvgHLFPdiff = trialAvgHLFPfail - trialAvgHLFPsuccess;
figh = figure; 
imagesc( t, 1:numChans, trialAvgHLFPdiff );
xlabel( sprintf('MS relative to %s', alignEvent ) );
ylabel('Electrode');
titlestr = 'Trial Avg Fail - Success High Frequency LFP';
title( titlestr ); figh.Name = titlestr;


