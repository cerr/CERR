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

if maskFlag ~= 0
    bboxmask = zeros(size(x3D));
    
    if maskFlag > 1
        minr = minr - maskFlag;
        maxr = maxr + maskFlag;
        if maxr > size(x3D,1)
            maxr = size(x3D,1);
        end
        minc = minc - maskFlag;
        maxc = maxc + maskFlag;
        if maxc > size(x3D,2)
            maxc = size(x3D,2);
        end
        mins = mins - maskFlag;
        maxs = maxs + maskFlag;
        if maxs > size(x3D,3)
            maxs = size(x3D,3);
        end
    end
    maxarr = [maxr,maxc,maxs];
    minarr = [minr, minc, mins];
    minarr(minarr < 1) = 1;
    minr = minarr(1);
    minc = minarr(2);
    mins = minarr(3);
    bboxmask(minarr(1):maxarr(1), minarr(2):maxarr(2), minarr(3):maxarr(3)) = 1;
end

return
