function LDDMM(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm, cropToStrCell, additionalStrMaskNames)
%%% Structures in CERR reference: https://github.com/cerr/CERR/wiki/Editing-Structures

% Extract list of available structures
% structureListCB = {basePlanC{indexS.structures}.structureName};
% structureListCM = {movPlanC{indexS.structures}.structureName};

if nargin < 7
    additionalStrMaskNames = {};
end


%% create masks if cropping structure name is passed

baseMask3M = [];
movMask3M  = [];

bboxStrCell = {};

if ~isempty(cropToStrCell)
    
    % check if bounding box ROI name has been given as input
    for i = 1:numel(cropToStrCell)
        cropToStrName = cropToStrCell{i};
        if ~strcmpi(cropToStrName(end-4:end),'_bbox')
            bboxStrName = [cropToStrName '_BBOX'];
        else
            bboxStrName = cropToStrName;
        end
        bboxStrCell{i} = bboxStrName;
    end

    cellPlanC = {basePlanC, movPlanC};
    cellScanNum = {baseScanNum, movScanNum};
    cellMask3M = {};
    
    for i = 1:numel(cellPlanC)
        planC = cellPlanC{i};
        indexS = planC{end};
        structureListC = {planC{indexS.structures}.structureName};
        bboxStrName = bboxStrCell{i};
        cropToStrName = cropToStrCell{i};
        %check if bbox mask structure is in planC, if not, create one
        if isempty(getMatchingIndex(lower(bboxStrName),lower(structureListC),'exact'))
            % Get structure number from name
            cropStructNum = getMatchingIndex(lower(cropToStrName),lower(structureListC),'exact');
            % Return sructure mask from number
            cropStructMask3M = getStrMask(cropStructNum, planC);
            %%%create bounding box mask for specified segments
            [minr, maxr, minc, maxc, mins, maxs, mask3M] = compute_boundingbox(cropStructMask3M, 1);
            %push mask back to planC
            isUniform = 0;
            assocScanNum = cellScanNum{i};
            strname = bboxStrName;
            planC = maskToCERRStructure(mask3M, isUniform, assocScanNum, strname, planC);
            cellPlanC{i} = planC;
        else
            bbIdx = getMatchingIndex(lower(bboxStrName),lower(structureListC),'exact');
            mask3M = getStrMask(bbIdx, planC);
        end
        cellMask3M{i} = mask3M;
    end
    baseMask3M = cellMask3M{1};
    movMask3M  = cellMask3M{2};
end

%% Determine inputCmdFile for given algorithm

inputCmdFile = '';

switch algorithm
    case 'LDDMM MASK ANTS'
        inputCmdFile = fullfile(getCERRPath,'ImageRegistration','antsScripts','LDDMM_MASK_ANTS_opts.txt');
    case 'LDDMM MASK DIR ANTS'
        inputCmdFile = fullfile(getCERRPath,'ImageRegistration','antsScripts','LDDMM_MASK_DIR_ANTS_opts.txt');
end

%%%Call register_scans.m

[basePlanC, movPlanC, ~] = register_scans(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M,...
    [], inputCmdFile, [], []);