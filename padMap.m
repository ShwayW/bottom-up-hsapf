function paddedMap = padMap(map,d)
%% Pad a map

paddedMap = true(size(map,1)+2*d,size(map,2)+2*d);
paddedMap(1+d:end-d,1+d:end-d) = map;

end
