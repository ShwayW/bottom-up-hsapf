function hct = simplifyHCT(hct, synH, verbose)
%% Simplify the given heuristic code tree and return the simplified result with the new data structure
% Shway Wang
% June 15th, 2020

%% Argument types and default parameters
arguments
    hct (1,1) string
    synH (1,:) cell = {}
    verbose (1,1) logical = false
end

%% Preliminaries
% Get the head and inputs of current hct
[head, inputs] = getHeadAndInputs(hct);

% initialize the simplified inputs
inputsSimplified = [];

%% Process it accordingly, from inner to outer
assert(length(inputs) < 3);

if (isempty(inputs))
    % Current node is in its simplist form, so change curNode to parent(if exists) and return
    if (verbose)
        fprintf("Current node is atomic: %s, \n", hct);
    end
    return;
end

switch (length(inputs))
    case (1) % curent node is unary
        if (verbose)
            fprintf("Current node is unary: %s, \n", hct);
        end
        
        % Current node is unary, need to simplify the subtree first, then deal with the outer structure
        inputsSimplified = [inputsSimplified, simplifyHCT(inputs(1), synH, verbose)];
    case (2) % current node is binary
        if (verbose)
            fprintf("Current node is binary: %s, \n", hct);
        end
        
        % simplify both inputs
        inputsSimplified = [inputsSimplified, simplifyHCT(inputs(1), synH, verbose)];
        inputsSimplified = [inputsSimplified, simplifyHCT(inputs(2), synH, verbose)];
end

% get the current hct
hct = sprintf("(%s)", join([head, inputsSimplified]));

%% Now to deal with the current node with successors simplified.
switch (length(inputs))
    case (1) % Unary case
        hct = simplifyCurrentUnaryHCT(hct, synH, verbose);
    case (2) % Binary case
        hct = simplifyCurrentBinaryHCT(hct, verbose);
    otherwise
        if verbose
            fprintf("No simplification needed for: %s\n", hct2latex(hct));
        end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hct = simplifyCurrentUnaryHCT(hct, synH, verbose)
%% If the current node is a unary node, simplify the current node
%% Assuming the current node"s successor is simplified
% Shway Wang, consulted with Justin Stevens
% May 30, 2021
% Modified to use the new data structure
% Shway Wang
% June 15, 2021

%% Argument types and default parameters
arguments
    hct (1,1) string
    synH (1,:) cell = {}
    verbose (1,1) logical = false
end

%% Preliminaries:
% declare the grammar of hct
grammar = GrammarHCT(synH);

% get the head of the current node
[curNodeHead, succContent] = getHeadAndInputs(hct);

% Get its successor'(s) id (current node is unary so only one)
[succHead, succsuccContent] = getHeadAndInputs(succContent);

% the set of constants
set = 0.1:0.1:10.0;
constants = strings(1, length(set));
for i = 1:length(set)
    constants(i) = num2str(set(i), "%0.1f");
end

if verbose
    fprintf("current node is unary: ");
