function names = getSubfolderNames(folderName)
%% Return the names of the subfolders in the folder specified by folderName ("." and ".." excluded)
% Shway Wang
% April 19, 2022

arguments
    folderName (1, :) char
end

% read in the image from the path specified by inFolder
folderInfo = dir(folderName);

% filter out irrelavent folders
notDots = ~startsWith({folderInfo.name}, '.');
notTxt = ~endsWith({folderInfo.name}, '.txt');
notMat = ~endsWith({folderInfo.name}, '.mat');
notPdf = ~endsWith({folderInfo.name}, '.pdf');
notGZ = ~endsWith({folderInfo.name}, '.gz');
notTex = ~endsWith({folderInfo.name}, '.tex');
notLog = ~endsWith({folderInfo.name}, '.log');
notAux = ~endsWith({folderInfo.name}, '.aux');
folderInfo = folderInfo(notDots & notTxt & notMat & notPdf & notGZ & notTex & notLog & notAux);

% get the names of the subfolders
subfolderNames = {folderInfo.name}';

% de-cell the name strings
names = [];
for i = 1:length(subfolderNames)
    name = subfolderNames(i);
    name = sprintf("%s/%s", folderName, convertCharsToStrings(name{1}));
    names = [names, name]; %#ok<AGROW>
end
names = names';
end