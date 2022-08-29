classdef (Sealed) Tasks
   properties (Constant)
      MOVEMENT = 1;
      CURSOR = 2;
   end

    methods (Access = private)    % private so that you cant instantiate
        function out = Tasks
        end
    end
end