function [Eccentricity,EulerNumber,Solidity,Extent] = getShapeParams(structNum,planC,filterFlag)
%function getHaralicParams(structNum)
%
%This function returns shape features.
%
%IEN,2/28/2006

if ~exist('planC')
    global planC
end
indexS = planC{end};

if ~exist('filterFlag','var')
    filterFlag = 0;
end
scanNum                             = getStructureAssociatedScan(structNum,planC);
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
if filterFlag
    NHOOD_outer = createEllipsoidNHOOD(1:3,1:3,1:3);
    mask3M = imclose(mask3M,NHOOD_outer);
    [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
    strElem = strel('square',3);
    for slcNum = mins:maxs
        mask3M(:,:,slcNum) = imopen(mask3M(:,:,slcNum),strElem);
    end
end
% scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
% SUVvals3M                           = single(mask3M).*single(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
% volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval(volToEval==0)             = NaN;
% %volToEval                           = volToEval - min(volToEval(:));
% volToEval                           = volToEval / max(volToEval(:));
% volToEval                           = sqrt(volToEval);
% [f,Ph]                              = haralick3D(volToEval,16);
% suv3M                               = scanArray3M(:,:,uniqueSlices);
L = double(mask3M(minr:maxr,minc:maxc,mins:maxs));
% Lz=double(mean(L,3)>0);
% Lx=permute(double(mean(L,1)>0),[2,3,1]);
% shapefeaturesz=regionprops(Lz,'all');
% Eccentricity_xy=shapefeaturesz.Eccentricity;
% EulerNumber_xy=shapefeaturesz.EulerNumber;
% Solidity_xy=shapefeaturesz.Solidity;
% Extent_xy=shapefeaturesz.Extent;
% shapefeaturesx=regionprops(Lx,'all');
% Eccentricity_yz=shapefeaturesz.Eccentricity;
% EulerNumber_yz=shapefeaturesz.EulerNumber;
% Solidity_yz=shapefeaturesz.Solidity;
% Extent_yz=shapefeaturesz.Extent;
% 
% Eccentricity=sqrt(Eccentricity_xy*Eccentricity_yz);
% EulerNumber=sqrt(EulerNumber_xy*EulerNumber_yz);
% Solidity=sqrt(Solidity_xy*Solidity_yz);
% Extent=sqrt(Extent_xy*Extent_yz);
for i=1:size(L,3)
     Eccentricity(i)=getfield(regionprops(L(:,:,i),'Eccentricity'),'Eccentricity') ;
     EulerNumber(i)=getfield(regionprops(L(:,:,i),'EulerNumber'),'EulerNumber');
     Solidity(i)=getfield(regionprops(L(:,:,i),'Solidity'), 'Solidity');
     Extent(i)=getfield(regionprops(L(:,:,i),'Extent'),'Extent');
end
Eccentricity=mean(Eccentricity);
EulerNumber=mean(EulerNumber);
Solidity=mean(Solidity);
Extent=mean(Extent);
return



