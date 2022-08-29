function str = getStringFromBytes(bytes)
  endInd = min(find(bytes==0));
  if ~length(endInd), endInd = length(bytes)+1; end
  str = char(bytes(1:endInd-1));
  str = str(:)';
end