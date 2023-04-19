function generateSaveProblemsPathFnd(folderName, goalNum)
%% Generate problems on a set of maps
% Vadim Bulitko
% June 4, 2020
% Modified by Shway Wang to add A* difficulties
% November 11, 2021

arguments
    folderName (1,1) string = "maps/evolved/evolvedA" % file name to the set of maps
    goalNum (1,1) double = 200
end

diary off
format short g
rng('shuffle');

%% Control parameters
% record the time it takes
ttt = tic;

% initialize the number of goals and number of starts per goal
numGoals = goalNum;
numStartsPerGoal = goalNum;

% get map names of each folder 
mapNames = getMapNames(folderName);    

% Load the maps
maps = loadMaps(mapNames, true);
numMaps = length(maps);

% Generate problems for the maps
%problems = generateProblemsPathFnd_mex(maps, mapNames, numGoals, numStartsPerGoal, true);
problems = generateProblemsPathFnd(maps, numGoals, numStartsPerGoal);

% get the number of goals and starts used to compute A* difficulties
numGoals = size(problems{1}.startIndx, 1);
numStarts = size(problems{1}.startIndx, 2);

% save the A* difficulties and state expansions to problems
for mapI = 1:numMaps
    [problems{mapI}.AStarDifficulties, problems{mapI}.numStateExpansions] =...
        getASDifficultiesPathFnd(maps{mapI}, problems{mapI});
end

% save them
[~,scenName,~] = fileparts(folderName);
save(sprintf('problems/pathfinding/%s-%dx%d.mat', scenName, numGoals, numStarts),...
	'problems', 'maps', 'mapNames');
   

%% Finish
fprintf('\nTotal time %s\n', sec2str(toc(ttt)));
end