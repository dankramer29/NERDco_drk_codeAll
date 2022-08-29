% SortTrialsBy3DpreviousTarget.m
%
% 3-D analog of SortTrialsByPreviousTarget.m. Designed to work on NPTL R structs.
% Looks at the previous target. If it doesnt exist (can happen for first trial of a block)
%returns a nan.
%
% USAGE: [ targetIdx, uniqueTargets, angle, distFromZero ] = SortTrialsBy3DpreviousTarget( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         NPTL R struct to operate on. Contains N trials.
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     targetIdx                 Nx1 vector giving the target index for each trial
%     uniqueTargets              Matrix where each row contains one of the unique targets.
%                               The row index corresponds to a target index that <targetIdx>
%                               refers to.
%     angle                     Gives angle (assuming 0,0 origin) of each target.
%                               Often useful. angle is [XY, YZ]
%     distFromZero              How far each target is from 0,0,0.
%
% Created by Sergey Stavisky on 17 March 2017

function [ targetIdx, uniqueTargets, angle, distFromZero ] = SortTrialsBy3DpreviousTarget( R, varargin )
    
    allTargets = arrayfun( @(x) x.lastPosTarget', R, 'UniformOutput', false )';
    invalidTrials = cellfun(@(x) size(x,2), allTargets ) < 3;

    % keep only 3D coordinate
    allTargetsTmp = cell2mat( allTargets(~invalidTrials) );
    allTargetsTmp = double( allTargetsTmp(:,1:3) );
    uniqueTargets = unique( allTargetsTmp, 'rows');
    
    % Put back in the invalid trial
    allTargets = nan( numel( R ), 3 );
    allTargets(~invalidTrials,:) = allTargetsTmp;
    %% Re-order sensibly
    % It's also convenient to order the targets by their direction (makes
    % for meaningful order in radial tasks). Do this:
    theta = cart2pol( uniqueTargets(:,1), uniqueTargets(:,2) ); % XY
    % add 2pi to all negative values so we can have actual ordering
    theta(theta<0) = 2*pi+theta(theta<0);
    [angle sortIdx] = sort( theta ); %#ok<ASGLU>
    uniqueTargets = uniqueTargets(sortIdx,:);
    
    % [0,0,X] needs to be handled specially
    nanTargs = EqRow( uniqueTargets(:,1:2), [0,0] );
    angle(nanTargs) = nan;
    % put these first
    if any( nanTargs )
       nanifyOrder = 1 :  size( uniqueTargets, 1 );
       nanInds = find( nanTargs );
       nanifyOrder(nanInds) = [];
       % sort these nan inds by z coordinate
       nanZ = uniqueTargets(nanInds,3);
       [~,nanZorder] = sort( nanZ, 'ascend');
       nanInds = nanInds(nanZorder);
       nanifyOrder = [nanInds',nanifyOrder]; % nan inds go first
       % apply this order to full set
           angle = angle(nanifyOrder);
           uniqueTargets = uniqueTargets(nanifyOrder,:);
    end
    
    % within the same XY angle, they will be sorted from smallest to largest Z coordinate
    uniqueAngle = unique( angle );
    for iAngle = 1 : numel( uniqueAngle )
        % which targets are of this angle?
        myTargs = angle == uniqueAngle(iAngle);  
        % what are their z coordiante?
        myZ = uniqueTargets(myTargs,3);
        [~,zZortIdx] = sort( myZ , 'ascend'); 
        myTargsInds = find( myTargs );
        % reorder
        uniqueTargets(myTargs,:) = uniqueTargets(myTargsInds(zZortIdx) ,:);
    end
    
    %% Assign each target an index based on which uniqueTargets it belongs to
    targetIdx = nan( numel( R ), 1 );
    for iTarget = 1 :  size( uniqueTargets, 1 )
        targetIdx(EqRow( allTargets, uniqueTargets(iTarget,:) )) = iTarget;
    end
    
    %% Additional Info
    distFromZero = sqrt( sum( uniqueTargets(:,1:3).^2, 2 ) );
    thetaYZ = cart2pol( uniqueTargets(:,2), uniqueTargets(:,3) );
    thetaYZ(thetaYZ<0) = 2*pi+thetaYZ(thetaYZ<0);
    % [X,0,0] needs to be handled specially
    nanTargs = EqRow( uniqueTargets(:,2:3), [0,0] );
    thetaYZ(nanTargs) = nan;

    angle(:,2) = thetaYZ;
    

end