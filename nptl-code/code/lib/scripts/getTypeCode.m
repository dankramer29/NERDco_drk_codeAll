function [typeCode,typeLen] = getTypeCode(var)
     switch(class(var))
         case 'uint8'
             typeCode = 1;
             typeLen = 1;
         case'int8'
             typeCode = 2;
             typeLen = 1;
         case 'logical'
             typeCode = 3;
             typeLen = 1;
         case'char'
             typeCode = 4;
             typeLen = 1;
         case 'uint16'
             typeCode = 5;
             typeLen = 2;
         case'int16'
             typeCode = 6;
             typeLen = 2;
         case 'uint32'
             typeCode = 7;
             typeLen = 4;
         case'int32'
             typeCode = 8;
             typeLen = 4;
         case 'single'
             typeCode = 9;
             typeLen = 4;
         case 'double'
             typeCode = 10;
             typeLen = 8;
        otherwise
            assert(false, 'Undefined data type in pack function!!')
    end
