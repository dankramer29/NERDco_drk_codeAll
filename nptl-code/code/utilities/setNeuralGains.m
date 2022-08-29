function varargout = setNeuralGains(varargin)
% SETNEURALGAINS MATLAB code for setNeuralGains.fig
%      SETNEURALGAINS, by itself, creates a new SETNEURALGAINS or raises the existing
%      singleton*.
%
%      H = SETNEURALGAINS returns the handle to a new SETNEURALGAINS or the handle to
%      the existing singleton*.
%
%      SETNEURALGAINS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETNEURALGAINS.M with the given input arguments.
%
%      SETNEURALGAINS('Property','Value',...) creates a new SETNEURALGAINS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before setNeuralGains_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to setNeuralGains_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help setNeuralGains

% Last Modified by GUIDE v2.5 31-Jul-2013 15:34:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @setNeuralGains_OpeningFcn, ...
                   'gui_OutputFcn',  @setNeuralGains_OutputFcn, ...
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


% --- Executes just before setNeuralGains is made visible.
function setNeuralGains_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to setNeuralGains (see VARARGIN)

% Choose default command line output for setNeuralGains
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes setNeuralGains wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = setNeuralGains_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function xGainSlider_Callback(hObject, eventdata, handles)
% hObject    handle to xGainSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
gains = getModelParam('neuralGain');
gains(1) = get(hObject, 'Value');
setModelParam('neuralGain', gains);
set(handles.xGainLabel, 'String', num2str(gains(1)))


% --- Executes during object creation, after setting all properties.
function xGainSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xGainSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
gains = getModelParam('neuralGain');
set(hObject, 'Value', gains(1))
set(handles.xGainLabel, 'String', num2str(gains(1))) 


% --- Executes on slider movement.
function xOffsetSlider_Callback(hObject, eventdata, handles)
% hObject    handle to xOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
setModelParam('vyOffset', get(hObject, 'Value'));

% --- Executes during object creation, after setting all properties.
function xOffsetSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject, 'Value', getModelParam('vxOffset'));


% --- Executes on slider movement.
function yGainSlider_Callback(hObject, eventdata, handles)
% hObject    handle to yGainSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
gains = getModelParam('neuralGain');
gains(2) = get(hObject, 'Value');
setModelParam('neuralGain', gains);
set(handles.yGainLabel, 'String', num2str(gains(2)))

% --- Executes during object creation, after setting all properties.
function yGainSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yGainSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
gains = getModelParam('neuralGain');
set(hObject, 'Value', gains(2))


% --- Executes on slider movement.
function yOffsetSlider_Callback(hObject, eventdata, handles)
% hObject    handle to yOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
setModelParam('vyOffset', get(hObject, 'Value'));

% --- Executes during object creation, after setting all properties.
function yOffsetSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject, 'Value', getModelParam('vyOffset'));



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
