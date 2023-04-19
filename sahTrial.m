function sahTrial(domain, budgetI, hChunkFiles, trialI, verbose)
%% Synthesize A+H : map(s) and a single trial
% no evaluation on full sets
% Vadim Bulitko
% Mar 25, 2021
% Modified by Justin Stevens and Matt Gallivan for priority functions
% Jun 08, 2021
% Modified by Shway Wang for better compatibility to Compute Canada environment
% March 31, 2021
% Shway Wang modified for multi-map synthesis code
% June 28, 2022
% Sean Paetz modified to support multiple fitness evaluation methods

arguments
    domain (1,1) Domain
    budgetI (1,1) uint64
    hChunkFiles (1,:) cell % building blocks for heuristics
    trialI (1,1) uint64 % index of trial
    verbose (1,1) logical = false
end

%% Preliminaries
%{
% get the random seed from time
rng('shuffle');
x = rng;
seed = x.Seed;

% mix in mapI and trialI
seedNew = double(seed) + trialI;
rng(seedNew);
%}
seed = 0;
rng(seed);

%% Load PSF problem set  ----------------------------------------------------------------
domain = domain.loadProblemSet("psf", verbose);

% print the information
if (verbose)
    mapsIArr = domain.mapI_cell_arr{budgetI};
    fprintf('---- PSF -------------------------------------\n');
    fprintf('\tusing %d map(s)\n\t%s goals on each\n\t%s starts for each goal\n\t%s problems/map\n',...
        length(mapsIArr), hrNumber(domain.psf.numGoals), hrNumber(domain.psf.numStarts),...
        hrNumber(domain.psf.numGoals * domain.psf.numStarts));
end

%% Load the PSF baseline
% load the baseline related to psf
[loadedBaseline, ~] = domain.loadBaseline("psf", verbose);

% extract subopt and number of nodes expanded to the corresponding variables
subopt = loadedBaseline.subopt;
expanded = loadedBaseline.expanded;

% print the information
if (verbose)
    fprintf('\nLoaded the baseline results: %d alg configurations\n', loadedBaseline.numConf);
end

%% Load additional chunked terminal nodes building blocks
% adding chunks for the heuristic expressions
synH = loadBuildingBlocks(hChunkFiles, verbose);

%% Initialize and load in small training problems
domain = domain.initTriageProblems(budgetI, 1);

%% Run the trial using the input synthesis method on smaller training data
% run synthesis
if (verbose)
	mapsIArr = domain.mapI_cell_arr{budgetI};
	fprintf('\n\n============= %d maps of %d sets ============\n', length(mapsIArr), length(domain.setNames));
	fprintf('\nRunning A+H synthesis on %d maps of %d sets\n', length(mapsIArr), length(domain.setNames));
end

% start the time count
oneRunBMDtt = tic;

% synthesis with the unified code
mapsIArr = domain.mapI_cell_arr{budgetI};
expandedBudget = domain.per_map_budget;
[ah, synthesisTime] = synthesizeAHmapBottomUp(domain, expandedBudget,...
    subopt, expanded, synH);
   
if (verbose)
    % display the time it took and the number of champion updates
    fprintf('\t... %s | %d a+h pairs\n', sec2str(toc(oneRunBMDtt)), length(ah));
    fprintf('\tsynthesis took: %s state exansions | %s\n',...
        hrNumber(expandedBudget), sec2str(synthesisTime));

    % display the champion's algorithm and heuristic formula
    [algStr, hStr] = alg2latex(ah.alg);
    fprintf('\t%s\n', algStr);
    fprintf('\t%s\n', hStr);

    % display other relative information about the champion
    fprintf('\tsize %d | regularized loss %0.2f\n\n', hctSize(ah.alg.hct), ah.regloss);
end

%% Evaluate the champion on PSF
% keep track of time
psfET = tic;

% evaluate the results on psf
ah = evaluateOnPSF(domain, budgetI, ah, subopt, expanded);

% record time for evaluating on psf
psftime = toc(psfET);

