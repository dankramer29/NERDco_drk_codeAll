function sentenceSeqRand

	numSentences = 7;
	
	seq = randperm(7);
	
	fprintf(1, 'Random sentence sequence:  ');
	for i = 1 : numSentences
		fprintf(1, '%02i  ', seq(i));
	end
	fprintf(1, '\n');
	
end