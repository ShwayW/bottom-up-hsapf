function str = hct2str(hct, synH)
%% Convert prefix notation to infix notation
% base on file: GrammarHCT.m
% Shway Wang
% June 22, 2022

arguments
    hct (1,1) string
    synH (1,:) cell = {}
end

%% Preliminaries
% declare the hct grammar object
grammar = GrammarHCT(synH);

%% Base case
% no parenthesis around
% If hct is a terminal, return it as it is.
terminals = grammar.T;

% note here that if hct is a number, it is also a terminal
if (ismember(hct, terminals) || ~isnan(str2double(hct)))
    if (contains(hct, "synH"))
        a = textscan(hct, "synH{%d}(x1,y1,x2,y2)");
        str = char(synH{a{1}}.hH);
        str = str(15:end); % get rid of the prefixing "@(x1,y1,x2,y2)"
    else
        str = inficizeSymbol(hct);
    end
    return;
end

%% Inductive case
% start analyze hct
[head, inputs] = getHeadAndInputs(hct);

% If hct is a unary operator, return in infix notation.
unaries = grammar.U;
if (ismember(head, unaries))
    % assuming here inputs is of length 1
    assert(length(inputs) == 1);
    
    % change the head to its infix version
    head = inficizeSymbol(head);
    
    % convert the input to infix
    input = hct2str(inputs, synH);
    
    % add one extra bracket by case
    if (isletter(head(1))) % "sqrt", "sqr" etc.
        str = sprintf("%s(%s)", head, input);
    else % "-" etc.
        str = sprintf("(%s(%s))", head, input);
    end
    return;
end

% If hct is a binary operator, return in infix notation.
binaries = grammar.B;
if (ismember(head, binaries))
    % assuming here inputs is of length 2
    assert(length(inputs) == 2);
    
    % change the head to its infix version
    head = inficizeSymbol(head);
    
    % convert the inputs to infix
    firstInput = hct2str(inputs(1), synH);
    secondInput = hct2str(inputs(2), synH);
    
    % different bracket positions by case
    if (isletter(head(1))) % "min", "max" etc.
        str = sprintf("%s(%s, %s)", head, firstInput, secondInput);
    else % "+", "-", "*", "/" etc.
        str = sprintf("(%s %s %s)", firstInput, head, secondInput);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%

function infixSymbol = inficizeSymbol(prefixSymbol)
%% Change the prefix symbol to its infix version
% Shway Wang
% June 22, 2022

arguments
    prefixSymbol (1,1) string
end

switch (prefixSymbol)
    case ("neg")
        infixSymbol = "-";
    case ("deltaX")
        infixSymbol = "delta(x1,x2)";
    case ("deltaY")
        infixSymbol = "delta(y1,y2)";
    otherwise
        infixSymbol = prefixSymbol;
end
end
