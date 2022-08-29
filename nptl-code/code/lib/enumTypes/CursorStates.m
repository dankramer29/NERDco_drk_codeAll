classdef (Enumeration) CursorStates < Simulink.IntEnumType
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
        STATE_SCORE_PAUSE(9)
        STATE_SCORE_TARGET(10)
        STATE_RECENTER_DELAY(11)
        STATE_MOVE_CLICK(12)
        STATE_HOVER(13)
        STATE_FINGER_MOVED(14)
        STATE_FINGER_LIFTED(15)
        STATE_FIXATE(16) %SNF DM state
        STATE_STIMULUS_ONSET(17) %SNF DM state
        STATE_INTERTRIAL(18) %SNF DM state
        STATE_DELAY(19) %SNF DM:stimulus first state
        STATE_CONTEXT(20) %LND YangTask
        STATE_GO(21)  %LND YangTask
        SOUND_STATE_IDLE(0)
        SOUND_STATE_SUCCESS(1)
        SOUND_STATE_FAIL(2)
        SOUND_STATE_GO(3)
        SOUND_STATE_OVER_TARGET(4)
    end
    methods (Static = true)
        function retVal = addClassNameToEnumNames()
            retVal = true;
        end
    end
end