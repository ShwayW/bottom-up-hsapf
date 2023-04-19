function paddedMatrix = padMatrix(m)
% padMatrix adds a right-most column and a bottom row of zeros
% This is useful for pcolor and surf which "chop off" the appropriate parts

% paddedMatrix = [m zeros(size(m,1),1)];
paddedMatrix = [m m(:,end)];

% paddedMatrix = [paddedMatrix ; zeros(1,size(paddedMatrix,2))];
paddedMatrix = [paddedMatrix ; paddedMatrix(end,:)];

end