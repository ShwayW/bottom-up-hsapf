function map = loadMap(mapName,pad,verbose)
%% loadMap
% Reads a HOG-formatted map (or a TXT map) and creates a map from it or simply loads a MAT-format map
% Vadim Bulitko
% Sep 2, 2008; updated on Feb 7, 2020

%% Argument types
arguments
    mapName (1,:) char
    pad (1,1) double = -1
    verbose (1,1) logical = false
end

%% Get the file type
[~, ~, ext] = fileparts(mapName);

%% Use the appropriate load
switch (ext)
    case ('.map')
        % MAP-file
        fid = fopen(mapName, 'r');
        a = textscan(fid, '%s', 'headerlines', 4);
        fclose(fid);
        map = (cell2mat(a{:}) == '@') | ...     % walls
            (cell2mat(a{:}) == 'O') | ...       % 'out of bounds'
            (cell2mat(a{:}) == 'W') | ...       % water
            (cell2mat(a{:}) == 'T');            % trees
        % 'G', 'g', 'S', 's' are allowed (passable)
        
    case ('.mat')
        % Straight load
        load(mapName); %#ok<LOAD>
        
    case ('.txt')
        % TXT-file
        fid = fopen(mapName,'r'); a = textscan(fid,'%s','headerlines',2); fclose(fid);
        map = (cell2mat(a{:}) == '0');     % walls
end

if (verbose)
    fprintf('Loaded %s: %dx%d\n',mapName,size(map,1),size(map,2));
end

%% Pad the map if needed
if (pad > 0 && ~isequal(ext,'.mat'))
    map = padMap(map,pad);
    if (verbose)
        fprintf('\tWe are given pad value of %d\n\tPaded %d-thick to %dx%d (HxW)\n\n',pad,pad,size(map,1),size(map,2));
    end
elseif (pad == -1)
    % determine if the map has a border already
    if (~isMapBordered(map))
        % no, so pad it
        map = padMap(map,1);
        if (verbose)
            fprintf('\tWe are given pad value of -1\n\tThe map did not have a border\n\tPaded 1-thick to %dx%d (HxW)\n\n',...
                size(map,1),size(map,2));
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Aux Funcs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function b = isMapBordered(map)
%% Determines if the map has border of width 1 (at least) already

%% Arguments
arguments
    map (:,:) logical
end

%% Check for all four borders
b = all(map(1,:)) && all(map(end,:)) && all(map(:,1)) && all(map(:,end));

end
