function outS = processImage(filterType,scan3M,mask3M,paramS,hWait)
% Process scan using selected filter and parameters
%-------------------------------------------------------------------------
% INPUTS
% filterType -  May be 'Haralick Cooccurance','Wavelets','Sobel',
%               'LoG','Gabor' or 'First order statistics'.
% scan3M     - 3-D scan array
% mask3M     - 3-D mask
% paramS     - Filter parameters
%-------------------------------------------------------------------------
%AI 03/16/18

filterType = strrep(filterType,' ','');

% record the original image size
origSiz = size(scan3M);
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);

switch filterType
    
    case 'HaralickCooccurance'
        maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        SUVvals3M                           = mask3M.*double(scan3M);
        volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
        volToEval(maskBoundingBox3M==0)     = NaN;
        volToEval                           = volToEval / max(volToEval(:));
        offsetsM = getOffsets(paramS.Directionality.val);
        typesC = {'All','Entropy','Energy','Sum Avg','Homogeneity','Contrast',...
                    'Correlation','Cluster Shade','Cluster Promincence', 'Haralick Correlation'};
        
        sel = paramS.Type.val;
        if strcmpi(sel,'all')
            flagV = ones(1,9); % All 9 haralick features;
        else
            idx = find(strcmp(typesC,sel));
            flagV = zeros(1,9);
            flagV(idx-1) = 1;
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
        
        if exist('hWait','var') && ishandle(hWait)
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
        
        % Use a margin of +/- 7 row/col/slcs
        minr = max(1,minr-7);
        maxr = min(origSiz(1),maxr+7);
        minc = max(1,minc-7);
        maxc = min(origSiz(2),maxc+7);
        mins = max(1,mins-7);
        maxs = min(origSiz(3),maxs+7);
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        %Pad image if no. slices is odd
        padFlag = 0;
        scan3M = flip(scan3M,3);
        if mod(size(scan3M,3),2) > 0
            scan3M(:,:,end+1) = min(scan3M(:))*scan3M(:,:,1).^0;
            mask3M(:,:,end+1) = 0*mask3M(:,:,1);
            padFlag = 1;
        end
        % vol3M   = double(mask3M).*double(scan3M);
        vol3M   = double(scan3M);
        
        dirListC = {'All','HHH','LHH','HLH','HHL','LLH','LHL','HLL','LLL'};       
