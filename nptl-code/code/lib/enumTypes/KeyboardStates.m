classdef (Enumeration) KeyboardStates < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        STATE_INIT(0)
        STATE_MOVE(2)
        STATE_OVER_TARGET(3)
        STATE_CLICK(4)
        STATE_CLICK_REFRACTORY(5)
        STATE_DWELL_REFRACTORY(6)
        STATE_SHOW_SCORE(9)
        STATE_END(10)
        STATE_KEY_PRESSED(11)
        STATE_INACTIVE(12)
        SOUND_STATE_IDLE(0)
        SOUND_STATE_OVER_TARGET(1)
        SOUND_STATE_CLICK(2)
        SOUND_STATE_ERROR(3)
    end
    methods (Static = true)
        function retVal = addClassNameToEnumNames()
            retVal = true;
        end
    end
end