function planC = divideStructureAntPostLeftRight(structNum, planC)
% function divideStructureAntPostLeftRight(structNum, planC)
%
% APA, 08/23/2012

if ~exist('planC','var')
    global planC
end

global stateS

indexS = planC{end};

scanNum = getStructureAssociatedScan(structNum,planC);

newStructNumT = length(planC{indexS.structures}) + 1;
newStructNumL = length(planC{indexS.structures}) + 2;
newStructNumB = length(planC{indexS.structures}) + 3;
newStructNumR = length(planC{indexS.structures}) + 4;

newStructTS = newCERRStructure(scanNum, planC, newStructNumT);
newStructLS = newCERRStructure(scanNum, planC, newStructNumL);
newStructBS = newCERRStructure(scanNum, planC, newStructNumB);
newStructRS = newCERRStructure(scanNum, planC, newStructNumR);

for slcNum = 1:length(planC{indexS.scan}(scanNum).scanInfo)
    
    % Calculate centroid for this slice
    [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
    rasterIndices = find(rasterSegments(:,6) == slcNum);
    
    zValue = planC{indexS.scan}(scanNum).scanInfo(slcNum).zValue;
    
    if ~isempty(rasterIndices)
        
        maskM = rasterToMask(rasterSegments(rasterIndices,:), scanNum, planC);
        
        %Get r,c,s list of all points in mask.
        [rV,cV] = find(maskM);
        
        %Take the mean of all points... unweighted as this is a mask.
        rowCOM = mean(rV);
        colCOM = mean(cV);
        slcCOM = 1; % dummy value
        
        %Convert from rcs, to xyz coordinates.
        [xc,yc] = mtoxyz(rowCOM, colCOM, slcCOM, scanNum, planC, 'uniform');
        
        for segNum = 1:length(planC{indexS.structures}(structNum).contour(slcNum).segments)
            xV = planC{indexS.structures}(structNum).contour(slcNum).segments(segNum).points(:,1);
            yV = planC{indexS.structures}(structNum).contour(slcNum).segments(segNum).points(:,2);
            [xyTV,xyLV,xyBV,xyRV] = dividePolygon(xV,yV,xc,yc);
            newStructTS.contour(slcNum).segments(segNum).points = [xyTV xyTV(:,1).^0*zValue];
            newStructLS.contour(slcNum).segments(segNum).points = [xyLV  xyLV(:,1).^0*zValue];
            newStructBS.contour(slcNum).segments(segNum).points = [xyBV  xyBV(:,1).^0*zValue];
            newStructRS.contour(slcNum).segments(segNum).points = [xyRV  xyRV(:,1).^0*zValue];
        end
        
    else
        newStructTS.contour(slcNum).segments(1).points = [];
        newStructLS.contour(slcNum).segments(1).points = [];
        newStructBS.contour(slcNum).segments(1).points = [];
        newStructRS.contour(slcNum).segments(1).points = [];
    end
    
end


stateS.structsChanged = 1;

newStructLS.structureName = [planC{indexS.structures}(structNum).structureName '_RIGHT'];
newStructRS.structureName = [planC{indexS.structures}(structNum).structureName '_LEFT'];
patientPosition = planC{indexS.scan}.scanInfo(1).DICOMHeaders.PatientPosition;
if isequal(patientPosition,'HFP') || isequal(patientPosition,'FFP')
    newStructTS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR'];
    newStructBS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR'];
else
    newStructTS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR'];
    newStructBS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR'];    
end
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructTS, newStructNumT);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructLS, newStructNumL);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructBS, newStructNumB);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructRS, newStructNumR);

planC = getRasterSegs(planC, [newStructNumT newStructNumL newStructNumB newStructNumR]);
planC = updateStructureMatrices(planC, newStructNumT);
planC = updateStructureMatrices(planC, newStructNumL);
planC = updateStructureMatrices(planC, newStructNumB);
planC = updateStructureMatrices(planC, newStructNumR);

% Refresh View
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && isnumeric(stateS.handle.CERRSliceViewer)    
    stateS.structsChanged = 1;
    CERRRefresh
end


