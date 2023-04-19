function h = pcolor2(x, y, v, linewidth, displayValues)
%% pcolor2 is a pcolor plot that displays all values
% Vadim Bulitko
% Feb 17, 2022

arguments
    x (1, :) double
    y (1, :) double
    v (:, :) double
    linewidth (1, 1) double = 0.1
    displayValues (1, 1) logical = false
end

%% Preliminaries
% don't display x and y labels if they are too long
maxLabelLength = 40;

%% Pad the matrix
h = pcolor(padMatrix(v));

%% Display the plot
if (length(x) <= maxLabelLength)
    set(gca, 'XTick', (1:length(x)) + 0.5);
    set(gca, 'XTickLabel', x);
end

if (length(y) <= maxLabelLength)
    set(gca, 'YTick', (1:length(y)) + 0.5);
    set(gca, 'YTickLabel', y);
end

colorbar(gca);
axis(gca, 'tight'); % ij;

%% Lines separating the plot
if (linewidth ~= 0)
    set(h, 'LineWidth', linewidth);
    set(h, 'EdgeColor', [0.8500, 0.3250, 0.0980]);
else
    set(h, 'EdgeColor', 'none');
end

box on

%% Display data values if requested
if (displayValues)
    hold on

    for xI = 1:size(v, 2)
        for yI = 1:size(v, 1)
            text(xI + 0.25, yI + 0.5, latexEN(v(yI, xI)), 'Color', 'white');
        end
    end

    hold off
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function paddedMatrix = padMatrix(m)
%% padMatrix adds a right-most column and a bottom row
% This is useful for pcolor and surf which remove the appropriate parts

paddedMatrix = [m, m(:, end)];
paddedMatrix = [paddedMatrix; paddedMatrix(end, :)];

end
