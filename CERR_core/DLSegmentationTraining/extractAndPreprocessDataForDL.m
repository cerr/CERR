function [scanOutC, maskOutC, scanNumV, planC] = ...
    extractAndPreprocessDataForDL(optS,planC,testFlag)
%
% Script to extract scan and mask and perform user-defined pre-processing.
%
% -------------------------------------------------------------------------
% INPUTS:
% optS          :  Dictionary of preprocessing options.
% planC         :  CERR archive
%
% --Optional--
% testFlag      : Set flag to true for test dataset. Default:true. Assumes testing dataset if not specified
% -------------------------------------------------------------------------
% AI 9/18/19
% AI 9/18/20  Extended to handle multiple scans

%% Get user inputs
regS = optS.register;
scanOptS = optS.scan;
resampleS = [scanOptS.resample];
cropS = [scanOptS.crop];
resizeS = [scanOptS.resize];

if isfield(optS,'structList')
    strListC = optS.structList;
else
    strListC = {};
end

if ~exist('testFlag','var')
    testFlag = true;
end

%% Identify available structures
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

%% Register scans
if ~isempty(fieldnames(regS))
    identifierS = regS.baseScan.identifier;
    scanNumV(1) = getScanNumFromIdentifiers(identifierS,planC);
    identifierS = regS.movingScan.identifier;
    movScanV = getScanNumFromIdentifiers(identifierS,planC);
    scanNumV(2:length(movScanV)+1) = movScanV;
    %--TBD
    % [outScanV, planC]  = registerScans(regS, planC);
    % Update scanNumV with warped scan IDs (outScanV)
    %---
else
    %Get scan no. matching identifiers
    scanNumV = nan(1,length(scanOptS));
    for n = 1:length(scanOptS)
        identifierS = scanOptS.identifier;
        scanNumV(n) = getScanNumFromIdentifiers(identifierS,planC);
    end
end

%% Extract data
numScans = length(scanOptS);
scanC = cell(numScans,1);
scanOutC = cell(numScans,1);
maskC = cell(numScans,1);
maskOutC = cell(numScans,1);

UIDc = {planC{indexS.structures}.assocScanUID};
%resM = nan(length(scanNumV),3);

%-Loop over scans
for scanIdx = 1:numScans
    
    %Extract scan array
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
    
    %Get scan-specific parameters
    channelParS = scanOptS(scanIdx).channels;
    numChannels = length(channelParS);
    filterTypeC = {channelParS.imageType};
    viewC = scanOptS(scanIdx).view;
    if ~iscell(viewC)
        viewC = {viewC};
    end
    if strcmp(resizeS(scanIdx).preserveAspectRatio,'Yes')
        preserveAspectFlag = 1;
    else
        preserveAspectFlag = 0;
    end
    
    %% Pre-processing
    
    %1. Resample to (resolutionXCm,resolutionYCm,resolutionZCm) voxel size
    if ~strcmpi(resampleS(scanIdx).method,'none')
        
        fprintf('\n Resampling data...\n');
        tic
        % Get the new x,y,z grid
        [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNumV(scanIdx)));
        if yValsV(1) > yValsV(2)
            yValsV = fliplr(yValsV);
        end
        
        xValsV = xValsV(1):resampleS(scanIdx).resolutionXCm:(xValsV(end)+10000*eps);
        yValsV = yValsV(1):resampleS(scanIdx).resolutionYCm:(yValsV(end)+10000*eps);
        zValsV = zValsV(1):resampleS(scanIdx).resolutionZCm:(zValsV(end)+10000*eps);
        
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
    if ~strcmpi({cropS(scanIdx).method},'none')
        fprintf('\nCropping to region of interest...\n');
        tic
        [minr, maxr, minc, maxc, slcV, planC] = ...
            getCropLimits(planC,mask3M,scanNumV(scanIdx),cropS(scanIdx));
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
    if ~strcmpi(resizeS(scanIdx).method,'none')
        fprintf('\nResizing data...\n');
        tic
        [scan3M, mask3M] = resizeScanAndMask(scan3M,mask3M,outSizeV,...
            resizeMethod,limitsM,preserveAspectFlag);
        toc
    end
    
    scanC{scanIdx} = scan3M;
    maskC{scanIdx} = mask3M;
    
    
    %4. Transform view
    tic
    if ~isequal(viewC,{'axial'})
        fprintf('\nTransforming orientation...\n');
    end
    [viewOutC,maskOutC{scanIdx}] = transformView(scanC{scanIdx},maskC(scanIdx),viewC);
    toc
    
    %5. Filter images
    tic
    procScanC = cell(numChannels,1);
    
    for i = 1:length(viewC)
        
        scanView3M = viewOutC{i};
        
        for c = 1:numChannels
            
            mask3M = true(size(scanView3M));
            
            if strcmpi(filterTypeC{c},'original')
                %Use original image
                procScanC{c} = scanView3M;
            else
                imType = fieldnames(filterTypeC{c});
                imType = imType{1};
                if strcmpi(imType,'original')
                    procScanC{c} = scanView3M;
                else
                    fprintf('\nApplying %s filter...\n',imType);
                    paramS = channelS(c);
                    paramS = getRadiomicsParamTemplate([],paramS);
                    filterParS = paramS.imageType.(imType).filterPar.val;
                    outS = processImage(imType,scanView3M,mask3M,filterParS);
                    fieldName = fieldnames(outS);
                    fieldName = fieldName{1};
                    procScanC{c} = outS.(fieldName);
                end
            end
        end
        viewOutC{i} = procScanC;
    end
    toc
    
    %--- TBD--
    %6. Adjust voxel values outside mask
    %outIntVal = channelParS.mask.assignIntensityVal;
    %for nView = 1:length(viewOutC)
    %    scan3M = viewOutC{nView};
    %    mask3M = maskOutC{nView};
    %    scan3M(~mask3M) = outIntVal;
    %    viewOutC{nView} = scan3M;
    %end
    %--------
    
    %7. Populate channels
    tic
    channelOutC = populateChannels(viewOutC,channelParS);
    if numChannels > 1
        fprintf('\nPopulating channels...\n');
        toc
    end
    
    scanOutC{scanIdx} = channelOutC;
    
end

%Get scan metadata
%uniformScanInfoS = planC{indexS.scan}(scanNumV(scanIdx)).uniformScanInfo;
%resM(scanIdx,:) = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];

end
