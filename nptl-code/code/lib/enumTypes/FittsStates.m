classdef (Enumeration) FittsStates < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        STATE_INIT(0)
        STATE_PRE_TRIAL(1)
        STATE_NEW_TARGET(2)
        STATE_MOVE(3)
        STATE_ACQUIRE(4)
        STATE_SUCCESS(5)
        STATE_FAIL(6)
        STATE_CENTER_TARGET(7)
        STATE_END(8)
        STATE_RECENTER_DELAY(11)
        STATE_MOVE_CLICK(12)
        STATE_HOVER(13)
        STATE_FINGER_MOVED(14)
        STATE_FINGER_LIFTED(15)
        SOUND_STATE_IDLE(0)
        SOUND_STATE_SUCCESS(1)
        SOUND_STATE_FAIL(2)        
    end
    methods (Static = true)
        function retVal = addClassNameToEnumNames()
            retVal = true;
        end
    end    
end