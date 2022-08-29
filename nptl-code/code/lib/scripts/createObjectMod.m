function varargout = createObjectMod(varargin) 
%% this is a minor modification of the matlab function Simulink.Bus.CreateObject
%% just allows buses created from struct vars to have their names specified


% createObject creates bus objects for the specified blocks or 
%    structure variable
% 
% Simulink.Bus.createObject(model, blks, fileName, format) creates bus objects
% in the MATLAB workspace for the specified blocks and optionally saves 
% the bus objects in the specified file.
%   
% Simulink.Bus.createObject(structVar, fileName, format) creates bus objects
% in the MATLAB workspace from the numeric MATLAB structure and optionally saves 
% the bus objects in the specified file.
%
%  Inputs Arguments
%    model:    Name or handle of model
%    blks:     List of subsystem-level Inport blocks, root-level or 
%              subsystem-level Outport blocks or Bus Creator blocks 
%              in the specified model. If only one block needs to
%              be specified, this argument can be the full pathname 
%              of the block. Otherwise, this argument can be either
%              a cell array containing block pathnames or a vector of 
%              block handles. 
%          
%   structVar: Numeric structure variable.
%
%    fileName: Name of a file to store the bus objects (optional)
%    format:   Can be 'cell' or 'object' or can be omitted in which
%              case 'cell' is the default. Use cell format to save the 
%              objects in a compact form.
%
%  Output Arguments 
%    busInfo:  A structure array containing bus information for the 
%              specified blocks. Each element of the structure array
%              corresponds to one of the specified blocks and contains
%              the following fields:
%                block:   Handle of the block 
%                busName: Name of the bus object associated with the block
%
%   See also Simulink.Bus.save and Simulink.Bus.cellToObject

%
%   Copyright 1994-2012 The MathWorks, Inc.


  if nargin < 1  
      DAStudio.error('Simulink:tools:slbusInvalidNumInputs');
  end
 
  structMode =  isstruct(varargin{1});
  
  if structMode
      % % This function expects 1 to 3 inputs in struct mode
      %% now 1 to 4 inputs
      isOk = (nargin >= 1 && nargin <= 4);
      if ~isOk
          DAStudio.error('Simulink:tools:slbusInvalidNumInputs');
      end
     
      sp      = varargin{1};
      
      if nargin < 4
          busName = '';
      else
          busName = varargin{4};
      end
      
      % Set the default value for fileName
      if nargin < 2
          fileName = '';
      else
          fileName = varargin{2};  
      end
  
      % Set the default value for format
      if  nargin < 3
          format = 'cell';
      else
          format = varargin{3};  
      end

      busInfo = createObjectFromVarStruct(sp, busName, fileName, format);
      if nargout > 0
          varargout{1} = busInfo;
      end
      return;
  end
    
 
  % This function expects 2 to 4 inputs
  isOk = (nargin >= 2 && nargin <= 4);
  if ~isOk
      DAStudio.error('Simulink:tools:slbusInvalidNumInputs');
  end

  model = varargin{1};
  blks  = varargin{2};
  
  % Set the default value for fileName
  if nargin < 3
    fileName = '';
  else
    fileName = varargin{3};  
  end
  
  % Set the default value for format
  if  nargin < 4
    format = 'cell';
  else
    format = varargin{4};  
  end

  busInfo = createObjectFromBlks(model, blks, fileName, format);
  if nargout > 0
      varargout{1} = busInfo;
  end
  return;
end

