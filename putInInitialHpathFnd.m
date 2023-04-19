function hInt = putInInitialHpathFnd(map, hH, goalIndx)
%% Computes the initial h, using a function handle hH
% Returns an empty matrix if the given heuristic misbehaves
% Vadim Bulitko, Shway Wang
% Jan 14, 2020

%% Argument types and default parameters
arguments
    map (:,:) logical
    hH (1,1) function_handle
    goalIndx (1,1) int64
end

%% See if we are asked to compute h*
switch (func2str(hH))
    case ('@(x1,y1,x2,y2)hStar(x1,y1,x2,y2)')
        % put in h*
        hInt = computeHStar2_mex(map, goalIndx);
        hInt(map) = int64(Inf);
    otherwise
        % otherwise
        [goalY, goalX] = ind2sub(size(map), goalIndx);
        
        h = zeros(size(map));
        for y = 1:size(map,1)
            for x = 1:size(map,2)
                if (map(y,x))
                    % a wall
                    h(y,x) = Inf;
                else
                    % an open grid cell
                    % attempt to compute h
                    % catch any arithmetic errors that might appear here
                    h(y,x) = real(hH(x, y, goalX, goalY));
                end
            end
        end
        
        % convert to int64
        hInt = int64(round(h));
end
end
