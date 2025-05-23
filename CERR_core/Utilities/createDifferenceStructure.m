function planC = createDifferenceStructure(structNum1,structNum2,planC)
% function planC = createDifferenceStructure(structNum1,structNum2,planC)
%
% Creates a structure which is (structNum1 - structNum2)
%
% APA, 09/11/2012

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% Get RasterSegments for structNum1 and structNum2
rasterSegs1 = getRasterSegments(structNum1, planC);
rasterSegs2 = getRasterSegments(structNum2, planC);

% Get associated scanNum 
%scanNum = 1;
scanNum = getStructureAssociatedScan(structNum1,planC);

% Get Difference of the two rasterSegments
if ~isempty(rasterSegs1) && ~isempty(rasterSegs2)
    rasterSegs = structDiff(rasterSegs1, rasterSegs2, scanNum, planC);
else
    rasterSegs = rasterSegs1;
end

% Get Contours from rasterSegs
contourS = rasterToPoly(rasterSegs, scanNum, planC);

% Generate Structure Name
strName1 = planC{indexS.structures}(structNum1).structureName;
strName2 = planC{indexS.structures}(structNum2).structureName;
strName = [strName1,'-',strName2];

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

