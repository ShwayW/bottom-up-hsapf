function [startI, hsStart] = generateRandomStart(hStar, prevStartI)
% Generates a random solvable problem given h*
% Vadim Bulitko
% Feb 4, 2020

%% Argument types and default parameters
arguments
    hStar (:,:) int64
    prevStartI (1,:) int64
end

%% Pick a random position reachable from the the goal
n = numel(hStar);
% walls and unreachable cells are -1 and the goal is 0. Everything else represents a valid reachable cell
startI = randi(n);
while (hStar(startI) <= 0 || ismember(startI, prevStartI))
    startI = randi(n);
end

% %% Find all positions which are:
% % 1. connected to the goal under maxHS
% % 2. not the goal
% reachableI = find(hStar ~= -1 & hStar ~= 0);
% 
% %% Pick one of them at random
% startI = reachableI(randi(length(reachableI)));

%% Get the cost of the optimal solution
hsStart = hStar(startI);

end