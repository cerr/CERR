function [scanOutC, maskOutC, planC] = extractAndPreprocessDataForDL(optS,planC,testFlag)
%
% Script to extract scan and mask and perform user-defined pre-processing.
%
% AI 9/18/19
% -------------------------------------------------------------------------
% INPUTS:
% optS          :  Dictionary of preprocessing options.
% planC         :  CERR archive
%
% --Optional--
% testFlag      : Set flag to true for test dataset. Default:true. Assumes testing dataset if not specified
% -------------------------------------------------------------------------

%% Get user inputs
outSizeV = optS.resize.size;
resampleMethod = optS.resample.method;
resizeMethod = optS.resize.method;
cropS = optS.crop;
resampleS = optS.resample;
channelS = optS.channels;
numChannels = length(channelS);
filterTypeC = {channelS.imageType};

viewC = optS.view;
if ~iscell(viewC)
    viewC = {viewC};
end

if strcmp(optS.resize.preserveAspectRatio,'Yes')
    preserveAspectFlag = 1;
else
    preserveAspectFlag = 0;
end

if isfield(optS,'structList')
    strListC = optS.structList;
else
    strListC = {};
end

if ~exist('testFlag','var')
    testFlag = true;
end

%% Extract data

%Identify available structures
indexS = planC{end};
allStrC = {planC{indexS.structures}.structureName};
strNotAvailableV = ~ismember(lower(strListC),lower(allStrC)); %Case-insensitive
labelV = 1:length(strListC);
if any(strNotAvailableV) && ~testFlag
    scanOutC = {};
    maskOutC = {};
    warning(['Skipping pt. Missing structures: ',strjoin(strListC(strNotAvailableV),',')]);
    return
end
exportStrC = strListC(~strNotAvailableV);

if ~isempty(exportStrC) || testFlag
    
    exportLabelV = labelV(~strNotAvailableV);
    
    %Get structure ID and assoc scan
    strIdxV = nan(length(exportStrC),1);
    for strNum = 1:length(exportStrC)
        
        currentLabelName = exportStrC{strNum};
        strIdxV(strNum) = getMatchingIndex(currentLabelName,allStrC,'exact');
        
    end
end

%Extract scan arrays
if isempty(exportStrC) && testFlag
        scanNumV = 1; %Assume scan 1
else
    if isfield(channelS,'scanType')
        scanTypeC = {channelS.scanType};
        for c = 1:length(scanTypeC)
            scanNumV(c) = find(strcmp(channelS(c).scanType, {planC{indexS.scan}.scanType}));
        end
    else
        scanNumV = unique(getStructureAssociatedScan(strIdxV,planC));
    end
end

UIDc = {planC{indexS.structures}.assocScanUID};
%resM = nan(length(scanNumV),3);

