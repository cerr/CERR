function outS = processImage(filterType,scan3M,mask3M,paramS,hWait)
% Process scan using selected filter and parameters
%-------------------------------------------------------------------------
% INPUTS
% filterType -  Supported textures: 'HaralickCooccurance','Wavelets','Sobel',
%               'LoG' (ITK-compliant),'LoG_IBSI' (IBSI-compliant),'Gabor'
%               (IBSI compliant), 'Gabor_deprecated', 'Mean','LawsEnergy'
%               'LawsConvolution','CoLlage','First order statistics', 
%               or 'SimpleITK'.
%               Other filters: 'suv', 'assignBkgIntensity'.
% scan3M     - 3-D scan array, cropped around ROI and padded if specified
% mask3M     - 3-D mask, croppped to bounding box
% paramS     - Filter parameters
% hWait      - Handle to progress bar (Optional)
%-------------------------------------------------------------------------
%
% EXAMPLES:
%
% The following examples demonstrate using filters from the SimpleITK
% library.
%
% global planC
% indexS = planC{end};
%
% filterType = 'SimpleITK';
% structNum = 1;
% scanNum = getStructureAssociatedScan(structNum,planC);
% CTOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
% scan3M = single(planC{indexS.scan}(scanNum).scanArray) - CTOffset;
% mask3M = getStrMask(structNum, planC);
% hWait = NaN;
%
% 1. Gradient Image Filter
% paramS.sitkFilterName = 'GradientImageFilter';
% paramS.useImageSpacing = false;
% paramS.useImageDirection = false;
% outS = processImage(filterType,scan3M,mask3M,paramS,hWait);
%
% 2 Histogram matching
% paramS.sitkFilterName = 'HistogramMatchingImageFilter';
% paramS.numHistLevel = 1024;
% paramS.numMatchPts = 7;
% paramS.ThresholdAtMeanIntensityOn = true;
% paramS.refImgPath = fullfile(getCERRPath,...
%     'ModelImplementationLibrary\SegmentationModels\MR_LungNodules_TumorAware\model_wrapper\reference_image_for_hist_match.nii');
% outS = processImage(filterType,scan3M,mask3M,paramS,hWait);
%-------------------------------------------------------------------------
%AI 03/16/18

if ~exist('hWait','var')
    hWait = [];
end

filterType = strrep(filterType,' ','');

% Compute ROI bounding box
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);

%Parameters for rotation invariance
aggregationMethod = 'none';
dim = '2d';
ndims = 1;
numRotations = 1;
if isfield(paramS,'RotationInvariance') && ~isempty(paramS.RotationInvariance)
    rotS = paramS.RotationInvariance.val;
    aggregationMethod = rotS.AggregationMethod;
    dim = rotS.Dim;
    if strcmpi(dim,'2d')
        numRotations = 4;
    else
        numRotations = 24;
    end
    %Remove padding
    %if isfield(paramS.padding,'method') && ~isempty(paramS.padding.method)
    %    padSizeV = paramS.padding.size;
    %    padMethod = paramS.padding.method;
    %    scanSizeV = size(scan3M);
    %    scan3M = scan3M(padSizeV(1)+1:scanSizeV(1)-padSizeV(1), ...
    %        padSizeV(2)+1:scanSizeV(2)-padSizeV(2),...
    %        padSizeV(3)+1:scanSizeV(3)-padSizeV(3));
    %    origScanSizeV = size(scan3M);
    %end
end

%% Apply filter at specified orientations
rotTextureC = cell(1,numRotations);

