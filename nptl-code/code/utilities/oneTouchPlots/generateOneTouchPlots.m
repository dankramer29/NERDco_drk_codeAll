function generateOneTouchPlots(participantID, sessionID, oneTouchOutputDir,options)
% GENERATEONETOUCHPLOTS    
% 
% generateOneTouchPlots(participantID, sessionID, oneTouchOutputDir, plotOutPref)

    options.rmsMult = -4.5;
    options.binSize=2000;
    if ~isfield(options,'channelList')
        options.channelList = [];
    end
        
    sessionName = [participantID ' - ' sessionID];
    [hf1, perfAxes] = oneTouchPerformanceFigure(1);
    [hf2, frAxes] = oneTouchFiringRateFigure(2);
    [hf3, frAxesNorm] = oneTouchFiringRateFigure(3);
    [hf4, rmsAxes] = oneTouchFiringRateFigure(4);
    rtPlotColor=[0.3 1 0.3];
    stLabelColor=[0.3 0.5 0.3];
    stLabelHeight=0.06;
    stTextXPosition=0.00;
        
    % nevFiles=loadvar([dataPref 'vars'],'nevFiles');
    streamDir = ['/net/derivative/stream/' participantID '/' sessionID]; %'/net/derivative/stream/';
    blocks=loadvar([streamDir '/blocks'],'blocks');
    [jnk,sortOrder] = sort([blocks.blockId],'ascend');
    blocks = blocks(sortOrder);
    
    Rdir = '/net/derivative/R/';
    
    plotOutPref = [participantID '/' sessionID '/'];
    if ~isdir([oneTouchOutputDir plotOutPref])
        mkdir([oneTouchOutputDir plotOutPref]);
    end
    
    
    blockstats = struct;
    for nr = 1:length(blocks)
        rFile=[Rdir participantID '/' sessionID '/R_' num2str(blocks(nr).blockId) '.mat'];
        if ~exist(rFile,'file')
            %BJ: previously, simply skipped that file:
