function matrixNames = getResultFN(folderName)
%% Generates a list of file names for result files
% Vadim Bulitko
% Mar 26, 2021
% modified to analyze all maps synthesis results
% Shway Wang
% Jan 7, 2022

arguments
    folderName (1,:) char
end

% get all files inside that folder
d = dir(folderName);

% filter out folders
isub = [d(:).isdir];
fileName = {d(~isub).name}';

% filter out non .map files
prefix = sprintf('sahPSF_trial');

% get the actual map names
matrixNames = fileName(contains(fileName, prefix));

% prepend the folder name
if (folderName(end) ~= '/')
    folderName = [folderName '/'];
end

for i = 1:length(matrixNames)
    matrixNames{i} = [folderName matrixNames{i}];
end
end
