function [figHandle] = oneTouchMovieStep(xMovie, t, reset, figHandle, figAxes, movieParams);
%DECODEMOVIESTEP generates a single frame of the movie.
%   FIGHANDLE = DECODEMOVIESTEP(XMOVIE, T, PARAMS) generates a single
%   frame for an offline decode movie.  Its input is an xMovie struct.  For
%   more information see buildXMovie.
%
%   The mParams is optional.  It is a struct with movei parameterse.
%   The fields used by the function are:
%       reset   - reset the decode to the hand per trial.  default: 1.
%
%   Copyright (c) by Jonathan C. Kao


    movieParams.foo = false;
    movieParams = setDefault(movieParams, 'drawArrows', false, true);
    movieParams = setDefault(movieParams, 'drawFiringRates', false, true);
    checkOption(movieParams, 'firstFrame', 'need to define movieParams.firstFrame');

    persistent persistents;
    if isempty(persistents) || movieParams.firstFrame
        persistents = struct();
        persistents.keyboards=allKeyboards();
        persistents.thisTrial = 0;
        persistents.handles = [];
        persistents.CLICKTIMEHANDLE = 1;
        persistents.SPEEDTIMEHANDLE = 2;
        persistents.ACCELTIMEHANDLE = 3;
        persistents.targetHandles=[];
    end
    %% is this a new trial?
    if persistents.thisTrial ~= xMovie.trial(t)
        newTrial = 1;
        persistents.thisTrial = xMovie.trial(t);
        disp(sprintf('trial %g',xMovie.trial(t)));
        pause(0.1);
    else
        newTrial = 0;
    end
    CLICKTIMEHANDLE = persistents.CLICKTIMEHANDLE;
    SPEEDTIMEHANDLE = persistents.SPEEDTIMEHANDLE;
    ACCELTIMEHANDLE = persistents.ACCELTIMEHANDLE;

