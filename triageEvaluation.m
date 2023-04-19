function [ahPop, budgetUsed] = triageEvaluation(domain, ahPop, budgetUsed, suboptM, expandedM,...
    synH, showGenTime)
%% Perform triage on a given number of problem sets for a given population
% Sean Paetz
% July 8th, 2022

% Code largely taken and modified from synthesizeAHmapUnified, written by
% Shway Wang, Justin Stevens,and Matt Gallivan

arguments
    domain (1,1) Domain % video game path finding, sliding tile puzzles and so on
    ahPop (1, :)struct % array of heuristics to be evaluated
    budgetUsed (1,1) double % tracker for many states we've expanded
    suboptM (:,:) double % the baseline subopt for loss calculations
    expandedM (:,:) double % the baseline states expanded for loss calculations
    synH (1,:) cell = {} % building blocks for heuristics
    showGenTime (1,1) logical = true;
end


%% Preliminaries
% minimum elite population size across different triage levels
minElitesSize = 1;

% the amount of the population that survives to be evaluated on the next
% level of triage after each problem set
reductionFactor = 0.05;

%% Initialization
% senity check
assert(minElitesSize <= length(ahPop));
assert(reductionFactor <= 1.0);

% initialize values
for popI = 1:length(ahPop)
    ahPop(popI).confidence = 0;
end

% handles index out of bounds error on small populations
if (length(ahPop) < minElitesSize)
    minElitesSize = length(ahPop);
end

% establish index value to track heuristics across changing confs and
% losses
if (~isfield(ahPop, 'initIndex'))
    for popI = 1:length(ahPop)
        ahPop(popI).initIndex = popI;
    end
end


%% Triage loop
for pI = 1:length(domain.problemSets)
    % Triage only
    % select the champions from the population according to the training losses on PS1
    % here the array ahPop is sorted in an ascending order
    % perform a sort on ahPop based on the level of confidence
    if (pI ~= 1)
        % clear previous elites and sort to get highest cofidence
        [~, I] = sort([ahPop.confidence], 'descend');
        ahPop = ahPop(I);
        maxConf = ahPop(1).confidence;

        % add all h to elites array that have the highest conf level
        for popI = 1:length(ahPop)
            if (ahPop(popI).confidence ~= maxConf)
                break;
            end
        end

        % get the current elites
        currentElites = ahPop(1:popI);        
        
        % best elites first
        [~, I] = sort([currentElites.regloss], 'ascend');
        currentElites = currentElites(I);

        % get factor by which to reduce elite pop, guarantee population has minimum size
        currentElites = currentElites(1 : max(minElitesSize, length(currentElites) * reductionFactor));
    else
        % for the first problem set, evaluate all members of the population
        currentElites = ahPop;
    end
    
    % start the stop watch
    if (showGenTime)
        discardUnfitsTime = tic;
    end
    
    % Choose the best individual from all currentElites
    [currentElites, numExpanded] = evalOnProblems(domain, pI, currentElites, length(currentElites),...
        suboptM, expandedM, synH);

    % add to the budget counter appropriately
    budgetUsed = budgetUsed + numExpanded;

    % stop watch for the time of discarding unfits ends here if the showGenTime flag is set to true
    if (showGenTime)
        fprintf('pI = %d evaluate time: %s\n', pI, sec2str(toc(discardUnfitsTime))); %#ok<*UNRCH>
    end

    % assign elites' info to the population accordingly
    for popI = 1:length(currentElites)
        I = [ahPop.initIndex] == currentElites(popI).initIndex;
        ahPop(I).regloss = currentElites(popI).regloss;
        ahPop(I).confidence = currentElites(popI).confidence;
        ahPop(I).alg = currentElites(popI).alg;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ahPairs, numExpanded] = evalOnProblems(domain, pI, ahPairs, popSize,...
    suboptM, expandedM, synH)
%% Return the top numChamps number of the population based on training losses evaluated on the input "problems"
% Shway Wang
% July 27, 2022

%% Argument types and default parameters
arguments
    domain (1,1) Domain
    pI (1,1) uint64
    ahPairs (1,:) struct  % the (a, h) pairs
    popSize (1,1) double % the size of the population being evaluated
    suboptM (:,:) double % baseline frontier
    expandedM (:,:) double % baseline frontier
    synH (1,:) cell = {} % building blocks
end

%% Preliminaries
% extract the problem set
problemSet = domain.problemSets{pI};

%% Draw heuristics and algorithms randomly and evaluate them on a small set of problems
numExpanded = 0;
mapsIArr = problemSet.mapsIArr; % get the mapsIArr from any problems
numMaps = length(mapsIArr);
for popI = 1:popSize
    % Create the function handle for evaluation
    hct = ahPairs(popI).alg.hct;
    functionStr = hct2str(hct, synH);
    ahPairs(popI).alg.hH = str2func(['@(x1,y1,x2,y2)' convertStringsToChars(functionStr)]);

    % loop for evaluating on the set of maps
    totalLoss = 0;
    for mapI = mapsIArr
        % Stats
        map = problemSet.maps{mapI};
        problems = problemSet.problems{mapI};

        % evaluate the algorithm on the problems and map of mapI
        [~, suboptPerProblem, expandedPerProblem, ~, ~] =...
            domain.evaluateAH(map, problems, ahPairs(popI).alg);

        % increment the number of state expanded
        numExpanded = numExpanded + sum(expandedPerProblem, 'all');

        % compute the ps1 training loss of the current A* + heuristic function pair
        totalLoss = totalLoss + lossAH(mean(suboptPerProblem, 'all'),...
            mean(expandedPerProblem, 'all'), suboptM(mapI, :), expandedM(mapI, :));
    end

    % compute the regularized loss
    ahPairs(popI).regloss = double(totalLoss) / numMaps;
    ahPairs(popI).confidence = numMaps * size(problemSet.problems{mapI}.startIndx, 1) *...
        size(problemSet.problems{mapI}.startIndx, 2);
end

% sort the ahPairs based on their ps1 losses
[~, I] = sort([ahPairs.regloss], 'ascend');
ahPairs = ahPairs(I);
end
