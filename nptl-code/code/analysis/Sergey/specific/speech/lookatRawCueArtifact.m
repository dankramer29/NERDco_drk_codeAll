


Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/withRaw/R_T5_2017_09_20-words.mat ';


excludeLabels = {'mm'}; % too few of these

% in = load( Rfile );
% R = in.R;

burstChans = [67, 68, 69, 73, 77, 78, 82];
smallBurstChans = [66, 76, 83, 85, 86, 94, 95, 96]; % just to be super caref

myWord = 'push';
chansOfInterest = [ 9, burstChans(4), burstChans(5)];

%%

params.plot.cueAlignEvent = 'cueEvent';
params.plot.cueStartEvent = 'cueEvent - 0.3';
params.plot.cueEndEvent = 'cueEvent + 1';

params.plot.speechAlignEvent = 'speechEvent';
params.plot.speechStartEvent = 'speechEvent - 0.6';
params.plot.speechEndEvent = 'speechEvent + 1';



% Scan for whether event labels files exist for these blocks. 
allLabels = arrayfun( @(x) x.label, R, 'UniformOutput', false );
if any( ismember( allLabels, excludeLabels ) )
    fprintf('Removing %i trials of label ''%s''\n', nnz( ismember( allLabels, excludeLabels ) ), ...
        CellsWithStringsToOneString( excludeLabels ) );
    R(ismember( allLabels, excludeLabels ))=[];
    allLabels(ismember( allLabels, excludeLabels ))=[];
end
uniqueLabels = unique( allLabels );
blocksPresent = unique( [R.blockNumber] );

fprintf('Loaded %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;


% alignment cues for silent trials
for iTrial = 1 : numel( R )
    if strcmp( R(iTrial).label, 'silence' )
        R(iTrial).cueEvent = R(iTrial).timeCueStart + 500; % not very precise, this should be improved later
        R(iTrial).speechEvent = R(iTrial).timeSpeechStart+ 500;
    elseif strfind( Rfile, 'thought' )
        % this is for the 'thoughtSpeak' experiment in which there's no overt sound during
        % response. Therefore, the timeSpeechStart annotation marker is aligned to start of second
        % response chime. For now I'll just advance by 500 ms to when the participant may be
        % responding.
        R(iTrial).cueEvent = R(iTrial).timeCueStart;
        R(iTrial).speechEvent = R(iTrial).timeSpeechStart + 500;
    else
        R(iTrial).cueEvent = R(iTrial).timeCueStart;
        R(iTrial).speechEvent = R(iTrial).timeSpeechStart;
    end  
end


% Group by cues
for iGroup = 1 : numel( uniqueLabels )
    Rgroup{iGroup} = R(strcmp( allLabels, uniqueLabels{iGroup} ));    
end

%%

myGroupInd = find( strcmp( uniqueLabels, myWord ) );

jenga = AlignedMultitrialDataMatrix( Rgroup{myGroupInd}, 'featureField', 'raw1', ...
        'startEvent', params.plot.cueStartEvent, 'alignEvent', params.plot.cueAlignEvent, 'endEvent', params.plot.cueEndEvent );
    
figh = figure;
myTrial = 5;
plot( jenga.t, squeeze( jenga.dat(myTrial,:,chansOfInterest ) ) );
title( [myWord, ' trial ', mat2str( myTrial )] )
legend( Rgroup{myGroupInd}(1).raw1.channelName(chansOfInterest), 'Interpreter', 'none' )
xlabel( params.plot.cueAlignEvent );
ylabel('Raw Voltage');