function [clickLabels, binsToChop, onTarget] = findClickTimes(D, options)
% findClickTimes labels click periods using D and options.
% 
% Called in multiple places during click decoder build (e.g. buildHMMOpenLoop,
% buildHMMDialog). Allows excludeAmbiguousData, etc. to apply during all parts 
% of build (including finding best channels, etc.). 
% 
% Beata Jarosiewicz, Feb 2017
% SNF: expand this for multiclick 
% SNF sees issues. Like, D.clickState previously ranged from 0 to binSize
% (usually 15), and now that's multiplied by the click Target ID number,
% but the clickStateThreshold is 0.5? whaaaaaaat...... So should this get
% unscaled or does none of it matter bc clickState used to be 0 or 15 in
% ints? 
switch options.clickSource
    case 'RTI'
        clickLabels = logical([D.clickState]);  %SELF: this is now defined as discreteStateLikelihoods > click threshold (and only moving-toward-target times are getting labeled as non-click).
        binsToChop = false(size(clickLabels));
        onTarget = clickLabels;  %targets are defined by where clicks occurred; assume on target while click is above threshold
    otherwise
% pick the the field in the D-struct that matches the click source
        %SNF: multiclick: if clickTarget > 0, dewell state is unused
        %hverTargetState is always filled in. T
        if options.statesToUse < 4
            onTarget = [D.overTargetState]>options.clickStateThreshold | ... 
                        [D.dwellState]>options.clickStateThreshold;          
            aboveThresh = [D.clickState]>options.clickStateThreshold; %SNF: clickState is # click ms
        else %multiclick 
            onTarget = [D.overTargetState]>options.clickStateThreshold | ... %SNF: for a click target (closed loop?)
                        [D.dwellState]>options.clickStateThreshold;           %SNF: this catches the dwell/no-click targets.. but confounds center targ?
            aboveThresh = [D.clickState]>options.clickStateThreshold; %SNF: clickState is # click ms
        end
end
% onTarget and aboveThresh are logicals
isAmbiguous = false(size([D.clickState]));
beyondMaxLength = false(size([D.clickState]));

switch options.clickSource
    case DiscreteStates.STATE_SOURCE_CLICK
        clickLabels = aboveThresh; %[D.clickState]>options.clickStateThreshold;
        %SNF: if this is always training the decoder, add matching logic to dwell here.  
    case DiscreteStates.STATE_SOURCE_DWELL
        %clickLabels = onTarget; % [D.dwellState]>options.clickStateThreshold;
        tmp = [D.clickTarget];
        clickLabels = tmp(onTarget); %find click target ID for all times when the cursor is on the target
        clear tmp; 
        %SNF: clickSource is dwell for open loop training. clickLabels need
        %to be target-based. 
    case DiscreteStates.STATE_SOURCE_CLICKOVERTARGET %SNF: this state is not multiclick-friendly.        
        clickLabels_temp = (onTarget + aboveThresh)/2;
        % ambiguous bins are at .5; unambiguous non-click bins are 0;
        % and unambiguous click bins are 1
        isAmbiguous = clickLabels_temp == 0.5;
         % now that ambiguous bins have been identified, make clickLabels 
        % the usual logical (1s for click, 0s for both non-click and 
        % ambiguous bins - the latter is default behavior, but if 
        % excludeAmbiguousData is on, ambiguous bins will be chopped downstream):
        clickLabels = logical(floor(clickLabels_temp));
end

% irrespective of clickSource, identify any click data points beyond max 
% click length: 
if options.maxClickLength
    % maximum number of continguous bins a click can occur for 
    maxClickBins = ceil(options.maxClickLength / options.binSize);

   % clickStateChanges = diff([0;clickLabels(:);0]); %original
    clickStateChanges = diff([0;logical(clickLabels(:));0]); %SNF modifying for multiclick
    %this is fine to be logical because we're just interested in click/non
    %click transitions, not click-type-specific wonkyness 
    clickStarts = find(clickStateChanges==1);   %in 15 ms bins (not ms)
    clickEnds = find(clickStateChanges==-1) - 1;  %note from BJ: clickEnds was previously the bin at the beginning of next non-click period; -1 makes it the actual last bin of each click period

    longClicks = find(clickEnds-clickStarts>maxClickBins); %converting to indices so we can loop through only long clicks below.

    if ~isempty(longClicks)
        clickEnds_prev = clickEnds;  %previous click ends (some of which are long)
        clickEnds(longClicks) = clickStarts(longClicks)+maxClickBins; %new click ends (long clicks will now end maxClickBins after start of each click)

        for lc = longClicks',
            indsBeyondMaxLength_c{lc} = clickEnds(lc,1):clickEnds_prev(lc,1);
        end
        indsBeyondMaxLength = cell2mat(indsBeyondMaxLength_c);
        beyondMaxLength = false(size(clickLabels));
        beyondMaxLength(indsBeyondMaxLength) = true;  %now logical array
        %SNF verifies that it's okay to have doubles and falses in the same
        %clickLabels vector. 
        clickLabels(beyondMaxLength) = false; %by default, turn bins after 
        % maxLength to non-click. If options.excludeAmbiguousData is true,
        % these bins will get chopped downstream. 
    end
end

binsToChop = isAmbiguous | beyondMaxLength;

        
%previously (in multiple places throughout click decoder build pipe):
% switch options.clickSource
%   case DiscreteStates.STATE_SOURCE_CLICK
%     clickTimes = [D.clickState]>options.clickStateThreshold;
%   case DiscreteStates.STATE_SOURCE_DWELL
%     clickTimes = [D.dwellState]>options.clickStateThreshold;
%   case DiscreteStates.STATE_SOURCE_CLICKOVERTARGET
%     clickTimes = [D.overTargetState]>options.clickStateThreshold & [D.clickState]>options.clickStateThreshold;
% end
