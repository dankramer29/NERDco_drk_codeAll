function [ epochs ] = logicalToEpochs( lString )
stringSize = size(lString);
if stringSize(1) > stringSize(2)
    lString = lString';
end

%in a string of logicals, converts the contiguous blocks of 1s to a matrix
%of epochs (start and end bins) 
lStringMarks = diff(lString);
strtIdx = find(lStringMarks==1)+1;
endIdx = find(lStringMarks==-1);

if lString(1) == 1
    strtIdx = [1 strtIdx];
end

if lString(end) == 1
    endIdx = [endIdx length(lString)];
end

epochs = [strtIdx' endIdx'];
end

