classdef (Enumeration) rsgStates < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        STATE_INIT(0)
        STATE_FIXATE(1)
        STATE_PRE_READY(2)
        STATE_POST_READY(3)
        STATE_POST_SET(4)
        STATE_ACQUIRE(5)
        SOUND_STATE_ACQUIRE(0)
        SOUND_STATE_SUCCESS(1)
        SOUND_STATE_IDLE(2)
        SOUND_STATE_FAIL(3)
    end
    methods (Static = true)
        function retVal = addClassNameToEnumNames()
            retVal = true;
        end
    end
end