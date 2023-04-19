function [goalI, hStar] = generateRandomGoal(map,lcc,prevGoalI)
% Generates a random goal, different from goals given
% Vadim Bulitko
% Feb 4, 2020

%% Argument types and default parameters
arguments
    map (:,:) logical
    lcc (1,:) int64
    prevGoalI (1,:) int64 = []
end

%% Find all cells that are not walls and haven't been used before
openI = lcc;
if ~isempty(prevGoalI)
    openI = setdiff(lcc, prevGoalI, 'stable');
end

assert(~isempty(openI));

%% Pick one of them at random, make sure there are other states reachable from it
while (true)
    % pick a candidate
    goalI = openI(randi(length(openI)));
    
    % compute h* for it
    hStar = computeHStar2_mex(map, goalI);
    
    % are there any states reachable from it?
    if (any(hStar(:) > 0))
        break
    end
end

end
