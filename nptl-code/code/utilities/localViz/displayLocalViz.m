function lvv = displayLocalViz(lvv, data)
%% lvv - local viz vars

persistent persistents;
if isempty(persistents)
    persistents.keyboards=allKeyboards();
end

wtot = 1920;
htot = 1080;
keyColor=[0.6 0.6 0.6];
overColor=[0 0.75 0];
cuedColor=[0 0.5 0];

mp = [wtot/2;htot/2];

lvv.scale = 1;

lvv.scaledw=wtot/lvv.scale;
lvv.scaledh=htot/lvv.scale;
lvv.scaledmp = mp./lvv.scale;

taskname = lvv.taskName;

%% make the background if it's empty
if isempty(lvv.background) || checkRelevantVars()
    %disp('displayLocalViz(): making a new background');
    storeRelevantVars()
    lvv.background = makeBackground();
end

sfigure(lvv.figNum);

%ymean=mean(get(localVizVars.axHandle,'ylim'));
%xmean=mean(get(localVizVars.axHandle,'xlim'));

%% handle task exists
if isfield(lvv,'state')
switch taskname
    case 'cursor'
        if data.state == uint16(CursorStates.STATE_END)
            lvv.state = lvv.const.end_state;
        end
    case 'fitts'
        if data.state == uint16(FittsStates.STATE_END)
            lvv.state = lvv.const.end_state;
        end
    case 'keyboard'
        if data.state == uint16(KeyboardStates.STATE_END)
            lvv.state = lvv.const.end_state;
        end
end
end


%% display the task time or clock time on the screen
ctime = [];
if isfield(data,'totalTaskTime'), ctime = data.totalTaskTime;
elseif isfield(data,'clock'), ctime = data.clock;
end

switch taskname
    case {'cursor', 'fitts'}
        textpos = [-920 -500];
    case 'keyboard'
        textpos = [10 40];
end

if ~isempty(ctime)
    str = sprintf('%2.1f s',(double(ctime)/1000));
    if ~isfield(lvv.currTask,'timeTextHandle')
        % disp time text for the first time if necessary
        
        lvv.currTask.timeTextHandle = ...
            text(textpos(1),textpos(2),str);
        set(lvv.currTask.timeTextHandle ,'color','w');
    else
        % update the time text
        set(lvv.currTask.timeTextHandle,'string',str);
    end
end

switch taskname
    case 'cursor'
        %% update the current target position
        pos1=lvv.currTask.targetOffset(1)+data.currentTarget(1)/lvv.scale;
        pos2=lvv.currTask.targetOffset(2)-data.currentTarget(2)/lvv.scale;
        cpos = get(lvv.currTask.targetHandle,'position');
        cpos(1:2) = [pos1 pos2];
        set(lvv.currTask.targetHandle,'position',cpos);

    case 'fitts'
        pos1=double(data.currentTarget(1))/lvv.scale - double(data.currentTargetDiameter)/2/lvv.scale;
        pos2=-double(data.currentTarget(2))/lvv.scale - double(data.currentTargetDiameter)/2/lvv.scale;
        cpos = get(lvv.currTask.targetHandle,'position');
        cpos(1:2) = [pos1 pos2];
        cpos(3:4) = data.currentTargetDiameter/lvv.scale;
        set(lvv.currTask.targetHandle,'position',cpos);
    case 'keyboard'
        %% update the displayed text
        if intersect(lvv.currTask.keyboard,[2 20 30])
            tl = numel(find(data.textSequence));
            if tl
                str=char(data.textSequence(1:tl));
                if ~isfield(lvv.currTask,'textHandle')
                    lvv.currTask.textHandle = ...
                        text(10,1000,str);
                    set(lvv.currTask.textHandle ,'color','w');
                else
                    set(lvv.currTask.textHandle,'string',str);
                end
            end
        end
        
        
        %% update the cued target position
        if isfield(lvv.currTask,'keyHandles') && ~isempty(lvv.currTask.keyHandles)
            set(lvv.currTask.keyHandles,'facecolor',keyColor);
            if data.cuedTarget
                set(lvv.currTask.keyHandles(data.cuedTarget),'facecolor',cuedColor);
            end
            if data.overTarget
                set(lvv.currTask.keyHandles(data.overTarget),'facecolor',overColor);
            end
        end
