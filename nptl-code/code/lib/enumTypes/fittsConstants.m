%% screen vizualization enumerated type NEW FOR VIZ
classdef (Enumeration) fittsConstants < Simulink.IntEnumType
    enumeration
        TASK_FITTS(1)
        %% just need these to bound memory usage, increase if we'll ever do larger blocks
%         MAX_DIAMETERS(10) % now that I'm moving away from haaving a
%         separate buildWorkspace for each task, this has been repalced by
%         cursorConstants.MAX_DIAMETERS, which had the same value
    end
end