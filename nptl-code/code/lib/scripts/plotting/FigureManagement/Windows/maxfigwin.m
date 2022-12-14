function maxfig(varargin)
% maxfig(fig,monitor,mode)  MAXimize a FIGure to fill the screen.
%   Subsequent calls will restore the maximized figure to its previous state.
%   "fig" (first numeric input) is the handle of the figure to maximize
%       (default is current figure).
%   "monitor" (second numeric input) (Default=1) is an integer corresponding
%       to a monitor. Monitor numbering is defined by the row number of the
%       corresponding monitor in the root property 'MonitorPositions'. 
%   "mode" is a string specifying whether to fully maximize the figure
%       (borders extend beyond the monitor, menu and tool bars are removed)
%       or set to normal mode with borders, menu & toolbars displayed.
%       Value for maximize mode is any of {m,max,y,yes,t,true}(default).
%       Value for normal mode is any of {n,normal,no,f,false}.
%   Examples:
%       maxfig, maxfig(3,2), maxfig([],3), maxfig('normal')

%   Copyright 2006 Mirtech, Inc.
%   created 08/23/2006  by Mirko Hrovat on Matlab Ver. 7.2
%   Mirtech, Inc.   email: mhrovat@email.com
%   Uses getmondim.m
% More notes:
% Extended monitors can have a different resolution from the primary monitor.
% Placement and size of the taskbar on the primary monitor can be changed
%   in the code, see commented sections.
% Will work with docked figures.
% Inspired by MAXFIGSIZE (ID 3036) by Duane Hanselman.
% The figure properties, TAG and USERDATA, are used to keep track of the
%   maximized figure. 

% --------- Key Constants -----------
% To allow for user or OS borders set the appropriate value in pixels.
topborder       =0;
bottomborder    =0;
rightborder     =0;
leftborder      =0;
taskbarborder   =30;
% Border properties for figures - Adjust if needed.
% determined by the difference between OuterPosition and Position values.
% GETFIGDIM can return these values for your system.  
figureborder    =5;
titleheight     =26;        %#ok
% ----------------------------------

fullflag=1;     % set default state for maximization choice
monnum=[];
% just in case, check all figures for 'MaxFig' tag
set(0,'ShowHiddenHandles','on')     
fig= findobj('Tag','MaxFig');
set(0,'ShowHiddenHandles','off')
% If "MaxFig" figure is found then reset size to original values
if ~isempty(fig),
    set(fig,'Tag','')
    userdata=get(fig,'UserData');
    set(fig,'Units',userdata{1},'OuterPosition',userdata{2});
    set(fig,'MenuBar',userdata{3},'ToolBar',userdata{4},...
        'WindowStyle',userdata{5});
    drawnow
end    
if nargin==0,
    if ~isempty(fig),
        return         
    % return if no arguments, maxfig is only resetting the figure.
    end
else
    count=0;
    for n=1:length(varargin),
        arg=varargin{n};
        if isnumeric(arg),      % note "empty" is also considered to be numeric!
            count=count+1;
            switch count
                case 1
                    fig=arg;
                case 2
                    monnum=arg;
            end  % switch count
        elseif ischar(arg),
            if any(strcmpi(arg,{'y','yes','t','true','m','max'})),
                fullflag=1;
            elseif any(strcmpi(arg,{'n','no','f','false','normal'})),
                fullflag=0;
            end
        end
    end  % for
end  % if nargin
if isempty(fig),        fig=gcf;    end
if isempty(monnum),     monnum=1;   end

% Check WindowStyle property
winstyle=get(fig,'WindowStyle');
if strcmpi(winstyle,'modal'),
    error('  Cannot maximize this figure.')
end
    
% Get screen dimensions. 
scnsize=getmondim(monnum);
if isempty(scnsize),
    error ('  Monitor %g does not exist',monnum)
end
% ----------------------- TASKBAR PLACEMENT --------------------
% adjust border for taskbar, edit appropriate line for position of taskbar
if monnum==1,   
    bottomborder=bottomborder+taskbarborder;
end
% ----------------------- TASKBAR PLACEMENT --------------------
scnwidth=scnsize(3)-leftborder-rightborder;
scnheight=scnsize(4)-topborder-bottomborder;

% Calculate offsets for multiple monitors.
offx=scnsize(1)+leftborder-1;
offy=scnsize(2)+bottomborder-1;

% Save properties for figure in UserData field
set(fig,'Tag','MaxFig')
menbar=get(fig,'MenuBar');
tbar=get(fig,'ToolBar');
set(fig,'UserData',{get(fig,'Units'), get(fig,'OuterPosition'),...
    menbar,tbar,winstyle})

if fullflag
    tbar='none';
    menbar='none';
    offx=offx-figureborder;
    offy=offy-figureborder;
    scnwidth=scnwidth+2*figureborder;
    scnheight=scnheight+2*figureborder;
%    scnheight=scnheight+2*figureborder+titleheight;  
% The above seems to create problems as results don't match settings.
%   The values seem to wrap around. So it looks like there is no simple
%   way to get rid of the title bar in Matlab.    
end

pos=[offx+1,offy+1,scnwidth,scnheight];
% Move, size figure and modify properties as needed.
if strcmpi(winstyle,'docked'),
    set(fig,'WindowStyle','normal')
    drawnow
end
set(fig,'Units','pixels', ...
        'OuterPosition',pos,...
        'MenuBar',menbar,...
        'ToolBar',tbar);
figure(fig)                 % bring figure to front.
end
