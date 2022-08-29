function Data = rescaleJPCADt (Data, newDt)
%% function Data = rescaleJPCADt (Data, newDt)

	for nb = 1:numel(Data)
		Data(nb).A = Data(nb).A(1:newDt:end,:);
		Data(nb).times = Data(nb).times(1:newDt:end);
	end