function [scanC, mask3M, resM, rcsM, originalImageSizV] = extractAndPreprocessDataForDL(optS,planC,testFlag)
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
resizeMethod = optS.resize.method;
cropS = optS.crop;
resampleS = optS.resample;
channelS = optS.channels;
maskChannelS = channelS;
maskChannelS.method = 'none';
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
if any(strNotAvailableV)
    warning(['Skipping missing structures: ',strjoin(strListC(strNotAvailableV),',')]);
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
    
    %Extract scan arrays
    scanC = {};
    maskC = {};
    if isempty(exportStrC) && testFlag
        scanNumV = 1; %Assume scan 1
    else
        if strcmpi(channelS.append.method,'multiscan')
            scanNumV = channelS.append.parameters;
        else
            scanNumV = unique(getStructureAssociatedScan(strIdxV,planC));
        end
    end
    
    UIDc = {planC{indexS.structures}.assocScanUID};
    resM = nan(length(scanNumV),3);
    
    for scanIdx = 1:length(scanNumV)
        
        scan3M = double(getScanArray(scanNumV(scanIdx),planC));
        CTOffset = planC{indexS.scan}(scanNumV(scanIdx)).scanInfo(1).CTOffset;
        scan3M = scan3M - CTOffset;
        
        originalImageSizV = size(scan3M);
        
        %Extract masks
        if isempty(exportStrC) && testFlag
            mask3M = [];
            validStrIdxV = [];
        else
            mask3M = zeros(size(scan3M));
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
        
        %1. Resample
        if ~strcmpi(resampleS.method,'none')
            
            % Get the new x,y,z grid
            [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNumV(scanIdx)));
            if yValsV(1) > yValsV(2)
                yValsV = fliplr(yValsV);
            end
            
            xValsV = xValsV(1):resampleS.resolutionXCm:(xValsV(end)+10000*eps);
            yValsV = yValsV(1):resampleS.resolutionYCm:(yValsV(end)+10000*eps);
            zValsV = zValsV(1):resampleS.resolutionZCm:(zValsV(end)+10000*eps);
            
            % Interpolate using sinc sampling
            numCols = length(xValsV);
            numRows = length(yValsV);
            numSlcs = length(zValsV);
            
            %Get resampling method
            if strcmpi(resampleS.method,'sinc')
                method = 'lanczos3';
            end
            scan3M = imresize3(scan3M,[numRows numCols numSlcs],'method',method);
            mask3M = imresize3(single(mask3M),[numRows numCols numSlcs],'method',method) > 0.5;
            
        end
        
        %2. Crop
        scanNum = scanNumV(scanIdx);
        mask3M = getMaskForModelConfig(planC,mask3M,scanNum,cropS);
        
        %3. Resize
        [scan3M, mask3M, rcsM] = resizeScanAndMask(scan3M,mask3M,outSizeV,resizeMethod);
        scanC{scanIdx} = scan3M;
        maskC{scanIdx} = mask3M;
        
    end
    
    %Populate channels
    scanC = populateChannels(scanC,channelS);
    maskC = populateChannels(maskC,maskChannelS);
    mask3M = maskC{1};
    
    %Get scan metadata
    uniformScanInfoS = planC{indexS.scan}(scanNumV(scanIdx)).uniformScanInfo;
    resM(scanIdx,:) = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];
    
    
end

end