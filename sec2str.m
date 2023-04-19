function str = sec2str(numSeconds)
%% Converts a number of seconds into a better human-readable string

if (numSeconds < 60)
    str = sprintf('%0.2f s',numSeconds);
elseif (numSeconds < 3600)
    str = sprintf('%0.1f m',numSeconds/60);
elseif (numSeconds < 86400)
    str = sprintf('%0.1f h',numSeconds/3600);
else
    str = sprintf('%0.1f d',numSeconds/86400);
end

return