scanC = cell(length(scanNumV),1);
maskC = cell(length(scanNumV),1);
for scanIdx = 1:length(scanNumV)
    
    scan3M = double(getScanArray(scanNumV(scanIdx),planC));
    CTOffset = planC{indexS.scan}(scanNumV(scanIdx)).scanInfo(1).CTOffset;
    scan3M = scan3M - CTOffset;
    
    %Extract masks
    if isempty(exportStrC) && testFlag
        mask3M = [];
        validStrIdxV = [];
    else
        mask3M = false(size(scan3M));
        assocStrIdxV = strcmpi(planC{indexS.scan}(scanNumV(scanIdx)).scanUID,UIDc);
        validStrIdxV = ismember(strIdxV,find(assocStrIdxV));
        validExportLabelV = exportLabelV(validStrIdxV);
        validStrIdxV = strIdxV(validStrIdxV);
    end
    
    for strNum = 1:length(validStrIdxV)
        
        strIdx = validStrIdxV(strNum);
        
        %Update labels
        tempMask3M = false(size(mask3M));
        [rasterSegM, planC] = getRasterSegments(strIdx,planC);
        [maskSlicesM, uniqueSlices] = rasterToMask(rasterSegM, scanNumV(scanIdx), planC);
        tempMask3M(:,:,uniqueSlices) = maskSlicesM;
        mask3M(tempMask3M) = validExportLabelV(strNum);
        
    end
    
    %Pre-processing
    
    %1. Resample to (resolutionXCm,resolutionYCm,resolutionZCm) voxel size
    if ~strcmpi(resampleS.method,'none')
        
        fprintf('\n Resampling data...\n');
        tic
        % Get the new x,y,z grid
        [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNumV(scanIdx)));
        if yValsV(1) > yValsV(2)
            yValsV = fliplr(yValsV);
        end
        
        xValsV = xValsV(1):resampleS.resolutionXCm:(xValsV(end)+10000*eps);
        yValsV = yValsV(1):resampleS.resolutionYCm:(yValsV(end)+10000*eps);
        zValsV = zValsV(1):resampleS.resolutionZCm:(zValsV(end)+10000*eps);
        
        %Compute output size
        numCols = length(xValsV);
        numRows = length(yValsV);
        numSlcs = length(zValsV);
        resampSizV = [numRows numCols numSlcs];
        
        %Resample
        [scan3M,mask3M] = resampleScanAndMask(scan3M,mask3M,resampSizV,resampleMethod);
        toc
        
    end
    
    %2. Crop around the region of interest
    if ~strcmpi({cropS.method},'none')
        fprintf('\nCropping to region of interest...\n');
        tic
        [minr, maxr, minc, maxc, slcV, planC] = getCropLimits(planC,mask3M,scanNumV(scanIdx),cropS);
        %- Crop scan
        if ~isempty(scan3M) && numel(minr)==1
            scan3M = scan3M(minr:maxr,minc:maxc,slcV);
            limitsM = [minr, maxr, minc, maxc];
        else
            scan3M = scan3M(:,:,slcV);
            limitsM = [minr, maxr, minc, maxc];
        end
        
        %- Crop mask
        if ~isempty(mask3M) && numel(minr)==1
            mask3M = mask3M(minr:maxr,minc:maxc,slcV);
        elseif ~isempty(mask3M)
            mask3M = mask3M(:,:,slcV);
        end
        toc
    end
    
    %3. Resize
    if ~strcmpi(resizeMethod,'none')
        fprintf('\nResizing data...\n');
        tic
        [scan3M, mask3M] = resizeScanAndMask(scan3M,mask3M,outSizeV,resizeMethod,limitsM,preserveAspectFlag);
        toc
    end
    
    scanC{scanIdx} = scan3M;
    maskC{scanIdx} = mask3M;
    
end

%4. Transform view
tic
if ~isequal(viewC,{'axial'})
    fprintf('\nTransforming orientation...\n');
end
[scanOutC,maskOutC] = transformView(scanC,maskC,viewC);
toc

%5. Filter images
tic
procScanC = cell(numChannels,1);

for i = 1:length(viewC)
    
    scanC = scanOutC{i};
    
    for c = 1:numChannels
        
        if isfield(channelS(c),'scanType')
            scanId = c;
        else
            scanId = 1;
        end
        
        mask3M = true(size(scanC{scanId}));
        if strcmpi(filterTypeC{c},'original')
            %Use original image
            procScanC{c} = scanC{scanId};
        else
            imType = fieldnames(filterTypeC{c});
            imType = imType{1};
            if strcmpi(imType,'original')
                procScanC{c} = scanC{scanId};
            else
                fprintf('\nApplying %s filter...\n',imType);
                paramS = channelS(c);
                paramS = getRadiomicsParamTemplate([],paramS);
                filterParS = paramS.imageType.(imType).filterPar.val;
                outS = processImage(imType,scanC{scanId},mask3M,filterParS);
                fieldName = fieldnames(outS);
                fieldName = fieldName{1};
                procScanC{c} = outS.(fieldName);
            end
        end
    end
    scanOutC{i} = procScanC;
end
toc

%6. Populate channels
tic
scanOutC = populateChannels(scanOutC,channelS);
if numChannels > 1
    fprintf('\nPopulating channels...\n');
    toc
end

%Get scan metadata
%uniformScanInfoS = planC{indexS.scan}(scanNumV(scanIdx)).uniformScanInfo;
%resM(scanIdx,:) = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];


end
