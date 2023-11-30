function planC = generateTextureMapFromPlanC(planC,scanNum,strNum,configFilePath)
% planC = generateTextureMapFromPlanC(planC,scanNum,strNum,configFilePath)
%
% Compute texture maps from and export to DICOM.
% -------------------------------------------------------------------------
% INPUTS
% planC            : CERR archive
% scanNum          : Scan no. Or leave empty to use scan associated with 
%                    strNum input.
% strNum           : Structure no.
% configFilePath   : Path to config files for texture calculation.
% -------------------------------------------------------------------------
% AI 07/22/20

if numel(strNum) > 1 && ~isempty(scanNum)
    mask3M = strNum;
    [~,~,sV] = find3d(mask3M);
    uniqueSlicesV = unique(sV);
else
    % Get scan no. & bounding box extents
    scanNum = getStructureAssociatedScan(strNum,planC);
    origSizV = size(getScanArray(scanNum,planC));
    % temp
    mask3M = false(origSizV);
    [rasterM, planC] = getRasterSegments(strNum,planC);
    [slMask3M,uniqueSlicesV] = rasterToMask(rasterM,scanNum,planC);
    mask3M(:,:,uniqueSlicesV) = slMask3M;
    % end temp
end
[minr, maxr, minc, maxc] = compute_boundingbox(mask3M);
%maskBoundingBox3M = mask3M(minr:maxr,minc:maxc,uniqueSlicesV);


%% Read config file
paramS = getRadiomicsParamTemplate(configFilePath);

%% Apply pre-processing
[procScan3M,procMask3M,gridS] = preProcessForRadiomics(scanNum,...
    strNum, paramS, planC);
[minr, maxr, minc, maxc] = compute_boundingbox(procMask3M);
maskSlcV = sum(sum(procMask3M))>0;
maskBoundingBox3M = procMask3M(minr:maxr,minc:maxc,maskSlcV);

%% Get filtered image
filterTypeC = fieldnames(paramS.imageType);
for nType = 1: length(filterTypeC)

    %Get params
    filterType = filterTypeC{nType};
    filtParamS = paramS.imageType.(filterType);

    for nParam = 1:length(filtParamS)

        currFiltParamS = filtParamS(nParam);
        voxSizV = gridS.PixelSpacingV;
        currFiltParamS.VoxelSize_mm.val = voxSizV * 10; %convert cm to mm
        currFiltParamS.padding = paramS.whichFeatS.padding;
        %Apply filter
        outS = processImage(filterType,procScan3M,procMask3M,currFiltParamS);

        %% Create texture scans
        fieldNamesC = fieldnames(outS);
        indexS = planC{end};

        for nOut = 1:length(fieldNamesC)

            filtScan3M = outS.(fieldNamesC{nOut});
            texSizV = size(filtScan3M);

            %Remove padding
            if currFiltParamS.padding.flag
                padSizV = currFiltParamS.padding.size;
            else
                %Undo default padding
                %padSizV = [5,5,5]; %For resampling
                padSizV = [0,0,0];
            end
            filtScan3M = filtScan3M(padSizV(1)+1 : texSizV(1)-padSizV(1),...
                padSizV(2)+1 : texSizV(2)-padSizV(2),...
                padSizV(3)+1 : texSizV(3)-padSizV(3));
            [~, maxr, minc, ~] = compute_boundingbox(mask3M);

            %Create texture object
            assocScanUID = planC{indexS.scan}(scanNum).scanUID;
            nTexture = length(planC{indexS.texture}) + 1;
            planC{indexS.texture}(nTexture).assocScanUID = assocScanUID;
            assocStrUID = '';
            if numel(strNum) == 1
                assocStrUID = strjoin({planC{indexS.structures}(strNum).strUID},',');
            end
            planC{indexS.texture}(nTexture).assocStructUID = assocStrUID;
            planC{indexS.texture}(nTexture).category = filterType;
            planC{indexS.texture}(nTexture).parameters = currFiltParamS;
            planC{indexS.texture}(nTexture).description = filterType;
            planC{indexS.texture}(nTexture).textureUID = createUID('TEXTURE');

            %Create new scan
            scanS = planC{indexS.scan}(scanNum);
            [xVals,yVals,zVals] = getScanXYZVals(scanS);
            zV = zVals(uniqueSlicesV);

            regParamsS.horizontalGridInterval = voxSizV(1);
            regParamsS.verticalGridInterval = voxSizV(2);
            regParamsS.coord1OFFirstPoint = xVals(minc);
            regParamsS.coord2OFFirstPoint = yVals(maxr);
            regParamsS.zValues = zV;
            regParamsS.sliceThickness = ...
                [planC{indexS.scan}(scanNum).scanInfo(uniqueSlicesV).sliceThickness];
            assocTextureUID = planC{indexS.texture}(nTexture).textureUID;
            planC = scan2CERR(filtScan3M,'CT','Passed',regParamsS,assocTextureUID,planC);

            %Update scan metadata
            newScanNum = length(planC{indexS.scan});
            planC{indexS.scan}(newScanNum).scanType = [filterType,'_',fieldNamesC{nOut}];
            %newSeriesInstanceUID = dicomuid;
            init_ML_DICOM
            orgRoot = '1.3.6.1.4.1.9590.100.1.2';
            newSeriesInstanceUID = javaMethod('createUID','org.dcm4che3.util.UIDUtils',orgRoot);
            %imgOriV = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
            for k = 1:length(planC{indexS.scan}(newScanNum).scanInfo)
                planC{indexS.scan}(newScanNum).scanInfo(k).seriesInstanceUID = newSeriesInstanceUID;
                %Handled in scan2CERR
                %planC{indexS.scan}(newScanNum).scanInfo(k).imageOrientationPatient = imgOriV;
                planC{indexS.scan}(newScanNum).scanInfo(k).imageOrientationPatient = ...
                    planC{indexS.scan}(scanNum).scanInfo(uniqueSlicesV(k)).imageOrientationPatient;
                planC{indexS.scan}(newScanNum).scanInfo(k).imagePositionPatient = ...
                    planC{indexS.scan}(scanNum).scanInfo(uniqueSlicesV(k)).imagePositionPatient;
            end
        end
    end
end


end