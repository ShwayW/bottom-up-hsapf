function [eRatio, bExpanded] = expandedRatio(subopt, expanded, baselineSubopt, baselineExpanded, verbose)
%% Compute expanded ratio
% Vadim Bulitko
% Jan 29, 2021
% Shway Wang added handle for the case where all elements of baselineSubopt
% are the same. Then should take the w with the fewest nodes expanded
% Oct. 31, 2022

arguments
    subopt (1,1) double
    expanded (1,1) double
    baselineSubopt (1,:) double
    baselineExpanded (1,:) double
    verbose (1,1) logical = false
end

%% Make sure the given subopt is not to the left of the baseline frontier
assert(subopt >= baselineSubopt(1));

%% Find the number of states expanded that the baseline would do for
if (subopt < baselineSubopt(1))
    % the value of suboptimality we have is beneath what we have in the baseline frontier
    % extend the frontier to the left
    bExpanded = baselineExpanded(1);
elseif (subopt >= max(baselineSubopt))
    % the value of suboptimality we have is beyond what we have in the baseline frontier
    % extend the frontier to the right
    bExpanded = baselineExpanded(end);
else
    % find two points in the baseline frontier which sandwich our subopt value
    for i = 1:length(baselineSubopt)-1
        if (baselineSubopt(i) <= subopt && baselineSubopt(i + 1) > subopt) % used to be && baselineSubopt(i + 1) > subopt)
            % linear interpolation
            bExpanded = baselineExpanded(i) + (baselineExpanded(i+1)-baselineExpanded(i))*(subopt-baselineSubopt(i))/(baselineSubopt(i+1)-baselineSubopt(i));
            break
        end
    end
end

%% Does the baseline expand fewer or more states than the candidate?
eRatio = expanded / bExpanded;

if (verbose)
    fprintf('%d/%d = %0.5f\n', expanded, bExpanded, eRatio);
end

end
