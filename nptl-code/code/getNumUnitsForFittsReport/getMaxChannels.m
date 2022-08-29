function mC = getMaxChannels(Ms)

mC = struct;

for i = 1 : size(Ms, 1) % loop days

	mC(i).expDay = Ms(i, 1).expDay;
	mC(i).maxChannels = max([Ms(i, :).uniqueChannels]);

end
