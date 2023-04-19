function [problems, mapsFilled] = generateProblemsPathFnd(maps, numGoals, numStartsPerGoal)
%% Generate sets of problems for each map
% Vadim Bulitko
% June 4, 2020

arguments
    maps (1,:) cell
    numGoals (1,1) double = 100
    numStartsPerGoal (1,1) double = 100
end

%% Go through the maps
problems = cell(length(maps), 1);
mapsFilled = cell(length(maps), 1);

% loop to generate the problems
for mapI = 1:size(maps, 2)
    [problems{mapI}, mapsFilled{mapI}] = generateProblemsSingleMap(maps{mapI}, numGoals, numStartsPerGoal);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [problems, mapLCConly] = generateProblemsSingleMap(map, numGoals, numStartsPerGoal)
%% Generate a set of problems for a single map

arguments
    map (:,:) logical
    numGoals (1,1) double
    numStartsPerGoal (1,1) double
end

% Find the largest connected component
%lcc = computeLCC_mex(map);
lcc = computeLCC(map);

% fill in the rest of the map with walls
mapLCConly = map;
mapLCConly(setdiff(1:numel(map),lcc)) = true;

% Adjust the number of goals given the size of the connected component
numGoals = min(numGoals,length(lcc));

% Generate problems on this map
problems.startIndx = zeros(numGoals, numStartsPerGoal, 'int64');
problems.optimalCosts = zeros(numGoals, numStartsPerGoal, 'int64');
problems.goalIndx = zeros(numGoals, 1, 'int64');

% The goal loop
for gI = 1:numGoals
    % generate a unique random goal and compute h* for the map
    [goalI, hs]  = generateRandomGoal(map, lcc, problems.goalIndx(1:gI-1));
    
    % package it
    problems.goalIndx(gI) = int64(goalI);
    
    % the start loop
    for sI = 1:numStartsPerGoal
        % create a random solvable problem
        [startI,hsStart] = generateRandomStart(hs, problems.startIndx(gI, :));
        
        % package it
        problems.startIndx(gI, sI) = int64(startI);
        problems.optimalCosts(gI, sI) = int64(hsStart);
    end
end
end

