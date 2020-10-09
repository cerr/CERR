function [minr, maxr, minc, maxc, mins, maxs, bboxmask]= compute_boundingbox(x3D, maskFlag)
% finding the bounding box parameters
% update: EML, 2020-Sep, return bounding box binary mask with optional padding
% if maskFlag > 1, it is interpreted as padding parameter

if nargin < 2
    maskFlag = 0;
end
maskFlag = floor(maskFlag);

[iV,jV,kV]=find3d(x3D);
minr=min(iV);
maxr=max(iV);
minc=min(jV);
maxc=max(jV);
mins=min(kV);
maxs=max(kV);

bboxmask = [];

if ~isempty(maskFlag)
    bboxmask = zeros(size(x3D));
    if maskFlag > 1
        minr = minr - maskFlag;
        maxr = maxr + maskFlag;
        minc = minc - maskFlag;
        maxc = maxc + maskFlag;
        mins = mins - maskFlag;
        maxs = maxs + maskFlag;
    end
    bboxmask(minr:maxr, minc:maxc, mins:maxs) = 1;
end

return
