function value = binaryFieldDlg(Title, fieldNames, value)
    %%%%%%%%%%%%%%%%%%%%%%%
%%% Create InputFig %%%
%%%%%%%%%%%%%%%%%%%%%%%

%assert(length(fieldNames) == prod(fieldDim), 'Field dimensions / number of fields mismatch!');

FigWidth=400;
FigHeight=400;
FigPos(3:4)=[FigWidth FigHeight];  %#ok
FigColor=get(0,'DefaultUicontrolBackgroundColor');

InputFig=dialog(                     ...
  'Visible'          ,'off'      , ...
  'KeyPressFcn'      ,@doFigureKeyPress, ...
  'Name'             ,Title      , ...
  'Pointer'          ,'arrow'    , ...
  'Units'            ,'pixels'   , ...
  'UserData'         ,'Cancel'   , ...
  'Tag'              ,Title      , ...
  'HandleVisibility' ,'callback' , ...
  'Color'            ,FigColor   , ...
  'NextPlot'         ,'add'      , ...
  'WindowStyle'      ,'modal',     ...
  'Resize'           ,'off' ,      ...
  'Position'         ,FigPos      ...
  );


%%%%%%%%%%%%%%%%%%%%%
%%% Set Positions %%%
%%%%%%%%%%%%%%%%%%%%%
DefOffset    = 5;
DefBtnWidth  = 53;
DefBtnHeight = 23;

TextInfo.Units              = 'pixels'   ;
TextInfo.FontSize           = get(0,'FactoryUicontrolFontSize');
TextInfo.FontWeight         = get(InputFig,'DefaultTextFontWeight');
TextInfo.HorizontalAlignment= 'left'     ;
TextInfo.HandleVisibility   = 'callback' ;

StInfo=TextInfo;
StInfo.Style              = 'text'  ;
StInfo.BackgroundColor    = FigColor;


EdInfo=StInfo;
EdInfo.FontWeight      = get(InputFig,'DefaultUicontrolFontWeight');
EdInfo.Style           = 'edit';
EdInfo.BackgroundColor = 'white';

BtnInfo=StInfo;
BtnInfo.FontWeight          = get(InputFig,'DefaultUicontrolFontWeight');
BtnInfo.Style               = 'pushbutton';
BtnInfo.HorizontalAlignment = 'center';

% Add VerticalAlignment here as it is not applicable to the above.
TextInfo.VerticalAlignment  = 'bottom';
TextInfo.Color              = get(0,'FactoryUicontrolForegroundColor');


% adjust button height and width
btnMargin=1.4;
ExtControl=uicontrol(InputFig   ,BtnInfo     , ...
  'String'   ,xlate('Cancel', '-s')        , ...
  'Visible'  ,'off'         ...
  );

% BtnYOffset  = DefOffset;
BtnExtent = get(ExtControl,'Extent');
BtnWidth  = max(DefBtnWidth,BtnExtent(3)+8);
BtnHeight = max(DefBtnHeight,BtnExtent(4)*btnMargin);
delete(ExtControl);

% Determine # of lines for all Prompts
TableWidth=FigWidth-2*DefOffset;
TableHeight=FigHeight-4*DefOffset-BtnHeight;

FigHeight= 2*DefOffset + BtnHeight+ TableHeight;


tablePosition = [DefOffset BtnHeight+2*DefOffset TableWidth TableHeight];
columnFormat = {'char', 'logical'};
data = [fieldNames', num2cell(value)'];
columnEditable = [false true];
TableHandle = uitable(InputFig, 'ColumnFormat', columnFormat, 'ColumnEditable', columnEditable, 'Data', data, 'columnName', [], 'rowName', [], 'Position', tablePosition);


VectorEntryHandle=uicontrol(InputFig     ,              ...
  BtnInfo      , ...
  'Position'   ,[ FigWidth-4*BtnWidth-3*DefOffset DefOffset 2*BtnWidth BtnHeight ] , ...
  'KeyPressFcn',@doVectorEntry , ...
  'String'     ,'Vector Entry'        , ...
  'Callback'   ,@doVectorEntry , ...
  'Tag'        ,'VectorEntry'        , ...
  'UserData'   ,TableHandle      ...
  );

