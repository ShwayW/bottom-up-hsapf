function str = hct2latex(hct, synH)
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
if (ismember(hct, terminals) || ~isnan(str2double(hct)) || startsWith(hct, "synH"))
    switch (hct)
        case ("x1")
            str = "x";
        case ("y1")
            str = "y";
        case ("x2")
            str = "x_g";
        case ("y2")
            str = "y_g";
        case ("deltaX")
            str = "\Delta x";
        case ("deltaY")
            str = "\Delta y";
        otherwise
            if (startsWith(hct, "synH"))
                % processing terminal nodes of the type synH{%d}(x1,y1,x2,y2)
                a = textscan(hct, "synH{%d}(x1,y1,x2,y2)");
                a = a{1}; % de-cell
                str = sprintf("\\mathbf{f_{%d}}", a);
            else
                % just a numeric constant
                str = sprintf("%0.1f", str2double(hct));
            end
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
    
    % convert the input to infix
    input = hct2latex(inputs, synH);
    
    % add one extra bracket by case
    switch (head)
        case ("sqrt")
            str = sprintf("\\sqrt{%s}", input);
        case ("sqr")
            str = sprintf("\\left(%s\\right)^2", input);
        case ("abs")
            str = sprintf("\\left|%s\\right|", input);
        case ("neg")
            str = sprintf("\\left(-%s\\right)", input);
    end
    return;
end

% If hct is a binary operator, return in infix notation.
binaries = grammar.B;
if (ismember(head, binaries))
    % assuming here inputs is of length 2
    assert(length(inputs) == 2);
    
    % convert the inputs to infix
    firstInput = hct2latex(inputs(1), synH);
    secondInput = hct2latex(inputs(2), synH);
    
    % different bracket positions by case
    switch (head)
        case "/"
            str = sprintf("\\frac{%s}{%s}", firstInput, secondInput);
        case "*"
            str = sprintf("%s \\cdot %s", firstInput, secondInput);
        case "+"
            str = sprintf("\\left(%s + %s\\right)", firstInput, secondInput);
        case "-"
            str = sprintf("\\left(%s - %s\\right)", firstInput, secondInput);
        case "max"
            str = sprintf("\\max\\left\\{%s,%s\\right\\}", firstInput, secondInput);
        case "min"
            str = sprintf("\\min\\left\\{%s,%s\\right\\}", firstInput, secondInput);
    end
end
end
