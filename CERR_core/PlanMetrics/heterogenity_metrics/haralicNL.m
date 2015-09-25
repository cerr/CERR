function fS = haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M)
% function fS = haralicNL(indM,sliceIndV,suvBoundingBox3M,maskBoundingBox3M)
%
% APA, 09/04/2013

suvWithinmaskV = [];
for i = 1:length(sliceIndV)    
    
    sliceNum = sliceIndV(i);
%     suvBoundingBox2M = suvBoundingBox3M(:,:,sliceNum);
    maskBoundingBox2M = maskBoundingBox3M(:,:,sliceNum);
    indV = indM(indM>0) + (sliceNum-1)*numel(maskBoundingBox2M);
    isROI = maskBoundingBox3M(indV);
    isROI = isROI(~isnan(isROI));
    indV = indV(isROI);
    suvWithinmaskV = [suvWithinmaskV; suvBoundingBox3M(indV).*maskBoundingBox3M(indV)];
    suvWithinmaskV = suvWithinmaskV(~isnan(suvWithinmaskV));
end

if length(unique(suvWithinmaskV)) > 1
    suvWithinmaskV = suvWithinmaskV / max(suvWithinmaskV);
    %suvWithinmaskV = sqrt(suvWithinmaskV);
    [f,Ph] = haralick3D(suvWithinmaskV,16);
    fS.energy = f(1);
    fS.contrast = f(2);
    fS.entropy = f(4);
    fS.homogenity = f(8);
    fS.stdDev = std(suvWithinmaskV);
%     switch upper(textureFeature)
%         case 'ENERGY' 
%             f = f(1);
%         case 'CONTRAST'
%             f = f(2);
%         case 'ENTROPY'
%             f = f(4);
%         case 'HOMOGENITY'
%             f = f(8);
%         case 'STD'
%             f = std(suvWithinmaskV);
%     end
else
    fS.energy = NaN;
    fS.contrast = NaN;
    fS.entropy = NaN;
    fS.homogenity = NaN;
    fS.stdDev = NaN;

%     f = NaN;
end
