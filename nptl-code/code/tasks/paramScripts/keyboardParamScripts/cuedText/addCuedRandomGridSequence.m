function addCuedRandomGridSequence(seqLength, numTargets)

	txt = char(randi(numTargets, [1 seqLength])+'0');

	txt1 = getModelParam('cuedText');
	txt1(1:seqLength) = txt;
	txt1(seqLength+1:end) = 0;
    
	setModelParam('cuedText', txt1);
	setModelParam('cuedTextLength', seqLength);
	
end