%             disp(['skipping R ' num2str(blocks(nr).blockId)]);
%             continue;
            
            %BJ: now, creating R from stream:
            warning(['R does not exist for block ' num2str(nr) '. Attempting to create it from stream...']) 
            tic
            try
                streamFile = [streamDir filesep num2str(nr) '.mat'];
                stream = load(streamFile);
            catch
                warning(['Stream couldn''t be loaded for ' streamFile '. Skipping this block.'])
                continue;
            end
            [R, taskDetails] = onlineR(stream);
            toc
            if isempty(R),
                warning(['Something went wrong in trying to create R from stream in block ' num2str(nr) '. Skipping block.'])
                continue;
            end

        else
            disp(['loading R ' num2str(blocks(nr).blockId)])
            tic;
            R=loadvar(rFile,'R');
            taskDetails=loadvar(rFile,'taskDetails');
            toc;
        end            
        
        stateVars = {taskDetails.states.name};
        stateIds = [taskDetails.states.id];
        
        inputIds = cellfun(@(x) strcmp(x(1:5),'INPUT'), stateVars);
        inputTypes = stateVars(inputIds);
        inputIds = stateIds(inputIds);

        taskIds = cellfun(@(x) strcmp(x(1:4),'TASK'), stateVars);
        taskTypeArray = stateVars(taskIds);
        taskTypeIds = stateIds(taskIds);
        
        tParams=[R.startTrialParams];
        
        % [g,gLabels]=gameTypes();
        % % taskTypes=[tParams.taskId];
        % % sTags=[tParams.saveTag];
        %sTags=[R.saveTag];
        blockstats(nr).sTags = zeros(size(R)) + blocks(nr).blockId;
        blockstats(nr).taskType = [tParams.taskType];
        
        % % how long is each trial (in s)?
        blockstats(nr).trialLengths=arrayfun(@(x) size(x.xk,2), R)/1000;
        blockstats(nr).acqTimes=[R.timeLastTargetAcquire];
        
        
        % % get "reach times"
        % reachTimeInds=find(taskTypes==g.radialTrain | taskTypes==g.clickTrain);
        % reachTimes=trialLengths(reachTimeInds);

        % get online control trials
        % timeToTargetInds=find(taskTypes==g.radial8 | taskTypes==g.fitts);
        blockstats(nr).timeToTarget=blockstats(nr).trialLengths;

        if ~exist('blockRms','var')
            blockRms = getThresholds(R);
        end            
        if ~isfield(R,'spikeRaster')
            R = onlineSpikeRaster(R, blockRms*options.rmsMult);
        end
        
        if ~isempty(options.channelList)
            for nn = 1:length(R)
                R(nn).spikeRaster = R(nn).spikeRaster(options.channelList,:);
            end
        end
        
        if ~isfield(R,'rms')
            R = onlineRMS(R);
        end
        if ~isempty(options.channelList)
            for nn = 1:length(R)
                R(nn).rms = R(nn).rms(options.channelList,:);
            end
        end

        
        %% bin the firing rates
        msBinnedSpikes=[R(:).spikeRaster];
        newBins=1:options.binSize:size(msBinnedSpikes,2);
        blockstats(nr).rebinnedSpikes=zeros([size(msBinnedSpikes,1) size(newBins,2)-1]);
        for nB = 1 : length(newBins)-1
            blockstats(nr).rebinnedSpikes(:,nB)=sum(full(msBinnedSpikes(:,newBins(nB):newBins(nB+1))),2);
        end
        % set the units to Hz
        blockstats(nr).rebinnedSpikes = blockstats(nr).rebinnedSpikes ./ (options.binSize / 1000);
    
        if ~exist('lastBlockTime','var')
            lastBlockTime =0;
        end
        startTime = lastBlockTime;
        endTime = sum(blockstats(nr).trialLengths)+lastBlockTime;
        
        % blockstats(nr).newBins = newBins+lastBlockTime;
        blockstats(nr).newBins = linspace(startTime,endTime,size(blockstats(nr).rebinnedSpikes,2));
        blockstats(nr).timePoints = (blockstats(nr).newBins(1:end-1) + diff(blockstats(nr).newBins)/2);
        % lastBlockTime = blockstats(nr).newBins(end)+options.binSize;
        lastBlockTime = endTime;

        %% bin the rms
        msBinnedRMS=[R(:).rms];
        blockstats(nr).rms=zeros([size(msBinnedRMS,1) size(newBins,2)-1]);
        for nB = 1 : length(newBins)-1
            blockstats(nr).rms(:,nB)=mean(full(msBinnedRMS(:,newBins(nB):newBins(nB+1))),2);
        end
            
    end
    
    sTags = [blockstats.sTags];
    rebinnedSpikes = [blockstats.rebinnedSpikes];
    rms = [blockstats.rms];
    timeToTarget = [blockstats.timeToTarget];
    taskTypes = [blockstats.taskType];
    timePoints = [blockstats.timePoints];
    trialStartTimes=cumsum([blockstats.trialLengths]);
    timeToTargetInds = 1:length(trialStartTimes);
    
        %% performance plot
        axes(perfAxes.performance);
        plot(trialStartTimes,zeros(size(trialStartTimes)),'-.k');
        hold on;
        set(gca,'tickdir','out');
        set(gca,'ticklen',[0.005 0.005]);
        set(gca,'box','off');        
        % %% plot "Reach times"
        % rtPlot=plot(trialStartTimes(reachTimeInds),reachTimes,'.');
        % set(rtPlot,'color',rtPlotColor);
        % set([rtPlot(:)], 'markersize', 8);
        xlabel('Time (s)');
        ylabel('Trial Length (s)');
        title([sessionName ' - Performance']);

        
        %% plot time-to-target times for online control
        timeToTargetPlot=plot(trialStartTimes(timeToTargetInds),timeToTarget,'.');
        axis('tight');
        set([timeToTargetPlot(:)], 'markersize', 8)    
        
        %% plot the firing rates
        axes(frAxes.firingrates)
        %% get vectors for x and y axes
        unitLabels = 1:size(rebinnedSpikes,1);
        imagesc(timePoints, unitLabels, rebinnedSpikes);
        colormap('hot');
        title([sessionName ' - Firing Rates - Max: ' num2str(max(rebinnedSpikes(:))) ' Hz']);
        xlabel('Time (s)');
        ylabel('Unit Number');
        set(gca,'tickdir','out');
        set(gca,'ticklen',[0.005 0.005]);
        set(gca,'box','off');

        %% normalize per channel
        for nC = 1:size(rebinnedSpikes,1)
            rebinnedSpikesNorm(nC,:) = rebinnedSpikes(nC,:) / max(rebinnedSpikes(nC,:));
        end
        
        %% plot the normalized firing rates
        axes(frAxesNorm.firingrates)
        imagesc(timePoints, unitLabels, rebinnedSpikesNorm);
        colormap('hot');
        title([sessionName ' - Normalized Firing Rates']);
        xlabel('Time (s)');
        ylabel('Unit Number');
        set(gca,'tickdir','out');
        set(gca,'ticklen',[0.005 0.005]);
        set(gca,'box','off');

        %% plot the RMS
        for nC = 1:size(rms,1)
           rmsNorm(nC,:) = rms(nC,:) / max(rms(nC,:));
        end
        axes(rmsAxes.firingrates)
        imagesc(timePoints, unitLabels, rmsNorm);
        colormap('jet');
        title([sessionName ' - RMS']);
        xlabel('Time (s)');
        ylabel('Unit Number');
        set(gca,'tickdir','out');
        set(gca,'ticklen',[0.005 0.005]);
        set(gca,'box','off');
        
        %find the boundaries between different savetags
        boundaries=find(diff(sTags));
        tagHandles=[];
        labelHandles=[];
