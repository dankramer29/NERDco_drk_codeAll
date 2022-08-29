function [className, typeLen] = getClassName(typeCode)
     switch(typeCode)
         case 1
         	className = 'uint8';
             % typeCode = 1;
             typeLen = 1;
         case 2
         	className = 'int8';
             % typeCode = 2;
             typeLen = 1;
         case 3
         	className = 'logical';
             % typeCode = 3;
             typeLen = 1;
         case 4
         	className = 'char';
             % typeCode = 4;
             typeLen = 1;
         case 5
         	className = 'uint16';
             % typeCode = 5;
             typeLen = 2;
         case 6 
         	className = 'int16';
             % typeCode = 6;
             typeLen = 2;
         case 7
         	className = 'uint32';
             % typeCode = 7;
             typeLen = 4;
         case 8
         	className = 'int32';
             % typeCode = 8;
             typeLen = 4;
         case 9 
         	className = 'single';
             % typeCode = 9;
             typeLen = 4;
         case 10
         	className = 'double';
             % typeCode = 10;
             typeLen = 8;
        otherwise
            assert(false, ['Undefined data type ' num2str(typeCode) ' in getClassName function!!'])
    end