end
%% In this case, current node is one of: "sqrt", "abs", "neg", "sqr" (unary)
switch (curNodeHead)
    case ("sqrt")
        if verbose
            fprintf("current node is sqrt\n");
        end
        switch (succHead)
            case ("sqr") % sqrt(sqr(a)) = |a|. According to Justin.
                if verbose
                    fprintf("\tchild is sqr, sqrt(sqr(a)) = |a| then simplify again\n");
                end
                
                % make current node "abs" and remove current node"s child.
                hct = sprintf("(abs %s)", succsuccContent);
                
                % need to simplify from here again to make sure current abs is checked
                if verbose
                    fprintf("\t\twent into |alpha|\n");
                end
            case ("1.0") % sqrt(1) = 1
                if verbose
                    fprintf("\tchild is 1, sqrt(1) = 1\n");
                end
                
                % remove current node "sqrt", then connect pred to succ
                hct = succContent;
            otherwise
                if verbose
                    fprintf("\tNot applicable child: %s\n", succContent);
                end
        end
    case ("sqr")
        if verbose
            fprintf("current node is sqr\n");
        end
        
        % get the grand child of current node
        switch (succHead)
            case ("sqrt")
                if verbose
                    fprintf("\tchild is sqrt, so remove both.\n");
                end
                
                % sqr(sqrt(a)) = a
                hct = succsuccContent;
            case ("neg")
                if verbose
                    fprintf("child is unary -\n");
                end

                % sqr(-a) = sqr(a)
                hct = sprintf("(%s %s)", curNodeHead, succsuccContent);
            case ("abs")
                if verbose
                    fprintf("\tchild is abs, so cancel the abs\n");
                end
                
                % sqr(|a|) = sqr(a)
                hct = sprintf("(%s %s)", curNodeHead, succsuccContent);
            case ("1.0")
                if verbose
                    fprintf("\tchild is 1, sqr(1) = 1\n");
                end
                
                % sqr(1) = 1
                % remove current node "sqr", then connect pred to succ
                hct = succContent;
            otherwise
                if verbose
                    fprintf("\tNot aplicable child: %s\n", succContent);
                end
        end
    case ("abs")
        if verbose
            fprintf("current node is abs\n");
        end
        
        % "abs" is not necessary if it is outside of one of: {"abs", "delta", "sqr", "sqrt(constant)"}
        % "abs" is still necessary if its successor is "sqrt", since we need to
        % take into account the complex numbers
        % get the grand child of current node
        switch (succHead)
            case ("sqr")
                if verbose
                    fprintf("\tchild is sqr, so cancel the parent abs\n");
                end
                
                % |sqr(a)| = sqr(a)
                hct = succContent;
            case ("neg")
                % need to know if succsucc has just one element or two, proceed if it has just one
                if verbose
                    fprintf("\tchild is unary - and grandChild is constant or must be positive\n");
                end

                % |-a| = a
                hct = succsuccContent;
            case ("sqrt")
                if verbose
                    fprintf("\tchild is sqrt, need to check if grand child is constant\n");
                end
                
                % |sqrt(constant)| = sqrt(constant)
                hct = succContent;
            case ("abs")
                if verbose
                    fprintf("\tchild is abs, need to check if grand child is constant\n");
                end
                
                % ||a|| = |a|
                hct = succContent;
            otherwise
                if (ismember(succHead, [grammar.T, constants]))
                    if verbose
                        fprintf("\t\tchild is abs, delta, or a constant, so cancel the parent abs\n");
                    end

                    % ||a|| = |a|; |delta(x1,x2)| = delta(x1,x2); |delta(y1,y2)| = delta(y1,y2); |constant| = constant
                    hct = succContent;
                else
                    if verbose
                        fprintf("\tNot aplicable child: %s\n", succContent);
                    end
                end
        end
    case ("neg")
        if verbose
            fprintf("current node is unary -\n");
        end
        
        % different actions based on different succesors
        switch (succHead)
            case ("neg")
                if verbose
                    fprintf("\tchild is unary -, so cancel both -,-\n");
                end

                % -(-a) = a
                hct = succsuccContent;
            case ("-")
                if verbose
                    fprintf("\tchild is binary -, so bypass current - and exchange the positions of grand children\n");
                end

                % -(a - b) = b - a
                hct = sprintf("(%s %s %s)", succHead, succsuccContent(2), succsuccContent(1));
            otherwise
                if verbose
                    fprintf("\tNot aplicable child: %s\n", succContent);
                end
        end
end
end


function hct = simplifyCurrentBinaryHCT(hct, verbose)
%% If the current node is a binary node, simplify the current node.
%% Assuming the current node"s successors are simplified
% Shway Wang, consulted with Justin Stevens
% May 30, 2020
% Modified to use the new data structure
% Shway Wang
% June 15, 2021

%% Argument types and default parameters
arguments
    hct (1,1) string
    verbose (1,1) logical = false
end

%% Preliminaries:
% get the content of the current node
[curNodeHead, succContents] = getHeadAndInputs(hct);

