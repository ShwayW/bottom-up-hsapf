function [travel, expanded, solved] = evaluateAHsingleGoal(map, startIndecies, goalIndex, h, alg)
%% Evaluate A+H for a single goal
% Vadim Bulitko
% Jan 24, 2021

%% Argument types
arguments
    map (:,:) logical
    startIndecies (1,:) int64
    goalIndex (1,1) int64
    h (:,:) int64
    alg (1,1) struct
end

%% Preliminaries
numStarts = length(startIndecies);
travel = zeros(1, numStarts, 'int64');
expanded = zeros(1, numStarts, 'int64');
solved = false(1, numStarts);

mapSize = size(map);
mapHeight = mapSize(1);
childrenI = int64([mapHeight 1 -mapHeight -1]);

%% Run A+H for each problem
str = param2str(alg.param); 
for i = 1:numStarts
    [travel(i), expanded(i), solved(i)] = mexAstarPathFnd(map, childrenI, startIndecies(i), goalIndex, h, str);
end
end
