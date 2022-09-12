function planC = createIntersectionStructure(structNum1,structNum2,planC)
% function planC = createIntersectionStructure(structNum1,structNum2,planC)
%
% APA, 01/09/2011

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% Get RasterSegments for structNum1 and structNum2
rasterSegs1 = getRasterSegments(structNum1, planC);
rasterSegs2 = getRasterSegments(structNum2, planC);

% Get associated scanNum 
scanNum = getStructureAssociatedScan(structNum1,planC);

% Get Intersection of the two rasterSegments
rasterSegs = structIntersect(rasterSegs1, rasterSegs2, scanNum, planC);

% Get Contours from rasterSegs
contourS = rasterToPoly(rasterSegs, scanNum, planC);

% Generate Structure Name
strName1 = planC{indexS.structures}(structNum1).structureName;
strName2 = planC{indexS.structures}(structNum2).structureName;
strName = [strName1,'_I_',strName2];

% Create New structure
%Make an empty structure, assign name/contour.
newstr = newCERRStructure(scanNum, planC);
newstr.contour = contourS;
newstr.structureName = strName;
newstr.associatedScan = scanNum;
newstr.assocScanUID = planC{indexS.scan}(scanNum).scanUID;
numStructs = length(planC{indexS.structures});

%Append new structure to planC.
if ~isempty(planC{indexS.structures})
    planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newstr, numStructs+1, []);
else
    planC{indexS.structures} = newstr;
end

%Update uniformized data.
planC = updateStructureMatrices(planC, numStructs+1);

% Refresh View
global stateS
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end
