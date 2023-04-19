function champs = insert(champs, ahCand, temperature)
%% probabilistic insert

% Preliminaries
arguments
    champs (1, :) struct % the current champion-pairs, assumed to be sorted by their losses in ascending order
    ahCand (1, 1) struct % the candidate pair to be inserted
    temperature (1, 1) double % the temperature used for probabilistic acceptance
end

% get the size of the champion
champSize = length(champs);

for i = 1:champSize    
    % Acceptance probability is e^(-(l_c-l_best)/T), where l_c is the
    % current loss and l_best is the best loss in the champion array
    % the temperature acceptance
    if (temperature == 0)
        isTempAccept = false;
    else
        aProb = exp(-(ahCand.ps2regloss - champs(i).ps2regloss)/temperature);
        isTempAccept = rand < aProb;    
    end

    % Update the best heuristic found so far according to the pseudocode
    % If the regularized loss is an improvement, then we update the
    % heuristic. Otherwise, we accept it with a probability and temperature
    isLowerRegPs2Loss = ahCand.ps2regloss < champs(i).ps2regloss;

    % check condition
    if (isLowerRegPs2Loss || isTempAccept)
        % update the old champion with the new one
        champs = [champs(1:(i - 1)), ahCand, champs(i:(champSize - 1))];
    end
end

end