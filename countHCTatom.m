function number = countHCTatom(hct, atom)
%% Counts the number of occurences of the given atom in the given hct
% base on file: GrammarHCT.m
% Shway Wang
% July 29, 2022

arguments
    hct (1,1) string
    atom (1,1) string
end

%% Preliminaries
number = 0;
[head, inputs] = getHeadAndInputs(hct);

% check if the head and the atom are the same, if so, increment number
if (isequal(atom, head))
    number = 1;
end

%% Base case
% if the head is a terminal
if (isempty(inputs))
    return;
end

%% Inductive case
% if the head is not a terminal
if (length(inputs) == 1) % the head is unary
    number = number + countHCTatom(inputs, atom);
elseif (length(inputs) == 2) % the head is binary
    number = number + countHCTatom(inputs(1), atom) + countHCTatom(inputs(2), atom);
end
end
