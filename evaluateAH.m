function [travelPerProblem, suboptPerProblem, expandedPerProblem, solvedPerProblem,...
    timePerGoal] = evaluateAH(problemUnit, alg, verbose)
%% Evaluate the algorithm given in the given game, right now, one of: ("pathfinding", "slidingtile")
% Shway Wang
% July 18, 2022

arguments
    problemUnit (1,1) struct
    alg (1,1) struct
    verbose (1,1) logical = false
end

% different evaluations for different games
switch (problemUnit.problemDomain)
    case ("pathfinding")
        [travelPerProblem, suboptPerProblem, expandedPerProblem, solvedPerProblem,...
            timePerGoal] = evaluateAHPathFnd(problemUnit.map, problemUnit.problems, alg, verbose);
    case ("slidingtile")
        [travelPerProblem, suboptPerProblem, expandedPerProblem, solvedPerProblem,...
            timePerGoal] = evaluateAHSlideTile(problemUnit.problems, alg, verbose);
end
end

%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [travelPerProblem, suboptPerProblem, expandedPerProblem, solvedPerProblem,...
    timePerGoal] = evaluateAHSlideTile(problems, alg, verbose)
%% Evaluates an algorithm and a heuristic combination on a set of problems on a given puzzle
% Shway Wang
% July 18, 2022

arguments
    problems (1,:) cell
    alg (1,1) struct
    verbose (1,1) logical = false
end

%% Preliminaries
numStarts = length(problems);
suboptPerProblem = NaN(1, numStarts);
travelPerProblem = NaN(1, numStarts);
expandedPerProblem = NaN(1, numStarts);
solvedPerProblem = false(1, numStarts);
timePerGoal = NaN(1, numStarts);

%% Go through all goals
if (numStarts < 10)
    % the job is not big enough to warrant parallelization
    for sI = 1:numStarts
        % get a puzzle from the set of problems
        startPuzzle = problems{sI}.startState;
        n = size(startPuzzle, 1);
        m = size(startPuzzle, 2);
        
        % initialize the goal puzzle
        goalPuzzle = initPuzzle(n, m, false);
        
        % put in the heuristic
        h = putInInitialHslideTile([n, m], alg.hH);
        
        % prepare start indecies and optimal+max costs
        optimalCosts = double(problems{sI}.optimalCosts);

        % batch-run the alg+h for a given goal
        ttRunTimeGoal = tic;
        [travel, expanded, solved] = evaluateAHsingleSlideTile(startPuzzle, goalPuzzle, h, alg);
        if (verbose)
            fprintf("%d/%d\n", sI, numStarts);
        end
        timePerGoal(sI) = toc(ttRunTimeGoal);

        % process the results
        travelPerProblem(sI) = double(travel);
        suboptPerProblem(sI) = double(travel) / optimalCosts;
        expandedPerProblem(sI) = double(expanded);
        solvedPerProblem(sI) = solved;
    end
else
    % we have enough goals and starts for the parallelization to be useful
    parfor sI = 1:numStarts
        % get a puzzle from the set of problems
        startPuzzle = problems{sI}.startState;
        n = size(startPuzzle, 1);
        m = size(startPuzzle, 2);
        
        % initialize the goal puzzle
        goalPuzzle = initPuzzle(n, m, false);
        
        % put in the heuristic
        h = putInInitialHslideTile([n, m], alg.hH); %#ok<PFBNS>
        
        % prepare start indecies and optimal+max costs
        optimalCosts = double(problems{sI}.optimalCosts);

        % batch-run the alg+h for a given goal
        ttRunTimeGoal = tic;
        [travel, expanded, solved] = evaluateAHsingleSlideTile(startPuzzle, goalPuzzle, h, alg);
        if (verbose)
            fprintf("%d/%d\n", sI, numStarts);
        end
        timePerGoal(sI) = toc(ttRunTimeGoal);

        % process the results
        travelPerProblem(sI) = double(travel);
        suboptPerProblem(sI) = double(travel) / optimalCosts;
        expandedPerProblem(sI) = double(expanded);
        solvedPerProblem(sI) = solved;
    end
end
end

function [travelPerProblem, suboptPerProblem, expandedPerProblem, solvedPerProblem,...
    timePerGoal] = evaluateAHPathFnd(map, problems, alg, verbose)
%% Evaluates an algorithm and a heuristic combination on a set of problems on a given single map
% Vadim Bulitko
% Jan 24, 2021

arguments
    map (:,:) logical
    problems (1,1) struct
    alg (1,1) struct
    verbose (1,1) logical = false
end

%% Preliminaries
numGoals = size(problems.startIndx, 1);
startsPerGoal = size(problems.startIndx, 2);
suboptPerProblem = NaN(numGoals, startsPerGoal);
travelPerProblem = NaN(numGoals, startsPerGoal);
expandedPerProblem = NaN(numGoals, startsPerGoal);
solvedPerProblem = false(numGoals, startsPerGoal);
timePerGoal = NaN(numGoals, 1);

%% Go through all goals
if (numGoals < 10 || startsPerGoal < 10)
    % the job is not big enough to warrant parallelization
    for gI = 1:numGoals
        % get the goal index in the column of goals
        goalIndex = problems.goalIndx(gI);
        
        % put in the heuristic
        h = putInInitialHpathFnd(map, alg.hH, goalIndex);
        
        if (~isempty(h))
            % prepare start indecies and optimal+max costs
            startIndecies = problems.startIndx(gI,:);
            optimalCosts = double(problems.optimalCosts(gI,:));
            
            % batch-run the alg+h for a given goal
            ttRunTimeGoal = tic;
            [travel, expanded, solved] = evaluateAHsingleGoal(map, startIndecies, goalIndex, h, alg);
            if (verbose)
                fprintf("%d/%d\n", gI, numGoals);
            end
            timePerGoal(gI) = toc(ttRunTimeGoal);
            
            % process the results
            travelPerProblem(gI,:) = double(travel);
            suboptPerProblem(gI,:) = double(travel) ./ optimalCosts;
            expandedPerProblem(gI,:) = double(expanded);
            solvedPerProblem(gI,:) = solved;
        end
    end
else
    % we have enough goals and starts for the parallelization to be useful
    parfor gI = 1:numGoals
        % get the goal index in the column of goals
        goalIndex = problems.goalIndx(gI); %#ok<PFBNS>
        
        % put in the heuristic
        h = putInInitialHpathFnd(map, alg.hH, goalIndex); %#ok<PFBNS>
        
        if (~isempty(h))
            % prepare start indecies and optimal+max costs
            startIndecies = problems.startIndx(gI, :);
            optimalCosts = double(problems.optimalCosts(gI, :));
            
            % batch-run the alg+h for a given goal
            ttRunTimeGoal = tic;
            [travel, expanded, solved] = evaluateAHsingleGoal(map, startIndecies, goalIndex, h, alg);
            if (verbose)
                fprintf("%d/%d\n", gI, numGoals);
            end
            timePerGoal(gI) = toc(ttRunTimeGoal);
            
            % process the results
            travelPerProblem(gI, :) = double(travel);
            suboptPerProblem(gI, :) = double(travel) ./ optimalCosts;
            expandedPerProblem(gI, :) = double(expanded);
            solvedPerProblem(gI, :) = solved;
        end
    end
end
end
