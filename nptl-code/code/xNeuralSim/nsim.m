function varargout = nsim(varargin)
% nsim MATLAB code for nsim.fig
%      nsim, by itself, creates a new nsim or raises the existing
%      singleton*.
%
%      H = nsim returns the handle to a new nsim or the handle to
%      the existing singleton*.
%
%      nsim('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in nsim.M with the given input arguments.
%
%      nsim('Property','Value',...) creates a new nsim or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before nsim_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to nsim_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help nsim

% Last Modified by GUIDE v2.5 11-Jul-2011 18:21:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @nsim_OpeningFcn, ...
    'gui_OutputFcn',  @nsim_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before nsim is made visible.
function nsim_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nsim (see VARARGIN)

% Choose default command line output for nsim
handles.stop=0;
handles.c=0;
handles.output = 0;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes nsim wait for user response (see UIRESUME)
% uiwait(handles.gui1);


% --- Outputs from this function are returned to the command line.
function varargout = nsim_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in playbutton.
function playbutton_Callback(hObject, eventdata, handles)
% hObject    handle to playbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.playbutton,'Value')==1
    set(handles.liveoutput,'String', ' ');
    mE=ones([96 150 10]); % Depends on variables yet unintroduced. Fix.
    mE(:,:,2)=0;
    mE(1,1,3)=1;
    set(handles.gui1,'UserData',mE);
    runSim(handles)
end
%guidata(hObject, handles);


% --- Executes on selection change in choosemap.
function choosemap_Callback(hObject, eventdata, handles)
% hObject    handle to choosemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns choosemap contents as cell array
%        contents{get(hObject,'Value')} returns selected item from choosemap


% --- Executes during object creation, after setting all properties.
function choosemap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to choosemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function NoiseSlider_Callback(hObject, eventdata, handles)
% hObject    handle to NoiseSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function NoiseSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NoiseSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function chooseview_Callback(hObject, eventdata, handles)
% hObject    handle to chooseview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of chooseview as text
%        str2double(get(hObject,'String')) returns contents of chooseview as a double


% --- Executes during object creation, after setting all properties.
function chooseview_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chooseview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on playbutton and none of its controls.
function playbutton_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to playbutton (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmpi(eventdata.Key,'escape')
    
end
guidata(hObject, handles);


% --- Executes on slider movement.
function BetaSlider_Callback(hObject, eventdata, handles)
% hObject    handle to BetaSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function BetaSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BetaSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in plotcheck.
function plotcheck_Callback(hObject, eventdata, handles)
% hObject    handle to plotcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plotcheck



function target_vectors_Callback(hObject, eventdata, handles)
% hObject    handle to target_vectors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of target_vectors as text
%        str2double(get(hObject,'String')) returns contents of target_vectors as a double


% --- Executes during object creation, after setting all properties.
function target_vectors_CreateFcn(hObject, eventdata, handles)
% hObject    handle to target_vectors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function confound_mode_Callback(hObject, eventdata, handles)
% hObject    handle to confound_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of confound_mode as text
%        str2double(get(hObject,'String')) returns contents of confound_mode as a double


% --- Executes during object creation, after setting all properties.
function confound_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to confound_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function confound_params_Callback(hObject, eventdata, handles)
% hObject    handle to confound_params (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of confound_params as text
%        str2double(get(hObject,'String')) returns contents of confound_params as a double


% --- Executes during object creation, after setting all properties.
function confound_params_CreateFcn(hObject, eventdata, handles)
% hObject    handle to confound_params (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in confound_button.
function confound_button_Callback(hObject, eventdata, handles)
% hObject    handle to confound_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of confound_button



% --- Executes on key press with focus on confound_mode and none of its controls.
function confound_mode_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to confound_mode (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
%disp(eventdata.Key)



function liveinput_Callback(hObject, eventdata, handles)
% hObject    handle to liveinput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of liveinput as text
%        str2double(get(hObject,'String')) returns contents of liveinput as a double
% --- Executes during object creation, after setting all properties.
try
    if get(handles.playbutton,'Value')==1
        query=get(hObject,'String');
        x=regexpi(query,' ','split');
        mode=x{1};
        if (length(x)>=2 );
            chans=x{2};
            txChannels=str2num(chans);
            if txChannels(end)>96 || txChannels (1)<0;
                output='Channel does not exist';
                error;
            end
        else
            txChannels=[1:1:96]; % This number should generalize.
            chans='1:96';
        end
        
        if (length(x)>=3 );
            params=x{3};
            px=str2num(params);
        end
        mEdit=get(handles.gui1,'UserData');
        if strcmpi(mode,'kill')
            mEdit(txChannels,:,1)=0;
            output=['Killed channel(s) ' chans '.'];
        elseif strcmpi(mode,'restore')
            mEdit(txChannels,:,1)=1;
            mEdit(txChannels,:,2)=0;
            mEdit(txChannels,:,4)=1;
            mEdit(txChannels,:,5)=1;
            mEdit(txChannels,:,6)=0;
            mEdit(txChannels,:,7)=1;

            output=['Restored channel(s) ' chans '.'];
        elseif strcmpi(mode,'t')
            if (handles.c==0.75)
                handles.c=0;
                set(handles.clickmark,'BackgroundColor','white')
                output='Toggled click OFF';
            else
                handles.c=0.75;
                set(handles.clickmark,'BackgroundColor','red')
                output='Toggled click ON';
            end
        elseif strcmpi(mode,'scale')
            mEdit(txChannels,:,1)=mEdit(txChannels,:,1)*px;
            output=['Scaled channel(s) ' chans ' by ' params '.'];
        elseif strcmpi(mode,'nscale')
            mEdit(txChannels,:,4)=mEdit(txChannels,:,4)*px;
            output=['Scaled noise in channel(s) ' chans ' by ' params '.'];
        elseif strcmpi(mode,'bscale')
            mEdit(txChannels,:,5)=mEdit(txChannels,:,5)*px;
            output=['Scaled LFPs in channel(s) ' chans ' by ' params '.'];
        elseif strcmpi(mode,'dcbias')
            mEdit(txChannels,:,2)=mEdit(txChannels,:,2)+px;
            output=['Biased channel(s) ' chans '.'];
        elseif strcmpi(mode,'view')
            mEdit(1,1,3)=txChannels(1);
            output=['Viewing ' num2str(txChannels(1)) '.'];
        elseif strcmpi(mode,'rand')
            mEdit(txChannels,:,1)=mEdit(txChannels,:,1).*(px*rand(length(txChannels),size(mEdit,2),1)-px/2)*20;
            output=['Haywired channel(s) ' chans '.'];
        elseif strcmpi(mode,'froffset')
            mEdit(txChannels,:,6)=mEdit(txChannels,:,6)+px;
            output=['Offset firing in channel(s) ' chans '.'];
        elseif strcmpi(mode,'frmod')
            mEdit(txChannels,:,7)=mEdit(txChannels,:,7)*px;
            output=['Modulated firing in channels ' chans '.'];
            
        else
            output='Invalid command or syntax.';
            error;
        end
        set(handles.gui1,'UserData',mEdit)
        set(handles.liveinput,'String','');
        set(handles.liveoutput,'ForegroundColor','black')
        set(handles.liveoutput,'String',output)
    else
        output='Start simulator first!';
        error;
    end
catch
    if exist('output') == 0
        output='Unknown failure.';
    end
    set(handles.liveoutput,'ForegroundColor','red')
    set(handles.liveoutput,'String',output)
end
guidata(hObject,handles);

function liveinput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to liveinput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on liveinput and none of its controls.
function liveinput_KeyPressFcn(hObject, eventdata, handles)
