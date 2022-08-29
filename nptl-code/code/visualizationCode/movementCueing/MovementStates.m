classdef (Enumeration) MovementStates < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        STATE_INIT(0)
        STATE_MOVEMENT_TEXT(1)
        STATE_GO_CUE(2)
        STATE_HOLD_CUE(3)
        STATE_RETURN_CUE(4)
        STATE_REST_CUE(5)
        STATE_END(6)
        STATE_PRE_MOVE(7)
        SOUND_STATE_IDLE(0)
        SOUND_STATE_MOVEMENT_TEXT(1)
        SOUND_STATE_GO_CUE(2)
        SOUND_STATE_HOLD_CUE(3)
        SOUND_STATE_RETURN_CUE(4)
        SOUND_STATE_REST_CUE(5)
        
    end
end