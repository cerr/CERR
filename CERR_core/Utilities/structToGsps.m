function planC = structToGsps(structNumV, planC)
% function planC = structToGsps(structNumV, planC)
%
% This function creates GSPS from the passed structures structNumV.
%
% APA, 12/01/2015

global stateS
if ~exist('planC','var')
    global planC
end
indexS = planC{end};

%scanNum = 1;
%newStructS = newCERRStructure(scanNum, planC);

for iStr = 1:length(structNumV)
    
    structNum = structNumV(iStr);
    
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
    xOffset = planC{indexS.scan}(scanNum).scanInfo(1).xOffset;
    yOffset = planC{indexS.scan}(scanNum).scanInfo(1).yOffset;
    
    % Loop through slices and add gsps annotations
    % createStructureFlag = 0;
    newGspsS = initializeCERR('GSPS');
    for slc=1:length(planC{indexS.structures}(structNum).contour) %gspsNumV
        %sliceNum = strmatch(planC{indexS.GSPS}(i).SOPInstanceUID, SOPInstanceUIDc, 'exact');
        %if isempty(sliceNum)
        %    continue
        %end
        %createStructureFlag = 1;
        %emptySicesV(sliceNum) = NaN;
        %numGraphic = length(planC{indexS.GSPS}(i).graphicAnnotationS);
        
        segS = planC{indexS.structures}(structNum).contour(slc).segments;
        if isempty(segS) || (~isempty(segS) && isempty(segS(1).points))
            continue;
        end
        
        graphicAnnotationS = struct();
        textAnnotationS = struct();
        maxAllSeg = -1;
        for segNum = 1:length(planC{indexS.structures}(structNum).contour(slc).segments)
            pointsM = planC{indexS.structures}(structNum).contour(slc).segments(segNum).points;
            [rowV, colV] = aapmtom(pointsM(:,1),pointsM(:,2),xOffset,yOffset,Dims(1:2),gridUnits);
            rowV = rowV - 1; % 1-index to 0-index
            colV = colV - 1;
            dataM = [colV(:),rowV(:)]';
            dataV = dataM(:);
            graphicAnnotationS(segNum).graphicAnnotationType = 'POLYLINE'; % 0070,0023
            graphicAnnotationS(segNum).graphicAnnotationNumPts = size(dataM,2); % 0070,0021
            graphicAnnotationS(segNum).graphicAnnotationDims = 2; % 0070,0020
            graphicAnnotationS(segNum).graphicAnnotationUnits = 'PIXEL'; % 0070,0005
            graphicAnnotationS(segNum).graphicAnnotationFilled = 'N'; % 0070,0024
            graphicAnnotationS(segNum).graphicAnnotationData = dataV; %  0070,0022
            
            % Location of anchor point
            [maxCol,maxInd] = max(colV(:));
            if maxCol > maxAllSeg
                maxRow = rowV(maxInd);
                anchorPoint = [maxCol+5,maxRow];
                maxAllSeg = maxCol;
            end
            %boundingBoxTopLeftHandCornerPt = [maxCol+10,maxRow];
            %boundingBoxBottomRightHandCornerPt = [maxCol+60,maxRow-20];
            
        end
        
        % Assign text to the rightmost segment
        textAnnotationS(1).anchorPtAnnotationUnits                   = 'PIXEL'; % 0070,0004
        textAnnotationS(1).unformattedTextValue                      = planC{indexS.structures}(structNum).structureName; % 0070,0006
        textAnnotationS(1).anchorPoint                               = anchorPoint; % col\row 0070,0014
        textAnnotationS(1).anchorPointVisibility                     = 'Y'; % required if anchorPoint is present 'Y' or 'N'
        %textAnnotationS(1).boundingBoxAnnotationUnits                = 'PIXEL'; % 0070,0003
        %textAnnotationS(1).boundingBoxTopLeftHandCornerPt            = boundingBoxTopLeftHandCornerPt; % 0070,0010 not required if anchor point is present
        %textAnnotationS(1).boundingBoxBottomRightHandCornerPt        = boundingBoxBottomRightHandCornerPt; % 0070,0011 not required if anchor point is present
        %textAnnotationS(1).boundingBoxTextHorizontalJustification    = 'LEFT'; % 0070,0011 not required if anchor point is present % 'CENTER'; % 0070,0012
        
        newGspsS(1).graphicAnnotationS = graphicAnnotationS;
        newGspsS(1).textAnnotationS = textAnnotationS;
        newGspsS(1).presentLabel = planC{indexS.structures}(structNum).structureName;
        newGspsS(1).presentRGBColor = planC{indexS.structures}(structNum).structureColor;
        newGspsS(1).presentDescription = 'RTSTRUCT converted to GSPS using CERR';
        newGspsS(1).presentCreationDate = datestr(now,'yyyymmdd');
        newGspsS(1).SOPInstanceUID = planC{indexS.scan}(scanNum).scanInfo(slc).sopInstanceUID; % 00081140, 00081155
        newGspsS(1).annotUID = createUID('ANNOTATION');
        
        newGspsIndex = length(planC{indexS.GSPS}) + 1;
        planC{indexS.GSPS} = dissimilarInsert(planC{indexS.GSPS},newGspsS,newGspsIndex);
        
    end % slices loop
    
end % structures loop

if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    % Refresh View
    CERRRefresh
end
