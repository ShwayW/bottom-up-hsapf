function mapNames = getMapNames(folderName)
%% Generates a list of map names inside a folder
% Vadim Bulitko
% June 4, 2020

arguments
    folderName (1,:) char
end

% get all files inside that folder
d = dir(folderName);

% filter out folders
isub = [d(:).isdir];
fileName = {d(~isub).name}';

% filter out non .map files
mapNames = fileName(contains(fileName,'.map'));

% prepend the folder name
if (folderName(end) ~= '/')
    folderName = [folderName '/'];
end

for i = 1:length(mapNames)
    mapNames{i} = [folderName mapNames{i}];
end

end
