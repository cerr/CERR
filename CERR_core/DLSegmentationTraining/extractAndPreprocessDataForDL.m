function [scanOutC, maskOutC, origScanNumV, scanNumV, optS, coordInfoS, planC] = ...
    extractAndPreprocessDataForDL(optS,planC,skipMaskExport,scanNumV,strNumV)
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
% varargin{3}: Vector of structure nos. Default: Use scan identifiers from optS.
% -------------------------------------------------------------------------
% AI 9/18/19
% AI 9/18/20  Extended to handle multiple scans

%% Get processing directives from optS
filtS = optS.filter;
regC = optS.register;
scanOptS = optS.input.scan;
resampleS = [scanOptS.resample];
resizeS = [scanOptS.resize];

indexS = planC{end};
strAssocScan = [];
if exist('strNumV','var') && ~isempty(strNumV)
    strListC = planC{indexS.structures}(strNumV).structureName;
    if ~iscell(strListC)
        strListC = {strListC};
    end
    labelV = 1:length(strListC);
else
    if isfield(optS.input,'structure')
        if isfield(optS.input.structure,'strNameToLabelMap')
            exportStrS = optS.input.structure.strNameToLabelMap;
            strListC = {exportStrS.structureName};
            labelV = [exportStrS.value];
        else
            strListC = optS.input.structure.name;
            if ~iscell(strListC)
                strListC = {strListC};
            end
            exportStrS.structureName = strListC;
            labelV = 1:length(strListC);
            exportStrS.value = labelV;
        end
        if isfield(optS.input.structure,'assocScan')
               strAssocScan = getScanNumFromIdentifiers(optS.input.structure.assocScan.identifier,planC);
        end
    else
        strListC = {};
    end
end

if ~exist('skipMaskExport','var')
    skipMaskExport = true;
end

%% Filter image
strC = {planC{indexS.structures}.structureName};
copyStrsC = {};
origScanNumV = nan(1,length(scanOptS));
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
            toCpyC = cellfun(@(x)isfield(x,'copyStr'),regC,'un',0);
            if any([toCpyC{:}])
                copyStrsC = [copyStrsC;regC([toCpyC{:}]).copyStr];
                if ~iscell(copyStrsC)
                    copyStrsC = {copyStrsC};
                end
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
            origScanNumV(n) = baseScanNum;
        else
            scanNumV(n) = getScanNumFromIdentifiers(identifierS,planC);
            origScanNumV(n) = scanNumV(n);
        end
    end
else
    origScanNumV = scanNumV;
end


%% Register scans 
indexS = planC{end};
allStrC = {planC{indexS.structures}.structureName};
%Loop over registration steps
for nReg = 1:length(regC)

    if iscell(regC)
        regS = regC{nReg};
    else
        regS = regC;
    end

    if ~isempty(fieldnames(regS))

        %Get base scan index
        identifierS = regS.baseScan.identifier;
        baseScanNum = getScanNumFromIdentifiers(identifierS,planC);
        regScanNumV(1) = baseScanNum;
        %Get moving scan index
        identifierS = regS.movingScan.identifier;
        movScan = getScanNumFromIdentifiers(identifierS,planC);
        regScanNumV(2) = movScan;
        %Get list of structures to deform
        if isempty(copyStrsC) && isfield(regS,'copyStr')
            copyStrsC = [regS.copyStr];
            if ~iscell(copyStrsC)
                copyStrsC = {copyStrsC};
            end
        end

        %Handle pre-registered scans
        if strcmp(regS.method,'none')
            if isfield(regS,'copyStr')
                if isfield(regS,'renameStr')
                    renameC = regS.renameStr;
                    if ~iscell(renameC)
                        renameC = {renameC};
                    end
                end
                for nStr = 1:length(copyStrsC)
                    cpyStrV = getMatchingIndex(copyStrsC{nStr},allStrC,'exact');
                    assocScanV = getStructureAssociatedScan(cpyStrV,planC);
                    cpyStr = cpyStrV(assocScanV==regScanNumV(1));
                    dstStr = cpyStrV(assocScanV==regScanNumV(2));
                    if isempty(dstStr) && ~isempty(cpyStr)
                        planC = copyStrToScan(cpyStr,regScanNumV(2),planC);
                        if isfield(regS,'renameStr')
                            planC{indexS.structures}(end).structureName = ...
                                renameC{nStr};
                        end
                    end
                    allStrC = {planC{indexS.structures}.structureName};
                end
            end
        else
            %Register scans
            planC = registerScansForDLS(planC,regScanNumV,...
                regS.method,regS);
            allStrC = {planC{indexS.structures}.structureName};
        end
        copyStrsC = {};
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
origScanNumV(ignoreIdxV) = [];


