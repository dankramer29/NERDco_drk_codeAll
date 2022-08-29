classdef (Enumeration) SymbolStates < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        STATE_INIT(0)
        STATE_MOVE_ONE(1)
        STATE_REHEARSE(2)
        STATE_READY(3)
        STATE_MOVE_TWO(4)
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