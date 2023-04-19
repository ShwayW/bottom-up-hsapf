%% Get average number of nodes of code trees, test losses over all maps
% and test losses on home maps from synthesis results
% Shway Wang
% April. 4th, 2022

close all;
clear;
clc;
diary off;

%% Preliminaries
warning('off','MATLAB:graphics:axestoolbar:PrintWarning');
warning('off','MATLAB:print:ContentTypeImageSuggested');

% path to the experiment results
experimentFolder =...
    "/home/shway/Desktop/vadim_research/workspace/experiments/oct_15_2022";

% define the save path
savePath = sprintf("%s/resultsInfo.mat", experimentFolder);

tic
% get the names of the subfolders
mapsFolderNames = getSubfolderNames(experimentFolder);

%% Get and save the average number of nodes, test losses and their std arrays
% compute the average number of nodes
[avgNumNodesArr, numNodesStdArr] = computeAvgNumNodes(mapsFolderNames);

% compute the average test losses on all maps
[avgAllMapsTestLossArr, allMapsTestLossStdArr] = computeAvgTestLossAllMaps(mapsFolderNames);

% compute the average test losses on home maps
[avgHomeMapsTestLossArr, homeMapsTestLossStdArr] = computeAvgTestLossHomeMaps(mapsFolderNames);

% save the results information into the savePath
save(savePath, 'avgNumNodesArr', 'numNodesStdArr', 'avgAllMapsTestLossArr', 'allMapsTestLossStdArr',...
    'avgHomeMapsTestLossArr', 'homeMapsTestLossStdArr');
toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [avgNumNodesArr, numNodesStdArr] = computeAvgNumNodes(mapsFolderNames)
%% compute the average number of nodes
% Shway Wang
% April 19, 2022

arguments
    mapsFolderNames (1, :) string
end

% initialize the return values
avgNumNodesArr = zeros(1, length(mapsFolderNames));
numNodesStdArr = zeros(1, length(mapsFolderNames));

% loop to compute average nodes in each maps folder
for mapsI = 1:length(mapsFolderNames)
    % construct whole paths
    folder = mapsFolderNames(mapsI);
    setsFolderNames = getSubfolderNames(folder);
    numNodesArr = [];
    
    % loop to compute average nodes in each map set folder
    for setsI = 1:length(setsFolderNames)
        folder = setsFolderNames(setsI);
        runsFolderNames = getSubfolderNames(folder);
        
        % loop to compute average nodes in each run folder
        for runFolderI = 1:length(runsFolderNames)
            resultName = sprintf("%s/bestSynthesized.mat", runsFolderNames(runFolderI));
            singleRunResults = load(resultName);

            % this is results of multi-map synthesis, so all formulae are the same
            numNodes = hctSize(singleRunResults.bestSynthResults(1).alg.hct);
            numNodesArr = [numNodesArr, numNodes]; %#ok<AGROW>
        end
    end
    % append the mean and std of number of nodes to the return arrays
    avgNumNodesArr(mapsI) = mean(numNodesArr);
    numNodesStdArr(mapsI) = std(numNodesArr);
end
end


function [avgAllMapsTestLossArr, allMapsTestLossStdArr] = computeAvgTestLossAllMaps(mapsFolderNames)
%% compute the average test losses
% Shway Wang
% April 19, 2022

arguments
     mapsFolderNames (1, :) string
end

% initialize the return values
avgAllMapsTestLossArr = zeros(1, length(mapsFolderNames));
allMapsTestLossStdArr = zeros(1, length(mapsFolderNames));

% loop to compute average test loss in each maps folder
for mapsI = 1:length(mapsFolderNames)
    % construct whole paths
    folder = mapsFolderNames(mapsI);
    setsFolderNames = getSubfolderNames(folder);
    testLossArr = [];
    
    % loop to compute average nodes in each map set folder
    for setsI = 1:length(setsFolderNames)
        folder = setsFolderNames(setsI);
        runFolderNames = getSubfolderNames(folder);
    
        % loop to compute average nodes in each run folder
        for runI = 1:length(runFolderNames)
            resultName = sprintf("%s/bestSynthesized.mat", runFolderNames(runI));
            singleRunResults = load(resultName);
            testLossArr = [testLossArr, mean([singleRunResults.bestSynthResults.testLoss])]; %#ok<AGROW>
        end
    end
    
    % append the mean and std of number of nodes to the return arrays
    avgAllMapsTestLossArr(mapsI) = mean(testLossArr);
    allMapsTestLossStdArr(mapsI) = std(testLossArr);
end
end


function [avgHomeMapsTestLossArr, homeMapsTestLossStdArr] = computeAvgTestLossHomeMaps(mapsFolderNames)
%% compute the average test losses on home maps
% Shway Wang
% April 19, 2022

arguments
     mapsFolderNames (1, :) string
end

% initialize the return values
avgHomeMapsTestLossArr = zeros(1, length(mapsFolderNames));
homeMapsTestLossStdArr = zeros(1, length(mapsFolderNames));

% loop to compute average test loss in each maps folder
for numMapsI = 1:length(mapsFolderNames)
    % construct whole paths
    mapsFolder = mapsFolderNames(numMapsI);
    setsFolderNames = getSubfolderNames(mapsFolder);
    
    % want to compute mean of the 4 trial folders
    testLossArr = [];
    
    % loop to compute average nodes in each map set folder
    for setI = 1:length(setsFolderNames)
        % get each run folders of each set folder
        setFolder = setsFolderNames(setI);
        runFolderNames = getSubfolderNames(setFolder);
    
        % extract the home maps combination of current set folder
        homeMapsIndicesPath = sprintf("%s/homeMapsIndices.txt", setFolder);
        
        % read in the content of the file specified by homeMapsIndicesPath
        homeMapsIndicesArr = readAllLinesFromPath(homeMapsIndicesPath);
        
        % loop to compute average nodes in each run folder
        for runI = 1:length(runFolderNames)
            % get the results in each of the run folders
            resultName = sprintf("%s/bestSynthesized.mat", runFolderNames(runI));
            singleRunResult = load(resultName);

            % put the home map test losses into test loss arrays
            tmpArr = [];
            for homeMapI = homeMapsIndicesArr
                testLoss = singleRunResult.bestSynthResults(homeMapI).testLoss;
                tmpArr = [tmpArr, testLoss]; %#ok<AGROW>
            end
            
            % add one entry to the testLossArr
            testLossArr = [testLossArr, mean(tmpArr)]; %#ok<AGROW>
        end
    end
    
    % append the mean and std of number of nodes to the return arrays
    avgHomeMapsTestLossArr(numMapsI) = mean(testLossArr);
    homeMapsTestLossStdArr(numMapsI) = std(testLossArr);
end
end

function homeMapsIndicesArr = readAllLinesFromPath(mapsIndicesPath)
%% Read all lines from a file specified by mapsIndicesPath, close the file in the end
% Shway Wang
% June 6, 2022

arguments
    mapsIndicesPath (1,1) string
end

% initialize the return value
homeMapsIndicesArr = [];

fileID = fopen(mapsIndicesPath, 'r');
while (true)
    % read a line
    mapIndsArr = fgetl(fileID);
    
    % if end of file is reached, break the loop
    if (mapIndsArr < 0)
        break;
    end
    
    % conver the line to an integer array and append it to mapI_cell_arr
    homeMapsIndicesArr = [homeMapsIndicesArr, str2num(mapIndsArr)]; %#ok<AGROW,ST2NM>
end
fclose(fileID);
end

