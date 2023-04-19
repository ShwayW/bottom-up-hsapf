function cc = connectedComponents(map)
%% Labels the map with connected components
% Vadim Bulitko
% May 12, 2020

% arguments 
%     map (:,:) logical
% end

%% Preliminaries
cc = zeros(size(map),'int64');
cc(map) = -1;  % walls
cI = int64(1);
%% As long as there are open cells, flood fill
while (true)
    % find still unlabeled cells
    a = find(cc == 0);
    
    if (isempty(a))
        % labeled everything: done
        break
    end
    
    % pick one of them at random
    i = a(randi(length(a)));
    
    % flood fill from it
    cc = floodFill(cc,i,cI);
    cI = cI + 1;
end

end


function cc = floodFill(cc,i,ccI)
%% Floods fills from a given index i
% Vadim Bulitko
% May 12, 2020

% arguments
%     cc (:,:) int64
%     i (1,1) double
%     ccI (1,1) int64
% end

%% Preliminaries
mapHeight = size(cc,1);
childrenI = int64([mapHeight 1 -mapHeight -1]);

% set up the frontier
frontierMaxSize = uint64(numel(cc));
frontier = zeros(1,frontierMaxSize,'int64');
fStartI = uint64(1);
fNextI = uint64(2);
frontier(fStartI) = int64(i);
cc(i) = ccI;
%% Run BFS from the initial state
while (fStartI ~= fNextI)
    % pop the state from the frontier
    i = frontier(fStartI);
    fStartI = fStartI + 1;
    if (fStartI > frontierMaxSize)
        fStartI = uint64(1);
    end
    
    % expand the state i
    childI = i + childrenI;
    
    % keep unlabeled children
    childI = childI(cc(childI) == 0);
    
    % label them with the connected component index
    cc(childI) = ccI;
    
    % append them to the frontier
    for cI = 1:length(childI)
        frontier(fNextI) = childI(cI);
        fNextI = fNextI + 1;
        if (fNextI > frontierMaxSize)
            fNextI = uint64(1);
        end
    end
end

end


%% ----------------- The following version works too but is much slower due to MATLAB list shrinking/growing operations
% function cc = floodFill(cc,i,cI)
% %% Floods fills from a given index
% % Vadim Bulitko
% % May 12, 2020
% 
% arguments
%     cc (:,:) int64
%     i (1,1) double
%     cI (1,1) int64
% end
% 
% %% Preliminaries
% mapHeight = size(cc,1);
% childrenOffset = [mapHeight 1 -mapHeight -1];
% 
% openList = i;
% 
% %% BFS
% while (~isempty(openList))
%     % remove the head of the open list
%     i = openList(1);
%     openList = openList(2:end);
%     
%     % mark it in the map
%     cc(i) = cI;
%     
%     % generate its children
%     iN = i + childrenOffset;
%     
%     % remove children that are already labeled
%     iN = iN(cc(iN) == 0);
%     
%     % add the remaining children to the open list
%     openList = [openList iN]; %#ok<AGROW>
% end
%     
% end
