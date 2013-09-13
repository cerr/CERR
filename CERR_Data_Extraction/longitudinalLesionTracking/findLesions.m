function lesionS = findLesions(scanNum,planC)
% function lesionS = findLesions(scanNum,planC)
%
% This function returns a structure array of lesions in the input scan.
%
% APA, 04/17/2013

indexS = planC{end};

slope = @(line) (line(2,2) - line(1,2))/(line(2,1) - line(1,1));
intercept = @(line,m) line(1,2) - m*line(1,1);
isPointInside = @(xint,myline) ...
    (xint >= myline(1,1) && xint <= myline(2,1)) || ...
    (xint >= myline(2,1) && xint <= myline(1,1));

% Initialize lesionS structure
lesionS = struct('assocScanUID','','assocAnnotUID','','graphicNumsV','','xV',[],'yV',[], 'zV', [],...
    'rowV',[], 'colV',[], 'lengthV', [], 'imageNumV', [], 'xIntersect', [], 'yIntersect', []);
lesionS(1) = [];

% Build a list of slices that are annotated
for slcNum=1:length(planC{indexS.scan}(scanNum).scanInfo)
    SOPInstanceUIDc{slcNum} = planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SOPInstanceUID;
end
numSignificantSlcs = length(planC{indexS.GSPS});
matchingSliceIndV = [];
matchingGSPSIndV = [];
for i=1:numSignificantSlcs
    sliceNum = strmatch(planC{indexS.GSPS}(i).SOPInstanceUID, SOPInstanceUIDc, 'exact');
    sliceNumsC{i} = sliceNum;
    if ~isempty(sliceNum)
        matchingSliceIndV = [matchingSliceIndV sliceNum];
        matchingGSPSIndV = [matchingGSPSIndV i];
    end
end
Dims = size(planC{indexS.scan}(scanNum).scanArray);
Dims(3) = [];
gridUnits = [planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
offset = [planC{indexS.scan}(scanNum).scanInfo(1).yOffset planC{indexS.scan}(scanNum).scanInfo(1).xOffset];
[~,~,zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
count = 0;
for gspsNum = matchingGSPSIndV
    count = count + 1;
    if ~isempty(planC{indexS.GSPS}(gspsNum).graphicAnnotationS)
        remainingGraphicNumV = find(strcmpi({planC{indexS.GSPS}(gspsNum).graphicAnnotationS.graphicAnnotationType},'POLYLINE'));
        for graphicNum = 1:length(planC{indexS.GSPS}(gspsNum).graphicAnnotationS)
            graphicAnnotationType = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(graphicNum).graphicAnnotationType;
            if strcmpi(graphicAnnotationType,'POLYLINE')
                % Check whether this graphic is already combined with another
                if ~ismember(graphicNum,remainingGraphicNumV)
                    continue
                end
                lesionS(end+1).assocAnnotUID = planC{indexS.GSPS}(gspsNum).annotUID;
                lesionS(end).graphicNumsV = graphicNum;
                lesionS(end).assocScanUID = planC{indexS.scan}(scanNum).scanUID;
                
                % Add this graphic to lesion
                graphicAnnotationData = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(graphicNum).graphicAnnotationData;
                rowV = graphicAnnotationData(1:2:end);
                colV = graphicAnnotationData(2:2:end);
                [xV, yV] = mtoaapm(colV, rowV, Dims, gridUnits, offset); 
                lesionS(end).xV = [lesionS(end).xV; xV];
                lesionS(end).yV = [lesionS(end).yV; yV];
                lesionS(end).zV = [lesionS(end).zV; zValsV(matchingSliceIndV(count))*xV.^0];
                lesionS(end).rowV = [lesionS(end).rowV; rowV];
                lesionS(end).colV = [lesionS(end).colV; colV];
                len = sqrt(diff(xV)^2+diff(yV)^2);
                lesionS(end).lengthV = [lesionS(end).lengthV; len];
                lesionS(end).imageNumV = [lesionS(end).imageNumV; matchingSliceIndV(count)];
                
                % Get in-between points
%                 x1 = xV(1);
%                 x2 = xV(2);
%                 y1 = yV(1);
%                 y2 = yV(2);
%                 slope = (y2-y1)/(x2-x1);
%                 yIntercept = y1 - slope*x1;
%                 xVox = linspace(x1,x2,500);
%                 yVox = slope*xVox + yIntercept;
%                 zVox = zValsV(matchingSliceIndV(count))*xVox.^0;
%                 lesionS(end).xV = [lesionS(end).xV; xVox];
%                 lesionS(end).yV = [lesionS(end).yV; yVox];
%                 lesionS(end).zV = [lesionS(end).zV; zVox];
                
                
                
                % Find corresponding cross-line on this slice
                indCurrentGraphic = find(remainingGraphicNumV == graphicNum);
                tmpRemGraphicV = remainingGraphicNumV;
                tmpRemGraphicV(indCurrentGraphic) = [];                
                for remainingGraphicNum = tmpRemGraphicV
                    % Determine if any of POLYLINES intersect with the
                    % current POLYLINE
                    graphicAnnotationData = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(remainingGraphicNum).graphicAnnotationData;                    
                    rowV = graphicAnnotationData(1:2:end);
                    colV = graphicAnnotationData(2:2:end);
                    [xRemV, yRemV] = mtoaapm(colV, rowV, Dims, gridUnits, offset);                    
%                     figure, hold on,
%                     plot(xV,yV)
%                     plot(xRemV,yRemV)
                    %intersectFlag = det([1,1,1;xV',xRemV(1);yV(1),yRemV'])*det([1,1,1;xV',xRemV(2);yV',yRemV(2)]) <= 0 && det([1,1,1;xV(1),xRemV';yV(1),yRemV'])*det([1,1,1;xV(2),xRemV';yV(2),yRemV']) <= 0;                    
                    line1 = [xV+rand(2,1)*1e-4 yV];
                    line2 = [xRemV+rand(2,1)*1e-4 yRemV];
                    m1 = slope(line1);
                    m2 = slope(line2);
                    intercept = @(line,m) line(1,2) - m*line(1,1);
                    b1 = intercept(line1,m1);
                    b2 = intercept(line2,m2);
                    xintersect = (b2-b1)/(m1-m2);
                    yintersect = m1*xintersect + b1;
                    intersectFlag = isPointInside(xintersect,line1) && isPointInside(xintersect,line2);
                    if intersectFlag
                        indRemGraphic = find(remainingGraphicNumV == remainingGraphicNum);
                        remainingGraphicNumV([indRemGraphic indCurrentGraphic]) = [];
                        lesionS(end).graphicNumsV = [lesionS(end).graphicNumsV remainingGraphicNum];
                        lesionS(end).xV = [lesionS(end).xV; xRemV];
                        lesionS(end).yV = [lesionS(end).yV; yRemV];
                        lesionS(end).zV = [lesionS(end).zV; zValsV(matchingSliceIndV(count))*xRemV.^0];
                        lesionS(end).rowV = [lesionS(end).rowV; rowV];
                        lesionS(end).colV = [lesionS(end).colV; colV];
                        len = sqrt(diff(xRemV)^2+diff(yRemV)^2);
                        lesionS(end).lengthV = [lesionS(end).lengthV; len];
                        lesionS(end).imageNumV = [lesionS(end).imageNumV; matchingSliceIndV(count)];
                        lesionS(end).xIntersect = xintersect;
                        lesionS(end).yIntersect = yintersect;                        
                    end
                end
            end
        end
    end
end
