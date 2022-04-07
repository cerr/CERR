function [scanOutC, maskOutC, scanNumV, optS, coordInfoS, planC] = ...
    extractAndPreprocessDataForDL(optS,planC,skipMaskExport,scanNumV)
%
% Script to extract scan and mask and perform user-defined pre-processing.
%
% -------------------------------------------------------------------------
% INPUTS:
% optS          :  Dictionary of preprocessing options.
% planC         :  CERR archive
%
% --Optional--
% varargin{1}: skipMaskExportf flag. Set to false to export structure masks. 
%              Default:true.
% varargin{2}: Vector of scan nos. Default: Use scan identifiers from optS. 
% -------------------------------------------------------------------------
% AI 9/18/19
% AI 9/18/20  Extended to handle multiple scans

%% Get processing directives from optS
filtS = optS.filter;
regS = optS.register;
scanOptS = optS.scan;
resampleS = [scanOptS.resample];
resizeS = [scanOptS.resize];

if isfield(optS,'inputStrNameToLabelMap')
    exportStrS = optS.inputStrNameToLabelMap;
    strListC = {exportStrS.structureName};
    labelV = [exportStrS.value];
else
    strListC = {};
end

if ~exist('testFlag','var')
    skipMaskExport = false;
end

%% Filter image
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};

if ~exist('scanNumV','var') || isempty(scanNumV)
    scanNumV = nan(1,length(scanOptS));
    for n = 1:length(scanOptS)
        
        identifierS = scanOptS(n).identifier;
        if ~isempty(filtS) && isfield(identifierS,'filtered') &&...
                identifierS.filtered
            
            % Filter scan
            [baseScanNum,filtScanNum,planC] = createFilteredScanForDLS(identifierS,...
                                  filtS,planC);
            
            % Copy structures required for registration/cropping
            copyStrsC = {};
            if isfield(regS,'copyStr')
                copyStrsC = [regS.copyStr];
            end
            if isfield(scanOptS(n),'crop') &&  isfield(scanOptS(n).crop,'params')
                scanCropParS = scanOptS(n).crop.params;
                if isfield(scanCropParS,'structureName')
                cropStrListC = arrayfun(@(x)x.structureName,...
                    scanCropParS,'un',0);
                copyStrsC = [copyStrsC;cropStrListC];
                end
            end
            if ~isempty(copyStrsC)
                for s = 1:length(copyStrsC)
                    cpyStrV = getMatchingIndex(copyStrsC{s},strC,'EXACT');
                    assocScanV = getStructureAssociatedScan(cpyStrV,planC);
                    cpyStr = cpyStrV(assocScanV==baseScanNum);
                    if ~isempty(cpyStr)
                        planC = copyStrToScan(cpyStr,filtScanNum,planC);
                    end
                end
            end
            
            %Update scan no.
            scanNumV(n) = filtScanNum;
        else
            scanNumV(n) = getScanNumFromIdentifiers(identifierS,planC);
        end
    end
end


%% Register scans 
if ~isempty(fieldnames(regS))
    identifierS = regS.baseScan.identifier;
    regScanNumV(1) = getScanNumFromIdentifiers(identifierS,planC);
    identifierS = regS.movingScan.identifier;
    movScan = getScanNumFromIdentifiers(identifierS,planC);
    regScanNumV(2) = movScan;
    if strcmp(regS.method,'none')
        %For pre-registered scans
        if isfield(regS,'copyStr')
            for nStr = 1:length(copyStrsC)
                cpyStrV = getMatchingIndex(copyStrsC{nStr},allStrC,'exact');
                assocScanV = getStructureAssociatedScan(cpyStrV,planC);
                cpyStr = cpyStrV(assocScanV==regScanNumV(1));
                planC = copyStrToScan(cpyStr,movScan,planC);
            end
        end
    else
        planC = registerScansForDLS(planC,regScanNumV,...
            regS.method,regS);
    end
end

%% Get scan nos. matching identifiers
if ~isempty(scanOptS)
    for n = 1:length(scanOptS)
        identifierS = scanOptS(n).identifier;
        if ~isempty(identifierS) && isfield(identifierS,'warped') &&  ...
                identifierS.warped
            scanNumV(n) = getAssocWarpedScanNum(scanNumV(n),planC);
        end
    end
end

% Ignore missing inputs if marked optional
optFlagV = strcmpi({scanOptS.required},'no');
ignoreIdxV = optFlagV & isnan(scanNumV);
scanNumV(ignoreIdxV) = [];

