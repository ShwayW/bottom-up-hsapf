function [ah, runningBest] = updateHistoricalBest(ahPair, timeElapsed, showGlobalBest)
%% returns the updated historical best ah pair and its ps2loss to be the new running best loss
% Shway Wang
% May 6, 2022

arguments
    ahPair (1,1) struct
    timeElapsed (1,1) double
    showGlobalBest (1,1) logical = false
end

% runningBest is a regloss
runningBest = ahPair.regloss;

% if running best updated, the historical champion is updated too
ah.champion = true;

% record the synthesis time it takes to get this pair
ah.totalTime = timeElapsed;

% retrieve the current best algorithm
ah.alg = ahPair.alg;

% evaluate the current pair on ps
ah.regloss = ahPair.regloss;

% print out current best ah pair if the flag showChampion is set to true
if (showGlobalBest)
	hStr = hct2latex(ahPair.alg.hct);
    fprintf('\nCurrent best:\n');
    fprintf('%s\n', hStr);
    fprintf('current best training loss: %f\n\n', runningBest);
end
end