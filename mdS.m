function md = mdS(mapSize,startI,goalI)
%% Compute MD for given state indecies
% Vadim Bulitko
% May 12, 2020

% Put mdI and mdXY into this file as auxiliary functions
% Shway Wang
% July 27, 2022

%% Preliminaries
numCells = length(startI);
md = zeros(1,numCells,'int64');

for j = 1:numCells
    i = startI(j);
    md(j) = mdI(i,goalI,mapSize);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function d = mdI(i1,i2,mapSize)
%% Manhattan distance between two indecies

% arguments
%     i1 (1,1) double
%     i2 (1,1) double
%     mapSize (1,2) double
% end

[y1,x1] = ind2sub(mapSize,i1);
[y2,x2] = ind2sub(mapSize,i2);
d = mdXY(int64(x1),int64(y1),int64(x2),int64(y2));

end


function d = mdXY(x1,y1,x2,y2)
%% MD with coordinates

% arguments
%     x1 (1,1) double
%     y1 (1,1) double
%     x2 (1,1) double
%     y2 (1,1) double
% end

d = abs(x1-x2) + abs(y1-y2);

end
