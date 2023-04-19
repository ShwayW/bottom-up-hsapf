function [d, h, m, s] = convertSeconds(sec)
%% Converts seconds to days, hours, minutes, seconds
% originally by Manuel Macedo Teran
% Comments added by Shway Wang
% May 4, 2022

arguments
    sec (1,1) uint64
end

% seconds
s = mod(double(sec), 60);

% minutes
m = floor(mod(double(sec), 3600) / 60);

% hours
h = floor(mod(double(sec), 86400) / 3600);

% days
d = floor(double(sec) / 86400);
end