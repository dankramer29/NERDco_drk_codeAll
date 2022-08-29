function structVar = createTunableStructurePost(systemName,subsystemName, busName, postfix, varargin)%value, dataType)
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


evtext = '';
numElements = 0;
for nn =1:2:length(varargin)
    if nn > 1
        evtext = [evtext ','];
    end
    evtext = [evtext '''' varargin{nn} ''',' 'varargin{' num2str(nn+1) '}'];
    
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

