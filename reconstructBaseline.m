function [subopt,expanded] = reconstructBaseline(ps, synthesisMapI)
%% Reconstruct baseline for a problem set
% Vadim Bulitko
% March 29, 2021

arguments
    ps (1,1) struct
    synthesisMapI (1,1) double
end

% preliminaries
subopt = ps.loadedBaseline.subopt(synthesisMapI, :);
expanded = ps.loadedBaseline.expanded(synthesisMapI, :);
end