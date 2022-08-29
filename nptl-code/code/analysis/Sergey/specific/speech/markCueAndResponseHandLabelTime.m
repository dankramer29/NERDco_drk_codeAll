% markCueAndResponseHandLabelTime.m
%
% Contains the rules for which of the hand-label .timeCueStart and .timeSpeechStart
% correspond to the cue event and response event of interest; these differs depending on
% the task type (e.g. phonemes versus instructed movements)
%
% USAGE: [ R ] = markCueAndResponseHandLabelTime( R, varargin )
%
% EXAMPLE: R = markCueAndResponseHandLabelTime( R );
%
% INPUTS:
%     R                         Speech experiment R struct
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R                         Speech experiment R struct with .handCueEvent and
%                               .handResponseEvent added.
%                              for instructed movement blocks, it creates a .handResponseEvent
%                              (which is the go cue) and .handReturnEvent .
%
% Created by Sergey Stavisky on 01 Dec 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ R ] = markCueAndResponseHandLabelTime( R, varargin )
    % These are the rules for the Words and Phonemes tasks
    def.speakingWhichIndexIsCueSound = 3; % it goes beep beep cue_word
    def.speakingWhichIndexIsResponseSound = 3; % it goes click click response_word
    def.speakingWhichIndexIsPreCueBeep = 2;
    def.speakingWhichIndexIsPreResponseBeep = 2;
    def.speakingSilentWhichIndexIsCueSound = 2; % it goes beep beep _____
    def.speakingSilentWhichIndexIsResponseSound = 2; % it goes click click ____
    def.speakingSilentLabel = 'silence';
    % These are the rules for the Instructed Movements task
    def.movementsWhichIndexIsCueSound = 3; % it goes beep beep instruction
    def.movementsWhichIndexIsPreCueBeep = 2;
    def.movementsWhichIndexIsGoCue = 2; % it goes click click (movement)    return 
    % note that movement task go cue is same as preResponseBeep
    def.movementsWhichIndexIsReturnCue = 3; 
    
    assignargs( def, varargin );

    % get the possible labels from a lookup function
    labelsSpeaking = [labelLists('phonemes'), labelLists('words')];
    labelsMovements = labelLists('movements');
    
    % Go through each trial and assign with appropriate rule
    for iTrial = 1 : numel( R )
       switch R(iTrial).label
           case labelsSpeaking
               if strcmp( R(iTrial).label, speakingSilentLabel )
                   % Silent speaking trial
                   R(iTrial).handCueEvent = R(iTrial).timeCueStart(speakingSilentWhichIndexIsCueSound);
                   R(iTrial).handResponseEvent = R(iTrial).timeSpeechStart(speakingSilentWhichIndexIsResponseSound);
                   % the pre-cue, pre-response beep are the same as the
                   % handCueEvent / handResponseEvent
                   R(iTrial).handPreCueBeep =  R(iTrial).timeCueStart(speakingSilentWhichIndexIsCueSound);
                   R(iTrial).handPreResponseBeep = R(iTrial).timeSpeechStart(speakingSilentWhichIndexIsResponseSound);
               else
                   % Regular speaking trial
                   try
                       R(iTrial).handCueEvent = R(iTrial).timeCueStart(speakingWhichIndexIsCueSound);
                   catch
                       fprintf( 2, 'Trial %i has no handCueEvent. Adding a nan\n', iTrial );
                       R(iTrial).handCueEvent = nan;
                   end
                   R(iTrial).handResponseEvent = R(iTrial).timeSpeechStart(speakingWhichIndexIsResponseSound);
                   R(iTrial).handPreCueBeep =  R(iTrial).timeCueStart(speakingWhichIndexIsPreCueBeep);
                   R(iTrial).handPreResponseBeep = R(iTrial).timeSpeechStart(speakingWhichIndexIsPreResponseBeep);
               end

           case labelsMovements               
               R(iTrial).handCueEvent = R(iTrial).timeCueStart(movementsWhichIndexIsCueSound);
               R(iTrial).handPreCueBeep = R(iTrial).timeCueStart(movementsWhichIndexIsPreCueBeep); % same as movementsWhichIndexIsGoCue
               R(iTrial).handResponseEvent = R(iTrial).timeSpeechStart(movementsWhichIndexIsGoCue);
               R(iTrial).handReturnEvent = R(iTrial).timeSpeechStart(movementsWhichIndexIsReturnCue);
               
           otherwise
               error('Label ''%s'' not recognized in my list of speaking or movement labels!', R(iTrial).label )
       end
    end
end