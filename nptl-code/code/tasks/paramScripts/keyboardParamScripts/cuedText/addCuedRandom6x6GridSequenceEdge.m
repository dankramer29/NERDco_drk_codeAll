function addCuedRandom6x6GridSequenceEdge(seqLength)

    numEdgeTargets = 20;

    randSeq = zeros(1, seqLength);
    numRepeats = floor(seqLength/double(numEdgeTargets));
    for i = 1 : numRepeats
        randSeq( (i - 1) * numEdgeTargets + 1 : i * numEdgeTargets ) = randperm(numEdgeTargets);
    end
    
    for i = 1 : numel(randSeq)
        
        switch(randSeq(i))
            case 8
                randSeq(i) = 12;
            case 9
                randSeq(i) = 13;
            case 10
                randSeq(i) = 18;
            case 11
                randSeq(i) = 19;
            case 12
                randSeq(i) = 24;
            case 13
                randSeq(i) = 25;
            case {14, 15, 16, 17, 18, 19, 20}
                randSeq(i) = randSeq(i) + 16;
        end
    end
    
    txt = char(randSeq) + '0';
    
%	txt = char(ceil(rand(seqLength,1)*numTargets)+'0');

	txt1 = getModelParam('cuedText');
	txt1(1:seqLength) = txt;
	txt1(seqLength+1:end) = 0;
	
	setModelParam('cuedText', txt1);
	setModelParam('cuedTextLength', numRepeats * numEdgeTargets);
	
end