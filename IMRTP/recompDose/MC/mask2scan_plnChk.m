function [segmentsM] = mask2scan(maskM, optS, sliceNum)
%function [segmentsM] = mask2scan(maskM, optS, sliceNum)
%segmentsM holds the mask in 'scan segment' format:
%each row of this 2-D matrix has the elements:
%yValue, xStart, xStop, delta_x (all in AAPM coordinates).
%xStart and xStop are the points at which the filled-in segment
%begins and ends; yValue is the y-value of that row.  delta_x is the
%interval between x values.
%
%Get scan format information:
%
%Starting points for filled segments will be those after diff = 1; stopping points will
%those where diff = -1.  This also works for jutting points (one point
%in the segment).
%
%J.O.Deasy, deasy@radonc.wustl.edu.
%LM:  18 Mar 02, JOD;
%Major bug fix: 28 dec 02: Scan row was shifted up one row;
%scan column was shifted to the right one column.  Fixed prior to release
%of version 2 beta, JOD.

imageSizeV = optS.ROIImageSize;

%First convert to pixel-based coords:
xOffset = optS.xCTOffset;
yOffset = optS.yCTOffset;

zerosV = zeros(size(maskM,1),1);  %padding vector

delta_x = optS.ROIxVoxelWidth;
delta_y = optS.ROIyVoxelWidth;

mask2M = [zerosV, maskM, zerosV];

diffM = diff(mask2M');  %note: mask is rotated here!
startM = [diffM == 1];
startM = startM(:,2:end-1);
stopM  = [diffM == -1];
stopM = stopM(:,2:end-1);

[i1V, j1V] = find(startM);
[xStartV, yStartV] = mtoaapm(j1V + 1, i1V, size(maskM));
xStartV = xStartV * delta_x;
yStartV = yStartV * delta_y;

xStartV = xStartV + optS.xCTOffset;
yStartV = yStartV + optS.yCTOffset;

[i2V, j2V] = find(stopM);
[xStopV, yStopV] = mtoaapm(j2V + 1, i2V - 1 , size(maskM));
xStopV = xStopV * delta_x;
yStopV = yStopV * delta_y;

xStopV = xStopV + optS.xCTOffset;
yStopV = yStopV + optS.yCTOffset;

if any(yStartV ~= yStopV)
    error('Ooops! Problem in converting a mask to scan segments.  Check options.')
end

%Store: row y, start x, stop x, delta x, CT mask row, CT start col, CT end col.
z1V = ones(length(j1V),1) * sliceNum;
segmentsM = [yStartV(:), xStartV(:), xStopV(:), ones(length(xStopV),1) * delta_x, z1V, j1V(:) + 1, i1V(:), i2V(:) - 1];

