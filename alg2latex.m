function [algStr,hStr] = alg2latex(alg)
%% Converts an A+H combination to two LaTeX strings
% Vadim Bulitko
% Jan 29, 2021
% Shway Wang removed support for priority functions and real-time search

arguments
    alg (1,1) struct
end

%% Convert the algorithm
% get the algorithm string
algStr = alg2latexNRT(alg.param);

% get the heuristic formula string
hStr = hct2latex(alg.hct);
end

