function [head, inputs] = getHeadAndInputs(hct)
%% Seperate the head and inputs of the tuple hct, assuming hct is not a terminal
% base on file: GrammarHCT.m
% If hct is a list
% "(head input1 input2 ...)" => ["head", ["input1", "input2", ...]]
% If hct is an atom
% "head" => ["head", []]
% Shway Wang
% June 22, 2022

arguments
    hct (1,1) string
end

if (startsWith(hct, "(")) % hct is a list
    % get the head and the rest of the input string from hct
    [head, restHCT] = seperateHead(hct);

    % make the input list
    inputs = splitElements(restHCT);
else % hct is an atom
    head = hct;
    inputs = [];
end
end

%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [head, restStr] = seperateHead(hct)
%% Assuming hct is a string of form: "(head element1 element2 ...)" assuming "head" is an atom
%% return ["head", "element1 element2 ..."]
% Shway Wang
% June 22, 2022

arguments
    hct (1,1) string 
end

% peel away the outer most parenthesis
charHCT = char(hct);
charHCT = charHCT(2:end - 1);
hct = string(charHCT);
hctList = split(hct);

% get the head of the current list
head = hctList(1);

% get the rest of hct without the head
hctList = hctList(2:end);
restStr = join(hctList);
end

function elements = splitElements(hct)
%% Assuming hct is of the form: "element1 element2 ..." where each element might be an atom or a list
%% Returns an array of form: ["element1", "element2", ...]
% Shway Wang
% June 22, 2022

arguments
    hct (1,1) string
end

%% Preliminaries
% initialize the output
elements = [];

% get rid of white spaces around hct
hct = strip(hct);

%% Base case,
if (isequal(hct, "") || ismissing(hct))
    % return an empty list
    return;
end

%% Inductive case
if (startsWith(hct, "(")) % first element is a list
    [firstElement, restHCT] = seperateFirstList(char(hct));
else % first element is an atom
    % split hct into an array of strings
    hctStrArr = split(hct);
    
    % get the first element and the rest of hct
    firstElement = hctStrArr(1);
    restHCT = join(hctStrArr(2:end));
end

% the list of elements is the first element with the rest of splited elements
elements = [firstElement, splitElements(restHCT)];
end

function [firstList, restHCT] = seperateFirstList(hct)
%% Assuming hct starts with a list, seperate that list from hct
% Shway Wang
% June 23, 2022

arguments
    hct (1,:) char
end

% number of lonely left brackets
numLoneLB = 0;
for charI = 1:length(hct)
    if (isequal(hct(charI), '('))
        numLoneLB = numLoneLB + 1;
    elseif (isequal(hct(charI), ')'))
        numLoneLB = numLoneLB - 1;
    end
    
    % if all lonely left brackets found their matches
    if (~numLoneLB)
        % return both as strings
        firstList = string(hct(1:charI));
        restHCT = string(hct(charI + 1:end));
        return;
    end
end
end
