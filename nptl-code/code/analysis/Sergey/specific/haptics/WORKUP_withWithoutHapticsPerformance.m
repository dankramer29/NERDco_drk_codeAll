% Shows performance from a single day of the haptics comparison
% Sergey D Stavisky, Neural Prosthetics Translational Laboratory
% 26 April 2018
clear
startupNPTL_analysis






%% T5
groupComparisons = {[1,2]}; % with hapics (1) vs NO haptics (2)


% streamsPath = '/net/experiments/t5/t5.2018.04.25/Data/FileLogger/';
% experiment  = 't5.2018.04.25';
% condition.blocks =   [6,  8  10,  11];
% condition.decoder =  [2,  2,  1,   1];

streamsPath = '/net/experiments/t5/t5.2018.07.02/Data/FileLogger/';
experiment  = 't5.2018.07.02';
condition.blocks =   [13,  14  15,  16,   17, 18, 19, 20,  21, 23,  24, 26, 27];
condition.decoder =  [ 2,   2,  1,   1,    1,  1,  2,  2,   2,  2,   2,  1,  1];


condition.conditionName = {'haptics', 'no haptics'};
% decoder '1' is with posFeedback, '2' is without
% These are the radial 8 blocks. There are also Fitts task blocks (9,10,11)


params.rootSaveDir = [FiguresRoot '/haptics/performance/']; % for figures




params.savePlots = false; % whether to save the  plots
params.metric = 'timeLastTargetAcquire';      % for trial-by-trial plot, which metric to use.

params.doubleSuccessOnly = true; % if true, will only analyze trials that are successes following another success 
                                 % This helps normalize motivaiton.
params.firstTryCentering = true; % if true, will only analyze centering trials that are following successful trials (to prevent
                                 % very short trials where he failed the last few)

colors = [...
    206/255, 64/255, 62/255; % with haptics
    126/255, 129/255, 142/255]; % no haptics
params.whiteBG = true; % for poster/paper
yCeiling = 10000; % pins metric values above this to this value, thus removing a few outliers


% use appropriate nanYvalue for metric
switch params.metric
    case 'successes';
        nanYvalue = 0;
    case 'timeLastTargetAcquire'
        nanYvalue = 5000;
end

%% Data selection
% load data
R = [];
for iBlock = 1 : numel( condition.blocks )   
    myBlock = condition.blocks(iBlock);
    stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, myBlock ), {'neural'} ); % note excluding neural, which I don't need here
    Rin = onlineR( stream );
    fprintf('Loaded %s block %i (%i trials). Throwing out first trial \n', experiment, myBlock, numel( Rin ) );
    Rin(1) = []; % remove first trial, which is often not formatted right or was super short
    % label trials with decoder of interest
    for i = 1 : numel( Rin )
        Rin(i).decoder = condition.decoder(iBlock);
        Rin(i).blockNumber = myBlock;
    end
    R = [R; Rin'];
end

    


% Before filtering out trials, report success rates per group
success = [];
blockLabels = []; % identify which block each trial comes from
groupLabels = []; % identify which group each trial comes from
for iBlock = 1 : numel( condition.blocks )
    myBlock = condition.blocks(iBlock);
    myCond = condition.decoder(iBlock);
      
    myTrials = SavetagInds(R, myBlock );
    success = [success; [R(myTrials).isSuccessful]'];
    blockLabels = [blockLabels; repmat(iBlock, numel(myTrials), 1 )];
    groupLabels = [groupLabels; repmat(myCond, numel(myTrials), 1)];     
end
fprintf('%s\n', experiment)
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


if params.doubleSuccessOnly
    R = AddPrevIsSuccessful( R );
    keepTrials = [R.isSuccessful] & [R.prevIsSuccessful];
    fprintf('Keeping only succesful trials that follow successful trials! From %i trials ', ...
        numel(R) )
    R = R(keepTrials);
    fprintf('%i tials remain\n', numel( R ) );
end

if params.firstTryCentering
    R = AddPrevIsSuccessful( R );
    centeringNotFirstTry = logical(CenteringTrialInds( R )') & ~[R.prevIsSuccessful];
    fprintf('Removing %i trials which are centering trials where previous trial is not successful\n', ...
        nnz( centeringNotFirstTry ) );
    R(centeringNotFirstTry) = [];
end



% -----------------------------------------------------------------
%%              Trial by Trial Performance
% -----------------------------------------------------------------

perfs = [];
blockLabels = []; % identify which block each trial comes from
groupLabels = []; % identify which group each trial comes from
allPerformance = [R.(params.metric)]';
for iBlock = 1 : numel( condition.blocks )
    myBlock = condition.blocks(iBlock);
    myCond = condition.decoder(iBlock);
    
    myTrials = SavetagInds(R, myBlock );
    perfs = [perfs; allPerformance(myTrials)];
    blockLabels = [blockLabels; repmat(iBlock, numel(myTrials), 1 )];
    groupLabels = [groupLabels; repmat(myCond, numel(myTrials), 1)];     
end


% -----------------------------------------------------------------
%%             Compare Statistics
% -----------------------------------------------------------------
datA = allPerformance(groupLabels==1);
datB = allPerformance(groupLabels==2);
[p,h]=ranksum(datA,datB);
fprintf('Comparing haptic  (%.2f+-%.2f,%.2fms, mean +- s.d., s.e., %i trials) versus no hapic (%.2f+-%.2f,%.2f, %i trials), p = %g (rank-sum test)\n', ...
    mean( datA ), std( datA ), sem( datA ), numel( datA ), ...
    mean( datB ), std( datB), sem( datB ), numel( datB ), p );



numCeiling = nnz( perfs > yCeiling );
fprintf('Bringing %i points down to y ceiling value of %g\n', ...
    numCeiling, yCeiling );
perfs(perfs > yCeiling) = yCeiling;

% match colors and groupnames size
colors = colors(1:numel( condition.conditionName),:);
[figPerf, stats, axh] = TrialByTrialPerformanceTimeline( perfs, blockLabels, ...
    'groupLabels', groupLabels, 'colors', colors, 'groupName', condition.conditionName, ...
    'groupComparisons', groupComparisons, 'nanYvalue', nanYvalue );
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
Rhaptic = R([R.decoder] == 1);
Rno = R([R.decoder] == 2);
statHaptic = CursorTaskSimplePerformanceMetrics( Rhaptic );
statNo = CursorTaskSimplePerformanceMetrics( Rno );

% Time to target
[p,h] = ranksum( statHaptic.TTT, statNo.TTT );
fprintf('TTT haptic: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmean( statHaptic.TTT ), nanmean( statNo.TTT ), p );

% Path efficiency
[p,h] = ranksum( statHaptic.pathEfficiency, statNo.pathEfficiency );
fprintf('PE haptic: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmean( statHaptic.pathEfficiency ), nanmean( statNo.pathEfficiency ), p );
    
% Dial-in 
[p,h] = ranksum( statHaptic.dialIn, statNo.dialIn );
fprintf('Dial-in haptic: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmean( statHaptic.dialIn ), nanmean( statNo.dialIn ), p );