%         %% plot the save tag boundaries   %we don't use save tags with  human data (this part was copied from monk data)
%         for nB=1:length(boundaries)
%             % get the start and end times for this saveTag
%             if nB==1
%                 startPoint=0;
%                 bPoint=trialStartTimes(boundaries(nB));
%             else
%                 startPoint=trialStartTimes(boundaries(nB-1));
%                 bPoint=trialStartTimes(boundaries(nB));
%             end
%             
%             axes(frAxes.firingrates);
%             vline(bPoint,'r');
%             axes(frAxesNorm.firingrates);
%             vline(bPoint,'r');
%             axes(rmsAxes.firingrates);
%             vline(bPoint,'r');
% 
%             axes(perfAxes.performance);
%             vline(bPoint,'r');
% 
%             % label the previous region
%             tmp=get(gca,'ylim');
%             stLabelHeight1=stLabelHeight*diff(tmp)+tmp(1);
%             tagHandles(end+1,1)=text(mean([bPoint startPoint]),...
%                                      stLabelHeight1,...
%                                      num2str(sTags(boundaries(nB))));
%             
%             currType=taskTypes(boundaries(nB));
%             typeInd=find(taskTypeIds==currType);
%             lName = taskTypeArray{typeInd};
%             lName(lName=='_') = ' ';
%             label=sprintf('%g: %g - %s',...
%                           sTags(boundaries(nB)),currType,lName);
%             axes(perfAxes.labels);
%             labelHandles(end+1,1)=text(stTextXPosition,...
%                                        (length(boundaries)+2-nB)/(length(boundaries)+2),label);
%             axes(frAxes.labels);
%             labelHandles(end+1,1)=text(stTextXPosition,...
%                                        (length(boundaries)+2-nB)/(length(boundaries)+2),label);
%             axes(frAxesNorm.labels);
%             labelHandles(end+1,1)=text(stTextXPosition,...
%                                        (length(boundaries)+2-nB)/(length(boundaries)+2),label);
%             axes(rmsAxes.labels);
%             labelHandles(end+1,1)=text(stTextXPosition,...
%                                        (length(boundaries)+2-nB)/(length(boundaries)+2),label);
%             
%             if nB==length(boundaries)
%                 %label the last region
%                 axes(perfAxes.performance);
%                 tagHandles(end+1,1)=text(mean([bPoint trialStartTimes(end)]),...
%                                          stLabelHeight1,...
%                                          num2str(sTags(boundaries(nB)+1)));
% 
%                 currType=taskTypes(boundaries(nB)+1);
%                 typeInd=find(taskTypeIds==currType);
%                 lName = taskTypeArray{typeInd};
%                 lName(lName=='_') = ' ';
%                 label=sprintf('%g: %g - %s',...
%                               sTags(boundaries(nB)+1),currType,lName);
%                 axes(perfAxes.labels);
%                 labelHandles(end+1,1)=text(stTextXPosition,...
%                                            (length(boundaries)-nB+1)/(length(boundaries)+2),label);
%                 axes(frAxes.labels);
%                 labelHandles(end+1,1)=text(stTextXPosition,...
%                                            (length(boundaries)-nB+1)/(length(boundaries)+2),label);
%                 axes(frAxesNorm.labels);
%                 labelHandles(end+1,1)=text(stTextXPosition,...
%                                            (length(boundaries)-nB+1)/(length(boundaries)+2),label);
%                 axes(rmsAxes.labels);
%                 labelHandles(end+1,1)=text(stTextXPosition,...
%                                            (length(boundaries)-nB+1)/(length(boundaries)+2),label);
%             end
%             
%         end
        clear nB;
        
        set(labelHandles,'color',stLabelColor);
        set(tagHandles,'color',stLabelColor);
        set([tagHandles(:); labelHandles(:)],'fontsize',12);
        im=getScreenshot(hf1);
        
        imwrite(im, [oneTouchOutputDir plotOutPref 'performancePlot.png']);
        
        im=getScreenshot(hf2);
        imwrite(im, [oneTouchOutputDir plotOutPref 'firingRatePlot.png']);

        im=getScreenshot(hf3);
        imwrite(im, [oneTouchOutputDir plotOutPref 'firingRateNormPlot.png']);

        im=getScreenshot(hf4);
        imwrite(im, [oneTouchOutputDir plotOutPref 'rmsPlot.png']);

        p.plotNames={['performancePlot.png'],
                     ['firingRatePlot.png'],
                     ['firingRateNormPlot.png'],
                     ['rmsPlot.png'],...
                    };        
        updateOneTouchDB(oneTouchOutputDir, participantID, sessionID, p);
    end