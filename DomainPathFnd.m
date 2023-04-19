classdef DomainPathFnd < Domain
%% Initialize the neccessary contents for path finding domain
% Shway Wang
% July 26, 2022

    % Public properties
    properties (Access = public)
        %% The properties below are set manually by user in this file
        % set name of the maps the heuristics were synthesized on
        % one or more of:
        % ["randomA"];
		setNames = ["randomA"];
        
        % set the per map budget (positive double)
        per_map_budget = inf;
                
        %% The properties below are set by the constructor automatically
        % the lower limit for the number of training problems
        numProblemsLowerBound;
        
        % maps indexes (cell array of positive integer arrays)
        % each positive integer array represents the set of maps for multi-map synthesis
        mapI_cell_arr;
        
        % the maximum number of maps
        maxMaps;
        
        % the list of map name string
        mapList;
    end

    % methods include the constructor that appends possible building blocks
    methods
        function obj = DomainPathFnd(mapI_cell_arr, numProblemsLowerBound, is_analyzing)
        %% The constructor of the DomainPathFnd class
        % Shway Wang
        % July 26, 2022
        
            arguments
                % maps indexes (cell array of positive integer arrays)
                % each positive integer array represents the set of maps for multi-map synthesis
                mapI_cell_arr (1,:) cell = {}
                
                % what we want for the lower bound of training problems' goals to be
                % the total number of problems should be numProblemsLowerBound^2
                numProblemsLowerBound (1,1) uint64 = 3
                
                % if we are analyzing
                is_analyzing (1,1) logical = false
            end
            
            % budgets (cell array of positive double arrays)
            % each positive integer array represents the total budget for the set of maps for multi-map synthesis
            budget_arr = zeros(1, length(mapI_cell_arr));
            
            % inheritance from super class
            obj = obj@Domain("pathfinding", budget_arr);
            
            % if mapI_cell_arr is empty, read in the map indices from the txt file
            if (isempty(mapI_cell_arr))
                % read from the text file of map indices and construct mapI_cell_arr
                mapsIndicesPath = 'maps/mapsIndices.txt';
                fileID = fopen(mapsIndicesPath, 'r');
                while (true)
                    % read a line
                    mapIndsArr = fgetl(fileID);

                    % if end of file is reached, break the loop
                    if (mapIndsArr < 0)
                        break;
                    end

                    % conver the line to an integer array and append it to mapI_cell_arr
                    mapI_cell_arr = [mapI_cell_arr, str2num(mapIndsArr)]; %#ok<AGROW,ST2NM>
                end
                fclose(fileID);
            end

            % put into budget_arr the computed budgets
            for bAI = 1:length(budget_arr)
                budget_arr(bAI) = length(mapI_cell_arr{bAI}) * obj.per_map_budget;
            end
            
            % The number of buget arrays must be equal to the number of maps arrays
            assert(length(budget_arr) == length(mapI_cell_arr));
            
            % assign the object's budget_arr
            obj.budget_arr = budget_arr;
            
            % assign the object's mapI_cell_arr
            obj.mapI_cell_arr = mapI_cell_arr;
            
            % assign the psf struct
            psf.numGoals = 100;
            psf.numStarts = 100;
            obj.psf = psf;
            
            % assign the test struct
            if (is_analyzing)
                % number of goals and number of starts for psf and test problem sets
                % almost always stay the same
                obj.test(1).numGoals = 200;
                obj.test(1).numStarts = 200;
            end
            
            % assign the maximum number of maps
            obj.maxMaps = getTotalNumMaps(obj.setNames);
            
            % assign the numProblemsLowerBound
            obj.numProblemsLowerBound = numProblemsLowerBound;
        end
        
        function self = loadProblemSet(self, psOption, verbose)
        %% Load the psf problem set binary file with specified number of starts and goals
        % Shway Wang
        % June 14, 2022

            arguments
                self (1,1) DomainPathFnd
                psOption (1,1) string = "psf" % "psf" or "test"
                verbose (1,1) logical = false
            end

            %% Preliminaries
            mapSetNames = self.setNames;
            
            % initialize the problem set struct
            switch (psOption)
                case ("psf")
                    ps = self.psf;
                case ("test")
                    ps = self.test;
            end
            ps.problems = {};
            ps.maps = {};
            ps.mapNames = {};

            % loop for each of the map sets and combine their problems
            for setNameI = 1:length(mapSetNames)
                switch (psOption)
                    case ("psf")
                        ps.problemFileName{setNameI} = sprintf('problems/%s-%dx%d.mat',...
                            mapSetNames(setNameI), self.psf.numGoals, self.psf.numStarts);
                    case ("test")
                        ps.problemFileName{setNameI} = sprintf('problems/%s-%dx%d.mat',...
                            mapSetNames(setNameI), self.test.numGoals, self.test.numStarts);
                end
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
            switch (psOption)
                case ("psf")
                    assert(self.psf.numGoals == size(ps.problems{1}.goalIndx, 1));
                    assert(self.psf.numStarts == size(ps.problems{1}.startIndx, 2));
                case ("test")
                    assert(self.test.numGoals == size(ps.problems{1}.goalIndx, 1));
                    assert(self.test.numStarts == size(ps.problems{1}.startIndx, 2));
            end
            
            % assign to self
            switch (psOption)
                case ("psf")
                    self.psf = ps;
                case ("test")
                    self.test = ps;
            end
        end
        
        function [baseline, bFN] = loadBaseline(self, psOption, verbose)
        %% Load the baseline files for computing losses
        % Shway Wang
        % June 14, 2022

            arguments
                self (1,1) DomainPathFnd
                psOption (1,1) string = "psf"
                verbose (1,1) logical = false
            end
            
            %% Preliminaries
            mapSetNames = self.setNames;
            
            % initialize the loadedBaseline struct
            baseline.expanded = [];
            baseline.numConf = 0;
            baseline.subopt = [];

            % load and combine baseline related to each map set
            for setNameI = 1:length(mapSetNames)
                switch (psOption)
                    case ("psf")
                        bFN = sprintf('results/baseline/baseline_non-real-time_%s_%dx%d.mat',...
                            mapSetNames(setNameI), self.psf.numGoals, self.psf.numStarts);
                    case ("test")
                        bFN = sprintf('results/baseline/baseline_non-real-time_%s_%dx%d.mat',...
                            mapSetNames(setNameI), self.test.numGoals, self.test.numStarts);
                end
                tmp = load(bFN, 'expanded', 'numConf', 'subopt');
                baseline.expanded = [baseline.expanded; tmp.expanded];
                baseline.numConf = baseline.numConf + tmp.numConf;
                baseline.subopt = [baseline.subopt; tmp.subopt];
                if (verbose)
                    fprintf("loaded baseline: %s\n", bFN);
                end
            end
            clear("tmp");            
        end
        
        function self = initTriageProblems(self, budgetI, numProblemSets, verbose)
        %% Generates all (non-final) problem sets
        % Sean Paetz
        % June 28th, 2022

        % Some code taken and modified from sahTrial, written by Shway Wang, Vadim Bulitko,
        % Justin Stevens and Matt Gallivan

        % Shway Wang added switch for different game domains
        % July 27, 2022

            arguments
                self (1,1) DomainPathFnd
                budgetI (1,1) uint64
                numProblemSets (1,1) uint64
                verbose (1,1) logical = true
            end
            
            %% Initialize Small training data
            for psI = 1:numProblemSets
                problemSets{psI} = self.psf; %#ok<AGROW>
                problemSets{psI}.numGoals = self.numProblemsLowerBound + 7 * (psI - 1); %#ok<AGROW>
                problemSets{psI}.numStarts = problemSets{psI}.numGoals; %#ok<AGROW>
                problemSets{psI}.mapsIArr = self.mapI_cell_arr{budgetI}; %#ok<AGROW>

                %% Generate the smaller problem sets
                % generate ps1 training set on the fly
                problemSets{psI}.problems = generateProblemsPathFnd(problemSets{psI}.maps,...
					problemSets{psI}.numGoals, problemSets{psI}.numStarts); %#ok<AGROW>

                % some sanity checks
                assert(problemSets{psI}.numMaps == self.psf.numMaps);
                assert(problemSets{psI}.numGoals == size(problemSets{psI}.problems{1}.goalIndx,1));
                assert(problemSets{psI}.numStarts == size(problemSets{psI}.problems{1}.startIndx,2));

                % display some information
                if (verbose)
                    fprintf('\n---- Generated PS #%d -------------------------------------\n', psI);
                    fprintf('\tusing %d map(s)\n\t%s goals on each\n\t%s starts for each goal\n\t%s problems/map\n\n',...
                        length(problemSets{psI}.mapsIArr), hrNumber(problemSets{psI}.numGoals),...
                        hrNumber(problemSets{psI}.numStarts), hrNumber(problemSets{psI}.numGoals * problemSets{psI}.numStarts));
                end
            end
            
            % assign problemSets
            self.problemSets = problemSets;
        end
        
        function [travelPerProblem, suboptPerProblem, expandedPerProblem, solvedPerProblem,...
            timePerGoal] = evaluateAH(self, map, problems, alg, verbose)
        %% Evaluates an algorithm and a heuristic combination on a set of problems on a given single map
        % Vadim Bulitko
        % Jan 24, 2021

            arguments
                self (1,1) DomainPathFnd %#ok<INUSA>
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
    end
end