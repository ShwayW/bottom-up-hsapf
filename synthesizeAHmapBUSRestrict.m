function [ah, synthesisTime] = synthesizeAHmapBUSRestrict(domain, budget, suboptM, expandedM, synH)
%% Synthesize A+H for a given single map using bottom up search (from Levi's pseudocode)
% Takes two sets of problems and returns a single best a+h combination
% Shway Wang
% May 3, 2022

arguments
    domain (1,1) Domain
    budget (1,1) double % budget allowance
    suboptM (:,:) double  % baseline frontier
    expandedM (:,:) uint64 % baseline frontier
    synH (1,:) cell = {} % heuristic formulae building blocks
end

%% Preliminaries
% verbose flags
showChampion = true;
showEval = false;

%% Initializations
% initialize the total number of state expanded
totalExpanded = 0;

% record the best ps loss so far
runningBest = Inf;

% the bound for bottom up search
bound = 5;

% want to record the amount of time it takes for this trial to complete
synTT = tic;

%% The heuristic growing search process
plist = [];
outputs = [];
number_eval = 1;
for curHLen = 1:bound
    % Grow the program list
    [plist, outputs] = growProgramList(plist, curHLen, outputs, domain, totalExpanded,...
		suboptM, expandedM, showEval, synH);
	assert(length(plist) == length(outputs));

    % some verbose showing some information
    if (showChampion)
        fprintf("size of program list: %d, tree level: %d\n", length(plist), curHLen);
    end

    % test to see if there is a better historical champion in the new list of programs
    for plistI = number_eval:length(plist)
        % Update the historical best if there is a better one
        if (outputs(plistI) < runningBest)
            [ah, runningBest] = updateHistoricalBest(plist(plistI), outputs(plistI), showChampion);
        end

        % if the budget allowed is reached, end the current trial
        if (totalExpanded > budget)
            synthesisTime = toc(synTT);
            return;
        end
    end

    % increment the number of evaluations
    number_eval = 1 + length(plist);
end

synthesisTime = toc(synTT);
end

%%%%%%%%%%%%%%%%%%%%%%%% Aux functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [plist, outputs] = growProgramList(plist, curHLen, outputs, domain,...
        totalExpanded, suboptM, expandedM, showEval, synH)
%% Grow the list of programs by searching the space of programs
% if plist is empty, initialize it with all terminal nodes
% Shway Wang
% May 6, 2022

arguments
    plist (1,:) % the set of programs we have so far
    curHLen (1,1) uint64 % the bound on the code tree size
	outputs (1,:) double
	domain (1,1) Domain
	totalExpanded (1,1) double
    suboptM (:,:) double
    expandedM (:,:) uint64
    showEval (1,1) logical = false
    synH (1,:) cell = {}
end

%% Preliminaries
grammar = GrammarHCT(synH);

%% Grow nplist for both unary operators and binary operators
nplist = [];
if (isempty(plist))
    nplist = grammar.T;

	% test to see if there is a better historical champion in the new list of programs
	for nplistI = 1:length(nplist)
    	% Evaluate plist(plistI) on ps to produce the ahPair struct
    	[ahPair, totalExpanded] = evaluateHeuristicFormula(domain, nplist, nplistI,...
        	totalExpanded, suboptM, expandedM, showEval, synH);
	
		% test for functional equivalence and add to outputs and plist
		outputs = [outputs, ahPair.regloss]; %#ok<AGROW>
		plist = [plist, nplist(nplistI)]; %#ok<AGROW>
	end
	return;
else
    % let each operator to grow the plist and append the results to nplist
    % uniary operators: [sqrt, abs, negation, sqr]
    unaryList = unaryGrow(grammar, plist, curHLen);

    % binary operators" [+, -, *, /, max, min]"
    binaryList = binaryGrow(grammar, plist, curHLen);

    % for the new program list
    nplist = [nplist, unaryList, binaryList];
end

fprintf("New program list size: %d\n", length(nplist));

% test to see if there is a better historical champion in the new list of programs
for nplistI = 1:length(nplist)
    % Evaluate plist(plistI) on ps to produce the ahPair struct
    [ahPair, totalExpanded] = evaluateHeuristicFormula(domain, nplist, nplistI,...
        totalExpanded, suboptM, expandedM, showEval, synH);

	% test for functional equivalence and add to outputs and plist
	if (~ismember(ahPair.regloss, outputs))
		outputs = [outputs, ahPair.regloss]; %#ok<AGROW>
		plist = [plist, nplist(nplistI)]; %#ok<AGROW>
	end
end
end


function nplist = binaryGrow(grammar, plist, targetHLen)
%% given the current program list, let all binary operators grow themselves
% Shway Wang
% May 11, 2022

arguments
    grammar (1,1) GrammarHCT
    plist (1,:) string
    targetHLen (1,1) uint64
end

%% Preliminaries
% get all the binary operators
bins = grammar.B;

% loop once to get the number of programs to increase
sizeCounter = 0;
for plistI = 1:length(plist)
    % get the root node's id for each code tree
    hctA = plist(plistI);
    hctALen = hctSize(hctA);
	[headA, ~] = getHeadAndInputs(hctA);

    % add each operator in ops as the root node for the existing code tree
    for opI = 1:length(bins)
		op = bins(opI);

        % form a new tree with every code tree from the program list by every binary operator from ops
        parfor plistJ = 1:length(plist)
            hctB = plist(plistJ);
            hctBLen = hctSize(hctB);
			[headB, ~] = getHeadAndInputs(hctB);

            % construct new code tree only if requirement tree size met
            if (isequal(hctALen + hctBLen + 1, targetHLen) && ~isequal(hctA, hctB))
				addFlag = true;
				if (isequal(op, "-") && isequal(headB, "neg"))
					addFlag = false;
				elseif (isequal(op, "*") && isequal(headA, "neg") && isequal(headB, "neg"))
					addFlag = false;
				elseif (isequal(op, "/") && isequal(headA, "neg") && isequal(headB, "neg"))
					addFlag = false;
				end
				
				if (addFlag)
					sizeCounter = sizeCounter + 1;
				end
            end
        end
    end
end

% initialize cell array for structs
nplist = strings(1, sizeCounter);

% loop for each existing program in plist
counter = 1;
for plistI = 1:length(plist)
    % get the root node's id for each code tree
    hctA = plist(plistI);
    hctALen = hctSize(hctA);
	[headA, ~] = getHeadAndInputs(hctA);

    % add each operator in ops as the root node for the existing code tree
    for opI = 1:length(bins)
        op = bins(opI);

        % form a new tree with every code tree from the program list by every binary operator from ops
        for plistJ = 1:length(plist)
            hctB = plist(plistJ);
            hctBLen = hctSize(hctB);
			[headB, ~] = getHeadAndInputs(hctB);

            % construct new code tree only if requirement tree size met
            if (isequal(hctALen + hctBLen + 1, targetHLen) && ~isequal(hctA, hctB))
				addFlag = true;
				if (isequal(op, "-") && isequal(headB, "neg"))
					addFlag = false;
				elseif (isequal(op, "*") && isequal(headA, "neg") && isequal(headB, "neg"))
					addFlag = false;
				elseif (isequal(op, "/") && isequal(headA, "neg") && isequal(headB, "neg"))
					addFlag = false;
				end

				if (addFlag)
					nct = sprintf("(%s %s %s)", op, hctA, hctB);
            		nplist(counter) = nct;
            		counter = counter + 1;
				end
            end
        end
    end
end
end


function nplist = unaryGrow(grammar, plist, targetHLen)
%% given the current program list, let all unary operators grow themselves
% Shway Wang
% May 11, 2022

arguments
    grammar (1,1) GrammarHCT
    plist (1,:) string
    targetHLen (1,1) uint64
end

% get all the unary operators
terms = grammar.T;
ops = grammar.U;
bins = grammar.B;

% compute the total number of programs
sizeCounter = 0;

% loop once to get the size of programs to increase
for plistI = 1:length(plist)
    % get the root node's id for each code tree
    hct = plist(plistI);
    ctLen = hctSize(hct);
	[head, ~] = getHeadAndInputs(hct);

    % add each operator in ops as the root node for the existing code tree
    parfor opI = 1:length(ops)
        if (isequal(ctLen + 1, targetHLen))
			addFlag = false;
			switch (ops(opI))
				case ("sqrt")
					if (isequal(head, "sqrt") || isequal(head, "abs")...
							|| ismember(head, terms) || ismember(head, bins))
            			addFlag = true;
					end
				case ("abs")
					if (ismember(head, bins))
            			addFlag = true;
					end
				case ("neg")
					if (isequal(head, "sqrt") || isequal(head, "sqr")...
							|| ismember(head, bins) || ismember(head, terms))
						addFlag = true;
					end
				case ("sqr")
					if (isequal(head, "sqr") || ismember(head, bins)...
							|| ismember(head, terms))
						addFlag = true;
					end
			end
			if (addFlag)
				sizeCounter = sizeCounter + 1;
			end
        end
    end
end

% initialize the return array new program list
nplist = strings(1, sizeCounter);

% loop for each existing program in plist
counter = 1;
for plistI = 1:length(plist)
    % get the root node's id for each code tree
    hct = plist(plistI);
    ctLen = hctSize(hct);
	[head, ~] = getHeadAndInputs(hct);

    % add each operator in ops as the root node for the existing code tree
    for opI = 1:length(ops)
        if (isequal(ctLen + 1, targetHLen))
			addFlag = false;
			switch (ops(opI))
				case ("sqrt")
					if (isequal(head, "sqrt") || isequal(head, "abs")...
							|| ismember(head, terms) || ismember(head, bins))
            			addFlag = true;
					end
				case ("abs")
					if (ismember(head, bins))
            			addFlag = true;
					end
				case ("neg")
					if (isequal(head, "sqrt") || isequal(head, "sqr")...
							|| ismember(head, bins) || ismember(head, terms))
						addFlag = true;
					end
				case ("sqr")
					if (isequal(head, "sqr") || ismember(head, bins)...
							|| ismember(head, terms))
						addFlag = true;
					end
			end
			if (addFlag)
				nct = sprintf("(%s %s)", ops(opI), hct);
				nplist(counter) = nct;
				counter = counter + 1;
			end
        end
    end
end
end

function [ahPair, totalExpanded] = evaluateHeuristicFormula(domain, plist, plistI,...
    totalExpanded, suboptM, expandedM, showEval, synH)
%% Evaluates the hct heuristic formula on problem set and construct the ahPair struct
% Shway Wang
% June 13, 2022

% Preliminaries
arguments
    domain (1,1) Domain
    plist (1,:) string
    plistI (1,1) uint64
    totalExpanded (1,1) double
    suboptM (:,:) double
    expandedM (:,:) uint64
    showEval (1,1) logical = false
    synH (1,:) cell = {}
end

% assign the A* algorithm
ahPair.alg.param = [1 1 0 NaN(1,10)];

% evaluate each of the hct's using A* search on ps2
ahPair.alg.hct = plist(plistI);

% compile the heuristic formula
hct = ahPair.alg.hct;
functionStr = hct2str(hct, synH);
ahPair.alg.hH = str2func(['@(x1,y1,x2,y2)' convertStringsToChars(functionStr)]);

% show the heuristic being evaluated currently
if (showEval)
    fprintf('evaluating heuristic %d/%d: %s\n', plistI, length(plist), hct);
end

[ahPair, totalExpanded] = triageEvaluation(domain, ahPair, totalExpanded, suboptM,...
	expandedM, synH, showEval);
end


function [ah, runningBest] = updateHistoricalBest(hct, regloss, showChampion, synH)
%% returns the updated historical best ah pair and its ps2loss to be the new running best loss
% Shway Wang
% May 6, 2022

arguments
	hct (1,1) string
	regloss (1,1) double
    showChampion (1,1) logical = false
	synH (1,:) cell = {}
end

% record the running best regularized loss
runningBest = regloss;
ah.regloss = regloss;

% assign the A* algorithm
ah.alg.param = [1 1 0 NaN(1,10)];

% evaluate each of the hct's using A* search on ps2
ah.alg.hct = hct;

% compile the heuristic formula
functionStr = hct2str(hct, synH);
ah.alg.hH = str2func(['@(x1,y1,x2,y2)' convertStringsToChars(functionStr)]);

% print out current best ah pair if the flag showChampion is set to true
if (showChampion)
	hStr = hct2latex(hct);
    fprintf('\nCurrent best:\n');
    fprintf('%s\n', hStr);
	fprintf('%s\n', hct);
    fprintf('current best ps training loss: %f\n\n', runningBest);
end
end
