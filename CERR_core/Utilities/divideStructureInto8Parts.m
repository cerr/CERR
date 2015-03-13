function planC = divideStructureInto8Parts(structNum, planC)
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

newStructNumTL = length(planC{indexS.structures}) + 5;
newStructNumTR = length(planC{indexS.structures}) + 6;
newStructNumBL = length(planC{indexS.structures}) + 7;
newStructNumBR = length(planC{indexS.structures}) + 8;

newStructNumLT = length(planC{indexS.structures}) + 9;
newStructNumLB = length(planC{indexS.structures}) + 10;
newStructNumRT = length(planC{indexS.structures}) + 11;
newStructNumRB = length(planC{indexS.structures}) + 12;

newStructTS = newCERRStructure(scanNum, planC, newStructNumT);
newStructLS = newCERRStructure(scanNum, planC, newStructNumL);
newStructBS = newCERRStructure(scanNum, planC, newStructNumB);
newStructRS = newCERRStructure(scanNum, planC, newStructNumR);

newStructTLS = newCERRStructure(scanNum, planC, newStructNumTL);
newStructTRS = newCERRStructure(scanNum, planC, newStructNumTR);
newStructBLS = newCERRStructure(scanNum, planC, newStructNumBL);
newStructBRS = newCERRStructure(scanNum, planC, newStructNumBR);

newStructLTS = newCERRStructure(scanNum, planC, newStructNumLT);
newStructLBS = newCERRStructure(scanNum, planC, newStructNumLB);
newStructRTS = newCERRStructure(scanNum, planC, newStructNumRT);
newStructRBS = newCERRStructure(scanNum, planC, newStructNumRB);

% Get index of CTV_1 structure
CTV_index = getMatchingIndex('CTV_1',lower({planC{indexS.structures}.structureName}),'exact');


for slcNum = 1:length(planC{indexS.scan}(scanNum).scanInfo)
    
    % Calculate centroid for this slice
    [rasterSegments, planC, isError]    = getRasterSegments(CTV_index,planC);
    rasterIndices = find(rasterSegments(:,6) == slcNum);
    
    zValue = planC{indexS.scan}(scanNum).scanInfo(slcNum).zValue;
    
    % Calculate centroid for this slice
    [rasterSegmentsStr, planC, isError]    = getRasterSegments(structNum,planC);
    rasterIndicesStr = find(rasterSegmentsStr(:,6) == slcNum);

    if ~isempty(rasterIndicesStr)
        
        maskM = rasterToMask(rasterSegments(rasterIndices,:), scanNum, planC);
        
        %Get r,c,s list of all points in mask.
        [rV,cV] = find(maskM);
        
        %Take the mean of all points... unweighted as this is a mask.
        rowCOM = mean(rV);
        colCOM = mean(cV);
        slcCOM = 1; % dummy value
        
        %Convert from rcs, to xyz coordinates.
        [xc,yc] = mtoxyz(rowCOM, colCOM, slcCOM, scanNum, planC, 'uniform');
        if isnan(xc)
            continue;
        end
        for segNum = 1:length(planC{indexS.structures}(structNum).contour(slcNum).segments)
            xV = planC{indexS.structures}(structNum).contour(slcNum).segments(segNum).points(:,1);
            yV = planC{indexS.structures}(structNum).contour(slcNum).segments(segNum).points(:,2);
            [xyTV,xyLV,xyBV,xyRV,xyTLV,xyTRV,xyBLV,xyBRV,xyLTV,xyLBV,xyRTV,xyRBV] = dividePolygonInto8Parts(xV,yV,xc,yc);
            newStructTS.contour(slcNum).segments(segNum).points = [xyTV xyTV(:,1).^0*zValue];
            newStructLS.contour(slcNum).segments(segNum).points = [xyLV  xyLV(:,1).^0*zValue];
            newStructBS.contour(slcNum).segments(segNum).points = [xyBV  xyBV(:,1).^0*zValue];
            newStructRS.contour(slcNum).segments(segNum).points = [xyRV  xyRV(:,1).^0*zValue];

            newStructTLS.contour(slcNum).segments(segNum).points = [xyTLV  xyTLV(:,1).^0*zValue];
            newStructTRS.contour(slcNum).segments(segNum).points = [xyTRV  xyTRV(:,1).^0*zValue];
            newStructBLS.contour(slcNum).segments(segNum).points = [xyBLV  xyBLV(:,1).^0*zValue];
            newStructBRS.contour(slcNum).segments(segNum).points = [xyBRV  xyBRV(:,1).^0*zValue];

            newStructLTS.contour(slcNum).segments(segNum).points = [xyLTV  xyLTV(:,1).^0*zValue];
            newStructLBS.contour(slcNum).segments(segNum).points = [xyLBV  xyLBV(:,1).^0*zValue];
            newStructRTS.contour(slcNum).segments(segNum).points = [xyRTV  xyRTV(:,1).^0*zValue];
            newStructRBS.contour(slcNum).segments(segNum).points = [xyRBV  xyRBV(:,1).^0*zValue];
        end
        
    else
        newStructTS.contour(slcNum).segments(1).points = [];
        newStructLS.contour(slcNum).segments(1).points = [];
        newStructBS.contour(slcNum).segments(1).points = [];
        newStructRS.contour(slcNum).segments(1).points = [];
        
        newStructTLS.contour(slcNum).segments(1).points = [];
        newStructTRS.contour(slcNum).segments(1).points = [];
        newStructBLS.contour(slcNum).segments(1).points = [];
        newStructBRS.contour(slcNum).segments(1).points = [];

        newStructLTS.contour(slcNum).segments(1).points = [];
        newStructLBS.contour(slcNum).segments(1).points = [];
        newStructRTS.contour(slcNum).segments(1).points = [];
        newStructRBS.contour(slcNum).segments(1).points = [];
        
    end
    
