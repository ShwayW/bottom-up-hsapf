function element = getElementByInd(hct, index)
%% Get an element from hct specified by index
% base on file: GrammarHCT.m
% Shway Wang
% June 23, 2022

arguments
    hct (1,1) string
    index (1,1) uint64
end

% Handle base cases
if (isequal(index, 1))
    element = hct;
    return;
end

% the index of the element we want cannot exceed the size of hct
if (index > hctSize(hct))
    element = "";
    return;
end

% decrement index by 1
index = index - 1;

% analyze the current element hct
[~, inputs] = getHeadAndInputs(hct);

% depth-first index search
for inputI = 1:length(inputs)
    % depth-first search the subHCT
    subHCT = inputs(inputI);
    element = getElementByInd(subHCT, index);

    % if element is found
    if (~isequal(element, ""))
        return;
    end

    % if element is not found
    index = index - hctSize(subHCT);
end
end