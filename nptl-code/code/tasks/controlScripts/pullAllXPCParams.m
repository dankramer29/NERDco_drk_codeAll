function params = pullAllXPCParams(xpc)

params = [];

numP = xpc.numParameters;

for i = 0 : numP - 1 
	pVal = xpc.getparam(i);
	[~, pName] = xpc.getparamname(i);

	params.(pName) = pVal;

end
