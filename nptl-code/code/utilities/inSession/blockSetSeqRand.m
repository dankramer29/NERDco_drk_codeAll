function blockSetSeqRand()
% outputs text for random blocks


	blockTypes = {'grid', 'typingQwerty','typingOptiII'};

	% reset random number generator based on current time
	%rng('shuffle');

	seqGrid = randperm(2);
    seqTyping = randperm(2);

    if seqGrid(1) == 1
       fprintf(1, sprintf('A: %s\n', blockTypes{1}) );
       
       if seqTyping(1) == 1
           fprintf(1, sprintf('B: %s\n', blockTypes{2}) );
           fprintf(1, sprintf('C: %s\n', blockTypes{3}) );
       else
           fprintf(1, sprintf('B: %s\n', blockTypes{3}) );
           fprintf(1, sprintf('C: %s\n', blockTypes{2}) );
       end
       
    else
        
       if seqTyping(1) == 1
           fprintf(1, sprintf('A: %s\n', blockTypes{2}) );
           fprintf(1, sprintf('B: %s\n', blockTypes{3}) );
       else
           fprintf(1, sprintf('A: %s\n', blockTypes{3}) );
           fprintf(1, sprintf('B: %s\n', blockTypes{2}) );
       end
  
       fprintf(1, sprintf('C: %s\n', blockTypes{1}) );
       
    end

    % old full random code
%   numBlocksPerSet = 3;
%     seq = randperm(numBlocksPerSet);
% 	fprintf(1, sprintf('A: %s\n', blockTypes{seq(1)}) );
% 	fprintf(1, sprintf('B: %s\n', blockTypes{seq(2)}) );
% 	fprintf(1, sprintf('C: %s\n', blockTypes{seq(3)}) );

end