keyColor=[0.6 0.6 0.6];
overColor=[0 0.75 0];
cuedColor=[0 0.5 0];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% "GLOBALS" and non-derived constants
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch xMovie.taskType
      case 'cursor'
        BOUNDS_SCALE    = 500;
        AX_RATIO        = [-1 1 -1 1];
        AX_LIM          = AX_RATIO * BOUNDS_SCALE;
        offsetxy = [0;0];
      case 'keyboard'
        dims = xMovie.taskParams.keyboardDims;
        %% add a 100pix boundary
        bnd = 100;
        AX_LIM = double([dims(1)-bnd dims(3)+dims(1)+bnd dims(2)-bnd dims(2)+dims(4)+bnd]);

        offsetxy = [mean([AX_LIM(1) AX_LIM(2)]);mean([AX_LIM(3) AX_LIM(4)])];
        AX_LIM = AX_LIM-[offsetxy(1) offsetxy(1) offsetxy(2) offsetxy(2)];
    end
    REUSE_PLOT      = 1;
    ARROW_SIZE      = 4;
    % TEXT_ABS_OFFSET = 50;
    TRIALTEXT_ABS_OFFSETY = 50;
    TRIALTEXT_ABS_OFFSETX = -20;
    TEXT_ABS_OFFSETY = 50;
    TEXT_ABS_OFFSETX = -20;
    TEXT_REL_OFFSETX = 12;
    TEXT_REL_OFFSETY = 12;

    %% for display purposes, Y axis needs to be reversed
    AXIS_MULTIPLIERS = [1 -1];
    xm = AXIS_MULTIPLIERS(1);
    ym = AXIS_MULTIPLIERS(2);

    if isfield(xMovie.taskParams,'targetDiameter')
        TARGET_MARKER_SIZE=double(xMovie.taskParams.targetDiameter);
    else
        TARGET_MARKER_SIZE=15;
    end
    if isfield(xMovie.taskParams,'cursorDiameter')
        CURSOR_MARKER_SIZE=double(xMovie.taskParams.cursorDiameter);
    else
        CURSOR_MARKER_SIZE=15;
    end
    
    TIME_MARKER_LINEWIDTH=3;
    FR_WINDOW_SIZE=76; % (ms)
    FR_POSTWINDOW_SIZE=50; % (ms)
    
    %HISTORY_LENGTH=100;
    HISTORY_LENGTH=1500/double(xMovie.dt);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Preprocessing and initialization
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Input checking
    assert(nargin >= 2, 'You did not specify all the inputs.');
    
    %localizeFields(figAxes);
    cursorAxis = figAxes.cursorAxis;
    
    % Localize fields of the movie parameters
    if ~exist('reset', 'var')       reset = 1;                  end

    % Derived parameters
    numX = length(xMovie.decodeX);
    
    % Draw a new figure or re-use what you have been drawing on.
    if REUSE_PLOT
        % figHandle = gcf;   cla;
        if gca ~= cursorAxis
            axes(cursorAxis);
        end
    else 
        figHandle = blackFigure(AX_LIM);
    end
    %%%%%%%%%%%%%%%%%%%%
    %%% Generate a frame
    %%%%%%%%%%%%%%%%%%%%
    
    if movieParams.firstFrame
        cla(cursorAxis);
        switch xMovie.taskType
            case 'keyboard'
                % render the keyboard
                q=persistents.keyboards(xMovie.taskParams.keyboard);
                axis(cursorAxis,AX_LIM);
                for nn = 1:q.keys(1).numKeys
                    xy = [q.keys(nn).x; q.keys(nn).y];
                    widthHeightXY = [q.keys(nn).width; q.keys(nn).height] + xy;
                    dchar = '';
                    if intersect(xMovie.taskParams.keyboard,[2 20 30])
                        dchar = char(q.keys(nn).text);
                    end
                    persistents.targetHandles(nn)=plotKeyboardTarget(xy,widthHeightXY,dims,offsetxy,xm,ym,dchar,...
                        'edgecolor','k','facecolor',keyColor);
                end
                
            case 'cursor'
                % Plot the target position
                cmark = plotCircle(0,0,TARGET_MARKER_SIZE/2);
                set(cmark,'faceColor','g');
                set(cmark,'edgeColor','g');
                persistents.targetHandles(1) = cmark;
                tmp = get(cmark,'position');
                tmp = tmp(:);
                persistents.targetOffset = tmp(1:2);
                clear tmp;
        end
        
        % Plot cursor data.
        cmark = plotCircle(0,0,CURSOR_MARKER_SIZE/2);
        set(cmark,'faceColor','w');
        set(cmark,'edgeColor','k');
        persistents.cursorHandle = cmark;
        tmp = get(cmark,'position');
        tmp=tmp(:);
        %% slightly offset because of the cursor's radius - just store that...
        persistents.cursorOffset = tmp(1:2);
        clear tmp;
    end

    %% update the current frame
    switch xMovie.taskType
        case 'keyboard'
            set(persistents.targetHandles,'facecolor',keyColor);
            cuedTarg = xMovie.cuedTarget(t);
            if ~isinteger(cuedTarg)
                disp('oneTouchMovieStep: dont know what to do with non-int target number');
            else
                set(persistents.targetHandles(cuedTarg),'facecolor',cuedColor);
            end
        case 'cursor'
          tpos = [xm*xMovie.posTarget(1,t); ym*xMovie.posTarget(2,t)];
          tpos2 = get(persistents.targetHandles(1),'position');
          tpos2(1:2) = tpos(:) + persistents.targetOffset;
          set(persistents.targetHandles(1),'position',tpos2);
          
    end
    % update cursor position
    cpos = xMovie.trueX(1:2,t) - offsetxy;
    cpos = cpos.* [xm; ym];
    %cpos = cpos-offsetxy(:);
    %keyboard
    cpos2 = get(persistents.cursorHandle,'position');
    cpos2(1:2) = cpos(:) + persistents.cursorOffset;
    set(persistents.cursorHandle,'position',cpos2);
    
    % Plot historical reaches in gray.
    startTime = max(1,t-HISTORY_LENGTH);
    tr = xMovie.trueX(1:2,startTime:t-1);
    tr = tr-repmat(offsetxy,[1 size(tr,2)]);
    if isfield(persistents,'traceHandles')
        delete(persistents.traceHandles);
    end
    persistents.traceHandles(1) = plot(xm*tr(1,:), ...
         ym*tr(2,:), ...
         'linewidth', 1, 'color', [0.5 0.5 0.5]);
        
    % Plot historical decodes in lighter colors.
    for j = 1:numX
        persistents.traceHandles(1+j) = plot(xm*(xMovie.decodeX{j}(1, startTime:t-1) + reset*xMovie.decodeO{j}(1, startTime:t-1)), ...
             ym*(xMovie.decodeX{j}(2,startTime:t-1) + reset*xMovie.decodeO{j}(2,startTime:t-1)), ...
             'linewidth', 1, 'color', preferredColors((j-1)*2 + 1));
    end


    %% do we want to draw arrows?
    if movieParams.drawArrows
        for j = 1:numX
            prevL = xMovie.decodeX{j}(1:2, t-1) + reset*xMovie.decodeO{j}(1:2, t-1);
            currL = xMovie.decodeX{j}(1:2, t) + reset *xMovie.decodeO{j}(1:2, t-1);
            % Draw an arrow.
            arrowMMC(prevL', currL', [], ARROW_SIZE, AX_LIM, preferredColors(2*j), preferredColors(2*j));
            % Plot new decode.
            plot([prevL(1) currL(1)], [prevL(2) currL(2)], 'linewidth', 3, 'color', preferredColors(2*j));
        end        
    end


    for j = 1:numX;
        text(AX_LIM(1) - TEXT_ABS_OFFSETX, AX_LIM(4) - TEXT_ABS_OFFSETY, sprintf('%s', visualizeStr(xMovie.names{j})), 'fontWeight', 'bold', 'fontSize', 11, 'color', preferredColors((j-1)*2 + 1));
    end
    axis(cursorAxis,AX_LIM);
    % axis('equal')
    txt = sprintf('Trial %d', xMovie.trial(t));
    if strcmp(xMovie.taskType,'keyboard')
        if xMovie.clicked(t) == 1
            txt=sprintf('%s - clicked',txt);
        elseif xMovie.clicked(t) == 0
            txt=sprintf('%s - dwelled',txt);
        end
    end
    if ~isfield(persistents,'textHandle')
        persistents.textHandle = text(AX_LIM(1) - TRIALTEXT_ABS_OFFSETX, AX_LIM(4) - TRIALTEXT_ABS_OFFSETY, txt, ...
                                      'fontWeight', 'bold', 'fontSize', 11, 'color', 'w');
    else
        set(persistents.textHandle,'string',txt);
    end

    % get the xMovie indices for this trial
    thisTrialInds =find(xMovie.trial==xMovie.trial(t));
    timepoints = thisTrialInds * xMovie.dt / 1000;
    timet = t * xMovie.dt / 1000;
        
