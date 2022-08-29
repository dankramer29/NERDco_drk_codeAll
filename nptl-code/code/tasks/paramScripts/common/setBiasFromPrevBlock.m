function setBiasFromPrevBlock()

selection = showBlocksDialog(struct('title','Choose block to use for bias'));
if isempty (selection)
    disp('No block selected. Setting initial bias to 0.')
else
    fprintf('setting initial bias from block %03i\n',selection);
    l=loadRuntimeLog();
    l=l.blocks;
    be = l([l.blockNum]==selection).biasEstimate;
    fprintf('bias: ');
    for iD = 1 : numel( be )
        fprintf('%1.3g ', be(iD) );
    end
    fprintf('\n');
       
    setModelParam('biasCorrectionInitial',be);
    setModelParam('biasCorrectionResetToInitial',true);
    pause(0.1);
    setModelParam('biasCorrectionResetToInitial',false);    %BJ: why is this reset to false here? (Would it keep resetting without it or something??)
end