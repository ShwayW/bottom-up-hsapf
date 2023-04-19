function [loadedBaseline, bFN, loadedBaselineTest, bFNTest] = loadBaseline(domain, verbose)
%% Load the baseline files for different problem domains
% July 26, 2022
% Shway Wang
arguments
    domain (1,1) Domain
    verbose (1,1) logical = false
end

loadedBaselineTest = nan(1,1);
bFN = nan(1,1);
switch (domain.problemDomain)
    case ("pathfinding")
        [loadedBaseline, bFN] = loadBaselinePathFnd(domain.setNames, domain.psf.numGoals, domain.psf.numStarts, verbose);
        if (~isempty(domain.test))
            [loadedBaselineTest, bFNTest] = loadBaselinePathFnd(domain.setNames, domain.test.numGoals, domain.test.numStarts, verbose);
        end
    case ("slidingtile")
        [loadedBaseline, bFN] = loadBaselineSlideTile(domain.boardDim);
        loadedBaselineTest = loadedBaseline;
        bFNTest = bFN;
end
end


%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [loadedBaseline, bFN] = loadBaselinePathFnd(mapSetNames, numGoals, numStarts, verbose)
%% Load the baseline files for computing losses
% Shway Wang
% June 14, 2022

arguments
    mapSetNames (1,:) string
    numGoals (1,1) uint64
    numStarts (1,1) uint64
    verbose (1,1) logical = false
end

% initialize the loadedBaseline struct
loadedBaseline.expanded = [];
loadedBaseline.numConf = 0;
loadedBaseline.subopt = [];

% load and combine baseline related to each map set
for setNameI = 1:length(mapSetNames)
    bFN = sprintf('results/baseline/pathfinding/baseline_non-real-time_%s_%dx%d.mat',...
        mapSetNames(setNameI), numGoals, numStarts);
    tmp = load(bFN, 'expanded', 'numConf', 'subopt');
    loadedBaseline.expanded = [loadedBaseline.expanded; tmp.expanded];
    loadedBaseline.numConf = loadedBaseline.numConf + tmp.numConf;
    loadedBaseline.subopt = [loadedBaseline.subopt; tmp.subopt];
    if (verbose)
        fprintf("loaded baseline: %s\n", bFN);
    end
end
clear("tmp");
end

function [loadedBaseline, bFN] = loadBaselineSlideTile(boardDim)
%% Load the baseline files for computing losses
% Shway Wang
% July 18, 2022

arguments
    boardDim (1,2) uint64
end

% load and combine baseline related to each puzzle
file = dir(sprintf('results/baseline/slidingtile/baseline_non-real-time_%dx%d_*', boardDim(1), boardDim(2)));
bFN = sprintf('results/baseline/slidingtile/%s', file.name);
loadedBaseline = load(bFN, 'expanded', 'numConf', 'subopt');
end