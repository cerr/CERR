function planC = divideStructureAntPost(structNum, planC)
% function divideStructureAntPost(structNum, planC)
%
% APA, 06/23/2015

if ~exist('planC','var')
    global planC
end

global stateS

indexS = planC{end};

scanNum = getStructureAssociatedScan(structNum,planC);

newStructNumT = length(planC{indexS.structures}) + 1;
newStructNumB = length(planC{indexS.structures}) + 2;

newStructTS = newCERRStructure(scanNum, planC, newStructNumT);
newStructBS = newCERRStructure(scanNum, planC, newStructNumB);

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
            %[xyTV,xyLV,xyBV,xyRV] = dividePolygon(xV,yV,xc,yc);
            % Top part
            xyTV = cutpolygon([xV(:) yV(:)], [[xc;xc+1],[yc; yc]], 'T');            
            % Bottom part
            xyBV = cutpolygon([xV(:) yV(:)], [[xc; xc+1],[yc;yc]], 'B');
            
            newStructTS.contour(slcNum).segments(segNum).points = [xyTV xyTV(:,1).^0*zValue];
            newStructBS.contour(slcNum).segments(segNum).points = [xyBV  xyBV(:,1).^0*zValue];
        end
        
    else
        newStructTS.contour(slcNum).segments(1).points = [];
        newStructBS.contour(slcNum).segments(1).points = [];
    end
    
end


stateS.structsChanged = 1;

patientPosition = planC{indexS.scan}.scanInfo(1).DICOMHeaders.PatientPosition;
if isequal(patientPosition,'HFP') || isequal(patientPosition,'FFP')
    newStructTS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR_HALF'];
    newStructBS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR_HALF'];    
else
    newStructTS.structureName = [planC{indexS.structures}(structNum).structureName '_POSTERIOR_HALF'];
    newStructBS.structureName = [planC{indexS.structures}(structNum).structureName '_ANTERIOR_HALF'];
end
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructTS, newStructNumT);
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructBS, newStructNumB);

planC = getRasterSegs(planC, [newStructNumT newStructNumB]);
planC = updateStructureMatrices(planC, newStructNumT);
planC = updateStructureMatrices(planC, newStructNumB);

% Refresh View
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && isnumeric(stateS.handle.CERRSliceViewer)    
    stateS.structsChanged = 1;
    CERRRefresh
end