%% Identify available structures in planC
allStrC = {planC{indexS.structures}.structureName};
strNotAvailableV = ~ismember(lower(strListC),lower(allStrC)); %Case-insensitive
if any(strNotAvailableV) && ~skipMaskExport
    scanOutC = {};
    maskOutC = {};
    warning(['Skipping pt. Missing structures: ',...
        strjoin(strListC(strNotAvailableV),',')]);
    return
end
exportStrC = strListC(~strNotAvailableV);

exportStrNum = 0;
strIdxC = {};
exportLabelV = labelV(~strNotAvailableV);
if ~isempty(exportStrC) || ~skipMaskExport
    %Get structure ID and assoc scan
    strIdxC = cell(length(exportStrC),1);
    for strNum = 1:length(exportStrC)
        currentLabelName = exportStrC{strNum};
         strMatchIdx = getMatchingIndex(currentLabelName,allStrC,'exact');
         skipFlag = 0;
         if length(strMatchIdx)>1
             if ~isempty(strAssocScan)
                 scanMatchIdx = getStructureAssociatedScan(strMatchIdx,planC);
                 strMatchIdx = strMatchIdx(scanMatchIdx==strAssocScan);
                 if isempty(strMatchIdx)
                     skipFlag = 1;
                     warning(['Missing structure: ',currentLabelName]);
                 elseif length(strMatchIdx)>1
                     error('Multiple structures found matching %s',currentLabelName);
                 end
             else
                 strMatchIdx = strMatchIdx(end);
             end
         end
         if ~skipFlag
             exportStrNum = exportStrNum+1;
             strIdxC{exportStrNum} = strMatchIdx;
         else
             exportLabelV(strNum) = [];
         end
    end
end

