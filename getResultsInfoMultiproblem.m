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
    "/home/shway/Desktop/vadim_research/workspace/experiments/multiproblems/sep_15/brc501d/noreg";

% define the save path
savePath = sprintf("%s/resultsInfo.mat", experimentFolder);

tic
% get the names of the subfolders
problemsFolderNames = getSubfolderNames(experimentFolder);

%% Get and save the average number of nodes, test losses and their std arrays
% compute the average number of nodes
[avgNumNodesArr, numNodesStdArr] = computeAvgNumNodes(problemsFolderNames);

% compute the average test losses on all maps
[avgAllMapsTestLossArr, allMapsTestLossStdArr] = computeAvgTestLossAllMaps(problemsFolderNames);

% compute the average test losses on home maps
[avgHomeMapsTestLossArr, homeMapsTestLossStdArr] = computeAvgTestLossHomeMaps(problemsFolderNames);

% compute the average training losses on home maps
[avgHomeMapsTrainLossArr, homeMapsTrainLossStdArr] = computeAvgTrainLossHomeMaps(problemsFolderNames);

% save the results information into the savePath
save(savePath, 'avgNumNodesArr', 'numNodesStdArr', 'avgAllMapsTestLossArr', 'allMapsTestLossStdArr',...
    'avgHomeMapsTestLossArr', 'homeMapsTestLossStdArr', 'avgHomeMapsTrainLossArr', 'homeMapsTrainLossStdArr');
toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [avgNumNodesArr, numNodesStdArr] = computeAvgNumNodes(problemsFolderNames)
%% compute the average number of nodes
% Shway Wang
% April 19, 2022

arguments
    problemsFolderNames (1, :) string
end

% initialize the return values
avgNumNodesArr = zeros(1, length(problemsFolderNames));
numNodesStdArr = zeros(1, length(problemsFolderNames));

% loop to compute average nodes in each maps folder
for problemsI = 1:length(problemsFolderNames)
    % construct whole paths
    folder = problemsFolderNames(problemsI);
    tmp = getSubfolderNames(folder);
    setsFolderNames = getSubfolderNames(tmp);
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
    avgNumNodesArr(problemsI) = mean(numNodesArr);
    numNodesStdArr(problemsI) = std(numNodesArr);
end
end


function [avgAllMapsTestLossArr, allMapsTestLossStdArr] = computeAvgTestLossAllMaps(problemsFolderNames)
%% compute the average test losses
% Shway Wang
% April 19, 2022

arguments
     problemsFolderNames (1, :) string
end

% initialize the return values
avgAllMapsTestLossArr = zeros(1, length(problemsFolderNames));
allMapsTestLossStdArr = zeros(1, length(problemsFolderNames));

% loop to compute average test loss in each maps folder
for problemsI = 1:length(problemsFolderNames)
    % construct whole paths
    folder = problemsFolderNames(problemsI);
    tmp = getSubfolderNames(folder);
    setsFolderNames = getSubfolderNames(tmp);
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
    avgAllMapsTestLossArr(problemsI) = mean(testLossArr);
    allMapsTestLossStdArr(problemsI) = std(testLossArr);
end
end


function [avgHomeMapsTestLossArr, homeMapsTestLossStdArr] = computeAvgTestLossHomeMaps(problemsFolderNames)
%% compute the average test losses on home maps
% Shway Wang
% April 19, 2022

arguments
     problemsFolderNames (1, :) string
end

% initialize the return values
avgHomeMapsTestLossArr = zeros(1, length(problemsFolderNames));
homeMapsTestLossStdArr = zeros(1, length(problemsFolderNames));

% loop to compute average test loss in each maps folder
for numProblemsI = 1:length(problemsFolderNames)
    % construct whole paths
    mapsFolder = problemsFolderNames(numProblemsI);
    tmp = getSubfolderNames(mapsFolder);
    setsFolderNames = getSubfolderNames(tmp);
    
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
    avgHomeMapsTestLossArr(numProblemsI) = mean(testLossArr);
    homeMapsTestLossStdArr(numProblemsI) = std(testLossArr);
end
end

function [avgHomeMapsTrainLossArr, homeMapsTrainLossStdArr] = computeAvgTrainLossHomeMaps(problemsFolderNames)
%% compute the average training losses on home maps
% Shway Wang
% Sep 10, 2022

arguments
     problemsFolderNames (1, :) string
end

% initialize the return values
avgHomeMapsTrainLossArr = zeros(1, length(problemsFolderNames));
homeMapsTrainLossStdArr = zeros(1, length(problemsFolderNames));

% loop to compute average test loss in each maps folder
for numProblemsI = 1:length(problemsFolderNames)
    % construct whole paths
    mapsFolder = problemsFolderNames(numProblemsI);
    tmp = getSubfolderNames(mapsFolder);
    setsFolderNames = getSubfolderNames(tmp);
    
    % want to compute mean of the 4 trial folders
    trainLossArr = [];
    
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
            disp(singleRunResult.bestSynthResults(5).alg);
            for homeMapI = homeMapsIndicesArr
                trainLoss = singleRunResult.bestSynthResults(homeMapI).psfLoss;
                tmpArr = [tmpArr, trainLoss]; %#ok<AGROW>
            end
            
            % add one entry to the testLossArr
            trainLossArr = [trainLossArr, mean(tmpArr)]; %#ok<AGROW>
        end
    end
    
    % append the mean and std of number of nodes to the return arrays
    avgHomeMapsTrainLossArr(numProblemsI) = mean(trainLossArr);
    homeMapsTrainLossStdArr(numProblemsI) = std(trainLossArr);
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

