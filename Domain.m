classdef Domain
%% The class representing problem domain, with the properties that all domain should have in common.
% Shway Wang
% July 26, 2022

%% Properties (will be set automatically)
properties (Access = public)
    % the problem domain, one of: ["pathfinding", "slidingtile"]
    %% TODO: consider name change
    problemDomain;
    
    % budgets (array of positive double arrays)
    budget_arr;
    
    % problem sets
    problemSets = {};
    
    % the struct for problem set final
    psf;
    
    % the struct for test problem set
    test = struct([]);
end

%% Methods
methods
    function obj = Domain(problemDomain, budget_arr)
    %% Constructor for the Domain class
    % July 26, 2022
    % Shway Wang
        arguments
            problemDomain (1,1) string
            budget_arr (1,:) double = []
        end

        % assignment to property
        obj.problemDomain = problemDomain;
        obj.budget_arr = budget_arr;
    end
end
end