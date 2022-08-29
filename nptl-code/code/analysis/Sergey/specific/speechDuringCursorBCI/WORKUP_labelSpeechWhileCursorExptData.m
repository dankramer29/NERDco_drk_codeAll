% Script used to guide the researcher in hand-labeling the audio stream. Based on 
% /speech/WORKUP_labelSPeechExptData.m, but for this new spin-off project.


autoplayEachSnippet = true; % for everythign except Caterpillar


%% t5.2018.12.12 Speech while BCI cursor task
audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
%
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2018.12.12/';

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.12/Lateral/7_cursorTask_Complete_t5_bld(007)008.ns5'; % t5.2018.12.12 CL R8 Block 7 with speaking (A)
% labelOptions = { 'beet'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.12/Lateral/9_cursorTask_Complete_t5_bld(009)010.ns5'; % t5.2018.12.12 CL R8 Block 9 NO speaking (B)
% labelOptions = { 'silence'};

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.12/Lateral/10_cursorTask_Complete_t5_bld(010)011.ns5'; % t5.2018.12.12 CL R8 Block 10 speaking (A)
% labelOptions = { 'bot'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.12/Lateral/12_cursorTask_Complete_t5_bld(012)013.ns5'; % t5.2018.12.12 CL R8 Block 12 NO speaking (B)
% labelOptions = { 'silence'}; 

%% t5.2018.12.17 Speech while BCI cursor task
% audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% %
saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2018.12.17/';
% 
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/8_cursorTask_Complete_t5_bld(008)009.ns5'; % t5.2018.12.17 CL R8 Block 8 no speaking (B)
% labelOptions = { 'silence'}; 
% 
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/9_cursorTask_Complete_t5_bld(009)010.ns5'; % t5.2018.12.17 CL R8 Block 9 yes speaking (A)
% labelOptions = { 'seal'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/10_cursorTask_Complete_t5_bld(010)011.ns5'; % t5.2018.12.17 CL R8 Block 10 yes speaking (A)
% labelOptions = { 'more'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/11_cursorTask_Complete_t5_bld(011)012.ns5'; % t5.2018.12.17 CL R8 Block 11 no speaking (B)
% labelOptions = { 'silence'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/12_cursorTask_Complete_t5_bld(012)013.ns5'; % t5.2018.12.17 CL R8 Block 12 yes speaking (A)
% labelOptions = { 'bat'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/13_cursorTask_Complete_t5_bld(013)014.ns5'; % t5.2018.12.17 CL R8 Block 13 no speaking (B)
% labelOptions = { 'silence'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/16_cursorTask_Complete_t5_bld(016)017.ns5'; % t5.2018.12.17 CL R8 Block 16 no speaking (B)
% labelOptions = { 'silence'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/17_cursorTask_Complete_t5_bld(017)018.ns5'; % t5.2018.12.17 CL R8 Block 17 yes speaking (A)
% labelOptions = { 'shot'}; 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/18_cursorTask_Complete_t5_bld(018)019.ns5'; % t5.2018.12.17 CL R8 Block 18 yes speaking (A)
% labelOptions = { 'beet'}; 

fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/19_cursorTask_Complete_t5_bld(019)020.ns5'; % t5.2018.12.17 CL R8 Block 19 no speaking (B)
labelOptions = { 'silence'}; 

msShownEachTime = 5500;


%% Run the labeling tool
% Allow 1 event
% Labeling rule: Prompt event 1 is cue
%                Response event 1 is Acoustic Onset if there's a response. Otherwise, it's
%                ignored.
[matName, sAnnotation] = soundLabelTool( fname, audioChannel, saveAnnotationPath, 'possibleCues', labelOptions, 'msShownEachTime', msShownEachTime, ...
    'autoplayEachSnippet', autoplayEachSnippet, 'maxEventsPerTrial', 1, 'minEventsPerTrial', 1);

