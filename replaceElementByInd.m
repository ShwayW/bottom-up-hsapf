function newHCT = replaceElementByInd(hct, index, newElement)
%% Replace an element from hct specified by index
% base on file: GrammarHCT.m
% Shway Wang
% June 23, 2022

arguments
    hct (1,1) string
    index (1,1) uint64
    newElement (1,1) string
end

% Handle base cases
if (isequal(index, 1))
    newHCT = newElement;
    return;
end

% the index of the element we want to replace cannot exceed the size of hct
if (index > hctSize(hct))
    newHCT = hct;
    return;
end

% decrement index by 1
index = index - 1;

% analyze the current element hct
[head, inputs] = getHeadAndInputs(hct);

% depth-first index search
for inputI = 1:length(inputs)
    % depth-first search the subHCT
    subHCT = inputs(inputI);
    newSubHCT = replaceElementByInd(subHCT, index, newElement);

    % index is reduced by size of subHCT
    index = index - hctSize(subHCT);
    
    % if element is found
    if (~isequal(newSubHCT, subHCT) || ~index)
        inputs(inputI) = newSubHCT;
        newHCT = sprintf("(%s)", join([head, inputs]));
        return;
    end
end
end