for index = 1:numRotations

    if strcmpi(dim,'2d')
        rotScan3M = rot90(scan3M, index-1);
        rotMask3M = rot90(mask3M, index-1);
    elseif strcmpi(dim,'3d')
        rotScan3M = rotate3dSequence(scan3M,index-1,1);
        rotMask3M = rotate3dSequence(mask3M,index-1,1);
    end

    %Apply padding
    %if isfield(paramS.padding,'method') && ~isempty(paramS.padding.method)...
    %        && numRotations>1
    %    [rotScan3M,rotMask3M] = padScan(rotScan3M,rotMask3M,padMethod,padSizeV);
    %end

    switch(filterType)

        case 'HaralickCooccurance'
            SUVvals3M  = double(rotScan3M);
            [minr,maxr,minc,maxc,mins,maxs] = compute_boundingbox(rotMask3M);
            volToEval  = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
            offsetsM = getOffsets(paramS.Directionality.val);
            typesC = {'All','Energy','Entropy','Sum Avg','Correlation',...
                'Homogeneity','Contrast','Cluster Shade',...
                'Cluster Promincence', 'Haralick Correlation'};

            sel = paramS.Type.val;
            if strcmpi(sel,'all')
                flagV = ones(1,9); % All 9 haralick features;
            else
                flagV = zeros(1,9);
                if iscell(sel)
                    for iFeat = 1:length(sel)
                        idx = find(strcmpi(typesC,sel{iFeat}));
                        flagV(idx-1) = 1;
                    end
                else
                    idx = find(strcmpi(typesC,sel));
                    flagV(idx-1) = 1;
                end
            end

            %Optional parametets
            if ~isfield(paramS,'minIntensity')
                paramS.minIntensity.val = [];
            end
            if ~isfield(paramS,'maxIntensity')
                paramS.maxIntensity.val = [];
            end
            if ~isfield(paramS,'binWidth')
                paramS.binWidth.val = [];
            end

            if ~ishandle(hWait)
                hWait = NaN;
            end
            % Single co-occurrence matrix from all directions
            [energy,entropy,sumAvg,corr,invDiffMom,contrast,clustShade,...
                clustProminence,haralCorr] = textureByPatchCombineCooccur...
                (volToEval, paramS.NumLevels.val, paramS.PatchSize.val,...
                offsetsM, flagV, hWait, paramS.minIntensity.val,...
                paramS.maxIntensity.val, paramS.binWidth.val);

            % Different co-occurrence mateices for dirrerent directions. Then average
            % the features.
            %         separateDirnFlag = 0; % average directions
            %         [energy,entropy,sumAvg,corr,...
            %             invDiffMom,contrast,clustShade,...
            %             clustProminence,haralCorr] = textureByPatch(volToEval,...
            %             paramS.NumLevels.val, paramS.PatchSize.val, offsetsM, flagV, hWait, ...
            %             paramS.minIntensity.val, paramS.maxIntensity.val, paramS.binWidth.val, separateDirnFlag);

            energy3M = zeros(size(rotScan3M));
            energy3M(minr:maxr,minc:maxc,mins:maxs) = energy;

            entropy3M = zeros(size(rotScan3M));
            entropy3M(minr:maxr,minc:maxc,mins:maxs) = entropy;

            sumAvg3M = zeros(size(rotScan3M));
            sumAvg3M(minr:maxr,minc:maxc,mins:maxs) = sumAvg;

            corr3M = zeros(size(rotScan3M));
            corr3M(minr:maxr,minc:maxc,mins:maxs) = corr;

            invDiffMom3M = zeros(size(rotScan3M));
            invDiffMom3M(minr:maxr,minc:maxc,mins:maxs) = invDiffMom;

            contrast3M = zeros(size(rotScan3M));
            contrast3M(minr:maxr,minc:maxc,mins:maxs) = contrast;

            clustShade3M = zeros(size(rotScan3M));
            clustShade3M(minr:maxr,minc:maxc,mins:maxs) = clustShade;

            clustProminence3M = zeros(size(rotScan3M));
            clustProminence3M(minr:maxr,minc:maxc,mins:maxs) = clustProminence;

            haralCorr3M = zeros(size(rotScan3M));
            haralCorr3M(minr:maxr,minc:maxc,mins:maxs) = haralCorr;

            outS.Energy = energy3M;
            outS.Entropy = entropy3M;
            outS.SumAvg = sumAvg3M;
            outS.Corr = corr3M;
            outS.InvDiffMom = invDiffMom3M;
            outS.Contrast = contrast3M;
            outS.ClustShade = clustShade3M;
            outS.ClustProminence = clustProminence3M;
            outS.HaralCorr = haralCorr3M;

            featC = fieldnames(outS);
            outS = rmfield(outS,featC(~flagV));

        case 'Wavelets'

            vol3M   = flip(double(rotScan3M),3); %FOR IBSI2

            dirListC = {'All','HHH','LHH','HLH','HHL','LLH','LHL','HLL','LLL'};
            wavType =  paramS.Wavelets.val;
            if ~isempty(paramS.Index.val)
                wavType = [wavType,paramS.Index.val];
            end
            dir = paramS.Direction.val;

            if strcmp(dir,'All')
                for n = 2:length(dirListC)
                    outname = [wavType,'_',dirListC{n}];
                    outname = strrep(outname,'.','_');
                    outname = strrep(outname,' ','_');

                    subbandsS = getWaveletSubbands(vol3M,wavType);
                    matchDir = [dirListC{n},'_',wavType];
                    out3M = subbandsS.(matchDir);

                    if ishandle(hWait)
                        set(hWait, 'Vertices', [[0 0 (n-1)/(length(dirListC)-1) (n-1)/(length(dirListC)-1)]' [0 1 1 0]']);
                        drawnow;
                    end

                    outS.(outname) = out3M;
                end
            else
                outname = [wavType,'_',dir];
                outname = strrep(outname,'.','_');
                outname = strrep(outname,' ','_');

                subbandsS = getWaveletSubbands(vol3M,wavType);
                matchDir = [dir,'_',wavType];
                out3M = subbandsS.(matchDir);

                if ishandle(hWait)
                    set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                    drawnow;
                end

                outS.(outname) = flip(out3M,3); %FOR IBSI2
            end


        case 'Sobel'

            vol3M = double(rotScan3M);
            [mag3M,dir3M] = sobelFilt(vol3M);

            %Remove padding
            outS.SobelMag = mag3M;
            outS.SobelDir = dir3M;

            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end


        case 'LoG'

            vol3M = double(rotScan3M);

            LoG3M = recursiveLOG(vol3M,...
                paramS.Sigma_mm.val,paramS.VoxelSize_mm.val);

            outS.LoG_recursive = LoG3M;

            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end

        case 'LoG_IBSI'

            vol3M = double(rotScan3M);

            sigmaV = reshape(paramS.Sigma_mm.val,1,[]);
            cutOffV = reshape(paramS.CutOff_mm.val,1,[]);
            voxelSizeV = paramS.VoxelSize_mm.val;
            LoG3M = logFiltIBSI(vol3M,sigmaV,cutOffV,voxelSizeV);

            outS.LoG_IBSI = LoG3M;

            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end

        case 'Gabor_deprecated'

            vol3M = double(rotScan3M);
            gabor3M = filtImgGabor(vol3M,paramS.Radius.val,paramS.Sigma.val,...
                paramS.AspectRatio.val,paramS.Orientation.val,paramS.Wavlength.val);

            outS.Gabor_deprecated = gabor3M;

            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end

        case 'Gabor'

            vol3M = double(rotScan3M);
            voxelSizV = paramS.VoxelSize_mm.val;
            sigma = paramS.Sigma_mm.val/voxelSizV(1);
            wavelength = paramS.Wavlength_mm.val./voxelSizV(1);
            theta = paramS.Orientation.val;
            gamma = paramS.SpatialAspectRatio.val;
            if isfield(paramS,'Radius_mm')
                radius = paramS.Radius_mm.val/voxelSizV(1);
                gabor3M = GaborFiltIBSI(vol3M,sigma,wavelength,gamma,theta,...
                    radius);
                outS.Gabor = gabor3M;
            else
                if length(theta)==1
                    gabor3M = GaborFiltIBSI(vol3M,sigma,wavelength,gamma,theta);
                    outS.Gabor = gabor3M;
                else
                    %Multiple orientations
                    gaborOutC = cell(1,length(theta));
                    for nTheta = 1:length(theta)
                        gaborOutC{nTheta} = GaborFiltIBSI(vol3M,sigma,wavelength,...
                            gamma,theta(nTheta));
                    end
                    if isfield(paramS,'mode') &&  strcmpi(paramS.mode.val,'avg')
                        gaborAll = cat(4, gaborOutC{:});
                        gabor3M = mean(gaborAll,4);
                        outS.Gabor = gabor3M;
                    else
                        for nTheta = 1:length(theta)
                            fieldName = ['Gabor_',num2str(theta(nTheta))];
                            outS.(fieldName) = gaborOutC{nTheta};
                        end
                    end
                end
            end

            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end


        case 'Mean'

            vol3M = double(rotScan3M);
            kernelSize = paramS.KernelSize.val;
            if ~isnumeric(kernelSize)
                kernelSize = str2double(kernelSize);
            end
            kernelSize = reshape(kernelSize,1,[]);

            filt3M = ones(kernelSize);
            filt3M = filt3M./sum(filt3M(:));

            if length(kernelSize)==3 %3d
                meanFilt3M = convn(vol3M,filt3M,'same');
            elseif length(kernelSize)==2 %2d
                meanFilt3M = nan(size(vol3M));
                for slc = 1:size(vol3M,3)
                    meanFilt3M(:,:,slc) = conv2(vol3M(:,:,slc),filt3M,'same');
                end
            end
            outS.meanFilt = meanFilt3M;

            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end

        case 'FirstOrderStatistics'
            [minr,maxr,minc,maxc,mins,maxs] = compute_boundingbox(rotMask3M);
            rotMask3M = rotMask3M(minr:maxr,minc:maxc,mins:maxs);
            rotScan3M = rotScan3M(minr:maxr,minc:maxc,mins:maxs);

            patchSizeV = paramS.PatchSize.val;

            %Get voxel size
            voxelSizV = paramS.VoxelSize_mm.val;
            voxelVol = prod(voxelSizV);

            %Compute patch-based statistics
            statC = {'min','max','mean','range','std','var','median','skewness',...
                'kurtosis','entropy','rms','energy','totalEnergy','meanAbsDev',...
                'medianAbsDev','P10','P90','robustMeanAbsDev','robustMedianAbsDev',...
                'interQuartileRange','coeffDispersion','coeffVariation'};

            [~,patchStatM] = firstOrderStatsByPatch(rotScan3M,rotMask3M,...
                patchSizeV,voxelVol);

            for n = 1:length(statC)
                out3M = zeros(size(rotScan3M));
                outV = patchStatM(:,n);
                out3M(rotMask3M) = outV;
                outS.(statC{n}) = out3M;
                if ishandle(hWait)
                    set(hWait, 'Vertices', [[0 0 n/length(statC) n/length(statC)]' [0 1 1 0]']);
                    drawnow;
                end
            end


        case 'LawsConvolution'

            vol3M = double(rotScan3M);

            %dirC = {'2d','3d','all'};
            %sizC = {'3','5','all'};
            normFlagC = {'Yes','No'};
            dir = paramS.Direction.val;
            type = paramS.Type.val;
            if isnumeric(type)
                type = num2str(paramS.Type.val);
            end
            selIdx = find(strcmpi(paramS.Normalize.val,normFlagC));
            normFlag = 2 - selIdx;
            lawsMasksS = getLawsMasks(dir,type,normFlag);

            %Compute features
            fieldNamesC = fieldnames(lawsMasksS);
            numFeatures = length(fieldNamesC);

            for i = 1:numFeatures

                text3M = convn(vol3M,lawsMasksS.(fieldNamesC{i}),'same');

                outS.(fieldNamesC{i}) = text3M;

                if ishandle(hWait)
                    set(hWait, 'Vertices', [[0 0 i/numFeatures i/numFeatures]' [0 1 1 0]']);
                    drawnow;
                end

            end

        case 'LawsEnergy'
            %Ref: %https://arxiv.org/pdf/2006.05470.pdf

            %Filter padded image using Laws' kernel
            lawsOutS = processImage('LawsConvolution',rotScan3M,rotMask3M,paramS,[]);

            fieldNameC = fieldnames(lawsOutS);
            numFeatures = length(fieldNameC);
            padMethod = paramS.PadMethod.val;
            padSizV = paramS.PadSize.val;

            %Loop over response maps
            for i = 1:length(fieldNameC)

                %Pad response map
                lawsTex3M = lawsOutS.(fieldNameC{i});
                if ~isequal(size(lawsTex3M),size(rotScan3M))
                    responseSizV = size(lawsTex3M);
                    lawsTex3M = lawsTex3M(padSizV(1)+1:responseSizV(1)-padSizV(1),...
                        padSizV(2)+1:responseSizV(2)-padSizV(2),...
                        padSizV(3)+1:responseSizV(3)-padSizV(3));
                    lawsTex3M = padScan(lawsTex3M,rotMask3M,padMethod,padSizV);
                end

                %Apply mean filter
                meanOutS = processImage('Mean',lawsTex3M,rotMask3M,paramS,[]);
                lawsEnergy3M = meanOutS.meanFilt;

                outField = [fieldNameC{i},'_Energy'];
                outS.(outField) = lawsEnergy3M;
                if ishandle(hWait)
                    set(hWait, 'Vertices', [[0 0 i/numFeatures i/numFeatures]' [0 1 1 0]']);
                    drawnow;
                end
            end


        case 'CoLlage'

            vol3M = single(rotScan3M);
            dir = paramS.Dimension.val;
            coLlAGe3M = getCollageFeature(vol3M, rotMask3M,...
                paramS.Dominant_Dir_Radius.val,...
                paramS.Cooccur_Radius.val, paramS.Number_Gray_Levels.val,...
                dir, hWait);

            outS.entropy = coLlAGe3M;
            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end

        case 'suv'
            scanName = ['suv3M_',paramS.suvType.val];
            headerS = paramS.scanInfoS;
            outS.(scanName) = getSUV(rotScan3M, headerS, paramS.suvType.val);

        case 'SimpleITK'

            vol3M   = double(rotScan3M);
            % Path to SimpleITK
            optS = opts4Exe([getCERRPath,'CERROptions.json']);
            sitkLibPath = optS.sitkLibPath;
            % Call the SimpleITK wrapper
            sitkFilterName = paramS.sitkFilterName.val;
            % to do - update the signature to include mask3M?
            sitkOutS = sitkWrapper(sitkLibPath, vol3M, sitkFilterName, paramS);
            filterNamC = fieldnames(sitkOutS);
            outS.(sitkFilterName) = sitkOutS.(filterNamC{1});

        case 'assignBkgIntensity'
            intVal = paramS.assignVal;
            rotScan3M(~rotMask3M) = intVal;
            outS.(filterType) = rotScan3M;


        otherwise
            %Call custom function 'filterType'
            filtImg3M = feval(filterType,rotScan3M,rotMask3M,paramS);
            outS.(filterType) = filtImg3M;
    end

    featNameC = fieldnames(outS);
    for nFeat = 1:length(featNameC)
        out3M = outS.(featNameC{nFeat});
        if strcmpi(dim,'2d')
            rotOut3M = rot90(out3M,-(index-1));
        elseif strcmpi(dim,'3d')
            rotOut3M = rotate3dSequence(out3M,index-1,-1);
        end
        outS.(featNameC{nFeat}) = rotOut3M;
    end
    rotTextureC{index} = outS;

