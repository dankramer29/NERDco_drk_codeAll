classdef (Enumeration) LinuxStates < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        STATE_INIT(0)
        STATE_FREE_RUN(1)
        STATE_PAUSE(2)
        STATE_END(3)
        SOUND_STATE_IDLE(0)
        SOUND_STATE_CLICK(0)
    end
end