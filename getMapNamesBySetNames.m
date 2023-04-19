function mapNames = getMapNamesBySetNames(setNames)
%% Get all names of maps given the map set names
% Shway Wang
% April 27, 2022

arguments
    setNames (1, :) string
end

% initialize return value
mapNames = [];

% loop to get all map names in each map set
for setNameI = 1:length(setNames)
    test.problemFileName = sprintf('problems/pathfinding/%s-100x100.mat', setNames(setNameI));
    tmp = load(test.problemFileName, 'mapNames');
    [~, mapName, ~] = fileparts(tmp.mapNames);
    mapNames = [mapNames; convertCharsToStrings(mapName)]; %#ok<AGROW>
end
end