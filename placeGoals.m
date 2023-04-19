function gI = placeGoals(mapSize,cc)
%% Places four goals in the corners of the connected component given
% Vadim Bulitko
% June 4, 2020

% arguments
%     mapSize (1,2) double
%     cc (1,:) int64
% end

%% Preliminaries
numGoals = 4;
gI = zeros(1,numGoals,'int64');

%% Define indecies of the four corners
mapCorners = [
    sub2ind(mapSize,1,1),...
    sub2ind(mapSize,1,mapSize(2)),...
    sub2ind(mapSize,mapSize(1),mapSize(2)),...
    sub2ind(mapSize,mapSize(1),1)];
    
%% Pick the closest member of the connected component
for i = 1:numGoals
    % compute all MD distances between a given corner and all states in the connected component
    md = mdS(mapSize,cc,mapCorners(i));
    
    % pick the closest one
    [~,j] = min(md);
    
    % set it as our goal
    gI(i) = cc(j);
end

end