end

%% Aggregate textures from all orientations
textureS = rotTextureC{1};
featNameC = fieldnames(textureS);
for nFeat = 1:length(featNameC)
    outC = cellfun(@(x) x.(featNameC{nFeat}),rotTextureC,'un',0);
    %Undo padding to aggregate response
    %if isfield(paramS.padding,'method') && ~isempty(paramS.padding.method)...
    %         && numRotations>1
    %    outC = cellfun(@(x) x(padSizeV(1)+1:scanSizeV(1)-padSizeV(1), ...
    %        padSizeV(2)+1:scanSizeV(2)-padSizeV(2),...
    %        padSizeV(3)+1:scanSizeV(3)-padSizeV(3)),outC,'un',0);
    %end
    out4M = cat(4,outC{:});
    switch(aggregationMethod)
        case 'avg'
            out3M = mean(out4M,4);
        case 'max'
            out3M = max(out4M,[],4);
        case 'std'
            out3M = std(out4M,0,4);
    end
    %Re-apply padding
    %if isfield(paramS.padding,'method') && ~isempty(paramS.padding.method)...
    %        && numRotations>1
    %    padOut3M = zeros(2*padSizeV(1)+origScanSizeV(1), ...
    %        2*padSizeV(2)+origScanSizeV(2),2*padSizeV(3)+origScanSizeV(3));
    %    padOut3M(padSizeV(1)+1:scanSizeV(1)-padSizeV(1),...
    %        padSizeV(2)+1:scanSizeV(2)-padSizeV(2),...
    %        padSizeV(3)+1:scanSizeV(3)-padSizeV(3)) = out3M;
    %else
        padOut3M = out3M;
    %end
    outS.(featNameC{nFeat}) = padOut3M;
end


% % make input/output dimensions same
% fieldNamC = fieldnames(outS);
% for i = 1:length(fieldNamC)
%     tempImg3M = NaN*ones(origSizV,'single');
%     tempImg3M(minr:maxr,minc:maxc,mins:maxs) = outS.(fieldNamC{i});
%     outS.(fieldNamC{i}) = tempImg3M;
% end

end