% Tests the lessBiasedDistance.m based on the approach described in the supplementary
% methods of Willett*, Deo*, et al 2019(?) movement sweep manuscript.
% 


numTrials_A = 20;
numTrials_B = 20;

D = 100; % dimensionality of the vectors
N = 100; % number of repetitions for each point in try_D
% try_d = 0 : 0.1 : 10; % which values of d (distance between the distributions) to try.
try_d = 0 : 0.5 : 3; % which values of d (distance between the distributions) to try.

% try_d = 0; % which values of d (distance between the distributions) to try.


distances_conventional = nan( N, numel( try_d ) ); % samples x d values
distances_unbiased = nan( N, numel( try_d ) ); % samples x d values
distances_unbiasedOriginal = nan( N, numel( try_d ) ); % samples x d values
distances_unbiasedSametrials = nan( N, numel( try_d ) ); % samples x d values; I'm curious as to how the function works when it's fed the *same* trials in (self comparison)
for iD = 1 : numel( try_d )
    d = try_d(iD);

    fprintf('d=%g\n', d )
    for iN = 1 : N
        % Generate distribution A
        A = randn(D,numTrials_A);
        % Generate distribution B
        B = d / sqrt(D) + randn(D,numTrials_B);
        
        % conventional distance
        distances_conventional(iN,iD) = norm( mean(A,2)- mean(B,2) );
        % Unbiased distance
        distances_unbiased(iN,iD) = lessBiasedDistance2(A', B');
        
        % Unbiased distance, original code
        distances_unbiasedOriginal(iN,iD) = lessBiasedDistance(A', B');
        
        % Distance within the same data
        % shuffle the trials or else it just gives 0
        Ashuffle = A(:, randperm(numTrials_A));
       distances_unbiasedSametrials(iN,iD) = lessBiasedDistance(A', Ashuffle'); % need to modify it to do the 'Sergey' way even if same number of trials

    end
    
    % Uncomment below to show scatter plot of distances for both methods
%     figh = figure;
%     scatter( distances_unbiased(:,iD), distances_unbiasedOriginal(:,iD) )
%     xlabel('Unbiased (Sergey)');
%     ylabel('Unbiased (Frank)');
    
end

figh = figure;
hold on;
meanConventional = mean( distances_conventional );
stdConventional = std( distances_conventional );
meanUnbiased = mean( distances_unbiased );
stdUnbiased = std( distances_unbiased );
lh = plot( try_d, meanConventional, 'Color', 'r', 'LineWidth', 1.5);
lh = plot( try_d, meanUnbiased, 'Color', 'b', 'LineWidth', 1.5);

lh = plot( try_d, meanConventional+stdConventional, 'Color', 'r', ...
    'LineStyle', ':', 'LineWidth', 0.5);
lh = plot( try_d, meanConventional-stdConventional, 'Color', 'r', ...
    'LineStyle', ':', 'LineWidth', 0.5);

lh = plot( try_d, meanUnbiased+stdUnbiased, 'Color', 'r', ...
    'LineStyle', ':', 'LineWidth', 0.5);
lh = plot( try_d, meanUnbiased-stdUnbiased, 'Color', 'r', ...
    'LineStyle', ':', 'LineWidth', 0.5);

axis equal
xlim( [min( try_d ), max( try_d )] );
ylim( [-2, max( try_d )+5] );
line( [min( try_d ), max( try_d )], [min( try_d ), max( try_d )], 'Color', 'k')
title( sprintf('%i and %i Trials', numTrials_A, numTrials_B ) )
legend( {'Conventional', 'Unbiased'} )



%% Plot same-trials metric
meanSametrial= mean( distances_unbiasedSametrials );
stdSametrial = std( distances_unbiasedSametrials );
figh = figure;
lh = plot( try_d, meanSametrial, 'Color', 'g', 'LineWidth', 1.5); hold on
lh = plot( try_d, meanSametrial+stdSametrial, 'Color', 'g', ...
    'LineStyle', ':', 'LineWidth', 0.5);
lh = plot( try_d, meanSametrial-stdSametrial, 'Color', 'g', ...
    'LineStyle', ':', 'LineWidth', 0.5);
legend( {'Same group of trials'} )

%% Dividing by sqrt(D) keeps firing rates intuitive (like single electrode)
% D = 10;
% X = 2.3.*ones(D,1);
% norm(X)/sqrt(D)