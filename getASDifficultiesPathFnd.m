function [aStarDifficulty, statesExpanded] = getASDifficultiesPathFnd(map, problems)
%% Compute A*+MD difficulties for all problems on a given map
% Shway Wang
% Oct 11, 2021
% debugged and simplified by Vadim Bulitko
% Apr 18, 2022

%% Argument types and default parameters
arguments
    map (:,:) logical   % the single map
    problems (1,1) struct % problems on it
end

%% Set up alg as A* + MD
alg.param = [1, 1, 0, nan(1, 10)];
alg.hct = "(+ deltaX deltaY)";
alg.hH = str2func(['@(x1,y1,x2,y2)' convertStringsToChars(hct2str(alg.hct))]);

%% Compute the number of states expanded by A*+MD for each problem
numGoals = length(problems.goalIndx);
numStartsPerGoal = size(problems.startIndx, 2);
statesExpanded = zeros(numGoals, numStartsPerGoal,'int64');

for goalI = 1:numGoals
    % put in the initial h for that goal
    goalIndx = problems.goalIndx(goalI);
    h = putInInitialHpathFnd(map, alg.hH, goalIndx);

    % run A* + MD on all start states for that goal
    [~, statesExpanded(goalI,:), ~] = evaluateAHsingleGoal(map, problems.startIndx(goalI, :),...
        goalIndx, h, alg);
end

%% Compute A* difficulty
aStarDifficulty = double(statesExpanded) ./ double(problems.optimalCosts);
end