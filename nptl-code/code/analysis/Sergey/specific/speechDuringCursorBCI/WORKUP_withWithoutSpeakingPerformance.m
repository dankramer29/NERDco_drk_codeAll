% Shows performance from one or multiple days of the cursor BCI comparison
% with or without concurrent speaking.
%
% Sergey D Stavisky, Neural Prosthetics Translational Laboratory
% 8 March 2019
clear







%% T5
% Point to R structs that have already been constructed
% experiment = 't5.2018.12.12';
% condition.blocks = {...
%    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B7.mat';
%    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B9.mat';
%    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B10.mat';
%    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B12.mat', ...
% };
% condition.day = repmat( 1, 1, numel( condition.blocks ) );

% experiment = 't5.2018.12.17';
% condition.blocks = {...
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B8.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B9.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B10.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B11.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B12.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B13.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B16.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B17.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B18.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B19.mat';
% };
% condition.day = repmat( 2, 1, numel( condition.blocks ) );

experiment = 't5.2018.12.12 and t5.2018.12.17';
condition.blocks = {...
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B7.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B9.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B10.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B12.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B8.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B9.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B10.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B11.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B12.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B13.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B16.mat';    
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B17.mat';    
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B18.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B19.mat';
};
condition.day = [repmat( 1, 1, 4 ), repmat( 2, 1, 10 )];


condition.conditionName = {'speech', 'no speech'};
% decoder '1' is with posFeedback, '2' is without
% These are the radial 8 blocks. There are also Fitts task blocks (9,10,11)


params.rootSaveDir = [FiguresRoot '/speechDuringBCI/performance/']; % for figures

params.savePlots = false; % whether to save the  plots
params.metric = 'timeLastTargetAcquire';      % for trial-by-trial plot, which metric to use.
params.doubleSuccessOnly = true; % if true, will only analyze trials that are successes following another success 
                                 % This helps normalize motivaiton.
params.firstTryCentering = true; % if true, will only analyze centering trials that are following successful trials (to prevent
                                 % very short trials where he failed the last few)

colors = [...
    0 0 0.8; % blue; with speech
    0.3 .3 .3]; % grey, no speech
cuedTrialColor = [248, 24, 148]./255; % hot pink for cued to speak (or not) trials
params.whiteBG = true; % for poster/paper
yCeiling = 10000; % pins metric values above this to this value, thus removing a few outliers


% use appropriate nanYvalue for metric
switch params.metric
    case 'successes'
        nanYvalue = 0;
    case 'timeLastTargetAcquire'
        nanYvalue = yCeiling;
end

