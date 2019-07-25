function planC = structToGsps(structNum, planC)
% function planC = structToGsps(structNum, planC)
%
% This function creates GSPS from the passed structure structNum.
%
% APA, 12/01/2015

global stateS
if ~exist('planC','var')
    global planC
end
indexS = planC{end};

%scanNum = 1;
%newStructS = newCERRStructure(scanNum, planC);

scanNum = getStructureAssociatedScan(structNum,planC);

% % Get z coordinates to assign to structure points
% [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
% 
% emptySicesV = 1:length(zVals);

% % Build a list of slices that are annotated
% for slcNum=1:length(planC{indexS.scan}(scanNum).scanInfo)
%     % SOPInstanceUIDc{slcNum} = planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SOPInstanceUID;
%     SOPInstanceUIDc{slcNum} = planC{indexS.scan}(scanNum).scanInfo(slcNum).sopInstanceUID;
% end

% if isempty(gspsNumV)
%     gspsNumV = 1:length(planC{indexS.GSPS});
% end

Dims = size(planC{indexS.scan}(scanNum).scanArray);
if numel(Dims) > 2
    Dims(3:end) = [];
end
gridUnits = [planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
% offset = [planC{indexS.scan}(scanNum).scanInfo(1).yOffset planC{indexS.scan}(scanNum).scanInfo(1).xOffset];
xOffset = planC{indexS.scan}(scanNum).scanInfo(slc).xOffset;
yOffset = planC{indexS.scan}(scanNum).scanInfo(slc).yOffset;

% Loop through slices and add gsps annotations
% createStructureFlag = 0;
numGsps = length(planC{indexS.GSPS});
for slc=1:length(planC{indexS.structures}(structNum).contour) %gspsNumV
    %sliceNum = strmatch(planC{indexS.GSPS}(i).SOPInstanceUID, SOPInstanceUIDc, 'exact');
    %if isempty(sliceNum)
    %    continue
    %end
    %createStructureFlag = 1;
    %emptySicesV(sliceNum) = NaN;
    %numGraphic = length(planC{indexS.GSPS}(i).graphicAnnotationS);
    for segNum = 1:length(planC{indexS.structures}(structNum).contour(slc).segments)
        pointsM = planC{indexS.structures}(structNum).contour(slc).segments(segNum).points;
        [rowV, colV] = aapmtom(pointsM(:,1),pointsM(:,2),xOffset,yOffset,Dims(1:2),gridUnits);
        dataM = [rowV(:), colV(:)]';
        dataV = dataM(:);
        gspsS(segNum).graphicAnnotationType = 'POLYLINE';
        gspsS(segNum).graphicAnnotationNumPts = size(dataM,2);
        gspsS(segNum).graphicAnnotationData = dataV;
        gspsS(segNum).SOPInstanceUID = planC{indexS.scan}(scanNum).scanInfo(slc).sopInstanceUID;
    end
    planC{indexS.GSPS}(numGsps+1).graphicAnnotationS(end+1) = gspsS;

end

if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    % Refresh View
    CERRRefresh
end
