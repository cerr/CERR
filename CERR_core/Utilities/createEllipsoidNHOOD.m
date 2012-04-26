function ellipoideM = createEllipsoidNHOOD(rowsV, colsV, slcsV)
% function ellipoideM = createEllipsoidNHOOD(rowsV, colsV, slcsV)
%
% This function creates an ellipsoid neighborhood from the passes rows,
% cols, slcs. The size of ellipoideM will be
% [2*length(rowsV)+1,2*length(colsV)+1,2*length(slcsV)+1]
%
% APA, 04/26/2012

rowCenter = 1+length(rowsV);
numRows = 2*rowCenter-1;
rowRadius = rowCenter-1;
if rowRadius == 0
    rowRadius = 1;
end

colCenter = 1+length(colsV);
numCols = 2*colCenter-1;
colRadius = colCenter-1;
if colRadius == 0
    colRadius = 1;
end

slcCenter = 1+length(slcsV);
numSlcs = 2*slcCenter-1;
slcRadius = slcCenter-1;
if slcRadius == 0
    slcRadius = 1;
end

ellipoideM = zeros(numRows,numCols,numSlcs);

[rowsM, colsM, slcsM] = meshgrid(1:numRows,1:numCols,1:numSlcs); 

indKeepM = (rowsM-rowCenter).^2/rowRadius^2 + (colsM-colCenter).^2/colRadius^2 + (slcsM-slcCenter).^2/slcRadius^2 <= 1;

ellipoideM(indKeepM) = 1;

