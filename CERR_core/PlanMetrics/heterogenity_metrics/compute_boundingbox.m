function [minr, maxr, minc, maxc, mins, maxs]=compute_boundingbox(x3D);
% finding the bounding box parameters

[iV,jV,kV]=find3d(x3D);
minr=min(iV);
maxr=max(iV);
minc=min(jV);
maxc=max(jV);
mins=min(kV);
maxs=max(kV);

return
