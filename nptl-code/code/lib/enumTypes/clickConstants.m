classdef (Enumeration) clickConstants < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        CLICK_TYPE_NONE(0)
        CLICK_TYPE_GLOVE(1)
        CLICK_TYPE_NEURAL(2)
        CLICK_TYPE_MOUSE(3)
        CLICK_TYPE_MULTI(4)
    end
end