%% Identify available structures in planC
indexS = planC{end};
allStrC = {planC{indexS.structures}.structureName};
strNotAvailableV = ~ismember(lower(strListC),lower(allStrC)); %Case-insensitive
if any(strNotAvailableV) && skipMaskExport
    scanOutC = {};
    maskOutC = {};
    warning(['Skipping pt. Missing structures: ',strjoin(strListC(strNotAvailableV),',')]);
    return
end
exportStrC = strListC(~strNotAvailableV);

if ~isempty(exportStrC) || skipMaskExport
    exportLabelV = labelV(~strNotAvailableV);
    %Get structure ID and assoc scan
    strIdxC = cell(length(exportStrC),1);
    for strNum = 1:length(exportStrC)
        currentLabelName = exportStrC{strNum};
        strIdxC{strNum} = getMatchingIndex(currentLabelName,allStrC,'exact');
    end
end

%% Extract & preprocess data
numScans = length(scanNumV);
scanC = cell(numScans,1);
scanOutC = cell(numScans,1);
maskC = cell(numScans,1);
maskOutC = cell(numScans,1);

UIDc = {planC{indexS.structures}.assocScanUID};
%resM = nan(length(scanNumV),3);

%-Loop over scans
for scanIdx = 1:numScans
        
    %Extract scan array from planC
    scan3M = double(getScanArray(scanNumV(scanIdx),planC));
    CTOffset = double(planC{indexS.scan}(scanNumV(scanIdx)).scanInfo(1).CTOffset);
    scan3M = scan3M - CTOffset;
    
    %Extract masks from planC
    strC = {planC{indexS.structures}.structureName};
    if isempty(exportStrC) && ~skipMaskExport
        mask3M = [];
        validStrIdxV = [];
    else
        mask3M = zeros(size(scan3M));
        assocStrIdxV = strcmpi(planC{indexS.scan}(scanNumV(scanIdx)).scanUID,UIDc);
        strIdxV = [strIdxC{:}];
        strIdxV = reshape(strIdxV,1,[]);
        validStrIdxV = ismember(strIdxV,find(assocStrIdxV));
        validStrIdxV = strIdxV(validStrIdxV);
        keepLabelIdxV = assocStrIdxV(validStrIdxV);
        validExportLabelV = exportLabelV(keepLabelIdxV);
    end
    
    if length(validStrIdxV)==0
        mask3M = [];
    else
        for strNum = 1:length(validStrIdxV)
            
            strIdx = validStrIdxV(strNum);
            
            %Update labels
            tempMask3M = false(size(mask3M));
            [rasterSegM, planC] = getRasterSegments(strIdx,planC);
            [maskSlicesM, uniqueSlices] = rasterToMask(rasterSegM, scanNumV(scanIdx), planC);
            tempMask3M(:,:,uniqueSlices) = maskSlicesM;
            mask3M(tempMask3M) = validExportLabelV(strNum);
        end
    end
    
    %Get affine matrix
    [affineInM,~,voxSizV] = getPlanCAffineMat(planC, scanNumV(scanIdx), 1);
    affineOutM = affineInM;
    originV = affineOutM(1:3,4);
    
    %Set scan-specific parameters: channels, view orientation, background adjustment, aspect ratio
    channelParS = scanOptS(scanIdx).channels;
    numChannels = length(channelParS);
    
    viewC = scanOptS(scanIdx).view;
    if ~iscell(viewC)
        viewC = {viewC};
    end
    
    if ~isequal(viewC,{'axial'})
        transformViewFlag = 1;
    else
        transformViewFlag = 0;
    end
    
    filterTypeC = {channelParS.imageType};
    structIdxC = cellfun(@isstruct,filterTypeC,'un',0);
    if any([structIdxC{:}])
     filterTypeC = arrayfun(@(x)fieldnames(x.imageType),channelParS,'un',0);
     if any(ismember([filterTypeC{:}],'assignBkgIntensity'))
         adjustBackgroundVoxFlag = 1;
     else
         adjustBackgroundVoxFlag = 0;
     end
    else
        adjustBackgroundVoxFlag = 0;
    end
    
    if strcmp(resizeS(scanIdx).preserveAspectRatio,'Yes')
        preserveAspectFlag = 1;
    else
        preserveAspectFlag = 0;
    end
    
    %% Pre-processing
    cropS = scanOptS(scanIdx).crop;
    
    %1. Resample to (resolutionXCm,resolutionYCm,resolutionZCm) voxel size
    if ~strcmpi(resampleS(scanIdx).method,'none')
        
        fprintf('\n Resampling data...\n');
        tic
        % Get the new x,y,z grid
        [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNumV(scanIdx)));
        if yValsV(1) > yValsV(2)
            yValsV = fliplr(yValsV);
        end
        
        %Get input resolution
        dx = median(diff(xValsV));
        dy = median(diff(yValsV));
        dz = median(diff(zValsV));
        inputResV = [dx,dy,dz];
        outResV = inputResV;
        resListC = {'resolutionXCm','resolutionYCm','resolutionZCm'};
        for nDim = 1:length(resListC)
            if isfield(resampleS(scanIdx),resListC{nDim})
                outResV(nDim) = resampleS(scanIdx).(resListC{nDim});
            else
                outResV(nDim) = nan;
            end
        end
        resampleMethod = resampleS(scanIdx).method;
        
        %Resample scan
        gridAlignMethod = 'center';
        [xResampleV,yResampleV,zResampleV] = ...
            getResampledGrid(outResV,xValsV,yValsV,zValsV,gridAlignMethod);
        [scan3M,mask3M] = resampleScanAndMask(double(scan3M),double(mask3M),...
            xValsV,yValsV,zValsV,xResampleV,yResampleV,zResampleV,...
            resampleMethod);

        %Store to planC
        scanInfoS.horizontalGridInterval = outResV(1);
        scanInfoS.verticalGridInterval = outResV(2);
        scanInfoS.coord1OFFirstPoint = xResampleV(1);
        scanInfoS.coord2OFFirstPoint = yResampleV(1);
        scanInfoS.zValues = zResampleV;
        sliceThicknessV = diff(zResampleV);
        scanInfoS.sliceThickness = [sliceThicknessV,sliceThicknessV(end)];
        planC = scan2CERR(scan3M,['Resamp_scan',num2str(scanNumV(scanIdx))],...
            '',scanInfoS,'',planC);
        scanNumV(scanIdx) = length(planC{indexS.scan});
        for strNum = 1:length(validStrIdxV)
            strMask3M = mask3M == validExportLabelV(strNum);
            outStrName = [exportStrC{strNum},'_resamp'];
            planC = maskToCERRStructure(strMask3M,0,scanNumV(scanIdx),...
                outStrName,planC);
        end

        toc
        
        % Resample structures required for training
        
        %Resample reqd structures
        % TBD: add structures reqd for training
        if ~(length(cropS) == 1 && strcmpi(cropS(1).method,'none'))
            cropStrListC = arrayfun(@(x)x.params.structureName,cropS,'un',0);
            cropParS = [cropS.params];
            if ~isempty(cropStrListC)
                for n = 1:length(cropStrListC)
                    resampStrIdx = getMatchingIndex(cropStrListC{n},strC,...
                        'EXACT');
                    if isempty(resampStrIdx)
                        strIdx = getMatchingIndex(cropStrListC{n},strC,'EXACT');
                        if ~isempty(strIdx)
                            str3M = double(getStrMask(strIdx,planC));
                            [~,outStr3M] = resampleScanAndMask([],double(str3M),...
                                xValsV,yValsV,zValsV,xResampleV,yResampleV,...
                                zResampleV);
                            outStr3M = outStr3M >= 0.5;
                            outStrName = [cropStrListC{n},'_resamp'];
                            cropParS(n).structureName = outStrName;
                            planC = maskToCERRStructure(outStr3M,0,scanNumV(scanIdx),...
                                outStrName,planC);
                        end
                    else
                        outStrName = [cropStrListC{n},'_resamp'];
                        cropParS(n).structureName = outStrName;
                    end
                    cropS(n).params = cropParS(n);
                end
            end
        end
    
        
        %Update affine matrix
        [affineOutM,~,voxSizV] = getPlanCAffineMat(planC, scanNumV(scanIdx), 1);
        originV = affineOutM(1:3,4);
        
    end
    
    %2. Crop around the region of interest
    limitsM = [];
    if ~(length(cropS) == 1 && strcmpi(cropS(1).method,'none'))
        fprintf('\nCropping to region of interest...\n');
        tic
        [minr, maxr, minc, maxc, slcV, cropStr3M, planC] = ...
            getCropLimits(planC,mask3M,scanNumV(scanIdx),cropS);
        %- Crop scan
        if ~isempty(scan3M) && numel(minr)==1
            scan3M = scan3M(minr:maxr,minc:maxc,slcV);
            limitsM = [minr, maxr, minc, maxc];
        else
            scan3M = scan3M(:,:,slcV);
            limitsM = [minr, maxr, minc, maxc];
        end
        
        %- Crop mask
        if numel(minr)==1
            cropStr3M = cropStr3M(minr:maxr,minc:maxc,slcV);
            if ~isempty(mask3M)
                mask3M = mask3M(minr:maxr,minc:maxc,slcV);
            end
        else
            cropStr3M = cropStr3M(:,:,slcV);
            if ~isempty(mask3M)
                mask3M = mask3M(:,:,slcV);
            end
        end
        toc
        %Update affine matrix
        %affineOutM = getAffineMatrixforTransform(affineOutM,operation,varargin);
    else
        cropStr3M = [];
    end
    scanOptS(scanIdx).crop = cropS;
    
    %3. Resize
    if ~strcmpi(resizeS(scanIdx).method,'none')
        fprintf('\nResizing data...\n');
        tic
        resizeMethod = resizeS(scanIdx).method;
        
        outSizeV = resizeS(scanIdx).size;
        [scan3M, mask3M] = resizeScanAndMask(scan3M,mask3M,outSizeV,...
            resizeMethod,limitsM,preserveAspectFlag);
        % obtain patient outline in view if background adjustment is needed
        if adjustBackgroundVoxFlag || transformViewFlag
            [~, cropStr3M] = resizeScanAndMask([],cropStr3M,outSizeV,...
                resizeMethod,limitsM,preserveAspectFlag);
        else
            cropStr3M = [];
        end
        toc
        
        %Update affine matrix
        %affineOutM = getAffineMatrixforTransform(affineOutM,operation,varargin);
    else
        if ~(adjustBackgroundVoxFlag || transformViewFlag)
            cropStr3M = [];
        end
    end
    
    scanC{scanIdx} = scan3M;
    maskC{scanIdx} = mask3M;
    
    
    %4. Transform view
    if transformViewFlag
        tic
        %     if ~isequal(viewC,{'axial'})
        fprintf('\nTransforming orientation...\n');
        %     end
        [viewOutC,maskOutC{scanIdx}] = transformView(scanC{scanIdx},...
            maskC{scanIdx},viewC);
        [~,cropStrC] = transformView([],cropStr3M,viewC);
        toc
        %Update affine matrix
        %affineOutM = getAffineMatrixforTransform(affineOutM,operation,varargin);
    else % case: 1 view, 'axial'
        viewOutC = {scanC{scanIdx}};
        maskOutC{scanIdx} = {maskC(scanIdx)};
        cropStrC = {cropStr3M};
    end
    
    
    %5. Filter images as required
    tic
    procScanC = cell(numChannels,1);
    
    for i = 1:length(viewC)
        
        scanView3M = viewOutC{i};
        maskView3M = logical(cropStrC{i});
        
        for c = 1:numChannels
            
            %mask3M = true(size(scanView3M));
            
            if strcmpi(filterTypeC{c},'original')
                %Use original image
                procScanC{c} = scanView3M;
                
            else
                imType = filterTypeC{c};
                imType = imType{1};
                if strcmpi(imType,'original')
                    procScanC{c} = scanView3M;
                else
                    fprintf('\nApplying %s filter...\n',imType);
                    paramS = channelParS(c);
                    filterParS = paramS.imageType.(imType);
                    outS = processImage(imType, scanView3M, maskView3M, filterParS);
                    fieldName = fieldnames(outS);
                    fieldName = fieldName{1};
                    procScanC{c} = outS.(fieldName);
                end
            end
        end
        viewOutC{i} = procScanC;
    end
    toc
    
    %6. Populate channels
    
    if numChannels > 1
        tic
        channelOutC = populateChannels(viewOutC,channelParS);
        fprintf('\nPopulating channels...\n');
        toc
    else
        channelOutC = viewOutC;
    end
    
    scanOutC{scanIdx} = channelOutC;
    
    %originV = affineOutM(1:3,4);
    coordInfoS(scanIdx).affineM = affineOutM;
    coordInfoS(scanIdx).originV = originV;
    coordInfoS(scanIdx).voxSizV = voxSizV;
    
end
optS.scan = scanOptS;

%Get scan metadata
%uniformScanInfoS = planC{indexS.scan}(scanNumV(scanIdx)).uniformScanInfo;
%resM(scanIdx,:) = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];

end
