function latexStr = latexEN(x)
% Outputs a number as x.yy \times 10^z

arguments
    x (1,1) double
end

% the special cases
if (x == 0)
    latexStr = '0';
    return
end

if (isinf(x))
    if (x < 0)
        latexStr = '-\infty';
    else
        latexStr = '\infty';
    end
    return
end

% a human readable range
if (x >= -1000 && x <= 1000)
    if (x == round(x))
        latexStr = sprintf('%d',x);
    else
        latexStr = sprintf('%0.2f',x);
    end
    return
end

% otherwise, find the scale
scale = 10^floor(log10(abs(x)));

mantissa = round(x/scale,2);
exponent = floor(log10(abs(x)));

% Do we have a non-trivial exponent?
if (exponent == 0)
    % no --- no need to multiply by 10^0
    if (round(mantissa) == mantissa)
        % integer mantissa
        latexStr = sprintf('%d',round(mantissa));
    else
        % general form
        latexStr = sprintf('%0.2f',mantissa);
    end
    return
end

% Yes
if (abs(mantissa) == 1)
    if (x < 0)
        % mantissa = -1
        latexStr = sprintf('-(10^{%d})',exponent);
    else
        % mantissa = 1
        latexStr = sprintf('10^{%d}',exponent);
    end
    return
end

if (round(mantissa) == mantissa)
    % integer mantissa
    latexStr = sprintf('%d \\times 10^{%d}',round(mantissa),exponent);
else
    % general form
    latexStr = sprintf('%0.2f \\times 10^{%d}',mantissa,exponent);
end

end