end


stateS.structsChanged = 1;

newStructLS.structureName = [planC{indexS.structures}(structNum).structureName '_RIGHT'];
newStructRS.structureName = [planC{indexS.structures}(structNum).structureName '_LEFT'];

patientPosition = planC{indexS.scan}.scanInfo(1).DICOMHeaders.PatientPosition;
if isequal(patientPosition,'HFP') || isequal(patientPosition,'FFP')
    newStructTS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR'];
    newStructBS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR'];
    newStructTLS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR_RIGHT'];
    newStructTRS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR_LEFT'];
    newStructBLS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR_RIGHT'];
    newStructBRS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR_LEFT'];
    newStructLTS.structureName = [planC{indexS.structures}(structNum).structureName '_RIGHT_POSTERIOR'];
    newStructLBS.structureName = [planC{indexS.structures}(structNum).structureName '_RIGHT_ANTERIOR'];
    newStructRTS.structureName = [planC{indexS.structures}(structNum).structureName '_LEFT_POSTERIOR'];
    newStructRBS.structureName = [planC{indexS.structures}(structNum).structureName '_LEFT_ANTERIOR'];
else
    newStructTS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR'];
    newStructBS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR'];    
    newStructTLS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR_RIGHT'];
    newStructTRS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR_LEFT'];
    newStructBLS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR_RIGHT'];
    newStructBRS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR_LEFT'];
    newStructLTS.structureName = [planC{indexS.structures}(structNum).structureName '_RIGHT_ANTERIOR'];
    newStructLBS.structureName = [planC{indexS.structures}(structNum).structureName '_RIGHT_POSTERIOR'];
    newStructRTS.structureName = [planC{indexS.structures}(structNum).structureName '_LEFT_ANTERIOR'];
    newStructRBS.structureName = [planC{indexS.structures}(structNum).structureName '_LEFT_POSTERIOR'];
end
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructTS, newStructNumT);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructLS, newStructNumL);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructBS, newStructNumB);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructRS, newStructNumR);

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructTLS, newStructNumTL);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructTRS, newStructNumTR);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructBLS, newStructNumBL);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructBRS, newStructNumBR);

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructLTS, newStructNumLT);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructLBS, newStructNumLB);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructRTS, newStructNumRT);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructRBS, newStructNumRB);

planC = getRasterSegs(planC, [newStructNumT newStructNumL newStructNumB newStructNumR newStructNumTL newStructNumTR newStructNumBL newStructNumBR newStructNumLT newStructNumLB newStructNumRT newStructNumRB]);
planC = updateStructureMatrices(planC, newStructNumT);
planC = updateStructureMatrices(planC, newStructNumL);
planC = updateStructureMatrices(planC, newStructNumB);
planC = updateStructureMatrices(planC, newStructNumR);

planC = updateStructureMatrices(planC, newStructNumTL);
planC = updateStructureMatrices(planC, newStructNumTR);
planC = updateStructureMatrices(planC, newStructNumBL);
planC = updateStructureMatrices(planC, newStructNumBR);

planC = updateStructureMatrices(planC, newStructNumLT);
planC = updateStructureMatrices(planC, newStructNumLB);
planC = updateStructureMatrices(planC, newStructNumRT);
planC = updateStructureMatrices(planC, newStructNumRB);

% Refresh View
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && isnumeric(stateS.handle.CERRSliceViewer)    
    stateS.structsChanged = 1;
    CERRRefresh
end


