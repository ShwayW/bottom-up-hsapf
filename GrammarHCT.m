classdef GrammarHCT
%% The class of Heuristic Formulae Code Tree grammar.
%% One can get all possible terminal, unary and binary nodes and generate random formulae given size
% Related files:
% getElementByInd.m, replaceElementByInd.m, getHeadAndInputs.m, hctSize.m,
% hct2str.m, hct2latex.m, countHCTatom.m, getDepth.m
% Shway Wang
% July 5, 2022

    % All terminal, unary and binary nodes
    properties (Access = public)
        T = ["x1", "y1", "x2", "y2", "deltaX", "deltaY"];
        U = ["sqrt", "abs", "neg", "sqr"];
        B = ["+", "-", "*", "/", "max"];
    end

    % methods include the constructor that appends possible building blocks
    methods (Access = public)
        function obj = GrammarHCT(synH)
        %% Constructor appending possible building blocks to the set of terminal nodes
        % Shway Wang
        % July 5, 2022

            arguments
                synH (1,:) cell = {}
            end

            % append to Terminals the building blocks
			if (nargin > 0)
				for i = 1:length(synH)
					obj.T = [obj.T, sprintf("synH{%d}(x1,y1,x2,y2)", i)];
				end
			end
			
			% add the constants to the set of terminals as well
			obj.T = [obj.T, 2];
        end

        function hct = randomHCT(self, hctSize)
        %% Produce a random hct using the CFG production rule
        %% checks if the produced hct has nested brackets of number less than 32 (matlab's limit)
        % Shway Wang
        % June 29, 2022
        % Aug 4, 2022

            arguments
                self (1,1) GrammarHCT
                hctSize (1,1) uint64 = randi(20)
            end

            % keep trying to produce a code tree with less than 32 nested brackets
            while (true)
                % generate an hct of size hctSize
                hct = self.generateRandomHCT(hctSize);

                % check if the nested brackets are of number less than 32
                if (count(hct2str(hct), "(") < 32)
                    return;
                end
            end
        end
    end
    methods (Access = private)
        function hct = generateRandomHCT(self, hctSize)
        %% Produce a random hct using the CFG production rule
        % Shway Wang
        % June 29, 2022

            arguments
                self (1,1) GrammarHCT
                hctSize (1,1) uint64
            end

            % Base cases
            if (hctSize == 1) % Terminal
                hct = randsample([self.T, sprintf("%0.1f", max(1.0, 10*rand(1, 1, "double")))], 1);
                return;
            elseif (hctSize == 2)
                hct = sprintf("(%s %s)", randsample(self.U, 1), self.generateRandomHCT(hctSize - 1));
                return;
            end

            % Inductive cases
            switch (randi(2))
                case (1) % Unary
                    hct = sprintf("(%s %s)", randsample(self.U, 1), self.generateRandomHCT(hctSize - 1));
                case (2) % Binary
                    % size of first and second inputs are random but must add up to hctSize - 1
                    firstLen = randi(hctSize - 2);
                    first = self.generateRandomHCT(firstLen);
                    second = self.generateRandomHCT(hctSize - 1 - firstLen);
                    hct = sprintf("(%s %s %s)", randsample(self.B, 1), first, second);
            end
        end
    end
end
