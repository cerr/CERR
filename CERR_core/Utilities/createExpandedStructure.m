function planC = createExpandedStructure(structNum, margin, planC)
% function createExpandedStructure.m(structNum, margin, planC)
%
% APA, 09/13/2012

if ~exist('planC','var')
    global planC
end

global stateS

indexS = planC{end};

scanNum = getStructureAssociatedScan(structNum,planC);

newStructNum = length(planC{indexS.structures}) + 1;

newStructS = newCERRStructure(scanNum, planC, newStructNum);

maskM = getSurfaceExpand(structNum, margin, 1, planC);
%If registered to uniformized data, use nearest slice neighbor
%interpolation.
[xUni, yUni, zUni] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
[xSca, ySca, zSca] = getScanXYZVals(planC{indexS.scan}(scanNum));
normsiz = size(getScanArray(planC{indexS.scan}(scanNum)));
tmpM = false(normsiz);
for i=1:normsiz(3)
    zVal = zSca(i);
    uB = find(zUni > zVal, 1 );
    lB = find(zUni <= zVal, 1, 'last' );
    if isempty(uB) || isempty(lB)
        continue
    end
    if abs(zUni(uB) - zVal) < abs(zUni(lB) - zVal)
        tmpM(:,:,i) = logical(maskM(:,:,uB));
    else
        tmpM(:,:,i) = logical(maskM(:,:,lB));
    end
end
rasterSegments = maskToRaster(tmpM, 1:normsiz(3), scanNum, planC);

newStructS.rasterSegments = rasterSegments;
newStructS.rasterized = 1;

contourS = rasterToPoly(rasterSegments, scanNum, planC);

newStructS.contour = contourS;

newStructS.structureName = [planC{indexS.structures}(structNum).structureName, '+3D_', num2str(margin)];

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);

planC = updateStructureMatrices(planC, newStructNum);

% Refresh View
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && isnumeric(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end


