%% To plot the comparison graph of different DSLs
% Shway Wang
% April 20, 2023

% if plotter does not work, try starting matlab using:
% matlab -softwareopengl

close all;
clear;
clc;
diary off;

%% Preliminaries
warning('off','MATLAB:graphics:axestoolbar:PrintWarning');
warning('off','MATLAB:print:ContentTypeImageSuggested');

% set the number of maps array
astSizes = [1, 2, 3, 4, 5];

% get the results
fPos = [50 50 500 300];
fig = figure('Position',fPos);
tiledlayout(1,1,'TileSpacing','compact','Padding','compact');

%% Plot
%ylim([0, 35]);
%xlim([0, 3]);

%set(gca,'XScale','log');
%set(gca,'YScale','log');

hold on
grid on
box on

pointMarkers = ["x-", "^-", "o-", "s-", "d-", "v-"];

%{
mbColors = [
    0.4940 0.1840 0.5560    % 1: purple dotted
    0.4940 0.1840 0.5560    % 2: purple
    0.4660 0.6740 0.1880    % 3: green dotted
    0.4660 0.6740 0.1880    % 4: green
    ];
%}

% The curve for the base grammar synthesis methods
xticks(astSizes);
plot(astSizes, [7, 28, 293, 1244, 9806], pointMarkers(1));

plot(astSizes, [7, 21, 261, 1196, 9146], pointMarkers(2));

plot(astSizes, [7, 21, 226, 1164, 8896], pointMarkers(3));

%title('brc501d avg. test loss');
xlabel('size of AST');
ylabel('number of formulas');
legend({"DSL^o", "DSL^b", "DSL^r"}, 'Location', 'northwest');
hold off

%% Wrap up
exportgraphics(fig, sprintf('plots/dsl_compare.png'));