%% draw the click likelihoods
    if movieParams.drawClickState && isfield(xMovie,'discreteStateLikelihoods')
        if newTrial
            clickAxis = figAxes.clickAxis;
            axes(clickAxis);
            cla('reset');
            % draw the clickState
            h=plot(timepoints,xMovie.discreteStateLikelihoods(2,thisTrialInds)');
            hold on;
            set(h,'linewidth',2,'color','w')
            set(clickAxis,'ylim',[-0.1 1.05]);

            makeBlank(clickAxis);
            persistents.handles(CLICKTIMEHANDLE) = vline(timet);
            set(persistents.handles(CLICKTIMEHANDLE),'linewidth',2);

            h=hline(xMovie.taskParams.hmmClickLikelihoodThreshold);
            set(h,'color',[0.5 0.5 0.5]);

            % set the axis limits        
            xlim = timepoints([1 end]);
            xlim = xlim + [-1 1]*2*xMovie.dt/1000;
            set(clickAxis,'xlim',xlim);
            axisXStart = xlim(1)+xMovie.dt/1000;

            %% draw a time axis
            clear taxis;
            taxis.tickLabels{1} = '0';
            taxis.tickLabels{2} = '0.5';
            taxis.axisOrientation = 'h';
            taxis.axisOffset = -0.05;
            taxis.color = 'w';
            taxis.tickLabelLocations = axisXStart + [0 0.5];
            AxisMMC(axisXStart, axisXStart+0.5, taxis);

            %% draw a likelihood axis
            clear taxis;
            taxis.tickLabels{1} = '0';
            taxis.tickLabels{2} = '1';
            taxis.axisOrientation = 'v';
            taxis.axisOffset = axisXStart;
            taxis.color = 'w';
            taxis.axisLabel = 'clickLikelihood';
            AxisMMC(0, 1, taxis);
        else
            tmp=get(persistents.handles(CLICKTIMEHANDLE),'xdata');
            tmp = zeros(size(tmp))+timet;
            set(persistents.handles(CLICKTIMEHANDLE),'xdata',tmp);
            clear tmp;
        end
    end

    if movieParams.drawSpeeds
        if newTrial
            speedAxis = figAxes.speedAxis;
            axes(speedAxis);
            cla('reset');
            % draw the speed
            speed = sqrt(sum(xMovie.trueV.^2));
            h=plot(timepoints,speed(thisTrialInds));
            hold on;
            set(h,'linewidth',2,'color','w')
            set(speedAxis,'ylim',[-0.1*max(speed) max(speed)]);

            makeBlank(speedAxis);
            persistents.handles(SPEEDTIMEHANDLE) = vline(timet);
            set(persistents.handles(SPEEDTIMEHANDLE),'linewidth',2);

            h=hline(xMovie.taskParams.hmmClickSpeedMax);
            set(h,'color',[0.5 0.5 0.5])

            xlim = timepoints([1 end]);
            xlim = xlim + [-1 1]*2*xMovie.dt/1000;
            set(speedAxis,'xlim',xlim);
            axisXStart = xlim(1)+xMovie.dt/1000;

            %% draw a speed axis
            clear taxis;
            taxis.tickLabels{1} = '0';
            taxis.tickLabels{2} = sprintf('%0.2f',(max(speed)/2));
            taxis.axisOrientation = 'v';
            taxis.axisOffset = axisXStart;
            taxis.color = 'w';
            taxis.axisLabel = 'speed';
            AxisMMC(0, max(speed)/2, taxis);
        else
            tmp=get(persistents.handles(SPEEDTIMEHANDLE),'xdata');
            tmp = zeros(size(tmp))+timet;
            set(persistents.handles(SPEEDTIMEHANDLE),'xdata',tmp);
            clear tmp;
        end
    end

    if movieParams.drawAccel
        if newTrial
            accelAxis = figAxes.accelAxis;
            axes(accelAxis);
            cla('reset');
            % draw the accel
            accelRaw = [0 diff(speed)];
            % calculate a moving average
            %malength=10;
            %mafilt = 1/malength+zeros(1,malength);
            %accel = [zeros(1,malength) conv(accelRaw,mafilt)];
            accel = smoothts(accelRaw,'e',20);
            h=plot(timepoints,accel(thisTrialInds));
            hold on;
            set(h,'linewidth',2,'color','w')
            ylims = quantile(accel,[0.01 0.99]);
            set(accelAxis,'ylim',[1.1*ylims(1) 1.1*ylims(2)]);
            h=hline(0);
            set(h,'color',[0.5 0.5 0.5]);
            makeBlank(accelAxis);
            persistents.handles(ACCELTIMEHANDLE) = vline(timet);

            xlim = timepoints([1 end]);
            xlim = xlim + [-1 1]*2*xMovie.dt/1000;
            set(accelAxis,'xlim',xlim);
            axisXStart = xlim(1)+xMovie.dt/1000;

            %% draw a accel axis
            clear taxis;
            taxis.tickLabels{1} = sprintf('%0.2f',(ylims(1)));
            taxis.tickLabels{2} = sprintf('%0.2f',(ylims(2)/2));
            taxis.axisOrientation = 'v';
            taxis.axisOffset = axisXStart;
            taxis.color = 'w';
            taxis.axisLabel = 'accel';
            AxisMMC(ylims(1), ylims(2)/2, taxis);

        else
            tmp=get(persistents.handles(ACCELTIMEHANDLE),'xdata');
            tmp = zeros(size(tmp))+timet;
            set(persistents.handles(ACCELTIMEHANDLE),'xdata',tmp);
            clear tmp;
        end
    end

    if movieParams.drawSingleChannelDecode
        if ~isfield(persistents,'filterChannels')
            persistents.filterChannels = find(sum(abs(xMovie.xSingleChannel')));
            persistents.maxDecodeRange = max(max(sqrt(xMovie.xSingleChannel.^2 + xMovie.ySingleChannel.^2)));
        end
        X = xMovie.xSingleChannel(persistents.filterChannels,t);
        Y = xMovie.ySingleChannel(persistents.filterChannels,t);

        chdAxis = figAxes.singleChDecodeAxis;
        axes(chdAxis);
        if newTrial
            cla;
        else
            delete(persistents.decodeHandles);
        end
        clear tmp1;
        tmp1(1) = compass(persistents.maxDecodeRange,persistents.maxDecodeRange);
        hold on;
        tmp1(2) = compass(-persistents.maxDecodeRange,-persistents.maxDecodeRange);
        lims = [-1 1] * persistents.maxDecodeRange;
        set(gca,'xlim',lims,'ylim',lims);
        persistents.decodeHandles=compass(X*xm,Y*ym);
        hold off;
        set(tmp1,'visible','off');
        clear tmp1;
    end

    if movieParams.drawFiringRates    
        %pull in the axes
        frAxis = figAxes.frAxis;
        popFrAxis = figAxes.popFrAxis;
        movAvgAxis = figAxes.movAvgAxis;

        %% plot individual firing rates
        axes(frAxis);
        %normalize neural data
        frMax = max(xMovie.neuralBin,[],2);
        normMtx = repmat(frMax, [1 size(xMovie.neuralBin,2)]);
        % normalized
        nBin = xMovie.neuralBin ./ normMtx;
        % get the index into the neural data of the end of the window
        endInd = min(t + FR_POSTWINDOW_SIZE - 1, size(xMovie.neuralBin, 2));
        % get the index into the neural data of the start of the window
        startInd = endInd - FR_WINDOW_SIZE;
        flooredStartInd=max([1 startInd]);
        
        %% get the moving averages
        mFilt=rectwin(FR_WINDOW_SIZE);
        movMax=zeros(size(nBin,1),1);
        for nChan=1:size(nBin,1)
            movMax(nChan,1) = max(conv(mFilt, nBin(nChan,:)));
        end
        
        % firing rates just for this window
        nBin2=zeros([size(xMovie.neuralBin,1) FR_WINDOW_SIZE]);
        nBin2(:, (flooredStartInd - startInd + 1) : end)=nBin(:, max(1, startInd) : endInd - 1);
        mAvgs=sum(nBin2,2)./movMax;
        imagesc(nBin2, [0 1]);
        colormap('hot');
        % colormap('gray');

        zeroMarker=vline(FR_WINDOW_SIZE - FR_POSTWINDOW_SIZE, 'r-');
        ylabel('Channel number');
        xlabel('Time (ms)');
        set(zeroMarker, 'linewidth', TIME_MARKER_LINEWIDTH);
        xTicks=[0:25:FR_WINDOW_SIZE]+1;
        % xTicks=[0 25 50 75];
        xLabels=mapc(@(x) num2str((x-(FR_WINDOW_SIZE-FR_POSTWINDOW_SIZE))*50), xTicks);
        set(frAxis, 'xtick', xTicks, 'xticklabel', xLabels);
        
        %% plot population firing rates
        axes(popFrAxis);
        
        %% zero out the non-finite data
        nBin(~isfinite(nBin))=0;
        
        %popFr=sum(xMovie.neuralBin,1);
        popFr=sum(nBin,1);
        %% transform to stretch the range somewhat
        %popFr=sqrt(popFr);
        popFr = log(popFr);
        frMax = max(popFr);
        frMin = min(popFr(isfinite(popFr)));
        popFr(isinf(popFr)) = frMin;
        normPopFr=popFr;
        % normPopFr = popFr ./ frMax;
        
        popFrToPlot = zeros([1 FR_WINDOW_SIZE])+frMin;
        popFrToPlot(1, (flooredStartInd - startInd + 1) : end) = ...
            normPopFr(1, max(1, startInd) : endInd - 1);
        plot(popFrToPlot);
        %set(popFrAxis,'visible', 'off');
        axis('tight');
        set(popFrAxis, 'ylim', [frMin frMax]);
        set(popFrAxis, 'xtick', []);
        
        axes(movAvgAxis);
        imagesc(mAvgs,[0 1]);
        colormap('hot');
        set(movAvgAxis,'visible', 'off');
    end
end

function rect = plotKeyboardTarget(xy,widthHeightXY,dims, offsetxy, xm, ym, dispchar, varargin)
xy2 = keyboardToScreenCoords(xy, dims);
widthHeightXY = keyboardToScreenCoords(widthHeightXY, dims);
widthHeight = widthHeightXY - xy2;
xy3 = xy2- [offsetxy(1); offsetxy(2)];
xstart = xm*xy3(1);
ystart = ym*xy3(2)-widthHeight(2);
xwidth = widthHeight(1);
yheight = widthHeight(2);
if xwidth <=0 || yheight <=0
    keyboard
end
rect=plotRectangle(xstart,ystart,xwidth,yheight);
set(rect,varargin{:});
if ~isempty(dispchar)
    h1=text(xstart+xwidth/2, ystart+yheight/2,dispchar);
    set(h1,'color','k');
end
%'facecolor','g')
%set(rect,'edgecolor','w')
end
