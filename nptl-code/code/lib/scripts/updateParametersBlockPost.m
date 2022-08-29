function updateParametersBlockPost(systemName,subsystemName, busName, postfix, varargin)%value, dataType)
%% expects arguments in sets of fours:
%%  fieldname, defaultvalue

if length(varargin)==1 && isstruct(varargin{1})
    s = varargin{1};
    f = fields(s);
    
    for nn=1:length(f)
        varargin{nn*2-1} = f{nn};
        varargin{nn*2} = [s.(f{nn})];
    end
end

assert(mod(length(varargin),2)==0,'createTunableParameter: arguments must be groups of 2');

%sys = ['vizTest/taskParameters'];
sys=[systemName '/' subsystemName];
open(systemName);
open_system(sys)
allBlocks = get_param(sys,'Blocks');
hadOutport = false;
%% delete all existing blocks
    %% note - do not delete the outport. that will screw up the block output.
for nn=1:length(allBlocks)
    if strcmp(get_param([sys '/' allBlocks{nn}],'BlockType'),'Outport')
        hadOutport = true;
        outportPorts = get_param([sys '/' allBlocks{nn}],'PortHandles');
    else
        delete_block([sys '/' allBlocks{nn}]);
    end
end
allLines = get_param(sys,'Lines');
for nn=1:length(allLines)
    delete_line(allLines(nn).Handle);
end


startx = 30;
starty = 30;
x=startx;y=starty;w=130;h=30;
offset=60;

evtext = '';
numElements = 0;
for nn =1:2:length(varargin)
    if nn > 1
        evtext = [evtext ','];
    end
    evtext = [evtext '''' varargin{nn} ''',' 'varargin{' num2str(nn+1) '}'];
    pos =[x y x+w y+h];
    add_block('built-in/Constant',[sys '/' varargin{nn}],'Position',pos);
    set_param([sys '/' varargin{nn}],'Value',[varargin{nn} postfix]);
    y = y+offset;
    
    numElements = numElements+1;
    signalNames{numElements} = varargin{nn};

    vclass = class(varargin{nn+1});
    if strcmp(vclass,'logical')
        vclass = 'boolean';
    end    
    assignin('base','tmpvar',varargin{nn+1});
    evalin('base', [varargin{nn} postfix ' = createTunableParameter(tmpvar, ''' ...
        vclass ''');' ]);
end


structVar = eval(['struct(' evtext ')']);
busInfo = createObjectMod(structVar,'','',busName);

pos = [startx+200 starty startx+250 y];
add_block('built-in/BusCreator',[sys '/BusOutput'],'Position',pos);
set_param([sys '/BusOutput'],'Inputs',num2str(numElements))
set_param([sys '/BusOutput'],'BusObject',busName,'UseBusObject','on');

inputSignals = '';
for nn = 1:length(signalNames)
    h = add_line(sys,[signalNames{nn} '/1'],['BusOutput/' num2str(nn)]);
    set_param(h,'Name',signalNames{nn});
    inputSignals =[inputSignals,signalNames{nn},','];
end
inputSignals = inputSignals(1:end-1);
set_param([sys '/BusOutput'],'Inputs',inputSignals);

busCreatorPorts = get_param([sys '/BusOutput'],'PortHandles');

if ~hadOutport
    %% if there was no output port, add one
    pos = [startx+300 mean([starty y]) startx+350 0];
    pos(4) = pos(2)+30;
    add_block('built-in/Outport',[sys '/' busName],'Position',pos);
    outportPorts = get_param([sys '/' busName],'PortHandles');
else
    add_line(sys,busCreatorPorts.Outport,outportPorts.Inport);    
end

save_system(systemName);
close_system(sys)
