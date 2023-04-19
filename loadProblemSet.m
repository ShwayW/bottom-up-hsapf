function [psf, test] = loadProblemSet(domain, verbose)
%% Load a problem set according to the game
% July 26, 2022
% Shway Wang

arguments
    domain (1,1) Domain
    verbose (1,1) logical = false
end

test = nan(1,1);
switch (domain.problemDomain)
    case ("pathfinding")
        psf = loadProblemSetPathFnd(domain.setNames, domain.psf, verbose);
        if (~isempty(domain.test))
            test = loadProblemSetPathFnd(domain.setNames, domain.test, verbose);
        end
    case ("slidingtile")
        psf = loadProblemSetSlideTile(domain.boardDim, verbose);
        test = psf;
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ps = loadProblemSetPathFnd(mapSetNames, ps, verbose)
%% Load the problem set binary file with specified number of starts and goals
% Shway Wang
% June 14, 2022

arguments
    mapSetNames (1,:) string
    ps (1,1) struct
    verbose (1,1) logical = false
end

% initialize the problem set struct
ps.problems = {};
ps.maps = {};
ps.mapNames = {};

% loop for each of the map sets and combine their problems
for setNameI = 1:length(mapSetNames)
    ps.problemFileName{setNameI} = sprintf('problems/pathfinding/%s-%dx%d.mat', mapSetNames(setNameI),...
        ps.numGoals, ps.numStarts);
    tmp = load(ps.problemFileName{setNameI}, 'problems', 'maps', 'mapNames');
    ps.problems = [ps.problems; tmp.problems];
    ps.maps = [ps.maps, tmp.maps];
    ps.mapNames = [ps.mapNames; tmp.mapNames];
    if (verbose)
        fprintf("loaded final problem set: %s\n", ps.problemFileName{setNameI});
    end
end
clear('tmp');

% compute the number of maps
ps.numMaps = length(ps.mapNames);

% some sanity checks
assert(ps.numGoals == size(ps.problems{1}.goalIndx, 1));
assert(ps.numStarts == size(ps.problems{1}.startIndx, 2));
end

function ps = loadProblemSetSlideTile(boardDim, verbose)
%% Load the sliding tile puzzle problem set binary file with specified board dimension
% Shway Wang
% June 14, 2022

arguments
    boardDim (1,2) uint64
    verbose (1,1) logical = false
end

% initialize the problem set struct
ps.problems = {};

% load the problems
file = dir(sprintf('problems/slidingtile/dim_%dx%d-*', boardDim(1), boardDim(2)));
nums = regexp(file.name, "\d*", "Match");
ps.numStarts = str2double(nums{3});
ps.problemFileName = sprintf("problems/slidingtile/%s", file.name);
if (verbose)
    fprintf("%s\n", ps.problemFileName);
end
tmp = load(ps.problemFileName, 'problems');
ps.problems = tmp.problems;
end