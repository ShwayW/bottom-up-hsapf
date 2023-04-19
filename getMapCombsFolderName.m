function directoryName = getMapCombsFolderName(parentFolderName, mapsIArr, maxSets)
%% get and create (not not exist) the folder for synthesis results from the
%% combination of maps specified by mapsIArr inside the folder specified by
%% parantFolderName
% Shway Wang
% April 25, 2022

%% Arguments
arguments
    parentFolderName (1, :) char
    mapsIArr (1, :) uint64
    maxSets (1,1) uint64
end

%% Preliminaries
% assume that the parent folder exists
assert(isfolder(parentFolderName));

%% Scan all subfolders of the parentFolder for the one with matching map indices with mapsIArr
% get all files inside parent folder
d = dir(parentFolderName);
subFolderNames = {d.name}';

% filter out folders "." and "..", make the results a row vector
subFolderNames = subFolderNames(~(eq(subFolderNames, ".") | eq(subFolderNames, "..")))';

% generate the name of the txt file containing the indices of the maps
folderExists = false;
for subFolderNameI = 1:length(subFolderNames)
    subFolderName = subFolderNames(subFolderNameI);
    mapsIndicesTextFileName = sprintf('%s/%s/homeMapsIndices.txt', parentFolderName, subFolderName{1});
    mapsIndicesTextFileID = fopen(mapsIndicesTextFileName, 'r');
    mapInds = fscanf(mapsIndicesTextFileID, '%d');
    fclose(mapsIndicesTextFileID);
    
    if (isequal(mapInds', mapsIArr))
        % correct folder exists, break the loop
        folderExists = true;
        mapsCombinationName = subFolderNames(subFolderNameI);
        mapsCombinationName = mapsCombinationName{1};
        break;
    end
end

%% If such folder exists, return the name of it
if (folderExists)
    % generate the entire directory name
    directoryName = sprintf("%s/%s", parentFolderName, mapsCombinationName);
else
%% If such folder does not exist, create a new folder and create a txt file in it and write mapsIArr to it
    % maps folder index, start from 1
    mapSetI = length(dir(parentFolderName)) - 1;

    % generate the run set name string
    directoryName = sprintf("%s/map_set_%s", parentFolderName, getIndStrByMaxInd(mapSetI, maxSets));

    % make the directory if necessary
    if(~(isfolder(directoryName)))
        mkdir(directoryName);
    end

    % create (if not exist) the text file to store the maps used for synthesis
    % in the maps combination folder
    mapsIndicesTextFileName = sprintf('%s/homeMapsIndices.txt', directoryName);
    mapsIndicesTextFileNameID = fopen(mapsIndicesTextFileName, 'w');
    fprintf(mapsIndicesTextFileNameID, '%d ', mapsIArr);
    fclose(mapsIndicesTextFileNameID);
end
end

