function selected = showBlocksDialog(options)

options.foo = false;
options = setDefault(options,'waitForDialog',true,true);

fields = {'block', 'task', 'parameterScript', 'startTime', 'biasEstimate', 'runTime', 'cont. filt', 'disc. filt'};
selected = [];

if ~isfield(options, 'log')
    options.log =loadRuntimeLog();
end
l = options.log;

if ~isfield(l, 'blocks')
    warning('showAllBlocks: no blocks in log...');
    return
else
    if length(l.blocks) > 10
        l.blocks(1:end-10) = [];
    end
end

dat = {};

idat = 0;
for nb = 1:numel(l.blocks)
    if ~isempty(l.blocks(nb).blockNum)
        idat = idat+1;
        dat{idat,1} = sprintf('%03i',l.blocks(nb).blockNum);
        for nf = 2:numel(fields)
            switch fields{nf}
                case 'startTime'
                    txt = datestr(l.blocks(nb).systemStartTime, 'HH:MM');
                case 'runTime'
                    txt = sprintf('%.2f min', l.blocks(nb).runtimeMS / 1000 / 60);
                case 'cont. filt'
                    txt = l.blocks(nb).filter;                    
                case 'disc. filt'
                    txt = l.blocks(nb).discreteFilter;
                case 'block'
                    txt = l.blocks(nb).blockNum;
                case 'task'
                    txt = l.blocks(nb).taskName;
                case 'biasEstimate'
                    txt = '';
                    % smart display of biases. Only shows dimensions that
                    % have a bias.
                    myBiases = l.blocks(nb).biasEstimate; 
                  
                    if any( myBiases )
                        hasBiases = find( myBiases );
                        for iD = 1 : numel( hasBiases )
                            switch  hasBiases(iD)
                                case 2
                                    dimStr = 'X';
                                case 4
                                    dimStr = 'Y';
                                case 6
                                    dimStr = 'Z';
                                case 8
                                    dimStr = 'R1';                                
                                otherwise
                                    dimStr = '?';
                            end
                                    
                            txt = [txt sprintf('%s=%.2g, ', dimStr, myBiases(hasBiases(iD)) )];
                        end
                    else
                        txt = '0';
                    end
%                     if ~isempty(l.blocks(nb).biasEstimate)
%                         txt = sprintf('X: %2.2g, Y:%2.2g', l.blocks(nb).biasEstimate(1), l.blocks(nb).biasEstimate(2));
%                     end
                otherwise
                    txt = l.blocks(nb).(fields{nf});
            end
            dat{idat,nf} = txt;
        end
    end
end
f = figure();
set(f,'position',[100 100 800 500]);
p = get(f,'position') .* [1 1 0.9 0.8];
p(1:2) = [20 60];
t = uitable(f,'Data',dat,'ColumnName',fields, 'Position',p ,'RowName',[]);
set(t,'CellSelectionCallback',@cscallback);
c1 = uicontrol(f,'Style','pushButton','Position',[600 20 75 20],'String','OK');
c2 = uicontrol(f,'Style','pushButton','Position',[680 20 75 20],'String','Cancel');
set(c1,'Callback',@okcallback);
set(c2,'Callback',@cancelcallback);

if isfield(options,'title')
    set(f,'name',options.title)
end

if options.waitForDialog
    uiwait(f);
end

%% event handlers

%% cell selection
function cscallback(src, event)
    selectedRow = event.Indices(1);
    set(src,'UserData',str2double(dat{selectedRow,1}));
end

%% OK selection
function okcallback(src, event)
    selected = get(t,'UserData');
    close(f);
end

%% cancel selection
function cancelcallback(src, event)
    set(t,'UserData',[]);
    close(f);
end
end