function [energy,constrast,Entropy,Homogeneity,standard_dev,Ph,Slope] = getHaralicParams(structNum,planC)
%function getHaralicParams(structNum)
%
%This function returns the haralic parameters for structure structNum.
%
%APA,12/26/2006

if ~exist('planC')
    global planC
end
indexS = planC{end};

scanNum                             = getStructureAssociatedScan(structNum,planC);
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(volToEval==0)             = NaN;
%volToEval                           = volToEval - min(volToEval(:));
volToEval                           = volToEval / max(volToEval(:));
%volToEval                           = sqrt(volToEval);
[f,Ph]                              = haralick3D(volToEval,16);
suv3M                               = scanArray3M(:,:,uniqueSlices);
maskScaled3D = suv3M(find(mask3M));
% maskScaled3D = maskScaled3D/
standard_dev                        = std(single(maskScaled3D));
%standard_dev                        = std(suv3M(find(mask3M)));
energy                              = f(1);
constrast                           = f(2);
Entropy                             = f(4);
Homogeneity                         = f(8);
%Calculate slope
indexS = planC{end};
init_th  = 10;
final_th = 80;
n_th     = 10;
Thresholds = linspace (init_th, final_th, n_th);
% Slope = calc_slope_grigsby(structNum,Thresholds,planC);
Slope = NaN;
disp(['Energy     : ',num2str(energy)])
disp(['Contrast   : ',num2str(constrast)])
disp(['Entropy    : ',num2str(Entropy)])
disp(['Homogenity : ',num2str(Homogeneity)])
disp(['Std. Dev.  : ',num2str(standard_dev)])
disp(['Slope      : ',num2str(Slope)])
