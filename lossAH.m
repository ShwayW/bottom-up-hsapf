function [loss, baselineRef] = lossAH(meanSubopt, meanExpanded, suboptM, expandedM, verbose)
%% Computes performance loss of A+H
% Vadim Bulitko
% Jan 29, 2021

arguments
    meanSubopt (1,1) double
    meanExpanded (1,1) double
    suboptM (1,:) double
    expandedM (1,:) double
    verbose (1,1) logical = false
end

% compute a scalar performance metric for the new combination of A+H
% loss is the ratio of expanded nodes to that of the baseline, for a matching suboptimality
[loss, baselineRef] = expandedRatio(meanSubopt, meanExpanded, suboptM, expandedM, verbose);
assert(~isnan(loss));
end
