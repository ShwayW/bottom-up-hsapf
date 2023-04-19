function componentIndecies = computeLCC(map)
%% Computes state indecies in the largest connected component in a map
% Vadim Bulitko
% June 4, 2020

arguments
    map (:,:) logical
end

%% Compute the largest connected component
cc = connectedComponents(map);
ccI = unique(cc(:));
if (ccI(1) == -1)
    ccI = ccI(2:end);       % drop the -1 denoting the walls
end
numCC = length(ccI);

% compute their sizes
ccSize = NaN(1,numCC);
for i = 1:numCC
    c = ccI(i);
    ccSize(i) = nnz(cc == c);
end

% pick the largest connected component
[~,i] = max(ccSize);
maxCCI = ccI(i);

assert(size(maxCCI,1) == 1 && size(maxCCI,2) == 1);

% get its indecies
componentIndecies = int64(find(cc == maxCCI)');
% shuffle them randomly
%componentIndecies = componentIndecies(randperm(length(componentIndecies)));

end
