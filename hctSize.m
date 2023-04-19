function numNodes = hctSize(hct)
%% Get the size of the hct
% base on file: GrammarHCT.m
% Shway Wang
% June 23, 2022

arguments
    hct (1,1) string
end

%% Base case
if (isequal(hct, ""))
    % size is 0 if hct is empty
    numNodes = 0;
    return;
elseif (~startsWith(hct, "("))
    % hct is an atom (terminal), so number of nodes is one
    numNodes = 1;
    return
end

%% Inductive case
% split hct into head and inputs format
[~, inputs] = getHeadAndInputs(hct);

% number of nodes in hct is 1 + number of nodes in each of the inputs
numNodes = 1;
for inputI = 1:length(inputs)
    numNodes = numNodes + hctSize(inputs(inputI));
end
end