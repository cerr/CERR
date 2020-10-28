function outS = processImage(filterType,scan3M,mask3M,paramS,hWait)
% Process scan using selected filter and parameters
%-------------------------------------------------------------------------
% INPUTS
% filterType -  May be 'HaralickCooccurance','Wavelets','Sobel',
%               'LoG','Gabor','Mean','First order statistics',
%               'LawsConvolution','LawsEnergy','CoLlage' or 'SimpleITK'.
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

% Apply filter
switch filterType
    
    case 'HaralickCooccurance'
        SUVvals3M                           = mask3M.*double(scan3M);
        volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
        volToEval(mask3M==0)                = NaN;
        volToEval                           = volToEval / max(volToEval(:));
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
        
        if ishandle(hWait)
            [energy,entropy,sumAvg,corr,...
                invDiffMom,contrast,clustShade,...
                clustProminence,haralCorr] = textureByPatchCombineCooccur(volToEval,...
                paramS.NumLevels.val, paramS.PatchSize.val, offsetsM, flagV, hWait, ...
                paramS.minIntensity.val, paramS.maxIntensity.val, paramS.binWidth.val);
        else
            [energy,entropy,sumAvg,corr,...
                invDiffMom,contrast,clustShade,...
                clustProminence,haralCorr] = textureByPatchCombineCooccur(volToEval,...
                paramS.NumLevels.val, paramS.PatchSize.val, offsetsM, flagV, NaN, ...
                paramS.minIntensity.val, paramS.maxIntensity.val, paramS.binWidth.val);
        end
        
        outS.Energy = energy;
        outS.Entropy = entropy;
        outS.SumAvg = sumAvg;
        outS.Corr = corr;
        outS.InvDiffMom = invDiffMom;
        outS.Contrast = contrast;
        outS.ClustShade = clustShade;
        outS.ClustProminence = clustProminence;
        outS.HaralCorr = haralCorr;
        
        featC = fieldnames(outS);
        outS = rmfield(outS,featC(~flagV));
        
    case 'Wavelets'
        
        vol3M   = double(scan3M);
        
        dirListC = {'All','HHH','LHH','HLH','HHL','LLH','LHL','HLL','LLL'};
        normFlagC = {'Yes','No'};
        wavType =  paramS.Wavelets.val;
        if ~isempty(paramS.Index.val)
            wavType = [wavType,paramS.Index.val];
        end
        dir = paramS.Direction.val;
        selIdx = find(strcmpi(paramS.Normalize.val,normFlagC));
        normFlag = 2 - selIdx;
        
        if strcmp(dir,'All')
            for n = 2:length(dirListC)
                outname = [wavType,'_',dirListC{n}];
                outname = strrep(outname,'.','_');
                out3M = wavDecom3D(vol3M,dirListC{n},wavType,normFlag);
                
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
            out3M = wavDecom3D(vol3M,dir,wavType,normFlag);
            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end
            outS.(outname) = out3M;
        end
        
        
    case 'Sobel'
        
        vol3M = double(scan3M);
        [mag3M,dir3M] = sobelFilt(vol3M);
        
        %Remove padding
        outS.SobelMag = mag3M;
        outS.SobelDir = dir3M;
        
        if ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        
        
    case 'LoG'
      
        vol3M = double(scan3M);
        
        LoG3M = recursiveLOG(vol3M,...
            paramS.Sigma_mm.val,paramS.VoxelSize_mm.val);
       
        outS.LoG_recursive = LoG3M;
        
        if ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        
    case 'Gabor'
        
        vol3M = double(scan3M);
        gabor3M = filtImgGabor(vol3M,paramS.Radius.val,paramS.Sigma.val,...
            paramS.AspectRatio.val,paramS.Orientation.val,paramS.Wavlength.val);
        
        outS.Gabor = gabor3M;
        
        if ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        
    case 'Mean'
        
        vol3M = double(scan3M);
        kernelSize = paramS.KernelSize.val;
        if ~isnumeric(kernelSize)
            kernelSize = str2double(kernelSize);
        end
        kernelSize = reshape(kernelSize,1,[]);
        
        filt3M = ones(kernelSize);
        filt3M = filt3M./sum(filt3M(:));
        meanFilt3M = convn(vol3M,filt3M,'same');
        outS.meanFilt = meanFilt3M;
        
        if ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        
    case 'FirstOrderStatistics'
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        
        patchSizeV = paramS.PatchSize.val;
        
        %Get voxel size
        voxelSizV = paramS.VoxelSize_mm.val;
        voxelVol = prod(voxelSizV);
        
        %Compute patch-based statistics
        statC = {'min','max','mean','range','std','var','median','skewness',...
            'kurtosis','entropy','rms','energy','totalEnergy','meanAbsDev',...
            'medianAbsDev','P10','P90','robustMeanAbsDev','robustMedianAbsDev',...
            'interQuartileRange','coeffDispersion','coeffVariation'};
        
        [~,patchStatM] = firstOrderStatsByPatch(scan3M,mask3M,patchSizeV,voxelVol);
        
        for n = 1:length(statC)
            out3M = zeros(size(scan3M));
            outV = patchStatM(:,n);
            out3M(mask3M) = outV;
            outS.(statC{n}) = out3M;
            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 n/length(statC) n/length(statC)]' [0 1 1 0]']);
                drawnow;
            end
        end
        
        
    case 'LawsConvolution'

        vol3M = double(scan3M);
        
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
        lawsOutS = processImage('LawsConvolution',scan3M,mask3M,paramS,[]);
        
        fieldNameC = fieldnames(lawsOutS);
        numFeatures = length(fieldNameC);
        padMethod = paramS.PadMethod.val;
        padSizV = paramS.PadSize.val;
        
        %Loop over response maps
        for i = 1:length(fieldNameC)
           
            %Pad response map 
            lawsTex3M = lawsOutS.(fieldNameC{i});
            if ~isequal(size(lawsTex3M),size(scan3M))
                responseSizV = size(lawsTex3M);
                lawsTex3M = lawsTex3M(padSizV(1)+1:responseSizV(1)-padSizV(1),...
                    padSizV(2)+1:responseSizV(2)-padSizV(2),...
                    padSizV(3)+1:responseSizV(3)-padSizV(3));
                lawsTex3M = padScan(lawsTex3M,mask3M,padMethod,padSizV);
            end
            
            %Apply mean filter
            meanOutS = processImage('Mean',lawsTex3M,mask3M,paramS,[]);
            lawsEnergy3M = meanOutS.meanFilt;
            
            outField = [fieldNameC{i},'_Energy'];
            outS.(outField) = lawsEnergy3M;
            if ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 i/numFeatures i/numFeatures]' [0 1 1 0]']);
                drawnow;
            end
        end
        
        
    case 'CoLlage'
     
        vol3M = single(scan3M);
        dir = paramS.Dimension.val;
        coLlAGe3M = getCollageFeature(vol3M, mask3M, paramS.Dominant_Dir_Radius.val,...
            paramS.Cooccur_Radius.val, paramS.Number_Gray_Levels.val, dir, hWait);
        
        outS.entropy = coLlAGe3M;
        if ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        
    case 'suv'
        scanName = ['suv3M_',paramS.suvType.val];
        headerS = paramS.scanInfoS;
        outS.(scanName) = getSUV(scan3M, headerS, paramS.suvType.val);
        
    case 'SimpleITK'
        
        vol3M   = double(scan3M);
        % Path to SimpleITK
        optS = opts4Exe([getCERRPath,'CERROptions.json']);
        sitkLibPath = optS.sitkLibPath;
        % Call the SimpleITK wrapper
        sitkFilterName = paramS.sitkFilterName.val;
        % to do - update the signature to include mask3M?
        sitkOutS = sitkWrapper(sitkLibPath, vol3M, sitkFilterName, paramS);
        filterNamC = fieldnames(sitkOutS);
        outS.(sitkFilterName) = sitkOutS.(filterNamC{1});
        
    otherwise
        %Call custom function 'filterType'
        filtImg3M = feval(filterType,scan3M,mask3M,paramS);
        outS.(filterType) = filtImg3M;
        
end

% % make input/output dimensions same
% fieldNamC = fieldnames(outS);
% for i = 1:length(fieldNamC)
%     tempImg3M = NaN*ones(origSizV,'single');
%     tempImg3M(minr:maxr,minc:maxc,mins:maxs) = outS.(fieldNamC{i});
%     outS.(fieldNamC{i}) = tempImg3M;
% end

end