ListEntryHandle=uicontrol(InputFig     ,              ...
  BtnInfo      , ...
  'Position'   ,[ FigWidth-6*BtnWidth-4*DefOffset DefOffset 2*BtnWidth BtnHeight ] , ...
  'KeyPressFcn',@doListEntry , ...
  'String'     ,'List Entry'        , ...
  'Callback'   ,@doListEntry , ...
  'Tag'        ,'ListEntry'        , ...
  'UserData'   ,TableHandle      ...
  );


OKHandle=uicontrol(InputFig     ,              ...
  BtnInfo      , ...
  'Position'   ,[ FigWidth-2*BtnWidth-2*DefOffset DefOffset BtnWidth BtnHeight ] , ...
  'KeyPressFcn',@doControlKeyPress , ...
  'String'     ,'OK'        , ...
  'Callback'   ,@doCallback , ...
  'Tag'        ,'OK'        , ...
  'UserData'   ,'OK'          ...
  );



CancelHandle=uicontrol(InputFig     ,              ...
  BtnInfo      , ...
  'Position'   ,[ FigWidth-BtnWidth-DefOffset DefOffset BtnWidth BtnHeight ]           , ...
  'KeyPressFcn',@doControlKeyPress            , ...
  'String'     ,xlate('Cancel', '-s')    , ...
  'Callback'   ,@doCallback , ...
  'Tag'        ,'Cancel'    , ...
  'UserData'   ,'Cancel'      ...
  ); %#ok

handles = guihandles(InputFig);
handles.MinFigWidth = FigWidth;
handles.FigHeight   = FigHeight;
handles.TextMargin  = 2*DefOffset;
guidata(InputFig,handles);


% make sure we are on screen
movegui(InputFig)


if ishghandle(InputFig)
  % Go into uiwait if the figure handle is still valid.
  % This is mostly the case during regular use.
  uiwait(InputFig);
end

% Check handle validity again since we may be out of uiwait because the
% figure was deleted.
if ishghandle(InputFig)
  value=value;
  if strcmp(get(InputFig,'UserData'),'OK'),
    data = get(TableHandle,'Data');
    value = cell2mat(data(:, 2));
  end
  delete(InputFig);
else
  value = value;
end

function doFigureKeyPress(obj, evd) %#ok
switch(evd.Key)
  case {'return','space'}
    set(gcbf,'UserData','OK');
    uiresume(gcbf);
  case {'escape'}
    delete(gcbf);
end

function doControlKeyPress(obj, evd) %#ok
switch(evd.Key)
  case {'return'}
    if ~strcmp(get(obj,'UserData'),'Cancel')
      set(gcbf,'UserData','OK');
      uiresume(gcbf);
    else
      delete(gcbf)
    end
  case 'escape'
    delete(gcbf)
end

function doCallback(obj, evd) %#ok
if ~strcmp(get(obj,'UserData'),'Cancel')
  set(gcbf,'UserData','OK');
  uiresume(gcbf);
else
  delete(gcbf)
end

function doVectorEntry(obj, evd)
tableHandle = get(obj, 'UserData');
data = get(tableHandle, 'Data');
value = cell2mat(data(:, 2))';
textValue = mat2str(double(value));

answer = inputdlg('Manually Enter Vector', 'Vector', 1, {textValue}, 'on');

try
    newValue = eval(answer{1});
catch err
    newValue = value;
end

if(all(size(newValue)==size(value)))
    data(:,2) = num2cell(logical(newValue'));
    set(tableHandle, 'Data', data);
end


function doListEntry(obj, evd)
tableHandle = get(obj, 'UserData');
data = get(tableHandle, 'Data');
value = cell2mat(data(:, 2))';
textValue = mat2str(find(value));

answer = inputdlg('Manually Enter Vector', 'Vector', 1, {textValue}, 'on');

try
    list = eval(strcat('[', answer{1}, ']'));
    if(max(list) <= length(value) && min(list) > 0)
        newValue = false(size(value));
        newValue(list) = true;
    else
        newValue = value;
    end
catch err
    newValue = value;
end

if(all(size(newValue)==size(value)))
    data(:,2) = num2cell(logical(newValue'));
    set(tableHandle, 'Data', data);
end