end

%% update the cursor position
pos1=lvv.currTask.cursorOffset(1)+data.cursorPosition(1,1)/lvv.scale;
pos2=lvv.currTask.offsetxy(2) + lvv.currTask.cursorOffset(2)+...
    lvv.currTask.ym*data.cursorPosition(2,1)/lvv.scale;
cpos = get(lvv.currTask.cursorHandle,'position');
cpos(1:2) = [pos1 pos2];

set(lvv.currTask.cursorHandle,'position',cpos);


    function storeRelevantVars()
        lvv.currTask = struct;
        switch taskname
            case 'cursor'
                lvv.currTask.cursorDiameter = data.cursorDiameter;
                lvv.currTask.targetDiameter = data.targetDiameter;
                lvv.currTask.numTargets = data.numTargets;
                lvv.currTask.targetInds = data.targetInds;
            case {'keyboard','CLKINSIM'}
                lvv.currTask.cursorDiameter = data.cursorDiameter;
                lvv.currTask.keyboard = data.keyboard;
                lvv.currTask.numKeys = data.numKeys;
                lvv.currTask.keyboardDims = data.keyboardDims;
            case 'fitts'
                lvv.currTask.cursorDiameter = data.cursorDiameter;
        end
    end
    function doReset = checkRelevantVars()
        doReset = 0;
        % reasons to re-make background
        switch taskname
            case 'cursor'
                if lvv.currTask.cursorDiameter ~= data.cursorDiameter, doReset = 1; end
                if lvv.currTask.targetDiameter ~= data.targetDiameter, doReset = 1; end
                if lvv.currTask.numTargets ~= data.numTargets, doReset = 1; end
                if any(lvv.currTask.targetInds(:) ~= data.targetInds(:)), doReset = 1; end
            case {'keyboard','CLKINSIM'}
                if lvv.currTask.cursorDiameter ~= data.cursorDiameter, doReset = 1; end
                if lvv.currTask.keyboard ~= data.keyboard, doReset = 1; end
                if lvv.currTask.numKeys ~= data.numKeys, doReset = 1; end
                if lvv.currTask.keyboardDims(:) ~= data.keyboardDims(:), doReset = 1; end
            case 'fitts'
                if lvv.currTask.cursorDiameter ~= data.cursorDiameter, doReset=1; end
        end
    end

    function im = makeBackground()
        %% make a blank screen
        sfigure(lvv.figNum);
        clf(lvv.figNum);
        set(lvv.figNum,'units','pixels');
        if isfield(lvv,'lastFigPosition') && ~isempty(lvv.lastFigPosition)
            set(lvv.figNum, 'position', lvv.lastFigPosition);
        end
        
        switch taskname
            case 'cursor'
                lvv.currTask.ym = -1; %ymultiplier
                lvv.currTask.offsetxy=[0 0];
                %% background for cursor
                h=rectangle('position',[-lvv.scaledw/2 -lvv.scaledh/2 lvv.scaledw lvv.scaledh]);
                lvv.axHandle = gca;
                set(h,'facecolor','k');
                axis('equal')
                cleanAxis(lvv.axHandle);
                
                % make all the targets
                for nt = 1:data.numTargets
                    tpos = data.targetInds(:,nt) / lvv.scale;
                    r = data.targetDiameter/2/lvv.scale;
                    sfigure(lvv.figNum);
                    h=plotCircle(tpos(1),tpos(2),r);
                    set(h,'facecolor',zeros(1,3)+0.5)
                end
                % always a central target
                tpos = [0;0];
                r = data.targetDiameter/2/lvv.scale;
                sfigure(lvv.figNum);
                h=plotCircle(tpos(1),tpos(2),r);
                set(h,'facecolor',zeros(1,3)+0.5)
                
                % current target
                h=plotCircle(data.currentTarget(1)/lvv.scale,...
                    data.currentTarget(2)/lvv.scale,data.targetDiameter/2/lvv.scale);
                set(h,'facecolor','g');
                lvv.currTask.targetHandle = h;
                p = get(lvv.currTask.targetHandle,'position');
                lvv.currTask.targetOffset = p(1:2);
                
            case 'fitts'
                lvv.currTask.ym = -1; %ymultiplier
                lvv.currTask.offsetxy=[0 0];
                %% background for cursor
                h=rectangle('position',[-lvv.scaledw/2 -lvv.scaledh/2 lvv.scaledw lvv.scaledh]);
                lvv.axHandle = gca;
                set(h,'facecolor','k');
                axis('equal')
                cleanAxis(lvv.axHandle);

                % always a central target
                tpos = [0;0];
                r = data.currentTargetDiameter/2/lvv.scale;
                sfigure(lvv.figNum);
                h=plotCircle(tpos(1),tpos(2),r);
                set(h,'facecolor',zeros(1,3)+0.5)
                
                % current target
                h=plotCircle(data.currentTarget(1)/lvv.scale,...
                    data.currentTarget(2)/lvv.scale,data.currentTargetDiameter/2/lvv.scale);
                set(h,'facecolor','g');
                lvv.currTask.targetHandle = h;
                p = get(lvv.currTask.targetHandle,'position');
                lvv.currTask.targetOffset = p(1:2);

                
            case {'keyboard','CLKINSIM'}
                lvv.currTask.offsetxy = [0 1080];%-[960 540];
                lvv.currTask.ym = -1; %ymultiplier
                
                %% background for keyboard
                h=rectangle('position',[0 0 lvv.scaledw lvv.scaledh]);
                lvv.axHandle = gca;
                set(h,'facecolor','k');
                axis('equal')
                cleanAxis(lvv.axHandle);
                
                if intersect(lvv.currTask.keyboard,[2 3 20 30])
                    q=persistents.keyboards(lvv.currTask.keyboard);
                    dims = lvv.currTask.keyboardDims;
                    for nn = 1:lvv.currTask.numKeys
                        xy = [q.keys(nn).x; q.keys(nn).y];
                        widthHeightXY = [q.keys(nn).width; q.keys(nn).height] + xy;
                        
                        dchar = '';
                        if intersect(lvv.currTask.keyboard,[2 20 30])
                            dchar = char(q.keys(nn).text);
                        end
                        
                        rect=plotKeyboardTarget(xy,widthHeightXY,dims,lvv.currTask.offsetxy,...
                            1,lvv.currTask.ym, dchar,...
                            'edgecolor','k','facecolor',keyColor);
                        lvv.currTask.keyHandles(nn) = rect;
                    end
                end
        end

        % cursor
        pin(1) = lvv.currTask.offsetxy(1) + data.cursorPosition(1,1)/lvv.scale;
        pin(2) = lvv.currTask.offsetxy(2) + lvv.currTask.ym*data.cursorPosition(2,1)/lvv.scale;
        h=plotCircle(data.cursorPosition(1,1)/lvv.scale,...
            data.cursorPosition(2,1)/lvv.scale,...
            data.cursorDiameter/2/lvv.scale);
        set(h,'facecolor','w');
        lvv.currTask.cursorHandle = h;
        p = get(lvv.currTask.cursorHandle,'position');
        lvv.currTask.cursorOffset = p(1:2)-pin;
        
        %% make the actual pixels on screen match w
        %set(lvv.axHandle,'units','normalized');
        %axdims = get(lvv.axHandle,'position');
        %set(lvv.figNum,'units','pixels');
        %figdims = get(lvv.figNum, 'position');
        %newfigw = w/axdims(3);
        %newfigh = h/axdims(4);
        %figdims(3:4) = [newfigw newfigh];
        
        set(lvv.figNum,'units','pixels');
        %set(lvv.figNum,'position',figdims);
        set(lvv.axHandle,'units','pixels');
        sfigure(lvv.figNum);
        lvv.axisPosition = get(lvv.axHandle,'position');
        lvv.figPosition = get(lvv.figNum,'position');
        % %% store the generated background        
        %im = frame2im(getframe(lvv.figNum,lvv.axisPosition));
        
        
        im = 1;
    end

    function cleanAxis(ah)
        set(ah,'visible','off')
        set(ah,'xtick',[],'ytick',[],'box','off');
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
end