% =========== createObjectFromBlks ======================================
%
function busInfo = createObjectFromBlks(model, blks, fileName, format)
  if ~ischar(model),
    % must be a handle to an open model
    if ~ishandle(model),
        DAStudio.error('Simulink:tools:slbusCreateObjectInvalidModelName');
    end
    model = get_param(model,'Name');
  else
    % load the model
    load_system(model);
  end

  simStatus = get_param(model,'SimulationStatus');
  if ~strcmpi(simStatus, 'stopped')
      DAStudio.error('Simulink:tools:slbusCreateObjectBadSimulationStatus', model, simStatus);
  end
  
  mdlIsCompiled = false;
  try
    % Step 1: get compile bus structure. 
    % The model will remain in the compiled phase.
    busInfo = sl('slbus_get_struct', model, blks, false);
    mdlIsCompiled = true;

    % Get initial list of bus creators with inferred bus objects via bus object
    % back propagation from blocks with specified bus objects.
    % Note: sl(slbus_gen_object) give precedence to bus object specified
    % on the Bus Creator blocks. We may need to report a warning
    % for this case in future.
    bclist = get_param(model, 'BackPropagatedBusObjects');
     
    % Step 2: generate bus object. Set all bus object sample times to -1
    [busInfo, bclist] = sl('slbus_gen_object', busInfo, false, bclist); %#ok
    cmd = [model,'([],[],[],''term'')'];
    evalc(cmd);
    mdlIsCompiled = false;
    
    % Remove the busObject and bus fields.
    busInfo = rmfield(busInfo, {'busObject', 'bus'});
    
    % Step 3: save bus objects in cell or object format
    if ~isempty(fileName)
        busNames = {};
        % Created bus names corresponding to the specified blocks
        % Also save related buses (buses defined by elements)
        for idx = 1:length(busInfo)
            busNames = get_dependent_bus_names(busInfo(idx).busName, busNames);
        end      
        busNames = unique(busNames);
        Simulink.Bus.save(fileName, format, busNames);
    end
    
  catch me
    if mdlIsCompiled
      cmd = [model,'([],[],[],''term'')'];
      evalc(cmd);
    end
    rethrow(me);
  end
end  
%endfunction

