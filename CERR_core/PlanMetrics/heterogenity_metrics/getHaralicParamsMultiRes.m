function [energy,contrast,Entropy,Homogeneity,standard_dev,Ph,Slope] = getHaralicParamsMultiRes(structNum,radiusV,multiResMethod,planC)
%function [energy,contrast,Entropy,Homogeneity,standard_dev,Ph,Slope] = getHaralicParamsMultiRes(structNum,radiusV,multiResMethod,planC)
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
            volToEval(maskBoundingBox3M==0)     = NaN;
            maskScaled3D                        = volToEval(maskBoundingBox3M);
            %volToEval                           = volToEval - min(volToEval(:));
            volToEval                           = volToEval / max(volToEval(:));            
            %volToEval                           = sqrt(volToEval); % used for PET scans
            [f,Ph]                              = haralick3D(volToEval,16);
            standard_dev(radiusIndex)           = std(single(maskScaled3D));
            energy(radiusIndex)                 = f(1);
            contrast(radiusIndex)              = f(2);
            Entropy(radiusIndex)                = f(4);
            Homogeneity(radiusIndex)            = f(8);
            
        case 'TEXTURE AVERAGING'
            [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
            maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
            suvBoundingBox3M                    = suvWithoutMask3M(minr:maxr,minc:maxc,mins:maxs);
            ind2M = reshape(1:numel(suvBoundingBox3M(:,:,1)),size(suvBoundingBox3M(:,:,1)));
            numSlices = size(suvBoundingBox3M,3);
            for slc = 1:numSlices
                sliceIndV = unique([max(1,slc-slcOut):slc-1, slc, slc+1:min(numSlices,slc+slcOut)]);
                fun = @(indM) haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M);
                textureImg3S(:,:,slc) = nlfilter(ind2M,[rowOut*2+1 colOut*2+1],fun);
            end
            % Extract individual textures from the structure array.
            energy(radiusIndex) = mean([textureImg3S(~isnan([textureImg3S.energy])).energy]);
            contrast(radiusIndex) = mean([textureImg3S(~isnan([textureImg3S.contrast])).contrast]);
            Entropy(radiusIndex) = mean([textureImg3S(~isnan([textureImg3S.entropy])).entropy]);
            Homogeneity(radiusIndex) = mean([textureImg3S(~isnan([textureImg3S.homogenity])).homogenity]);
            standard_dev(radiusIndex) = mean([textureImg3S(~isnan([textureImg3S.stdDev])).stdDev]);
             
            % Ph and Slope are not computed for local texture averaging.
            Ph = [];
            Slope = [];            
            
    end
    
end

Slope = [];
if strcmpi(multiResMethod,'IMAGE SMOOTHING') && 0
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
