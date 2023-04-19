function indStr = getIndStrByMaxInd(index, totalIndex)
%% Get the map set's index string by giving the max number of maps
% Shway Wamg
% April 29, 2022

arguments 
    index (1,1) uint64
    totalIndex (1,1) uint64 % total number of maps in the provided map set
end

% get the number of digits in the total number of maps
digitNum = length(sprintf('%d', totalIndex));

% initialize the map set index string
indStr = sprintf('%d', index);

% digitNum must be greater than the map set's index
assert(digitNum >= length(indStr));

% preppend (digitNum - length(mapSetIndStr)) many zeros to mapSetIndStr
for prefixZeroI = 1:(digitNum - length(indStr))
    indStr = sprintf("0%s", indStr);
end

% convert mapSetIndStr to a string if it is not already one
indStr = convertCharsToStrings(indStr);
end