function planC = createExpandedStructure2D(structNum, margin, planC)
% function createExpandedStructure2D(structNum, margin, planC)
%
% APA, 09/09/2014

if ~exist('planC','var')
    global planC
end

global stateS

indexS = planC{end};

scanNum = getStructureAssociatedScan(structNum,planC);

newStructNum = length(planC{indexS.structures}) + 1;

%newStructS = newCERRStructure(scanNum, planC, newStructNum);

rasterSegs = getRasterSegments(structNum, planC);

% Get Rastersegments +/- margin, thus creating an halo
halo = structMargin(rasterSegs, margin, scanNum, planC);

% Expand rastersegments by the margin
rasterSegsExpanded = structUnion(halo, rasterSegs, scanNum, planC);

% Get Contours from rasterSegs
contourS = rasterToPoly(rasterSegsExpanded, scanNum, planC);

% Generate Structure Name
strName = planC{indexS.structures}(structNum).structureName;
strName = [strName,' + 2D_',num2str(margin)];

% Create New structure
%Make an empty structure, assign name/contour.
newstr = newCERRStructure(scanNum, planC, newStructNum);
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
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && isnumeric(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end