%         wavFamilyC = {'Daubechies','Haar','Coiflets','FejerKorovkin','Symlets',...
%                     'Discrete Meyer wavelet','Biorthogonal','Reverse Biorthogonal'}
%         typeC =  {{'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16',...
%             '17','18','19','20','21','22','23','24','25','26','27','28','29','30',...
%             '31','32','33','34','35','36','37','38','39','40','41','42','43','44','45'},{},...
%             {'1','2','3','4','5'},{'4','6','8','14','18','22'},{'2','3','4','5',...
%             '6','7','8','9','10','11','12','13','14','15','16',...
%             '17','18','19','20','21','22','23','24','25','26','27','28','29','30',...
%             '31','32','33','34','35','36','37','38','39','40','41','42','43','44','45'},...
%             {},{'1.1','1.3','1.5','2.2','2.4','2.6','2.8','3.1','3.3','3.5',...
%             '3.7','3.9','4.4','5.5','6.8'},{'1.1','1.3','1.5','2.2','2.4','2.6',...
%             '2.8','3.1','3.3','3.5','3.7','3.9','4.4','5.5','6.8'}};
%         wavType =  [wavFamilyC{paramS.Wavelets.val},typeC{paramS.Wavelets.val}{paramS.Index.val}];
        wavType =  [paramS.Wavelets.val,num2str(paramS.Index.val)];
        dir = paramS.Direction.val;
        
        
        if strcmp(dir,'All')
            for n = 2:length(dirListC)
                outname = [wavType,'_',dirListC{n}];
                outname = strrep(outname,'.','_');
                out3M = wavDecom3D(vol3M,dirListC{n},wavType);
                if padFlag
                    out3M = out3M(:,:,1:end-1);
                end
                out3M = flip(out3M,3);
                
                outS.(outname) = out3M;
                
                if exist('hWait','var') && ishandle(hWait)
                    set(hWait, 'Vertices', [[0 0 (n-1)/(length(dirListC)-1) (n-1)/(length(dirListC)-1)]' [0 1 1 0]']);
                    drawnow;
                end
                
            end
        else
            outname = [wavType,'_',dir];
            outname = strrep(outname,'.','_');
            outname = strrep(outname,' ','_');
            out3M = wavDecom3D(vol3M,dir,wavType);
            if padFlag
                out3M = out3M(:,:,1:end-1);
            end
            out3M = flip(out3M,3);
            if exist('hWait','var') && ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
                drawnow;
            end
            outS.(outname) = out3M;
            
        end
        
        
    case 'Sobel'
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        vol3M   = double(mask3M).*double(scan3M);
        [outS.SobelMag,outS.SobelDir] = sobelFilt(vol3M);
        if exist('hWait','var') && ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        %     case 'LoG'
        %         tic
        %         vol3M   = double(mask3M).*double(scan3M);
        %         outS.LoG = LoGFilt(vol3M,paramS.KernelSize.val,paramS.Sigma.val);
        %         toc
        
    case 'LoG'
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        vol3M   = double(mask3M).*double(scan3M);
        outS.LoG_recursive = recursiveLOG(vol3M,paramS.Sigma_mm.val,paramS.VoxelSize_mm.val);
        if exist('hWait','var') && ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        
    case 'Gabor'
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        vol3M   = double(mask3M).*double(scan3M);
        outS.Gabor = filtImgGabor(vol3M,paramS.Radius.val,paramS.Sigma.val,...
            paramS.AspectRatio.val,paramS.Orientation.val,paramS.Wavlength.val);
        if exist('hWait','var') && ishandle(hWait)
            set(hWait, 'Vertices', [[0 0 1 1]' [0 1 1 0]']);
            drawnow;
        end
        
    case 'FirstOrderStatistics'
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        
        patchSizeV = paramS.PatchSize.val;
        
        %Get voxel size
        voxelVol = paramS.VoxelVolume.val;
        
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
            if exist('hWait','var') && ishandle(hWait)
                set(hWait, 'Vertices', [[0 0 n/length(statC) n/length(statC)]' [0 1 1 0]']);
                drawnow;
            end
        end
        
        
    case 'LawsConvolution'
        
                mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
                scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
                vol3M = double(mask3M).*double(scan3M);
                vol3M(mask3M==0) = NaN;
        
                %Pad with mean intensities
                meanVol = nanmean(vol3M(:));
                paddedVolM = padarray(vol3M,[5 5 5],meanVol,'both');
                dirC = {'2d','3d','all'};
                sizC = {'3','5','all'};
                dir = dirC{paramS.Direction.val};
                siz = sizC{paramS.KernelSize.val};
                lawsMasksS = getLawsMasks(dir,siz);
        
                %Compute features
                fieldNamesC = fieldnames(lawsMasksS);
                numFeatures = length(fieldNamesC);
                for i = 1:numFeatures
                    text3M = convn(paddedVolM,lawsMasksS.(fieldNamesC{i}),'same');
                    text3M = text3M(6:end-5,6:end-5,6:end-5);
                    outS.(fieldNamesC{i}) = text3M; % for the entire cubic roi
                    if exist('hWait','var') && ishandle(hWait)
                        set(hWait, 'Vertices', [[0 0 i/numFeatures i/numFeatures]' [0 1 1 0]']);
                        drawnow;
                    end
                end
        
    case 'CoLlage'
        
        mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M = single(scan3M);
        dir = paramS.Dimension.val;
        coLlAGe3M = getCollageFeature(scan3M, mask3M, paramS.Dominant_Dir_Radius.val,...
            paramS.Cooccur_Radius.val, paramS.Number_Gray_Levels.val, dir, hWait);
        outS.entropy = coLlAGe3M;
        
end

% make input/output dimensions same
fieldNamC = fieldnames(outS);
for i = 1:length(fieldNamC)
    tempImg3M = NaN*ones(origSiz,'single');
    tempImg3M(minr:maxr,minc:maxc,mins:maxs) = outS.(fieldNamC{i});
    outS.(fieldNamC{i}) = tempImg3M;
end

end