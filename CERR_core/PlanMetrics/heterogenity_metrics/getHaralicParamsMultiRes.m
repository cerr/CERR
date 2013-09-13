function [energy,contrast,Entropy,Homogeneity,standard_dev,Ph,Slope] = getHaralicParamsMultiRes(structNum,radiusV,multiResMethod,planC)
%function getHaralicParamsMultiRes(structNum)
%
%This function returns multi-scale haralic parameters for structure structNum.
%
%APA,09/04/2013

if ~exist('planC')
    global planC
end
indexS = planC{end};

scanNum                             = getStructureAssociatedScan(structNum,planC);
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
if isempty(uniqueSlices)
    energy = [];
    contrast = [];
    Entropy = [];
    Homogeneity = [];
    standard_dev = [];
    Ph = [];
    Slope = [];
    return;
end
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
suvWithoutMask3M                    = double(scanArray3M(:,:,uniqueSlices));

[xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
deltaX = abs(xV(2)-xV(1));
deltaY = abs(yV(2)-yV(1));
deltaZ = abs(zV(2)-zV(1));
%radiusV = [0.5 1 1.5 2 2.5 3];
for radiusIndex = 1:length(radiusV)
    
    outerRadius = radiusV(radiusIndex);
    rowOut = floor(outerRadius/deltaY);
    colOut = floor(outerRadius/deltaX);
    slcOut = floor(outerRadius/deltaZ);
    
    switch upper(multiResMethod)
        
        case 'IMAGE SMOOTHING'
            if rowOut && colOut && slcOut
                filterM = createEllipsoidNHOOD(1:rowOut,1:colOut,1:slcOut,0);
                filterM = filterM/length(find(filterM));
                suvWithoutMaskConv3M                = convn(suvWithoutMask3M,filterM,'same');
            else
                filterM = [];
                suvWithoutMaskConv3M                = suvWithoutMask3M;
            end
            SUVvals3M                           = mask3M.*suvWithoutMaskConv3M;
            [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
            maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
            volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
%             figure, imagesc(volToEval(:,:,4))
%             title(['Radius = ', num2str(outerRadius)],'fontSize',16)
%             if ~isempty(filterM)
%                 figure, imagesc(filterM(:,:,ceil(size(filterM,3)/2)))
%                 title(['Radius = ', num2str(outerRadius)],'fontSize',16)
%             end
            volToEval(maskBoundingBox3M==0)     = NaN;
            maskScaled3D                        = volToEval(maskBoundingBox3M);
            %volToEval                           = volToEval - min(volToEval(:));
            volToEval                           = volToEval / max(volToEval(:));
            %volToEval                           = sqrt(volToEval);
            [f,Ph]                              = haralick3D(volToEval,16);
            %suv3M                               = scanArray3M(:,:,uniqueSlices);
            %maskScaled3D = suv3M(find(mask3M));
            % maskScaled3D = maskScaled3D/
            standard_dev(radiusIndex)           = std(single(maskScaled3D));
            %standard_dev                        = std(suv3M(find(mask3M)));
            energy(radiusIndex)                 = f(1);
            contrast(radiusIndex)              = f(2);
            Entropy(radiusIndex)                = f(4);
            Homogeneity(radiusIndex)            = f(8);
            
        case 'TEXTURE AVERAGING'
            SUVvals3M                           = mask3M.*suvWithoutMask3M;
            [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
            maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
            suvBoundingBox3M                    = suvWithoutMask3M(minr:maxr,minc:maxc,mins:maxs);
            %ind3M = reshape(1:numel(suvBoundingBox3M),size(suvBoundingBox3M));
            ind2M = reshape(1:numel(suvBoundingBox3M(:,:,1)),size(suvBoundingBox3M(:,:,1)));
            siz = size(ind2M);
            numSlices = size(suvBoundingBox3M,3);
            for slc = 1:numSlices
                sliceIndV = unique([max(1,slc-slcOut):slc-1, slc, slc+1:min(numSlices,slc+slcOut)]);
                fun = @(indM) haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M);
                textureImg3M(:,:,slc) = nlfilter(ind2M,[rowOut*2+1 colOut*2+1],fun);
%                 fun = @(indM) haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M,'Contrast');
%                 contrastImg3M(:,:,slc) = nlfilter(ind2M,[rowOut*2+1 colOut*2+1],fun);
%                 fun = @(indM) haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M,'Entropy');
%                 entropyImg3M(:,:,slc) = nlfilter(ind2M,[rowOut*2+1 colOut*2+1],fun);
%                 fun = @(indM) haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M,'Homogenity');
%                 homogenityImg3M(:,:,slc) = nlfilter(ind2M,[rowOut*2+1 colOut*2+1],fun);
%                 fun = @(indM) haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M,'Std');
%                 stdImg3M(:,:,slc) = nlfilter(ind2M,[rowOut*2+1 colOut*2+1],fun);
            end
            %             figure, imagesc(energyImg3M(:,:,4))
            %             title(['Energy with sliding window = ', num2str(outerRadius),' cm'],'fontSize',16)
            %             figure, imagesc(contrastImg3M(:,:,4))
            %             title(['Contrast with sliding window = ', num2str(outerRadius),' cm'],'fontSize',16)
            %             figure, imagesc(entropyImg3M(:,:,4))
            %             title(['Entropy with sliding window = ', num2str(outerRadius),' cm'],'fontSize',16)
            %             figure, imagesc(homogenityImg3M(:,:,4))
            %             title(['Homogenity with sliding window = ', num2str(outerRadius),' cm'],'fontSize',16)
            %             figure, imagesc(stdImg3M(:,:,4))
            %             title(['Std. Dev. with sliding window = ', num2str(outerRadius),' cm'],'fontSize',16)
            
            energy(radiusIndex) = mean([textureImg3M(~isnan([textureImg3M.energy])).energy]);
            contrast(radiusIndex) = mean([textureImg3M(~isnan([textureImg3M.contrast])).contrast]);
            Entropy(radiusIndex) = mean([textureImg3M(~isnan([textureImg3M.entropy])).entropy]);
            Homogeneity(radiusIndex) = mean([textureImg3M(~isnan([textureImg3M.homogenity])).homogenity]);
            standard_dev(radiusIndex) = mean([textureImg3M(~isnan([textureImg3M.stdDev])).stdDev]);
             
%             energy(radiusIndex) = mean(energyImg3M(~isnan(energyImg3M(:))));
%             constrast(radiusIndex) = mean(contrastImg3M(~isnan(contrastImg3M(:))));
%             Entropy(radiusIndex) = mean(entropyImg3M(~isnan(entropyImg3M(:))));
%             Homogeneity(radiusIndex) = mean(homogenityImg3M(~isnan(homogenityImg3M(:))));
%             standard_dev(radiusIndex) = mean(stdImg3M(~isnan(stdImg3M(:))));
            
            Ph = [];
            Slope = [];            
            
    end
    
end

if strcmpi(multiResMethod,'IMAGE SMOOTHING')
    %Calculate slope
    init_th  = 10;
    final_th = 80;
    n_th     = 10;
    Thresholds = linspace (init_th, final_th, n_th);
    Slope = calc_slope_grigsby(structNum,Thresholds,planC);
end

disp(['Energy     : ',num2str(energy)])
disp(['Contrast   : ',num2str(contrast)])
disp(['Entropy    : ',num2str(Entropy)])
disp(['Homogenity : ',num2str(Homogeneity)])
disp(['Std. Dev.  : ',num2str(standard_dev)])
disp(['Slope      : ',num2str(Slope)])
