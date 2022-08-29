function stopLocalViz

global localVizVars

try
    pnet(localVizVars.datasock, 'close');
catch
    %meh.
end
try
    pnet(localVizVars.controlsock, 'close');
catch
    %meh.
end
localVizVars.controlsock = [];
localVizVars.datasock = [];
localVizVars.currTask = struct;
localVizVars.background = [];

try
    stop(localVizVars.timerObj);
    localVizVars.isRunning = false;
    set(localVizVars.figNum,'units','pixels');
    localVizVars.lastFigPosition = get(localVizVars.figNum,'position');
    close(localVizVars.figNum);
catch
    errstr = lasterror();
    
    if isfield(localVizVars,'isRunning') && localVizVars.isRunning
        warning('stopLocalViz: problems closing figure / saving info: %s',errstr.message);
    end
end