classdef (Enumeration) rigHardwareConstants < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        REREFERENCE_NONE(0)
        REREFERENCE_COMMON_AVG(1)
        REREFERENCE_COMMON_MEDIAN(2)
        
        ARRAY_T7_MEDIAL(10)
        ARRAY_T7_LATERAL(11)
        ARRAY_T7_BOTH(12)

        ARRAY_T5_LATERAL(40) %ANTERIOR
        ARRAY_T5_MEDIAL(41) %POSTERIOR
        ARRAY_T5_BOTH(42)

        ARRAY_T6(1)
        
        ARRAY_T9_MEDIAL(20)
        ARRAY_T9_LATERAL(21)
        ARRAY_T9_BOTH(22)

        ARRAY_T8_MEDIAL(30)
        ARRAY_T8_LATERAL(31)
        ARRAY_T8_BOTH(32)
    end
end