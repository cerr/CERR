function outS = processImage(filterType,scan3M,mask3M,paramS)
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


switch filterType
    
    case 'Haralick Cooccurance'
        [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
        maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        SUVvals3M                           = mask3M.*double(scan3M);
        volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
        volToEval(maskBoundingBox3M==0)     = NaN;
        volToEval                           = volToEval / max(volToEval(:));
        offsetsM = getOffsets(paramS.Directionality.val);
        
        if strcmpi(paramS.PatchType.val,'cm')
            patchUnit = 'cm';
            [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
            deltaX = abs(xVals(1)-xVals(2));
            deltaY = abs(yVals(1)-yVals(2));
            deltaZ = abs(zVals(1)-zVals(2));
            patchSizeV = paramS.PatchSize;
            slcWindow = floor(patchSizeV(3)/deltaZ);
            rowWindow = floor(patchSizeV(1)/deltaY);
            colWindow = floor(patchSizeV(2)/deltaX);
            patchSizeV = [rowWindow, colWindow, slcWindow];
            paramS.PatchSize = patchSizeV;
        end
        
        sel = paramS.Type.val;
        if sel == 1
            flagV = ones(1,9); % All 9 haralick features;
        else
            flagV = zeros(1,9);
            flagV(sel-1) = 1;
        end
        
        [energy,entropy,sumAvg,corr,...
          invDiffMom,contrast,clustShade,...
          clustProminence,haralCorr] = textureByPatchCombineCooccur(volToEval,...
            paramS.NumLevels.val, paramS.PatchSize.val, offsetsM, flagV); %,hWait
        
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
        
        [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        %Pad image if no. slices is odd
        scan3M = flip(scan3M,3);
        if mod(size(scan3M,3),2) > 0
            scan3M(:,:,end+1) = 0*scan3M(:,:,1);
            mask3M(:,:,end+1) = 0*mask3M(:,:,1);
        end
        vol3M   = double(mask3M).*double(scan3M);
        
        dirListC = {'All','HHH','LHH','HLH','HHL','LLH','LHL','HLL','LLL'};
        wavFamilyC = {'db','haar','coif', 'fk','sym','dmey','bior','rbio'};
        typeC =  {{'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16',...
            '17','18','19','20','21','22','23','24','25','26','27','28','29','30',...
            '31','32','33','34','35','36','37','38','39','40','41','42','43','44','45'},{},...
        {'1','2','3','4','5'},{'4','6','8','14','18','22'},{'2','3','4','5',...
        '6','7','8','9','10','11','12','13','14','15','16',...
        '17','18','19','20','21','22','23','24','25','26','27','28','29','30',...
        '31','32','33','34','35','36','37','38','39','40','41','42','43','44','45'},...
        {},{'1.1','1.3','1.5','2.2','2.4','2.6','2.8','3.1','3.3','3.5',...
        '3.7','3.9','4.4','5.5','6.8'},{'1.1','1.3','1.5','2.2','2.4','2.6',...
        '2.8','3.1','3.3','3.5','3.7','3.9','4.4','5.5','6.8'}};
    wavType =  [wavFamilyC{paramS.Wavelets.val},typeC{paramS.Wavelets.val}{paramS.Index.val}];
    dir = dirListC{paramS.Direction.val};

    
    if strcmp(dir,'All')
        for n = 2:length(dirListC)
            outname = [wavType,'_',dirListC{n}];
            
            out3M = wavDecom3D(vol3M,dirListC{n},wavType);
            if mod(size(out3M,3),2) > 0
                out3M = out3M(:,:,1:end-1);
            end
            out3M = flip(out3M,3);
            
            outS.(outname) = out3M;
        end
    else
        outname = [wavType,'_',dir];
        out3M = wavDecom3D(vol3M,dir,wavType);
        if mod(size(out3M,3),2) > 0
            out3M = out3M(:,:,1:end-1);
        end
        out3M = flip(out3M,3);
        outS.(outname) = out3M;
        
    end
    
    case 'Sobel'
        [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        vol3M   = double(mask3M).*double(scan3M);
        [outS.SobelMag,outS.SobelDir] = sobelFilt(vol3M);
        
%     case 'LoG'
%         tic
%         vol3M   = double(mask3M).*double(scan3M);
%         outS.LoG = LoGFilt(vol3M,paramS.KernelSize.val,paramS.Sigma.val);
%         toc
        
    case 'LoG'
        [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        vol3M   = double(mask3M).*double(scan3M);
        outS.LoG_recursive = recursiveLOG(vol3M,paramS.Sigma_mm.val,paramS.VoxelSize_mm.val);
        
    case 'Gabor'
        [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
        mask3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
        scan3M                   = scan3M(minr:maxr,minc:maxc,mins:maxs);
        vol3M   = double(mask3M).*double(scan3M);
        outS.Gabor = filtImgGabor(vol3M,paramS.Radius.val,paramS.Sigma.val,...
            paramS.AspectRatio.val,paramS.Orientation.val,paramS.Wavlength.val);
        
    case 'First order statistics'
        
        % Get bounds of ROI
        [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
        bboxDimV = [minr, maxr, minc, maxc, mins, maxs];
        bbox3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        
        vol3M = double(scan3M);
        patchSizeV = paramS.PatchSize.val;
        
        %Get voxel size
        voxelVol = paramS.VoxelVolume.val;
        
        
        % Compute patch-based statistics
        statC = {'min','max','mean','range','std','var','median','skewness',...
            'kurtosis','entropy','rms','energy','totalEnergy','meanAbsDev',...
            'medianAbsDev','P10','P90','robustMeanAbsDev','robustMedianAbsDev',...
            'interQuartileRange','coeffDispersion','coeffVariation'};
        
        [~,patchStatM] = firstOrderStatsByPatch(vol3M,bboxDimV,patchSizeV,voxelVol);
        
        mask3M = zeros(size(mask3M));
        for n = 1:length(statC)
        outV = patchStatM(:,n);
        outBox3M = reshape(outV,maxr-minr+1,maxc-minc+1,maxs-mins+1);
        outBox3M(~bbox3M) = 0;
        out3M(minr:maxr,minc:maxc,mins:maxs) = outBox3M;
        outS.(statC{n}) = out3M;
        end
        
end


end