function haus = calc_HausdorffMetric(structNum1,structNum2,planC)
%function haus = calc_HausdorffMetric(structNum1,structNum2,planC)
%
%This function computes Hausdorff distance between structNum1 and structNum2
%
%APA, 11/20/2014


[~, x1V, y1V, z1V] = getStructSurface(structNum1,planC);
[~, x2V, y2V, z2V] = getStructSurface(structNum2,planC);

haus = hausdorff([x1V(:) y1V(:) z1V(:)],[x2V(:) y2V(:) z2V(:)]);