% Get its successor'(s) id (current node is unary so only one)
[leftSuccHead, leftSuccsuccContent] = getHeadAndInputs(succContents(1));
[rightSuccHead, rightSuccsuccContent] = getHeadAndInputs(succContents(2));

if (verbose)
    fprintf("current node is binary: ");
end

%% In this case, current node is one of: "+", "-", "*", "/", "max", "min"
switch (curNodeHead)
    case ("+")
        if verbose
            fprintf("current node is binary + \n");
        end
        if (isequal(leftSuccHead, "neg"))
            if verbose
                fprintf("\tleft child is unary -\n");
            end
            
            % -a + b = b - a
            hct = sprintf("(- %s %s)", succContents(2), leftSuccsuccContent);
        elseif (isequal(rightSuccHead, "neg"))
            if verbose
                fprintf("\tright child is unary -\n");
            end
            
            % a + (-b) = a - b
            hct = sprintf("(- %s %s)", succContents(1), rightSuccsuccContent);
        end
    case ("-")
        if verbose
            fprintf("current node is binary - \n");
        end
        if (isequal(rightSuccHead, "neg"))
            if verbose
                fprintf("\tright child is unary -\n");
            end
            
            % a - (-b) = a + b
            hct = sprintf("(+ %s %s)", succContents(1), rightSuccsuccContent);
        end
    case ("*")
        if verbose
            fprintf("current node is *\n");
        end
        if (isequal(rightSuccHead, "1.0"))
            if verbose
                fprintf("\tchild is 1.0, so remove both * and 1\n");
            end
            
            % a * 1 = a
            hct = succContents(1);
        elseif (isequal(rightSuccHead, "neg") && isequal(rightSuccsuccContent, "1.0"))
            if verbose
                fprintf("\tright child is -1, so make current node unary - and remove edge between curNode and right child\n");
            end
            
            % a * -1 = -a
            hct = sprintf("(neg %s)", succContents(1));
        elseif (isequal(leftSuccHead, "1.0"))
            if verbose
                fprintf("\tleft child is 1, so remove current * and 1\n");
            end
            
            % 1 * a = a
            hct = succContents(2);
        elseif (isequal(leftSuccHead, "neg") && isequal(leftSuccsuccContent, "1.0"))
            if verbose
                fprintf("\tleft child is -1, so make current node unary - and remove edge between curNode and left child\n");
            end
            
            % -1 * a = -a
            hct = sprintf("(neg %s)", succContents(2));
        end
    case ("/")
        if verbose
            fprintf("current node is /\n");
        end
        if (isequal(rightSuccHead, "1.0"))
            if verbose
                fprintf("\tright child is 1, so remove the current / and 1\n");
            end
            
            % a / 1 = a
            hct = succContents(1);
        elseif (isequal(rightSuccHead, "neg") && isequal(leftSuccsuccContent, "1.0"))
            if verbose
                fprintf("\tright child is -1, so make current node unary - and remove current /\n");
            end
            
            % a / -1 = -a
            hct = sprintf("(neg %s)", succContents(1));
        end
    case ("max")
        if verbose
            fprintf("current node is max\n");
        end
        if (~isnan(str2double(leftSuccHead)) && ~isnan(str2double(rightSuccHead)))
            if verbose
                fprintf("\tboth children are constants, so the greater is left\n");
            end
            
            % max(bigger, smaller) = bigger
            hct = num2str(max(str2double(leftSuccHead), str2double(rightSuccHead)));
        end
    case ("min")
        if verbose
            fprintf("current node is min\n");
        end
        if (~isnan(str2double(leftSuccHead)) && ~isnan(str2double(rightSuccHead)))
            if verbose
                fprintf("\tboth children are constants, so the lesser is left\n");
            end
            
            % min(bigger, smaller) = smaller
            hct = num2str(min(str2double(leftSuccHead), str2double(rightSuccHead)));
        end
otherwise
    if verbose
        fprintf("No simplify\n");
    end
end
end

