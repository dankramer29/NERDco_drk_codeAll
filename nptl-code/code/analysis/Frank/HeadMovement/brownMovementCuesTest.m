slc1 = load('/Users/frankwillett/Data/BG Datasets/movementSweepDatasets/Data/SLC Data/SLCdata_2013_0823_170439(8).mat');
slc2 = load('/Users/frankwillett/Data/BG Datasets/movementSweepDatasets/Data/SLC Data/SLCdata_2013_0823_171729(11).mat');

taskCode = [slc1.SLCdata.task.receivedState.values; slc2.SLCdata.task.receivedState.values];
codeList = unique(taskCode);
codeList = codeList((end-3):end);

eventIdx = [];
movCues = [];
for x=1:length(codeList)
    trlStart = find(taskCode(2:end)==codeList(x) & taskCode(1:(end-1))==0);
    eventIdx = [eventIdx; trlStart];
    movCues = [movCues; repmat(codeList(x), length(trlStart), 1)];
end

%neuralFeatures = zscore(SLCdata.spikePower.values);
s1 = slc1.SLCdata.spikePower.values;
s2 = slc2.SLCdata.spikePower.values;
s1 = s1 - mean(s1);
s2 = s2 - mean(s2);
neuralFeatures = zscore([s1; s2]);
neuralFeatures = gaussSmooth_fast(neuralFeatures, 3);

timeWindow = [-150, 150];
dPCA_out = apply_dPCA_simple( neuralFeatures, eventIdx, ...
    movCues, timeWindow, 0.02, {'CD','CI'} );

lineArgs = cell(length(unique(movCues)),1);
colors = jet(length(lineArgs))*0.8;
for l=1:length(lineArgs)
    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
end

oneFactor_dPCA_plot( dPCA_out,  timeWindow(1):timeWindow(2), ...
    lineArgs, {'CD','CI'}, 'sameAxes');

%%
%evidence against it being an artifact:
%--robust discriminability across all movement types (if it was a
%commensurate jaw clench, head movement, or timing-related activity, we
%would not be able to robustly distinguish all subtypes within an effector)
%--tuning exists in different subspaces for each effector (check this)
%--tuning exists even for toe/ankle pointing movements that do not cause large
%postural perturbations when sitting in chair)
%--video shows T5, by eye, very still when doing the task
%--task cues do not induce different head or eye movements for the
%different movements (all are cued by text appearing in the same location)
%--tuning for face movements is lower strength than tuning for arm & leg
%movements, so it is not likely an artifact of concommitant movement
%--tuning for simultaneous movement, arm & leg dominate head

%figures
%(1) tuning to everything: confusion matrices, dimension examples, PSTH
%examples, bar plots comparing modulation strength
%(a) confusion matrices for each dataset + participant (T5 all, T5 ipsi vs.
%contra, T7, T9)
%(b) bar graphs showing relative modulation strengths in above datasets
%(c) selected PSTHs from above datasets (including sorted units)

%(2) distribution of tuning (do separate effectors have separate subspaces?
%do single neurons/channels have preference for certain effectors, or is
%tuning broadly distributed)? 
%(a) Joint movement dataset
%(b) Use radial 8 directional modulation dataset to answer this? Recollect
%with more intermixing and eye fixation? 

%(3) ipsilateral vs. contralateral modulation structure
%(a) dPCA plots showing side-specific dimension + side-independent movement
%dimensions
%(b) correlation of PDs across sides

%(4) simultaneous movement tuning change
%(a) Neural dimension examples of right arm dominance during simultaneous
%movement
%(b) Summarize across all effector pairings to show that the effector with
%the largest modulation when measured in isolation "dominates" the weaker
%effector during simultaneous movement
%(c) Analyze PD change during simultaneous movement to show that PDs remain
%constant for the dominant effector, but change significantly for the
%subordinate effector

%(5) real-time discrete decoding 
%(a) bit rates & classification accuracies of real-time decoding using single joystick, dual joystick, quad
%effector, and dual joystick simultaneous movements
%(b) free typing with quad effector keyboard

%%
%Supplement questions:

%is tuning somatotopically organized? It doesn't look to be.

%is tuning in a single neuron/channel broadly distributed or focused on a
%single effector? PDs are correlated across ipsi/contra but unrelated
%across effectors.

%verify results for sorted units - do results change? 