if ~isempty(strAssocScan)
    if ~isempty(strIdxC)
        strIdxV = [strIdxC{:}];
        scanMatchIdxV = getStructureAssociatedScan(strIdxV,planC);
        keepIdxV = scanMatchIdxV==strAssocScan;
        strIdxC(~keepIdxV) = [];
        exportLabelV = exportLabelV(keepIdxV);
    else
        keepIdxV = false(1,length(exportLabelV));
    end
    if any(~keepIdxV)
        warning([' Missing structures: ',...
            strjoin(exportStrC(~keepIdxV),',')]);
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
    imageUnits = '';
    if isfield(scanOptS(n),'scanUnits')
        imageUnits = scanOptS(n).scanUnits;
    end
    scan3M = transformScanUnits(scanNumV(scanIdx),planC,imageUnits);
    
    %Extract masks from planC
    strC = {planC{indexS.structures}.structureName};
    if isempty(exportStrC) && skipMaskExport
        mask4M = [];
        validStrIdxV = [];
    else
        assocStrIdxV = strcmpi(planC{indexS.scan}(scanNumV(scanIdx)).scanUID,UIDc);
        strIdxV = [strIdxC{:}];
        strIdxV = reshape(strIdxV,1,[]);
        validStrIdxV = ismember(strIdxV,find(assocStrIdxV));
        scanExportStrC = exportStrC(validStrIdxV);
        validStrIdxV = strIdxV(validStrIdxV);
        keepLabelIdxV = assocStrIdxV(validStrIdxV);
        validExportLabelV = exportLabelV(keepLabelIdxV);
        maskSizeV = [size(scan3M),length(validExportLabelV)];
        mask4M = zeros(maskSizeV);
    end
    
    if length(validStrIdxV)==0
        mask4M = [];
    else
        for strNum = 1:length(validStrIdxV)
            strIdx = validStrIdxV(strNum);
            %Update labels
            tempMask3M = false(size(scan3M));
            [rasterSegM, planC] = getRasterSegments(strIdx,planC);
            [maskSlicesM, uniqueSlices] = rasterToMask(rasterSegM, scanNumV(scanIdx), planC);
            tempMask3M(:,:,uniqueSlices) = maskSlicesM;
            mask4M(:,:,:,validExportLabelV(strNum)) = tempMask3M;
        end
    end
    
    %Get affine matrix
    %[affineInM,~,voxSizV] = getPlanCAffineMat(planC, scanNumV(scanIdx), 1);
    [affineInM,~,voxSizV] = getPlanCAffineMat(planC, origScanNumV(scanIdx), 1);
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
        origScanIdx = scanNumV(scanIdx);
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
        originV = [xValsV(1),yValsV(1),zValsV(end)];        
        [xResampleV,yResampleV,zResampleV] = ...
            getResampledGrid(outResV,xValsV,yValsV,zValsV,...
            originV,gridAlignMethod);
        [scan3M,mask4M] = resampleScanAndMask(double(scan3M),double(mask4M),...
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

        %Copy identifying information
        copyInfoC = {'scanType','imageType','seriesDescription',...
            'seriesDate','studyDate'};
        for nCpy = 1:length(copyInfoC)
        scanInfoS.(copyInfoC{nCpy}) = ...
            planC{indexS.scan}(origScanIdx).scanInfo(1).(copyInfoC{nCpy});
        end
   
        planC = scan2CERR(scan3M,['Resamp_scan',origScanIdx],'',...
            scanInfoS,'',planC);
        resampScanNum = length(planC{indexS.scan});
        scanNumV(scanIdx) = resampScanNum;
        planC{indexS.scan}(resampScanNum).assocBaseScanUID = ...
        planC{indexS.scan}(origScanIdx).scanUID;
        for strNum = 1:length(validStrIdxV)
            strMask3M = squeeze(mask4M(:,:,:,validExportLabelV(strNum)));
            outStrName = [scanExportStrC{strNum},'_resamp'];
            planC = maskToCERRStructure(strMask3M,0,resampScanNum,...
                outStrName,planC);
            replaceStrIdx = strcmpi(scanExportStrC{strNum},strListC);
            optS.input.structure.strNameToLabelMap(replaceStrIdx).structureName = outStrName;
        end

        toc
        %Resample reqd structures associated with scan
        if ~(length(cropS) == 1 && strcmpi(cropS(1).method,'none'))
            cropStrListC = arrayfun(@(x)x.params.structureName,cropS,'un',0);
            cropParS = [cropS.params];
            if ~isempty(cropStrListC) 
                for n = 1:length(cropStrListC)
                    resampStrIdx = getMatchingIndex(cropStrListC{n},strC,...
                        'EXACT');
                    assocScanIdx = getStructureAssociatedScan(resampStrIdx,planC);  
                    if ~isempty(resampStrIdx) && assocScanIdx==origScanIdx
                        str3M = double(getStrMask(resampStrIdx,planC));
                        [~,outStr3M] = resampleScanAndMask([],double(str3M),...
                            xValsV,yValsV,zValsV,xResampleV,yResampleV,...
                            zResampleV);
                        outStr3M = outStr3M >= 0.5;
                        outStrName = [cropStrListC{n},'_resamp'];
                        cropParS(n).structureName = outStrName;
                        planC = maskToCERRStructure(outStr3M,0,scanNumV(scanIdx),...
                            outStrName,planC);
                    else
                        outStrName = [cropStrListC{n},'_resamp'];
                        cropParS(n).structureName = outStrName;
                    end
                    cropS(n).params = cropParS(n);
                end
            end
        end

        %Update relevant scan identifiers to point to the resampled scan
        allCropS = [scanOptS(:).crop];
        candidateIdxC = arrayfun(@(x) isfield(x.params,'scanIdentifier'),...
            allCropS,'un',0);
        candidateIdxV = find([candidateIdxC{:}]);
        relScanIdxV = false(1,length(candidateIdxV));
        for nCd = 1:length(candidateIdxV)
            cdIdentifierS = allCropS(candidateIdxV(nCd)).params.scanIdentifier;
            relScan = getScanNumFromIdentifiers(cdIdentifierS,planC);
            if relScan == origScanIdx
                relScanIdxV(nCd) = true;
            end
        end
        dependentIdxV = candidateIdxV(relScanIdxV);

        for nDep = 1:length(dependentIdxV)
            newParamS = scanOptS(dependentIdxV(nDep)).crop.params;
            newParamS.scanIdentifier.resampled = 1;
            scanOptS(dependentIdxV(nDep)).crop.params = newParamS;
        end
    
        %Update affine matrix
        %[affineOutM,~,voxSizV] = getPlanCAffineMat(planC, scanNumV(scanIdx), 1);
        [affineOutM,~,voxSizV] = getPlanCAffineMat(planC, origScanNumV(scanIdx), 1);
        originV = affineOutM(1:3,4);
        
    end
    
    %2. Crop around the region of interest
    limitsM = [];
    if ~(length(cropS) == 1 && strcmpi(cropS(1).method,'none'))
        fprintf('\nCropping to region of interest...\n');
        tic
        [minr, maxr, minc, maxc, slcV, cropStr3M, planC] = ...
            getCropLimits(planC,mask4M,scanNumV(scanIdx),cropS);
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
            if ~isempty(mask4M)
                mask4M = mask4M(minr:maxr,minc:maxc,slcV,:);
            end
        else
            cropStr3M = cropStr3M(:,:,slcV);
            if ~isempty(mask4M)
                mask4M = mask4M(:,:,slcV,:);
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

        resizeMethodS = resizeS(:,scanIdx);
        for nMethod = 1:length(resizeMethodS)
            resizeMethod = resizeMethodS(nMethod).method;
            outSizeV = resizeMethodS(nMethod).size;
            [scan3M, mask4M] = resizeScanAndMask(scan3M,mask4M,outSizeV,...
                resizeMethod,limitsM,preserveAspectFlag);
            % obtain patient outline in view if background adjustment is needed
            if adjustBackgroundVoxFlag || transformViewFlag
                [~, cropStr3M] = resizeScanAndMask([],cropStr3M,outSizeV,...
                    resizeMethod,limitsM,preserveAspectFlag);
            else
                cropStr3M = [];
            end
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
    maskC{scanIdx} = mask4M;
    
    
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
        cropStrView3M = logical(cropStrC{i});
        
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
                    outS = processImage(imType, scanView3M,...
                        cropStrView3M, filterParS);
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
    coordInfoS(scanIdx).originV = originV;% to do - get this from the resized scan?
    coordInfoS(scanIdx).voxSizV = voxSizV; % to do - get this from the resized scan.
    %coordInfoS(scanIdx).imageOrientationV =...
    %    planC{indexS.scan}(scanNumV(scanIdx)).scanInfo(1).imageOrientationPatient;
    coordInfoS(scanIdx).imageOrientationV =...
        planC{indexS.scan}(origScanNumV(scanIdx)).scanInfo(1).imageOrientationPatient;
    
end
optS.input.scan = scanOptS;

%Get scan metadata
%uniformScanInfoS = planC{indexS.scan}(scanNumV(scanIdx)).uniformScanInfo;
%resM(scanIdx,:) = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];

end
