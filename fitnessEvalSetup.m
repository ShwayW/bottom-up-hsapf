function [hStar, cc, gI, ensembleNet, knnData, useGenNumAsLoopCondition] = fitnessEvalSetup(domain,...
    fitnessEvalMethod, useGenNumAsLoopCondition)
%% Performs one-time setup actions for fitness eval methods
% Sean Paetz
% July 15th, 2022

arguments
    domain (1,1) Domain % video game path finding, sliding tile puzzles and so on
    fitnessEvalMethod (1,1) string % determines which setup to perform
    useGenNumAsLoopCondition (1,1) double % flag for exit condition which may change here
end

% check case and perform relevant setup
switch (fitnessEvalMethod)
    case ("annProxy")
        % get the current maps indices array
        mapsIArr = domain.problemSets{1}.mapsIArr; %#ok<NASGU>

        % we don't use budgets with proxy
        useGenNumAsLoopCondition = true;

        % # of MCE images per h
        numPlanes = 4;

        if (strcmp(domain.problemDomain, "slidingtile"))
            mceSet = generateProblemsSlideTile(domain.boardDim, 4); %#ok<NASGU>
        elseif (strcmp(domain.problemDomain, "pathfinding"))

            % get the current maps indices array
            mapsIArr = domain.problemSets{1}.mapsIArr;

            % get largest connected component and set goals in its 4 corners
            for mapI = mapsIArr
                mapSize = [size(domain.mapList{mapI}, 1), size(domain.mapList{mapI}, 2)];
                cc{mapI} = computeLCC_mex(domain.mapList{mapI}); %#ok<AGROW>
                gI{mapI} = placeGoals(mapSize, cc{mapI}); %#ok<AGROW>
            end

            % pre-compute h* for all 4 corner goals
            for j = 1:length(mapsIArr)
                for i = 1:numPlanes
                    hStar{j}{i} = computeHStar2_mex(domain.mapList{j}, gI{j}(i)); %#ok<AGROW>
                end
            end

            % load ensemble
            netName = "ann/vbcnnP-cog_g_h10000_p4_ensemble4.mat";
            load(netName, "ensembleNet");
        end

        % set to empty, since we don't load this
        dummyStruct.data = 0;
        knnData = dummyStruct;

    case ("knn")
        % get the current maps indices array
        mapsIArr = domain.problemSets{1}.mapsIArr;

        % we don't use budget with a knn
        useGenNumAsLoopCondition = true;

        % get largest connected component and set goals in its 4 corners
        mapSize = [size(domain.mapList{mapsIArr}, 1), size(domain.mapList{mapsIArr}, 2)];
        cc = computeLCC_mex(domain.mapList{mapsIArr});
        gI = placeGoals(mapSize, cc);

        % pre-compute h* for all 4 corner goals
        for i = 1:4
            hStar{i} = computeHStar2_mex(domain.mapList{mapsIArr} ,gI(i)); %#ok<AGROW>
        end

        % load the knn and assign it to appropriate variable
        knnFN = "dl/hLoss_h1000_p4_brc504d.mat";
        load(knnFN); %#ok<LOAD>
        knnData.hImage = hImage;
        knnData.loss = loss;

        % set to empty, since we don't use an ensemble network
        ensembleNet = {};
    otherwise
        % declare variables empty, since we will not use them
        hStar = {};
        cc= [];
        gI = [];
        ensembleNet = {};
        knnData.data = 0;
end
end
