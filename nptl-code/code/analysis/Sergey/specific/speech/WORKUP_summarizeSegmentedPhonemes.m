% Goes through the phoneme segmentation .textGrid files for the extended words, and
% summarizes the number of phonemes in the dataset. This script is intended both to
% overview the data (which phonemes do we have? how many?), and for quality control to
% detect if some instances of a word were labelled differently than other instances.
%
% creates structures allWords and allPhonemes with various subfields.
%
% July 22 2019
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Lab




% Where are the segmentation files?
segmentedTextgridDir = '/Users/sstavisk/Google Drive/segmentationProject/phonemeAnnotation/';


%% Get all the files, report inconsistencies across repetitions.

% will fill in allWords structure
allWords.blocknum = [];
allWords.trialnum = []; % trial number
allWords.prompt = cell(0);
allWords.phonemes = {}; % list of the phonemes
allWords.phonemesConcatenated = {}; % combined together (easier to read or compare)
allWords.numPhonemes = []; % number of phonemes in each word
allWords.filename = {};
% get the list of files
filesList = dir( [segmentedTextgridDir '*.textGrid'] );


warning off MATLAB:iofun:UnsupportedEncoding;

% Loop through the files.
for iFile = 1 : numel( filesList )
    % Parse out the trial number and word
    fname = filesList(iFile).name;
    pT = strfind( fname, '_trial' );
    
    % Get the block number
    myBlocknum = str2num( fname(pT-4+regexp(fname(pT-3:pT), '[0-9]')) );
    allWords.filename{iFile} = fname;
    allWords.blocknum(iFile) = myBlocknum;
    
    % Get the trial num
    myTrialnum = str2num( fname(pT+6:pT+9) );
    allWords.trialnum(iFile) = myTrialnum;
    
    % Get the prompted word
    wS = strfind(fname(pT+1:end), '_');
    wE = strfind(fname(pT+1:end), '.');
    myWord = fname(pT+wS+1:pT+wE-1);
    allWords.prompt{iFile} = myWord;    
    
    % Get the segmentation for this word
    % annoyingly need to try two ways
    try
        tgin = tgRead( [segmentedTextgridDir, fname], 'Unicode' );
    catch
        tgin = tgRead( [segmentedTextgridDir, fname] );
    end
    myLabels = tgin.tier{1}.Label;
    % sanity check: should start and end with empty
    if ~strcmp( myLabels{1}, '' )
        fprintf( 2, '%s starts with %s, not empty.\n', ...
            fname, myLabels{1} );        
    end
    if ~strcmp( myLabels{end}, '' )
        fprintf( 2, '%s ends with %s, not empty.\n', ...
            fname, myLabels{end} );
    end
    allWords.phonemes{iFile} = {};
    allWords.phonemesConcatenated{iFile} = [];
    for iL = 1 : numel( myLabels )        
        % ignore empty labels (first, last, extra 'mmm' blanks
        if ~isempty( myLabels{iL} )
           allWords.phonemes{iFile}{end+1} = myLabels{iL};
           allWords.phonemesConcatenated{iFile} = [allWords.phonemesConcatenated{iFile}, myLabels{iL}];    
        end         
        
        % Report if there's a space in one of these phonemes (there should not be but they're hard
        % to see in Praat)
        if any( myLabels{iL} == ' ' )
            fprintf( 2, 'Warning! %s has a phoneme with extra space: %s\n', fname, myLabels{iL} );
        end
        
    end
    allWords.numPhonemes(iFile) = numel(  allWords.phonemes{iFile} );

    % Look through previous words, warn if segmentation differs for other trials of this word.
    for iBack = 1 : iFile - 1
        if strcmp( allWords.prompt{iBack}, allWords.prompt{iFile} )
            % same word, warn if phonetic annotation differs
            if ~strcmp( allWords.phonemesConcatenated{iBack}, allWords.phonemesConcatenated{iFile} )
                fprintf( 2, 'Alert!: %s annotated as ''%s'', wheras %s annotated as ''%s''. This could indicate an annotation error.\n', ...
                    allWords.filename{iBack}, allWords.phonemesConcatenated{iBack}, allWords.filename{iFile}, allWords.phonemesConcatenated{iFile} )
            end
        end
    end
    
  
    
end


%%
% Flag duplicate files
for i = 1 : numel( allWords.prompt )
    if strfind( allWords.prompt{i}, '(1)' )
        fprintf( 2, '%s\n', filesList(i).name )
    end
end



% Report number of words and counts for each
allWords.uniqueWords = unique( allWords.prompt );
for i = 1 : numel( allWords.uniqueWords )
    numMatching = nnz( strcmp( allWords.prompt, allWords.uniqueWords{i} ) );
    allWords.uniqueWordsReps(i) = numMatching;
    fprintf('%-10s %i\n', [allWords.uniqueWords{i} ':'], numMatching )
end
fprintf('%i unique words\n', numel( allWords.uniqueWords ) );
figure;
histogram( allWords.numPhonemes(:) )
xlabel('# Phonemes' )
ylabel('# Trials' )




%% Compile count of how many instances of each phoneme there are.
allPhonemes = [];
flatPhonemes = [allWords.phonemes{:}]; %flattened list
allPhonemes.uniquePhonemes = unique( flatPhonemes );

fprintf('\n%i unique phonemes\n', numel( allPhonemes.uniquePhonemes  ) );
allPhonemes.numEachPhoneme = [];
for iP = 1 : numel( allPhonemes.uniquePhonemes )
    allPhonemes.numEachPhoneme(iP) = nnz( strcmp( allPhonemes.uniquePhonemes{iP}, flatPhonemes ) );
    fprintf('/%s/ %i\n', allPhonemes.uniquePhonemes{iP}, allPhonemes.numEachPhoneme(iP) )
end

fprintf('Min/median/max instances of each phoneme: %i / %i / %i \n', ...
    min( allPhonemes.numEachPhoneme ), median( allPhonemes.numEachPhoneme ), max( allPhonemes.numEachPhoneme ) )

fprintf('%i total phonemes\n',  sum( allPhonemes.numEachPhoneme ) )

%% todo: could build up table of durations, order, etc for each phoneme