% display the evaluation results
if (verbose)
    fprintf('\tPSF: size %d | reg loss %0.2f | psf eval time %s\n',...
        hctSize(ah.alg.hct), ah.psfregloss, sec2str(psftime));
    fprintf('\n');
end

%% Wrap up and save the results
% make the directory name based on the parameters past in
directoryName = makeResultsDirPath(domain, budgetI, ~isempty(hChunkFiles));

% generate the full name: directoryName/map_set_%d <= appended
directoryName = getMapCombsFolderName(directoryName, mapsIArr, domain.maxMaps);

% create the directory if it does not exist
if(~isfolder(directoryName))
    mkdir(directoryName);
end

% generate the name of the output binary file
fileName = sprintf('sahPSF_trial%d_seed%d.mat', trialI, seed);

% keeping only the fields 'numGoals' and 'numStarts' for small training sets
for psI = 1:length(domain.problemSets)
    ps = domain.problemSets{psI};
    ps = rmfield(ps, setdiff(fieldnames(ps), {'numGoals', 'numStarts'}));
    domain.problemSets{psI} = ps;
end

% keeping only the fields 'numGoals', 'numStarts', 'numMaps' and 'mapNames' for psf
domain.psf = rmfield(domain.psf, setdiff(fieldnames(domain.psf), {'numGoals', 'numStarts', 'numMaps', 'mapNames'}));

% save the result
psf = domain.psf;
problemSets = domain.problemSets;
setNames = domain.setNames;
save(append(directoryName, '/', fileName),...
    'ah', 'problemSets', 'psf', 'setNames', 'expandedBudget', 'trialI', 'seed',...
    'loadedBaseline', 'synthesisTime', "setNames", 'psftime', 'hChunkFiles', 'synH');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ah = evaluateOnPSF(domain, budgetI, ah, subopt, expanded)
%% Evaluate the ah on problem set and compute its loss by comparing to subopt and expanded
% Shway Wang
% June 14, 2022

% Supports both pathfinding and slidingtile problem domains
% Shway Wang
% July 27, 2022

arguments
    domain (1,1) Domain
    budgetI (1,1) uint64
    ah (1,1) struct
    subopt (:,:) double
    expanded (:,:) uint64
end

% want to compute average values for all maps in the set, then take mean
tTravel = 0;
tSubopt = 0;
tExpanded = 0;
tTimePerGoal = 0;
tLoss = 0;

% get the maps indices array
mapsIArr = domain.mapI_cell_arr{budgetI};
numMaps = length(mapsIArr);
for mapI = mapsIArr
    % stats
    map = domain.psf.maps{mapI};
    problems = domain.psf.problems{mapI};

    % evaluate the ah pair
    [travelPerProblem, suboptPerProblem, expandedPerProblem,...
        solvedPerProblem, timePerGoal] = domain.evaluateAH(map, problems, ah.alg, false);

    % record the stats
    tTravel = tTravel + mean(travelPerProblem,'all');
    tSubopt = tSubopt + mean(suboptPerProblem,'all');
    tExpanded = tExpanded + mean(expandedPerProblem,'all');
    tTimePerGoal = tTimePerGoal + mean(timePerGoal,'all');

    % compute PSF loss
    [loss, ~] = lossAH(mean(suboptPerProblem,'all'), mean(expandedPerProblem,'all'),...
        subopt(mapI, :), expanded(mapI, :));

    % sum loss
    tLoss = tLoss + loss;
end

% record data averages
ah.psfperformance.meanTravel = double(tTravel) / numMaps;
ah.psfperformance.meanSubopt = double(tSubopt) / numMaps;
ah.psfperformance.meanExpanded = double(tExpanded) / numMaps;
ah.psfperformance.meanSolved = mean(solvedPerProblem, 'all');
ah.psfperformance.meanTimePerGoal = double(tTimePerGoal) / numMaps;

% compute the regularized psf loss
ah.psfregloss = double(tLoss) / numMaps;
end