% Recurse to get all related bus object names from base workspace
function busNames = get_dependent_bus_names(name, busNames) 
  if ~isempty(name) && isempty(strmatch(name, busNames, 'exact')) && ...
        isvarname(name) && ...
        loc_evalinContext(['exist(''', name, ''', ''var'') && isa(', ...
        name, ',''Simulink.Bus'')'])
    
    busNames{end+1} = name;
    bus = loc_evalinContext(name);
    for idx = 1: length(bus.Elements)
        busNames = get_dependent_bus_names(bus.Elements(idx).DataType, ...
            busNames);
    end
  end
end

% ====  createObjectFromVarStruct =========================================
%
function busInfo = createObjectFromVarStruct(sp, name, fileName, format)
  busInfo = [];
  name = createBus(sp, '',  name, 0);
  if isempty(name) 
    return;
  end

  busInfo.block = [];
  busInfo.busName = name;
   
  if ~isempty(fileName)
        busNames = {};
        % Created bus names corresponding to the specified blocks
        % Also save related buses (buses defined by elements)
        busNames = get_dependent_bus_names(name, busNames);
        busNames = unique(busNames);
        Simulink.Bus.save(fileName, format, busNames);
  end
end


% Generate valid bus name
% name - is proposed name (could be empty)
function [busName, idx] = generateBusName(name, idx)
  prefix='slBus';
  busName = name;
   
  if ~isvarname(name)
      error([name ' is not a valid bus/variable name']);
  end
  
  needNewName = loc_evalinContext(['exist(''',name,''')']);
  if needNewName
      disp(['Warning: clearing previous bus/variable ' name]);
      evalin('base',['clear ' name ';'])
      %loc_evalinContext(['clear ' name]);
  end
%     needNewName = loc_evalinContext(['exist(''',name,''')']);
%     postfix = ['_' name];
%   else
%     needNewName = true;
%     postfix = '';
%   end
% 
%   while  needNewName
%     idx = idx + 1;
%     busName = [prefix num2str(idx) postfix];
%     
%     needNewName = loc_evalinContext(['exist(''',busName,''')']);
%   end
  
end

% Create Bus object (recursive calls)
function [busName, idx]= createBus(sp, path, name, idx)
  busName=[];
  if ~isstruct(sp)
      return;
  end
  
  if ~isempty(path)
      path = [path, '.'];
  end
  
  busObj=Simulink.Bus;
  nodeNames = fieldnames(sp);
  for n=1:size(nodeNames,1)
    node = sp.(nodeNames{n});
    if isstruct(node)
        % Generate sub-bus
        subBusName = nodeNames{n};
        if numel(node) > 1
            checkSubStructuresForConsistency([path, nodeNames{n}], node);
        end
        [subBusName, idx] = createBus(node, [path, nodeNames{n}], subBusName, idx); 
        el=Simulink.BusElement;
        el.Name =nodeNames{n};
        el.DataType =subBusName;
        % [1x1x1] => 1 (retain default dims for bus element)
        if isequal(numel(node), 1)
            el.Dimensions = 1;
        else
            el.Dimensions = size(node);
        end
        busObj.Elements(end+1)=el;
    elseif isnumeric(node) || islogical(node)
        el=Simulink.BusElement;
        el.Name =nodeNames{n};
        try
            [el.DataType, el.Dimensions, el.Complexity]=getValueAttr(node);
        catch me
            DAStudio.error('Simulink:tools:slbusCreateObjectGeneric', ...
                [path, nodeNames{n}], me.message);
        end
        busObj.Elements(end+1)=el;
    else
       DAStudio.error('Simulink:tools:slbusCreateObjectNonNumericStructField', ...
                       [path, nodeNames{n}]);
   end       
  end

  [busName, idx] = generateBusName(name, idx);
  loc_assigninContext(busName, busObj);
end

% Check substructures of an array for consistency
function checkSubStructuresForConsistency(path, node)
    assert(isstruct(node) && numel(node) > 1);    
    for idx = 1:numel(node)-1
        path1 = [path '(' num2str(idx) ')'];
        path2 = [path '(' num2str(idx+1) ')'];
        compareStructsForSimilarity(path1, path2, node(idx), node(idx+1));
    end
end

% Check two structures for compatibility
function compareStructsForSimilarity(path1, path2, s1, s2)
    
    if ~isequal(fieldnames(s1),fieldnames(s2))
        DAStudio.error('Simulink:tools:slbusCreateObjectOrderMismatch', ...
            path1, path2);
    end
    
    fnames = fieldnames(s1);
    for idx = 1:numel(fnames)
        s1field = s1.(fnames{idx});
        s2field = s2.(fnames{idx});
        
        pathloop1 = [path1 '.' fnames{idx}];
        pathloop2 = [path2 '.' fnames{idx}];
        if (isstruct(s1field) && ~isstruct(s2field))
            DAStudio.error('Simulink:tools:slbusCreateObjectStructNonStructMismatch', ...
                pathloop1, pathloop2);
        end
        
        if (isstruct(s2field) && ~isstruct(s1field))
            DAStudio.error('Simulink:tools:slbusCreateObjectStructNonStructMismatch', ...
                pathloop2, pathloop1);
        end            
        
        if ~isequal(size(s1field), size(s2field))
            DAStudio.error('Simulink:tools:slbusCreateObjectDimsMismatch', ...
                pathloop1, pathloop2);
        end
        
        if isstruct(s1field)
            appendIndex = (numel(s1field) > 1);
            p1 = pathloop1;
            p2 = pathloop2;
            for jdx = 1:numel(s1field)
                if appendIndex
                    p1 = [pathloop1 '(' num2str(jdx) ')'];
                    p2 = [pathloop2 '(' num2str(jdx) ')'];
                end
                compareStructsForSimilarity(p1, p2, s1field(jdx), s2field(jdx));
            end
        else
            if ~isequal(class(s1field), class(s2field))
                DAStudio.error('Simulink:tools:slbusCreateObjectDataTypeMismatch', ...
                    pathloop1, pathloop2);
            end
            
            if ~isequal(isreal(s1field), isreal(s2field))
                DAStudio.error('Simulink:tools:slbusCreateObjectComplexityMismatch', ...
                    pathloop1, pathloop2);
            end
            
        end
        
    end
    
end

% Get DataType, Dims and Complexity 
function [dt, dims, compl] = getValueAttr(val)
  p=Simulink.Parameter;
  p.Value=val;
  dt=p.DataType;
  if isequal(dt, 'auto')
      dt='double';
  end
  dims=p.Dimensions;
  compl=p.Complexity;
end

%endfunction

% This function is intended to evaluate the given expression in the
% workspace we are currently executing in, but for now it just
% evaluates in the base workspace
function outputValue = loc_evalinContext(expr)
    outputValue = evalin('base',expr);
end

% This function is intended to assign to the given variable in the
% workspace we are currently executing in, but for now it just
% assigns in the base workspace
function loc_assigninContext(varName, varValue)
    assignin('base',varName,varValue);
end