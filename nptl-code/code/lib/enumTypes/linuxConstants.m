%% screen vizualization enumerated type NEW FOR VIZ
classdef (Enumeration) linuxConstants < Simulink.IntEnumType
    enumeration
        TASK_FREE_RUN(1)
        
        DEVICE_LINUX(0)
        DEVICE_HIDCLIENT(1)
        DEVICE_ARM(2)
    end
end