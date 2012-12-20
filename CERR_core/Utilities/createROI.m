function createROI(clipBoxMsg,planC)
% function createROI(clipBoxMsg, planC)
%
% APA, 05/04/2012

if ~exist('planC','var')
    global planC
end
indexS = planC{end};
global stateS

if nargin == 0
    ButtonName = questdlg('Draw clip-boxes on any of the two views', 'Create ROI', 'Continue', 'Cancel', 'Continue');
    if strcmpi(ButtonName, 'Continue')
        stateS.ROIcreationMode = 1;
        stateS.clipState = 1;
        figure(stateS.handle.CERRSliceViewer)
    end
    return;    
elseif nargin == 1 && strcmpi(clipBoxMsg,'clipBoxDrawn')
    clipHv = [];
    for axisNum = 1:length(stateS.handle.CERRAxis)
        clipHv = [clipHv findobj(stateS.handle.CERRAxis(axisNum),'tag','clipBox')];
    end
    if length(clipHv) ~= 2
        return;
    else        
        stateS.clipState = 0;        
        % Continue to create an ROI based on clip boxes
    end
end

xmin = Inf;
xmax = -Inf;
ymin = Inf;
ymax = -Inf;
zmin = Inf;
zmax = -Inf;

for axisNum = 1:length(stateS.handle.CERRAxis)    
    hClip = findobj(stateS.handle.CERRAxis(axisNum),'tag','clipBox');
    if ~isempty(hClip)
        axisView = getAxisInfo(stateS.handle.CERRAxis(axisNum),'view');
        switch upper(axisView)
            case 'TRANSVERSE'
                xData = get(hClip,'xData');
                yData = get(hClip,'yData');
                xmin = min([xData,xmin]);
                ymin = min([yData,ymin]);
                xmax = max([xData,xmax]);
                ymax = max([yData,ymax]);
            case 'SAGITTAL'
                yData = get(hClip,'xData');
                zData = get(hClip,'yData');
                ymin = min([yData,ymin]);
                zmin = min([zData,zmin]);
                ymax = max([yData,ymax]);
                zmax = max([zData,zmax]);                
            case 'CORONAL'
                xData = get(hClip,'xData');
                zData = get(hClip,'yData');
                xmin = min([xData,xmin]);
                zmin = min([zData,zmin]);
                xmax = max([xData,xmax]);
                zmax = max([zData,zmax]);
        end
    end
end

% delete clipbox
delete(clipHv)

scanNum = getAxisInfo(gca,'scanSets');
scanNum = scanNum(1);

xV = [xmin xmax xmax xmin xmin];
yV = [ymin ymin ymax ymax ymin];
pointsM = [xV' yV'];

% get min and max slices
zValsV = [planC{indexS.scan}(scanNum).scanInfo.zValue];
minSliceIndex = findnearest(zValsV,zmin);
maxSliceIndex = findnearest(zValsV,zmax);
slcsV = minSliceIndex:maxSliceIndex;

% Create a rectangular ROI on each transverse slice
newStructNum = length(planC{indexS.structures}) + 1;
newStructS = newCERRStructure(scanNum, planC);
for slcNum = slcsV    
    newStructS.contour(slcNum).segments(1).points = [pointsM zValsV(slcNum)*pointsM.^0];
end
for slcNum = 1:minSliceIndex-1    
    newStructS.contour(slcNum).segments.points = [];
end
for slcNum = maxSliceIndex+1:length(zValsV)
    newStructS.contour(slcNum).segments.points = [];
end

stateS.structsChanged = 1;

newStructS.structureName    = 'ROI';

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
planC = getRasterSegs(planC, newStructNum);
planC = updateStructureMatrices(planC, newStructNum, slcsV);

% Refresh View
CERRRefresh


