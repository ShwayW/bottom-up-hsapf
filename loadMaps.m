function map = loadMaps(mapNames,verbose)
%% Loads maps specified by a list
% Vadim Bulitko
% June 4, 2020

arguments
    mapNames (:,1) cell
    verbose (1,1) logical = false
end

for i = 1:length(mapNames)
    map{i} = loadMap(mapNames{i}); %#ok<AGROW>
    if (verbose)
        fprintf('Map %d | %s | %d x %d\n',i,mapNames{i},size(map{i},1),size(map{i},2));
    end
end

end