%% Data Load
% load data
R = [];
for iBlock = 1 : numel( condition.blocks )   
    in = load( condition.blocks{iBlock} );   
    hasSpeech = arrayfun( @(x) ~isempty( x.labelSpeech ), in.R );
    myUniqueLabels = unique( arrayfun(@(x) x.labelSpeech{1}, in.R(hasSpeech), 'UniformOutput', false ) );
    if numel( myUniqueLabels ) > 1
        error('not expecting more than one label per block')
    end
    % I'm calling 
    if strcmp( myUniqueLabels, 'silence' )
        myCondition = 2;
    else
        myCondition = 1;
    end
    condition.condition(iBlock) = myCondition;
    condition.blockNum(iBlock) = in.R(1).startTrialParams.blockNumber; % numericla block number
    fprintf('Loaded %s condition %s (%i trials).  \n', ...
        condition.blocks{iBlock}, upper( condition.conditionName{myCondition} ), numel( in.R ) );
   
    % annotate it with block number and condition
    for iTrial = 1 : numel( in.R )
        in.R(iTrial).blockNum = in.R(iTrial).startTrialParams.blockNumber;
        in.R(iTrial).condition = myCondition;
        in.R(iTrial).day = condition.day(iBlock);
        
        % did previous trial have a speech cue?
        in.R(iTrial).prevTrialHasCue = false;
        if (iTrial > 1) && (in.R(iTrial).trialNum == in.R(iTrial-1).trialNum+1)
            % yes, we have a previous trial available
            if any( ~isnan( in.R(iTrial-1).timeCue ) )
                in.R(iTrial).prevTrialHasCue = true;
            end
        end
    end
    R = [R; in.R'];
end

    

%% Data Filtering
% Before filtering out trials, report success rates per group
success = [];
blockLabels = []; % identify which block each trial comes from
groupLabels = []; % identify which group each trial comes from
for iBlock = 1 : numel( condition.blocks )
    myBlockNum = condition.blockNum(iBlock);
    myCond = condition.condition(iBlock);
      
    myTrials = SavetagInds( R, myBlockNum );
    success = [success; [R(myTrials).isSuccessful]'];
    blockLabels = [blockLabels; repmat(iBlock, numel(myTrials), 1 )];
    groupLabels = [groupLabels; repmat(myCond, numel(myTrials), 1)];     
end
uniqueGroups = unique( groupLabels );
for iGroup = 1 : numel( uniqueGroups )
    myTrials = groupLabels == uniqueGroups(iGroup);
    numTrials = numel( success(myTrials) );
    numSuccess = nnz( success(myTrials) );
    fprintf('Group %i (%s) %i/%i successful (%.1f%%)\n', ...
        uniqueGroups(iGroup), condition.conditionName{uniqueGroups(iGroup)}, ...
        numSuccess, numTrials, ...
        100*(numSuccess/numTrials) );
    results.success.group(iGroup) = uniqueGroups(iGroup);
    results.success.numSuccess(iGroup) = numSuccess;
    results.success.numTrials(iGroup) = numTrials;
    results.success.successRate(iGroup) = numSuccess/numTrials';
end

% restrict to succesful only
fprintf('Restricting to %i successful trials\n', numel( [R.isSuccessful]));
R = R([R.isSuccessful]);

% Remove very short trials (probably reseeds)
shortTrials = FindShortTrials( R, 'tooShort', 101 );
fprintf('removing %i trials for being too short (reseeds likely)\n', nnz( shortTrials ) );
R(shortTrials)=[];

% Remove trials > 10 sec
longTrials = arrayfun( @(x) numel(x.clock), R ) > 10000;
fprintf('removing %i trials for being too long (>10s)\n', nnz( longTrials ) );
R(longTrials)=[];

if params.doubleSuccessOnly
    R = AddPrevIsSuccessful( R );
    keepTrials = [R.isSuccessful] & [R.prevIsSuccessful];
    fprintf('Keeping only succesful trials that follow successful trials! From %i trials ', ...
        numel(R) )
    R = R(keepTrials);
    fprintf('%i trials remain\n', numel( R ) );
end

if params.firstTryCentering
    R = AddPrevIsSuccessful( R );
    centeringNotFirstTry = logical(CenteringTrialInds( R )') & ~[R.prevIsSuccessful];
    fprintf('Removing %i trials which are centering trials where previous trial is not successful\n', ...
        nnz( centeringNotFirstTry ) );
    R(centeringNotFirstTry) = [];
end


%% Add a few other metrics
R = AddDialInTime( R );
R = AddCursorPathEfficiency( R, 'radiusCounts', false ); 

% -----------------------------------------------------------------
%%              Trial by Trial Performance
% -----------------------------------------------------------------

perfs = [];
blockLabels = []; % identify which block each trial comes from
groupLabels = []; % identify which group each trial comes from
eachTrialColor = []; % will build up and will mark the trials when speaking happened.


allPerformance = [R.(params.metric)]';
for iBlock = 1 : numel( condition.blocks )
    myBlock = condition.blockNum(iBlock);
    myDay = condition.day(iBlock);
    myCond = condition.condition(iBlock);
    
    % bit awkard to accomodate multiple days, which means repeating blocj numbers
    myTrials = find( [R.blockNum] == myBlock & [R.day] ==condition.day(iBlock) );
    perfs = [perfs; allPerformance(myTrials)];
    blockLabels = [blockLabels; repmat(iBlock, numel(myTrials), 1 )];
    groupLabels = [groupLabels; repmat(myCond, numel(myTrials), 1)];     
    
    myColors = repmat( colors(myCond,:), numel( myTrials), 1 );
    myCuedTrials = find( ~isnan( [R(myTrials).timeCue] )  );
    for i = 1 : numel( myCuedTrials)        
       myColors(myCuedTrials(i),:) = cuedTrialColor; 
    end
    eachTrialColor = [eachTrialColor; myColors];
end


% -----------------------------------------------------------------
%%             Compare Statistics
% -----------------------------------------------------------------
datA = allPerformance(groupLabels==1);
datB = allPerformance(groupLabels==2);
[p,h]=ranksum(datA,datB);
fprintf('Comparing %s  (%.2f+-%.2f,%.2fms, mean +- s.d., s.e., %i trials) versus %s (%.2f+-%.2f,%.2f, %i trials), p = %g (rank-sum test)\n', ...
    upper( condition.conditionName{1} ), ...
    nanmean( datA ), nanstd( datA ), nansem( datA ), numel( datA ), ...
    upper( condition.conditionName{2} ), ...
    nanmean( datB ), nanstd( datB), nansem( datB ), numel( datB ), p );
fprintf('MEDIAN %s = %gms, MEDIAN %s = %gms)\n', ...
    upper( condition.conditionName{1} ), nanmedian( datA ), ...
    upper( condition.conditionName{2} ), nanmedian( datB ) )


numCeiling = nnz( perfs > yCeiling );
fprintf('Bringing %i points down to y ceiling value of %g\n', ...
    numCeiling, yCeiling );
perfs(perfs > yCeiling) = yCeiling;

colors = colors(1:numel( condition.conditionName),:); % match colors and groupnames size

% -----------------------------------------------------------------
%%             Make Figure 
% -----------------------------------------------------------------
groupComparisons = {[1 2]};
[figPerf, stats, axh] = TrialByTrialPerformanceTimeline( perfs, blockLabels, ...
    'groupLabels', groupLabels, 'colors', colors, 'groupName', condition.conditionName, ...
    'groupComparisons', groupComparisons, 'nanYvalue', nanYvalue, 'singleTrialColors', eachTrialColor, ...
    'drawMeanBar', false, 'drawMedianBar', true, 'rightGroupSummary', 'median', 'verbose', true);
ylabel( [params.metric ' (ms) ']);



titlestr = sprintf(' Performance Comparison %s ', experiment );
MakeTitle( titlestr );
set( figPerf, 'Name', MakeValidFilename( titlestr ) );
if params.whiteBG
    figPerf = ConvertToWhiteBackground( figPerf );
end

if params.savePlots
    ExportFig( figPerf, [params.rootSaveDir MakeValidFilename( titlestr )] );
end

%% Some additional metrics
% These are after trial exclusions
Rspeech = R([R.condition] == 1);
RnoSpeech = R([R.condition] == 2);
statSpeech = CursorTaskSimplePerformanceMetrics( Rspeech );
statNoSpeech = CursorTaskSimplePerformanceMetrics( RnoSpeech );

% Time to target
[p,h] = ranksum( statSpeech.TTT, statNoSpeech.TTT );
fprintf('TTT speech: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmean( statSpeech.TTT ), nanmean( statNoSpeech.TTT ), p );

% Path efficiency
[p,h] = ranksum( statSpeech.pathEfficiency, statNoSpeech.pathEfficiency );
fprintf('PE haptic: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmean( statSpeech.pathEfficiency ), nanmean( statNoSpeech.pathEfficiency ), p );
    
% Dial-in 
[p,h] = ranksum( statSpeech.dialIn, statNoSpeech.dialIn );
fprintf('Dial-in haptic: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmean( statSpeech.dialIn ), nanmean( statNoSpeech.dialIn ), p );



% -----------------------------------------------------------------
%%     Compare trials with and without a cue
% -----------------------------------------------------------------
% I'm also including the trial that follows a speech cue, which allows for both 
% speaking that rolls into the next trial, and some lingering attentional interference.

hasCueTrials = arrayfun( @(x) any(~isnan( x.timeCue ) ), R );
followsCueTrials = [R.prevTrialHasCue]';

% non-speaking trials 
pristineTrials = ~(hasCueTrials | followsCueTrials);
perfsPristine = allPerformance(pristineTrials);
fprintf('\n%i trials with no cue and not following a cue trial. %.2f+-%.2f (mean +- std) %s\n',...
    nnz( pristineTrials ) , nanmean( perfsPristine ), nanstd( perfsPristine ), params.metric );

% cued (and subsequent) trials during the silent condition
cuedNonspeechTrials = (hasCueTrials | followsCueTrials) & ([R.condition]' == 2);
perfsCuedNonspeech = allPerformance(cuedNonspeechTrials);
fprintf('%i trials with or following cue but SILENT. %.2f+-%.2f (mean +- std)\n',...
    nnz( cuedNonspeechTrials ) , nanmean( perfsCuedNonspeech ), nanstd( perfsCuedNonspeech ) );

% cued (and subsequent) trials during the verbal condition
cuedVerbalTrials = (hasCueTrials | followsCueTrials) & ([R.condition]' == 1);
perfsCuedVerbal = allPerformance(cuedVerbalTrials);
fprintf('%i trials with or following cue, VERBAL. %.2f+-%.2f (mean +- std)\n',...
    nnz( cuedVerbalTrials ) , nanmean( perfsCuedVerbal ), nanstd( perfsCuedVerbal ) );

% Plot
datMat = cell2matIrregular( {perfsPristine, perfsCuedNonspeech, perfsCuedVerbal} );
barColors = [.3 .3 .3; % gray for clean
    .42 0.01 .49; %purple for cued silent
    .99 0.5 .62]; % pink for cued verbal
[stats, figh, axh] = MultipointComparisonBarplots( datMat, ...
    'conditionNames', {'clean', 'cued silent', 'cued verbal'}, 'colors', barColors, ...
    'numericMean', true );
ylabel( params.metric );
figh = ConvertToWhiteBackground( figh );

fprintf(' clean vs cued silent: p = %g\n', stats{1,2}.p )
fprintf(' clean vs cued verbal: p = %g\n', stats{1,3}.p )
fprintf(' cued silent vs cued verbal: p = %g\n', stats{2,3}.p )

%% Make it as a box-and-whiskers plot
figh = figure;
bh1 = boxplot( datMat, ...
    'BoxStyle', 'outline', 'Notch', 'on', 'OutlierSize', 2, ...
    'Symbol', 'o');
axh = gca;
axh.XTickLabel = {'clean', 'cued silent', 'cued verbal'};
ylim([0 10000])
figh.Name = sprintf('Box and whiskers %s', experiment );
axh.TickDir = 'out';
box off;

fprintf('Median clean: %gms\n', nanmedian( datMat(:,1) ) )
fprintf('Median prompted silent: %gms\n', nanmedian( datMat(:,2) ) )
fprintf('Median prompted verbal: %gms\n', nanmedian( datMat(:,3) ) )