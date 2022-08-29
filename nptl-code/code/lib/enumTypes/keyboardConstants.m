%% Keyboard Constants
classdef (Enumeration) keyboardConstants < Simulink.IntEnumType
   enumeration
      KEYBOARD_NONE(0)
      KEYBOARD_QWERTY1(1)		% first keyboard, with spaces
      KEYBOARD_QWERTY2(2)		% second keyboard, without spaces between keys
      KEYBOARD_GRID_6X6(3)		% 6 x 6 grid keyboard for calculating bitrate
      KEYBOARD_GRID_7X7(4)		% 7 x 7 grid keyboard for calculating bitrate
      KEYBOARD_GRID_8X8(5)		% 8 x 8 grid keyboard for calculating bitrate
      KEYBOARD_GRID_9X9(6)		% 9 x 9 grid keyboard for calculating bitrate
	  KEYBOARD_GRID_10X10(7)	% 10 x 10 grid keyboard for calculating bitrate
      KEYBOARD_GRID_5X5(8)		% 5 x 5 grid keyboard for calculating bitrate
      KEYBOARD_GRID_12X12(12)    % 12 x 12 grid keyboard for calculating bitrate
      KEYBOARD_GRID_14X14(14)   % 14 x 14 grid keyboard for calcuating bitrate
      KEYBOARD_GRID_15X15(15)   % 15 x 15 grid keyboard for calculating bitrate
      KEYBOARD_GRID_16X16(16)   % 16 x 16 grid keyboard for calcuating bitrate
      KEYBOARD_GRID_18X18(18)   % 18 x 18 grid keyboard for calcuating bitrate
      KEYBOARD_GRID_20X20(21)   % 20 x 20 grid keyboard for calcuating bitrate
      KEYBOARD_GRID_22X22(22)   % 22 x 22 grid keyboard for calcuating bitrate
      KEYBOARD_GRID_24X24(24)   % 24 x 24 grid keyboard for calcuating bitrate  %SELF: not sure about the (24) -- purpose?
      KEYBOARD_QABCD(20)		% Qwerty geometry, ABCD layout
      KEYBOARD_OPTIII(30)		% OPTI II optimized layout
      KEYBOARD_OPTIFREE(31)		% OPTI II optimized layout optimized for free typing
      
      SHAPE_RECT(1)
      SHAPE_ROUNDED_RECT(11)
      
      
      TASK_CUED_TEXT(1)
      TASK_FREE_TYPE(2)
      
      % make sure acquire methods are uint8 powers of 2, for bit-or-ing
      % (i.e., 1, 2, 4, 8, 16, 32, 64, 128, 256)
      ACQUIRE_DWELL(1)
      ACQUIRE_CLICK(2)

      KEY_TYPE_LETTER(1)
      KEY_TYPE_BACKSPACE(2)
      KEY_TYPE_SPACE(3)
      KEY_TYPE_RETURN(4)
      KEY_TYPE_STARTSTOP(5)
      
      KEY_INDEX_STARTSTOP(4) % 4 is the ASCII EOT character
      
      MAX_CUED_TEXT(300)
      MAX_NUM_KEYS(576)
      
      
   end
end