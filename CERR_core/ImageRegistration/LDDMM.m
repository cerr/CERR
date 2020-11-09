function [basePlanC, movPlanC] = LDDMM(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm, baseBboxCropStr, movBboxCropStr, padWidth, baseDeformMaskStr, movDeformMaskStr,tmpDirPath)
%Usage: [basePlanC, movPlanC] = LDDMM(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm, baseBboxCropStr, movBboxCropStr, padWidth, baseDeformMaskStr, movDeformMaskStr)
%Function for running LDDMM registration on planC scans
%EML 2020-09

%% parse input

if nargin < 11 || ~exist('tmpDirPath','var')
    tmpDirPath = fullfile(getCERRPath,'ImageRegistration','tmpFiles');
end

if nargin < 10 || ~exist('movDeformMaskStr','var')
    movDeformMaskStr = '';
end

if nargin < 9 || ~exist('baseDeformMaskStr','var')
    baseDeformMaskStr = '';
end

if nargin < 8 || ~exist('padWidth','var') || isempty(padWidth)
    padWidth = 0;
end

%% Test if base- & movPlanC are identical

if isequal(basePlanC, movPlanC)
    planEqual = 1;
    planC = basePlanC;
else
    planEqual = 0;
    planC = {};
end

registration_tool = 'ANTS';

%% create masks if cropping structure name is passed

if ~isempty(baseBboxCropStr) || ~isempty(movBboxCropStr)
    cropToStrCell = {baseBboxCropStr,movBboxCropStr};
else
    cropToStrCell = {};
end
bboxStrCell = {};

if ~isempty(baseDeformMaskStr) && ~isempty(movDeformMaskStr)
    deformStrCell = {baseDeformMaskStr, movDeformMaskStr};
else
    deformStrCell = {};
end

%% check if bounding box ROI name has been given as the input string

for i = 1:numel(cropToStrCell)
    cropToStrName = cropToStrCell{i};
    if ~isempty(cropToStrName) && ~strcmp(cropToStrName, 'NULL')
        if padWidth > 0
            pW = ['_' num2str(padWidth)];
        else
            pW = '';
        end
        try
            if ~strcmpi(cropToStrName(end-4 - length(pW):end),['_bbox' pW])
                bboxStrName = [cropToStrName '_BBOX' pW];
            else
                bboxStrName = cropToStrName;
            end
        catch
            bboxStrName = [cropToStrName '_BBOX' pW];
        end
    else
        bboxStrName = 'NULL';
    end
    bboxStrCell{i} = bboxStrName;
end


%% Create mask arrays for base, mov

cellPlanC = {basePlanC, movPlanC};
cellScanNum = {baseScanNum, movScanNum};
cellMask3M = {};

for i = 1:numel(cellPlanC)
    if ~planEqual
        planC = cellPlanC{i};
    end
    indexS = planC{end};
    structureListC = {planC{indexS.structures}.structureName};
    bboxStrName = bboxStrCell{i};
    cropToStrName = cropToStrCell{i};
    if ~isempty(cropToStrName)
        %check if bbox mask structure is in planC, if not, create one
        bbIdx = getMatchingIndex(lower(bboxStrName),lower(structureListC),'exact');
        if isempty(bbIdx)
            % Get structure number from name
            cropStructNum = getMatchingIndex(lower(cropToStrName),lower(structureListC),'exact');
            if ~isempty(cropStructNum)
                % Return sructure mask from number
                cropStructMask3M = getStrMask(cropStructNum, planC);
                %%%create bounding box mask for specified segments
                [minr, maxr, minc, maxc, mins, maxs, mask3M] = compute_boundingbox(cropStructMask3M, padWidth);
                %push mask back to planC
                isUniform = 0;
                assocScanNum = cellScanNum{i};
                strname = bboxStrName;
                planC = maskToCERRStructure(mask3M, isUniform, assocScanNum, strname, planC);
                cellPlanC{i} = planC;
            else
                mask3M = [];
            end
        else
            mask3M = getStrMask(bbIdx, planC);
        end
    else
        mask3M = [];
    end
    cellMask3M{1}{i} = mask3M;
    
    if ~isempty(baseDeformMaskStr) && ~isempty(movDeformMaskStr)
        deformStr = deformStrCell{i};
        deformStructNum = getMatchingIndex(lower(deformStr),lower(structureListC),'exact');
            % Return sructure mask from number
        if ~isempty(deformStructNum)
            deformStructMask3M = getStrMask(deformStructNum, planC);
            cellMask3M{2}{i} = deformStructMask3M;
        else
            deformStructMask3M = [];
            cellMask3M{2}{i} = deformStructMask3M;
        end
    else
        cellMask3M{2}{1} = [];
        cellMask3M{2}{2} = [];
    end
end


baseMask3M = cellMask3M{1}{1};
movMask3M  = cellMask3M{1}{2};

if ~isempty(cellMask3M{2}{1})
    baseMask3M(:,:,:,2) = cellMask3M{2}{1};
    movMask3M(:,:,:,2) = cellMask3M{2}{2};
end

%% Determine inputCmdFile for given algorithm

inputCmdFile = '';

if ~isempty(cropToStrCell)
    if ~isempty(deformStrCell)
        inputCmdFile = fullfile(getCERRPath,'ImageRegistration','antsScripts','LDDMM_bbox_deformstructures.txt');
    else
        inputCmdFile = fullfile(getCERRPath,'ImageRegistration','antsScripts','LDDMM_bbox.txt');
    end
else
    inputCmdFile = fullfile(getCERRPath,'ImageRegistration','antsScripts','LDDMM_nomask.txt');
end
disp(inputCmdFile);

%% Run register_scans
[basePlanC, movPlanC, ~] = register_scans(basePlanC, baseScanNum, movPlanC,movScanNum, algorithm, registration_tool, tmpDirPath, ... 
    baseMask3M, movMask3M, [], inputCmdFile, '', '');