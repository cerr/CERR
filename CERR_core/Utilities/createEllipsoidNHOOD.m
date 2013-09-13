function ellipoideM = createEllipsoidNHOOD(rowsV, colsV, slcsV, ringFlag)
% function ellipoideM = createEllipsoidNHOOD(rowsV, colsV, slcsV, ringFlag)
%
% This function creates an ellipsoid ring neighborhood from the passes rows,
% cols, slcs. The size of ellipoideM will be
% [2*length(rowsV)+1,2*length(colsV)+1,2*length(slcsV)+1]
%
% If ringFlag if not passed or if it is 1, a ring is created with width of 1 pixel 
%
% If ringFlag of 0 is passed, ring is NOT created and the entire ellipsoid
% neighborhood is created.
%
% APA, 04/26/2012

% global globalEllipsoidM

if ~exist('ringFlag','var')
    ringFlag = 1;
end
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

innerRowRingLevel = (rowRadius-1).^2/rowRadius^2;
innerColRingLevel = (colRadius-1).^2/colRadius^2;
innerSlcRingLevel = (slcRadius-1).^2/slcRadius^2;
innerRingLevel = min([innerRowRingLevel innerColRingLevel innerSlcRingLevel]);

ellipoideM = zeros(numRows,numCols,numSlcs);

[rowsM, colsM, slcsM] = meshgrid(1:numRows,1:numCols,1:numSlcs); 

indKeepM = (rowsM-rowCenter).^2/rowRadius^2 + (colsM-colCenter).^2/colRadius^2 + (slcsM-slcCenter).^2/slcRadius^2 <= 1;

if ringFlag
    indKeepM = indKeepM & ((rowsM-rowCenter).^2/rowRadius^2 + (colsM-colCenter).^2/colRadius^2 + (slcsM-slcCenter).^2/slcRadius^2) > innerRingLevel;
end

ellipoideM(indKeepM) = 1;


% % QA
% tmpGlobalEllipsoidM = zeros([21    21    11]);
% centerRow = ceil(size(tmpGlobalEllipsoidM,1)/2);
% rowLen = floor(size(ellipoideM,1)/2);
% centerCol = ceil(size(tmpGlobalEllipsoidM,2)/2);
% colLen = floor(size(ellipoideM,2)/2);
% centerSlc = ceil(size(tmpGlobalEllipsoidM,3)/2);
% slcLen = floor(size(ellipoideM,3)/2);
% tmpGlobalEllipsoidM(centerRow-rowLen:centerRow+rowLen,centerCol-colLen:centerCol+colLen,centerSlc-slcLen:centerSlc+slcLen) = ellipoideM;
% globalEllipsoidM = globalEllipsoidM | tmpGlobalEllipsoidM;
% figure, imagesc(tmpGlobalEllipsoidM(:,:,4))
% 
% % globalEllipsoidM = zeros([21    21    11]);
% 

