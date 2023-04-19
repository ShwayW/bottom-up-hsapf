function sahBatch(domain)
%% Running a number of multimap heuristic forlumae synthesis trials on a number of maps
% Shway Wang
% June 7, 2022

% Sean Paetz
% July 8th, 2022

arguments
    % Should be one of: [
    % DomainPathFnd({[<mapIndices>], <mapIArrays>}, <numProblemsLowerBound>)
    % DomainSlideTile(<budget>)
    % ]
    domain (1,1) Domain = DomainPathFnd({[1]}, 1)
end

% matlab initialization
clc;
format short g

%% Parameters (modify below as you see fit)
% building blocks for heuristics
% (each element of cell a string containing the paths to chunks)
hChunkFiles = {
    %"results/bblocks/wallhug.mat"
};

% the verbose
verbose = true;

%% the trial loop and other setting that are almost always fixed
% if on Compute Canada, this script runs only 1 trial
numTrials = 1;

% start recording the total time it takes
tic

% loop for all possible combainations of the array variables above
for tI = 1:numTrials
    % run a trial with the specified parameters
    sahTrial(domain, 1, hChunkFiles, tI, verbose);
end

% time record stops here
toc
end
