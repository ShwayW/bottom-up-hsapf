function dirName = makeResultsDirPath(domain, budgetI, chunking)
%% Construct the path to store the synthesis results
% Shway Wang
% June 14, 2022
% Shway Wang added support for sliding tile puzzles
% July 21, 2022

arguments
    domain (1,1) Domain
    budgetI (1,1) uint64
    chunking (1,1) logical
end

% Options for printing out the heuristics (either we use the Manhattan Distance or we synthesized)
% and information for the unified algorithm
% and grammar can be either base grammar or enriched (chunking) grammar
grammarOptions = ["base", "chunking"];

% construct the set name
setNamesStr = sprintf("%d_sets", length(domain.setNames));
dirName = sprintf('results/synthesis/mat/%s_permap-budget-%s',...
	setNamesStr, hrNumber(domain.per_map_budget));

% generate the name of the parent directory
dirName = sprintf('%s_chunking-%s', dirName, grammarOptions(chunking + 1));

% for different problem domains
ind = getIndStrByMaxInd(length(domain.mapI_cell_arr{budgetI}), domain.maxMaps);
dirName = sprintf('%s/%s_maps', dirName, ind);

% make the directory if it does not exist
if(~(isfolder(dirName)))
    mkdir(dirName);
end
end