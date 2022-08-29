sounds = {'up','down','left','right'};
for s=1:length(sounds)
    [Y,FS]=audioread(['E:\Session\Software\nptlBrainGateRig\code\visualizationCode\sounds\movementCue\' sounds{s} '.wav']);
    Y = Y * 1.4;
    audiowrite(['E:\Session\Software\nptlBrainGateRig\code\visualizationCode\sounds\movementCue\' sounds{s} '.wav'],Y,FS); 
end