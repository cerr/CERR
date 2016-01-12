function planC = gspsToStruct(scanNum, gspsNumV)
% function planC = gspsToStruct(scanNum, gspsNumV)
%
% this function creates a Structure out of GSPS objects associated with
% the input scanNum. gspsNumV is an optional parameter which specifies a 
% vector of gsps indices to convert to structure.
%
% APA, 12/01/2015

global stateS planC
indexS = planC{end};

if ~exist('gspsNumV','var')
    gspsNumV = [];
end
%scanNum = 1;
newStructS = newCERRStructure(scanNum, planC);

% Get z coordinates to assign to structure points
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));

emptySicesV = 1:length(zVals);

% Build a list of slices that are annotated
for slcNum=1:length(planC{indexS.scan}(scanNum).scanInfo)
    SOPInstanceUIDc{slcNum} = planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SOPInstanceUID;
end

if isempty(gspsNumV)
    %numSignificantSlcs = length(planC{indexS.GSPS});
    gspsNumV = 1:length(planC{indexS.GSPS});
end

Dims = size(planC{indexS.scan}(scanNum).scanArray);
if numel(Dims) > 2
    Dims(3:end) = [];
end
gridUnits = [planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
offset = [planC{indexS.scan}(scanNum).scanInfo(1).yOffset planC{indexS.scan}(scanNum).scanInfo(1).xOffset];

% Loop through slices and create assign points to a new structure
for i=gspsNumV
    sliceNum = strmatch(planC{indexS.GSPS}(i).SOPInstanceUID, SOPInstanceUIDc, 'exact');
    if isempty(sliceNum)
        continue
    end
    emptySicesV(sliceNum) = [];
    numGraphic = length(planC{indexS.GSPS}(i).graphicAnnotationS);
    for iGraphic = 1:numGraphic
        graphicAnnotationType = planC{indexS.GSPS}(i).graphicAnnotationS(iGraphic).graphicAnnotationType;
        graphicAnnotationNumPts = planC{indexS.GSPS}(i).graphicAnnotationS(iGraphic).graphicAnnotationNumPts;
        graphicAnnotationData = planC{indexS.GSPS}(i).graphicAnnotationS(iGraphic).graphicAnnotationData;
        rowV = graphicAnnotationData(1:2:end);
        colV = graphicAnnotationData(2:2:end);
        [xV, yV] = mtoaapm(colV, rowV, Dims, gridUnits, offset);
        if strcmpi(graphicAnnotationType,'POLYLINE')
            plot(xV,yV,'r')
        elseif strcmpi(graphicAnnotationType,'ELLIPSE')
            plot(xV(1:2),yV(1:2),'r','linewidth',2)
            plot(xV(3:4),yV(3:4),'r','linewidth',2)
        end
        
        points = [xV(:) yV(:) zVals(sliceNum)*ones(length(xV),1)];
        newStructS.contour(sliceNum).segments(iGraphic).points = points;
        
    end

end

for empt = emptySicesV
    newStructS.contour(empt).segments.points = [];
end

newStructS.structureName    = 'ROI';
newStructNum = length(planC{indexS.structures}) + 1;
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
planC = getRasterSegs(planC, newStructNum);
planC = updateStructureMatrices(planC, newStructNum);

if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    % Refresh View
    CERRRefresh
end
