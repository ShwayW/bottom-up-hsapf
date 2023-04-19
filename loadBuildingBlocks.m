function synH = loadBuildingBlocks(hChunkFiles, verbose)
%% Load the building blocks from the files specified by paths in hChunkFiles
% Shway Wang
% June 17, 2022

arguments
    hChunkFiles (1,:) cell
    verbose (1,1) logical = false
end

% initialize the output
synH = {};

% adding chunks for the heuristic expressions
for i = 1:length(hChunkFiles)
    file = hChunkFiles{i};
    data = load(file);
    
    % all building blocks are the same within each building block file
    synH{end + 1} = data.bestSynthResults(1).alg; %#ok<AGROW>
    
    if (verbose)
        fprintf('\nLoaded heuristic terminal node from:\n\t%s\n', file);
    end
end
end