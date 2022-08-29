classdef (Sealed) ImageCues
   properties (Constant)
      REST = 50;
      ELBOWFLEX = 1;
      HUMERALROTIN = 2;
      HUMERALROTOUT = 3;
      SHOULDERABD = 4;
      SHOULDERFORW = 5;
      WRISTEXT = 6;
      WRISTFLEX = 7;
      WRISTPRON = 8;
      WRISTSUP = 9;
      WRISTRAD = 10;
      WRISTULN = 11;

      FIST = 30;
      INDEX = 31;
      MIDDLE = 32;
      PINCH = 33;
      PINKIE = 34; 
      POINT = 35;
      RING = 36;
      THUMB = 37;
      VULCAN = 38;

   end

    methods (Access = private)    % private so that you cant instantiate
        function out = ImageCues
        end
    end
end