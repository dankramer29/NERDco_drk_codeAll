classdef (Enumeration) xkConstants < Simulink.IntEnumType
% Here we define very high-level constants realted to how many dimensions
% xk has.
    enumeration
      NUM_STATE_DIMENSIONS(21) % Sergey and Chethan trying to make this a flexible
                                 % way to have potentially made dimensions.
                                 % last element is always a bias (1) state.
                                 % Typically decoding will be done in lower D.
      NUM_TARGET_DIMENSIONS(5)   % Defines dimensionality that the target
                                 % has. This is used in e,g. taskBlock output.
    end
end



