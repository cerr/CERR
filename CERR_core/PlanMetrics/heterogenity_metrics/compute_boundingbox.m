function [minr, maxr, minc, maxc, mins, maxs, bboxmask]= compute_boundingbox(x3D, maskFlag)
% finding the bounding box parameters

if nargin < 2
    maskFlag = 0;
end

[iV,jV,kV]=find3d(x3D);
minr=min(iV);
maxr=max(iV);
minc=min(jV);
maxc=max(jV);
mins=min(kV);
maxs=max(kV);

bboxmask = [];

if maskFlag
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
