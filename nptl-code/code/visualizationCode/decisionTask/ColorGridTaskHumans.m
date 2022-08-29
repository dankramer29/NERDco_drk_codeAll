% Psychtoolbox script to generate Red and Green Squares to display the
% grids
%
% CC - Feb 28th 2012 -
Events = 'internal';
nlevels = 14;
ntrials = 20;
nblocks = 2;
totaltrials = nlevels*ntrials;

whichScreen = 0;
window = Screen(whichScreen, 'OpenWindow');
[width, height]=Screen('WindowSize', window);
white = WhiteIndex(window); % pixel value for white
black = BlackIndex(window); % pixel value for black
gray = (black + white)/2;

Screen(window,'FillRect',gray);
Screen('TextStyle',window,0)
DrawFormattedText(window,'This experiment has 2 blocks of approximately 300 trials each. \n Please press a button to continue',width/2-100,height/2-20);
Screen(window,'flip');
keyIsDown = 0;
while(~keyIsDown)
    [keyIsDown, secs, keyCode] = KbCheck;
end


exitflag = 0;
GlobalTrials = [];
money = 0;
for blockid = 1:nblocks
    ProbDist = GenerateProbabilityDist(nlevels,ntrials);
    TrialIndex = [];
    
    
    for trialid = 1:totaltrials
        DrawFixationCross(window,width,height);
        [VBLTimestamp FixOnsetTime FlipTimestamp] = Screen(window,'flip',0,0,1);
        [VBLTimestamp FixOnsetTime FlipTimestamp]
        WaitSecs(1 + rand);
        [CorrectResponse] = DrawGridOnSecondaryBuffer(window,width,height,ProbDist(trialid));
        DrawFixationCross(window,width,height);
        N = tic;
        [VBLTimestampGrid GridOnsetTime GridFlipTimestamp] = Screen(window,'flip',0,0,1);
        FlushEvents(['mouseUp'],['mouseDown'],['keyDown']);
        keyIsDown = 0; t = 0; refreshed = false;
        DrawFixationCross(window,width,height);
        
        timev = GetSecs;
        FlushEvents('keyDown');
        Screen(window, 'FillRect', gray);
        while(~keyIsDown && 1000*(GetSecs - timev) < 2000)
            WaitSecs(0.004);
            [keyIsDown, secs, keyCode] = KbCheck;
            %             if 1000*(GetSecs - timev) > 100
            %                 Screen(window,'flip',0,0,1);
            %             end
        end
        refreshed = true;
        
        Screen(window, 'FillRect', gray);
        DrawFixationCross(window,width,height);
        if ~isempty(find(keyCode))
            if find(keyCode) ~= 25
                TrialIndex(trialid,:) = [ProbDist(trialid) CorrectResponse find(keyCode) toc(N) secs - GridFlipTimestamp];
                if CorrectResponse == find(keyCode)
                    DrawFormattedText(window,'+100',width/2-50,height/2+50);
                    money = money + 100;
                else
                    DrawFormattedText(window,'-100',width/2-50,height/2+50);
                    money = money - 100;
                end
                
            else
                exitflag = 1;
                break;
            end
        else
            TrialIndex(trialid,:) = [ProbDist(trialid) CorrectResponse -1 toc(N) secs - GridFlipTimestamp];
        end
        Screen(window,'flip');
        Screen(window, 'FillRect', gray);
        WaitSecs(0.6);
        Screen(window,'flip');
        WaitSecs(0.4);
    end
    GlobalTrials = [GlobalTrials; TrialIndex];
    if ~exitflag
        Screen(window,'FillRect',gray);
        DrawFormattedText(window,'Please take a short break \n Press any key to Continue',200,200);
        Screen(window,'flip');
    else
        break;
    end
    keyIsDown = 0;
    while(~keyIsDown)
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    
    
end

Screen('CloseAll');
