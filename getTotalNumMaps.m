function totalMapNum = getTotalNumMaps(mapSetNames)
%% Compute the total number of maps in all sets from mapSetNames
% Shway Wang
% June 13, 2022

arguments
    mapSetNames (1,:) string
end

% initialize the map counter
totalMapNum = 0;

for setI = 1:length(mapSetNames)
    % construct the folder name
    mapSetNameChar = char(mapSetNames(setI));
    folderName = sprintf("./maps/%s/%s", mapSetNameChar(1:end-1), mapSetNameChar);

    % read in the image from the path specified by inFolder
    folderInfo = dir(folderName);
    
    % want only the map files
    endsMap = endsWith({folderInfo.name}, '.map');
    folderInfo = folderInfo(endsMap);
    
    % count to the total number of maps
    totalMapNum = totalMapNum + length({folderInfo.name});
end
end