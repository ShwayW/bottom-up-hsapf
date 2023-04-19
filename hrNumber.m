function str = hrNumber(x,roundAnswer)
%% Converts a number into a better human-readable string
% Vadim Bulitko
% modified on May 27, 2020 and Dec 12, 2020

arguments
    x (1,1) double
    roundAnswer (1,1) logical = false
end

% check for infinity
if (isinf(x))
    if (x < 0)
        str = '-Inf';
    else
        str = 'Inf';
    end
    return
end

if (~roundAnswer)
    % use %0.1f output
    if (x < 10^3)
        str = sprintf('%0.0f',x);
    elseif (x < 10^6)
        str = sprintf('%0.1fK',x/10^3);
    elseif (x < 10^9)
        str = sprintf('%0.1fM',x/10^6);
    else
        str = sprintf('%0.1fB',x/10^9);
    end
    
else
    % use int output
    if (x < 10^3)
        str = sprintf('%d',round(x));
    elseif (x < 10^6)
        str = sprintf('%dK',round(x/10^3));
    elseif (x < 10^9)
        str = sprintf('%dM',round(x/10^6));
    else
        str = sprintf('%dB',round(x/10^9));
    end
end

return
