classdef (Enumeration) DiscreteStates < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        % POSSIBLE CLICK STATES
        CLICK_IDLE(0);  % unclicked/move % move states are always 0, so that's good. 
        CLICK_MAIN(1);  % default click
        CLICK_LCLICK(2); % SNF Emulates left click of the mouse, same as "main" I think
        CLICK_RCLICK(3); % SNF Emulates right click
        CLICK_2CLICK(4); % SNF Emulates double clicking. "2Click" for "Double Click"
        CLICK_SCLICK(5); % SNF Emulates click and drag. "SCLICK" for "Sticky Click"
        % STATE MODELS
        STATE_MODEL_MOVECLICK(1);     % 2-state is the default model we use
        STATE_MODEL_MOVEIDLECLICK(2); % 3-state model includes idle but is never actually used
        STATE_MODEL_MULTICLICK(3);    % SNF multiclick task using moveclick
        STATE_MODEL_MULTICLICK3(4);   % SNF multiclick task using the 3-state model
        MOVECLICK_STATE_MOVE(0);        % move states are always 0, so that's good.
        MOVECLICK_STATE_CLICK(1);       % SNF thinks this should be a 2 and click_main should be 2, but the assumption that this is 1 is pervasive in the code
        MOVEIDLECLICK_STATE_MOVE(0);    % move states are always 0, so that's good. 
        MOVEIDLECLICK_STATE_IDLE(1);    % idle states are always 1, but not all 1's are idle states. side eye. 
        MOVEIDLECLICK_STATE_CLICK(2);   % matches multiclick 
        MULTICLICK_STATE_MOVE(0);       % SNF for consistency with prev models
        MULTICLICK_STATE_IDLE(1);       % SNF for consistency across multiclick and 3-state- just used with multiclick3
        MULTICLICK_STATE_LCLICK(2);     % SNF Emulates left click of the mouse, overlaps with "MAIN"
        MULTICLICK_STATE_RCLICK(3);     % SNF Emulates right click
        MULTICLICK_STATE_2CLICK(4);     % SNF Emulates double clicking. "2Click" for "Double Click"
        MULTICLICK_STATE_SCLICK(5);     % SNF Emulates click and drag. "SCLICK" for "Sticky Click" or "scroll click"
        % CLICK SOURCES
        STATE_SOURCE_CLICK(1) % take state information from 'clickState'
        STATE_SOURCE_DWELL(2) % take state information from 'dwellState'
        STATE_SOURCE_REST(3) % take state information from 'restState'
        STATE_SOURCE_CLICKOVERTARGET(4) % take state information from 'clickState' & 'overTargetState'
    end
end