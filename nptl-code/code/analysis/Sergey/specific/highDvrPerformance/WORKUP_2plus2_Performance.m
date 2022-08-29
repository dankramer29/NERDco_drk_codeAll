% Shows performance from 2 + 2 task.
% Sergey D Stavisky, Neural Prosthetics Translational Laboratory
% 18 May 2018
clear
startupNPTL_analysis






%% T5
listname = 't5_2plus2D';
groupComparisons = {[1,2]}; %  4 DOF versus 2+2 D

params.rootSaveDir = [FiguresRootNPTL '/twoPlusTwo/performance/']; % for figures



params.savePlots = true; % whether to save the  plots
params.metric = 'timeLastTargetAcquire';      % for trial-by-trial plot, which metric to use.

params.doubleSuccessOnly = false; % if true, will only analyze trials that are successes following another success 
                                 % This helps normalize motivaiton.
params.firstTryCentering = false; % if true, will only analyze centering trials that are following successful trials (to prevent
                                 % very short trials where he failed the last few)

colors = [...
    130/255, 130/255, 130/255;
    206/255, 64/255, 62/255; % 4 DOF
    ]; % 2 + 2
params.whiteBG = true; % for poster/paper
yCeiling = 60000; % pins metric values above this to this value, thus removing a few outliers
nanYvalue = yCeiling + 2000;
yTicks = [0 yCeiling/2 yCeiling nanYvalue];

% use appropriate nanYvalue for metric
switch params.metric
    case 'successes';
        nanYvalue = 0;
    case 'timeLastTargetAcquire'
        nanYvalue = 5000;
end


%%
if params.savePlots  && ~isdir( params.rootSaveDir )
    mkdir( params.rootSaveDir )
end

datasets = datasets_2plus2D( listname );









% loop through data
for iDS = 1 : numel( datasets )
    [dataset, condition] = datasets_2plus2D( datasets{iDS} );
    experiment =  datasets{iDS};
    participant = experiment(1:2);
    streamsPath = sprintf( '/net/experiments/%s/%s/Data/FileLogger/', ...
        participant, experiment);
    
    %% load data
    R = [];
    for iBlock = 1 : numel( condition.blocks )
        myBlock = condition.blocks(iBlock);
        stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, myBlock ), {'neural'} ); % note excluding neural, which I don't need here
        Rin = onlineR( stream );
        fprintf('Loaded %s block %i (%i trials). Throwing out first trial \n', experiment, myBlock, numel( Rin ) );
        Rin(1) = []; % remove first trial, which is often not formatted right or was super short
        % label trials with decoder of interest
        for i = 1 : numel( Rin )
            Rin(i).task = condition.task(iBlock);
            Rin(i).blockNumber = myBlock;
        end
        R = [R; Rin'];
    end
    
    
    % Report success rates per group
    success = [];
    blockLabels = []; % identify which block each trial comes from
    groupLabels = []; % identify which group each trial comes from
    for iBlock = 1 : numel( condition.blocks )
        myBlock = condition.blocks(iBlock);
        myCond = condition.task(iBlock);
        
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
    
    
    % make .timeFirstTargetAcquire and .timeLastTargetAcquire a nan for fail trials so
    % so downstream code works works (otherwise bracket flattening ignores
    % these)
    for i = 1 : numel( R )
        if isempty( R(i).timeFirstTargetAcquire )
            R(i).timeFirstTargetAcquire = nan;           
        end
        if isempty( R(i).timeLastTargetAcquire )
             R(i).timeLastTargetAcquire = nan;
        end
    end  
    
    
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
    startcounter = []; % can be used to plot as a timeline instead of trial
    runningCounter = 0; % increments after each block
    blockLabels = []; % identify which block each trial comes from
    groupLabels = []; % identify which group each trial comes from
    allPerformance = [R.(params.metric)]';
    allStartcounter = [R.startcounter]';
    for iBlock = 1 : numel( condition.blocks )
        myBlock = condition.blocks(iBlock);
        myCond = condition.task(iBlock);
        
        myTrials = SavetagInds(R, myBlock );
        perfs = [perfs; allPerformance(myTrials)];
        blockLabels = [blockLabels; repmat(iBlock, numel(myTrials), 1 )];
        groupLabels = [groupLabels; repmat(myCond, numel(myTrials), 1)];
        startcounter = [startcounter;  runningCounter + allStartcounter(myTrials)];
        runningCounter = runningCounter + R(myTrials(end)).endcounter(end);
    end
    
    
    % -----------------------------------------------------------------
    %%             Compare Statistics
    % -----------------------------------------------------------------
    datA = allPerformance(groupLabels==1);
    datB = allPerformance(groupLabels==2);
    [p,h]=ranksum(datA,datB);
    fprintf('Comparing 4D  (%.2f+-%.2f,%.2fms, mean +- s.d., s.e., %i trials) versus 2+2D (%.2f+-%.2f,%.2f, %i trials), p = %g (rank-sum test)\n', ...
        nanmean( datA ), nanstd( datA ), nansem( datA ), numel( datA ), ...
        nanmean( datB ), nanstd( datB), nansem( datB ), numel( datB ), p );
    
    
    
    numCeiling = nnz( perfs > yCeiling );
    fprintf('Bringing %i points down to y ceiling value of %g\n', ...
        numCeiling, yCeiling );
    perfs(perfs > yCeiling) = yCeiling;
    
    % x location corresponds to start of block
    xLocation = double( [startcounter - startcounter(1)]./1000 ); % in seconds
    
    % match colors and groupnames size
    colors = colors(1:numel( condition.conditionName),:);
    [figPerf, stats, axh] = TrialByTrialPerformanceTimeline( perfs, blockLabels, ...
        'groupLabels', groupLabels, 'colors', colors, 'groupName', condition.conditionName, ...
        'groupComparisons', groupComparisons, 'nanYvalue', nanYvalue, 'yTicks', yTicks, ...
        'xLocation', xLocation);
    xlabel( 'task time (s)' )
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
    R4D = R([R.task] == 1);
    R22D = R([R.task] == 2);
    stat4D = CursorTaskSimplePerformanceMetrics( R22D );
    stat2plus2 = CursorTaskSimplePerformanceMetrics( R4D );
    
    % Time to target
    [p,h] = ranksum( stat4D.TTT, stat2plus2.TTT );
    fprintf('TTT 4D: %.2f, 2+2D: %.2f, (p=%g, ranksum)\n', ...
        nanmean( stat4D.TTT ), nanmean( stat2plus2.TTT ), p );
    
    % Path efficiency
    [p,h] = ranksum( stat4D.pathEfficiency, stat2plus2.pathEfficiency );
    fprintf('PE 4D: %.2f, 2+2D: %.2f, (p=%g, ranksum)\n', ...
        nanmean( stat4D.pathEfficiency ), nanmean( stat2plus2.pathEfficiency ), p );
   
    
end
