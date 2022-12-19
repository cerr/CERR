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
%AI 11/16/22  Support for rotation-invariant filtering

if ~exist('hWait','var')
    hWait = [];
end

filterType = strrep(filterType,' ','');

% Compute ROI bounding box
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);

%Parameters for rotation invariance
aggregationMethod = 'none';
dim = '2d';
numRotations = 1;
if isfield(paramS,'RotationInvariance') && ...
        ~isempty(paramS.RotationInvariance) ...
        && ~strcmpi(filterType,'LawsEnergy') 
    rotS = paramS.RotationInvariance.val;
    aggregationMethod = rotS.AggregationMethod;
    dim = rotS.Dim;
    if strcmpi(dim,'2d')
        numRotations = 4;
    else
        numRotations = 24;
    end
end

%Handle S-I orientation flip for Wavelet filters
if strcmpi(filterType,'wavelets')
    scan3M   = flip(double(scan3M),3); %FOR IBSI2 compatibility
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

            %vol3M   = flip(double(rotScan3M),3); %FOR IBSI2
            vol3M = double(rotScan3M);
            wavType =  paramS.Wavelets.val;
            if ~isempty(paramS.Index.val)
                wavType = [wavType,num2str(paramS.Index.val)];
            end
            level = 1; %default
            if isfield(paramS,'Level')
                level =  paramS.Level.val;
            end
            dir = paramS.Direction.val;

            if length(dir) == 3
                dim = '3d';
            elseif length(dir) == 2
                dim = '2d'; 
            end

            if strcmpi(dim,'3d')
                dirListC = {'All','HHH','LHH','HLH','HHL','LLH','LHL',...
                    'HLL','LLL'};
            elseif strcmpi(dim,'2d')
                dirListC = {'All','HH','HL','LH','LL'};
            end

            if strcmp(dir,'All')
                for n = 2:length(dirListC)
                    outname = [wavType,'_',dirListC{n}];
                    outname = strrep(outname,'.','_');
                    outname = strrep(outname,' ','_');

                    subbandsS = getWaveletSubbands(vol3M,wavType,level,dim);
                    matchDir = [dirListC{n},'_',wavType];
                    out3M = subbandsS.(matchDir);

                    if ishandle(hWait)
                        set(hWait, 'Vertices', ...
                            [[0 0 (n-1)/(length(dirListC)-1) ...
                            (n-1)/(length(dirListC)-1)]' [0 1 1 0]']);
                        drawnow;
                    end

                    outS.(outname) = out3M;
                end
            else
                outname = [wavType,'_',dir];
                outname = strrep(outname,'.','_');
                outname = strrep(outname,' ','_');

                subbandsS = getWaveletSubbands(vol3M,wavType,level,dim);
                matchDir = [dir,'_',wavType];
                out3M = subbandsS.(matchDir);

                if ishandle(hWait)
                    set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                    drawnow;
                end

                %outS.(outname) = flip(out3M,3); %FOR IBSI2
                outS.(outname) = out3M;
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

            %Read filter parameters
            vol3M = double(rotScan3M);
            voxelSizV = paramS.VoxelSize_mm.val;
            sigma = paramS.Sigma_mm.val/voxelSizV(1);
            wavelength = paramS.Wavlength_mm.val./voxelSizV(1);
            theta = reshape(paramS.Orientation.val,1,[]);
            gamma = paramS.SpatialAspectRatio.val;
            planes = 'Axial'; %default
            if isfield(paramS,'ImagePlane')
                planes = paramS.ImagePlane.val;
            end
            if ~iscell(planes)
                planes = {planes};
            end

            %Set default filter size (IBSI-2 recommendation)
            padV = reshape(paramS.padding.size,1,[]);
            scanSizeV = size(rotScan3M) - 2*padV;
            rV = scanSizeV(1:2);
            evenIdxV = mod(rV,2) == 0;
            rV(evenIdxV) = rV(evenIdxV)+1;

            %Loop over image planes
            for nPlane = 1:length(planes)

                switch lower(planes{nPlane})
                    case 'axial'
                        % do nothing
                    case 'sagittal'
                        vol3M = permute(vol3M,[3,1,2]);
                    case 'coronal'
                        vol3M = permute(vol3M,[3,2,1]);
                end

                %Apply filter
                if isfield(paramS,'Radius_mm')
                    %Use specified filter size
                    radius = paramS.Radius_mm.val;
                    if length(radius) == 1
                        radius = [radius radius];
                    end
                    radius = radius/voxelSizV(1:2);
                    gabor3M = GaborFiltIBSI(vol3M,sigma,wavelength,...
                        gamma,theta,radius);
                    fieldname = ['Gabor_',lower(planes{nPlane})];
                    outS.(fieldname) = gabor3M;
                else
                    %Use default filter size
                    radius = floor(rV/2);     %IBSI recommendation
                    if length(theta)==1
                        gabor3M = GaborFiltIBSI(vol3M,sigma,wavelength,...
                            gamma,theta,radius);
                        fieldname = ['Gabor_',lower(planes{nPlane})];
                        outS.(fieldname) = gabor3M;
                    else
                        %Loop over multiple orientations
                        gaborOutC = cell(1,length(theta));
                        for nTheta = 1:length(theta)
                            gaborOutC{nTheta} = GaborFiltIBSI(vol3M,...
                                sigma,wavelength,gamma,theta(nTheta),radius);
                        end

                        %Aggregate results from different orientaitons
                        if isfield(paramS,'OrientationAggregation') && ...
                                ~isempty(paramS.OrientationAggregation)
                            gaborAll = cat(4, gaborOutC{:});
                            aggMethod = paramS.OrientationAggregation.val;
                            switch(aggMethod)
                                case 'average'
                                    gabor3M = mean(gaborAll,4);
                                case 'max'
                                    gabor3M = max(gaborAll,[],4);
                                case 'std'
                                    gabor3M = std(gaborAll,0,4);
                            end
                            angle_str = strrep(strjoin(""+theta,'_'),'.','p');
                            angle_str = char(strrep(angle_str,'-','M'));
                            if length(angle_str)>39
                                %temp
                                angle_str = angle_str(1:39);
                                %tbd: gen unique fieldname
                            end
                            fieldname = ['Gabor_',lower(planes{nPlane}),...
                                '_',angle_str,'_',aggMethod];
                            outS.(fieldname) = gabor3M;
                        else
                            fieldname = {};
                            for nTheta = 1:length(theta)
                                currFieldName = ['Gabor_',num2str(theta(nTheta))];
                                outS.(currFieldName) = gaborOutC{nTheta};
                                fieldname = [fieldname,currFieldName];
                            end
                        end
                    end
                end

                % Re-orient results for cross-plane aggregation
                if isfield(paramS,'PlaneAggregation') && ...
                        ~isempty(paramS.PlaneAggregation)
                    if ~iscell(fieldname)
                        fieldname = {fieldname};
                    end
                    for nFields = 1:length(fieldname)
                        out3M = outS.(fieldname{nFields});
                        switch lower(planes{nPlane})
                            case 'axial'
                                % do nothing
                            case 'sagittal'
                                out3M = permute(out3M,[2,3,1]);
                                vol3M = permute(vol3M,[2,3,1]);
                            case 'coronal'
                                out3M = permute(out3M,[3,2,1]);
                                vol3M = permute(vol3M,[3,2,1]);
                        end
                        outS.(fieldname{nFields}) = out3M;
                    end
                end

            end

            %Agggregate resutls across orthogonal planes
            if isfield(paramS,'PlaneAggregation') && ...
                    ~isempty(paramS.PlaneAggregation)

                aggMethod = paramS.PlaneAggregation.val;
                getMatchFields = @(S,varargin) cellfun(@(f)S.(f),...
                    varargin,'un',0);

                %Gather results from common settings
                fieldsC = fieldnames(outS);
                settingC = regexprep(fieldsC,{'axial','sagittal','coronal'},...
                    {'','',''});
                uqSettingC = unique(settingC);

                %Aggregate
                for nSettings = 1:length(uqSettingC)
                    matchIdxV = ismember(settingC, uqSettingC{nSettings});
                    matchFieldsC = fieldsC(matchIdxV);
                    matchValC = getMatchFields(outS,matchFieldsC{:});
                    gaborAll = cat(4, matchValC{:});
                    switch(aggMethod)
                        case 'average'
                            gabor3M = mean(gaborAll,4);
                        case 'max'
                            gabor3M = max(gaborAll,[],4);
                        case 'std'
                            gabor3M = std(gaborAll,0,4);
                    end
                    planes_str = strjoin(planes,'_');
                    fieldname = [uqSettingC{nSettings},'_',planes_str,...
                        '_', aggMethod];
                    outS = rmfield(outS,matchFieldsC);
                    outS.(fieldname) = gabor3M;
                end
            end

            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end


        case 'Mean'

            % Generate mean filter kernel
            vol3M = double(rotScan3M);
            kernelSize = paramS.KernelSize.val;
            if ~isnumeric(kernelSize)
                kernelSize = str2double(kernelSize);
            end
            kernelSize = reshape(kernelSize,1,[]);

            filt3M = ones(kernelSize);
            filt3M = filt3M./sum(filt3M(:));

            %Support absolute mean (e.g. for energy calc.)
            if isfield(paramS,'Absolute') && strcmpi(paramS.Absolute.val,'yes')
                vol3M = abs(vol3M);
            end

            if length(kernelSize)==3 && kernelSize(3)~=0 %3d
                meanFilt3M = convn(vol3M,filt3M,'same');
            elseif length(kernelSize)==2 || kernelSize(3)==0 %2d
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
            lawsOutS = processImage('LawsConvolution',rotScan3M,...
                rotMask3M,paramS,[]);

            fieldNameC = fieldnames(lawsOutS);
            numFeatures = length(fieldNameC);
            padMethod = paramS.EnergyPadMethod.val;
            padSizV = paramS.EnergyPadSize.val;
            %Set reqd mean filter param
            paramS.KernelSize.val = paramS.EnergyKernelSize.val;
            paramS.Absolute.val ='yes';

            %Loop over response maps
            for i = 1:length(fieldNameC)

                %Remove padding for Laws response map
                cropFlag = 1; %remove padding used for Law's filter
                if isfield(paramS,'padding')
                    origPadV = reshape(paramS.padding.size,1,[]);
                else
                    origPadV = [0,0,0];
                end
                lawsTex3M = lawsOutS.(fieldNameC{i});
                origSizeV = size(lawsTex3M);

                calcMask3M = true(size(lawsTex3M));
                calcMask3M([1:origPadV(1),...
                    origSizeV(1)-origPadV(1)+1:origSizeV(1)],:,:) = false;
                calcMask3M(:,[1:origPadV(2),...
                    origSizeV(2)-origPadV(2)+1:origSizeV(2)],:) = false;
                calcMask3M(:,:,[1:origPadV(3),...
                    origSizeV(3)-origPadV(3)+1:origSizeV(3)]) = false;

                %Pad for mean filter
                cropLawsTex3M = padScan(lawsTex3M,calcMask3M,padMethod,...
                    padSizV,cropFlag);

                %Apply mean filter
                if isfield(paramS,'RotationInvariance')
                    paramS = rmfield(paramS,'RotationInvariance');
                end
                meanOutS = processImage('Mean',cropLawsTex3M,...
                    rotMask3M,paramS,[]);
                lawsEnergy3M = meanOutS.meanFilt;
                padResponseSizeV = size(lawsEnergy3M);

                %Remove padding
                lawsEnergy3M = lawsEnergy3M(padSizV(1)+1:...
                    padResponseSizeV(1)-padSizV(1),...
                    padSizV(2)+1:padResponseSizeV(2)-padSizV(2),...
                    padSizV(3)+1:padResponseSizeV(3)-padSizV(3));

                %Reapply original padding
                lawsEnergyPad3M = nan(origSizeV);
                lawsEnergyPad3M(origPadV(1)+1:end-origPadV(1),...
                origPadV(2)+1:end-origPadV(2),origPadV(3)+1:...
                end-origPadV(3)) = lawsEnergy3M;

                %cropSizeV = size(lawsEnergy3M);
                lawsEnergyPad3M([1:origPadV(1),end-origPadV(1)+1:end],:,:) = ...
                lawsTex3M([1:origPadV(1),end-origPadV(1)+1:end],:,:);
                lawsEnergyPad3M(:,[1:origPadV(2),end-origPadV(2)+1:end],:) = ...
                lawsTex3M(:,[1:origPadV(2),end-origPadV(2)+1:end],:);
                lawsEnergyPad3M(:,:,[1:origPadV(3),end-origPadV(3)+1:end]) = ...
                lawsTex3M(:,:,[1:origPadV(3),end-origPadV(3)+1:end]);

                outField = [fieldNameC{i},'_Energy'];
                outS.(outField) = lawsEnergyPad3M;
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
        if strcmpi(filterType,'Wavelets')
            rotOut3M = flip(rotOut3M,3);
        end
        outS.(featNameC{nFeat}) = rotOut3M;
    end
    rotTextureC{index} = outS;
end

%% Aggregate textures from all orientations
if isfield(paramS,'RotationInvariance') && ~isempty(paramS.RotationInvariance)
    textureS = rotTextureC{1};
    featNameC = fieldnames(textureS);
    for nFeat = 1:length(featNameC)
        outC = cellfun(@(x) x.(featNameC{nFeat}),rotTextureC,'un',0);
        out4M = cat(4,outC{:});
        switch(aggregationMethod)
            case 'avg'
                out3M = mean(out4M,4);
            case 'max'
                out3M = max(out4M,[],4);
            case 'std'
                out3M = std(out4M,0,4);
        end
        outS.(featNameC{nFeat}) = out3M;
    end
end


% % make input/output dimensions same
% fieldNamC = fieldnames(outS);
% for i = 1:length(fieldNamC)
%     tempImg3M = NaN*ones(origSizV,'single');
%     tempImg3M(minr:maxr,minc:maxc,mins:maxs) = outS.(fieldNamC{i});
%     outS.(fieldNamC{i}) = tempImg3M;
% end

end