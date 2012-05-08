function createROI(xyzCoord,xyzWidth,scanNum,planC)
% function createROI(xyzCoord)
%
% APA, 05/04/2012

if ~exist('planC','var')
    global planC
end
indexS = planC{end};
global stateS

if ~exist('xyzCoord','var')
    msgText = 'click on an axis to obtain point to create ROI around it';
    hMsg = msgbox(msgText,'Click to get a point');
    [x,y] = ginput(1);
    close(hMsg)
    % get View that was clicked
    viewType = getAxisInfo(gca,'view');
    switch upper(viewType)
        case 'TRANSVERSE'
            z = getAxisInfo(gca,'coord');
        case 'SAGITTAL'
            z = y;
            y = x;
            x = getAxisInfo(gca,'coord');            
        case 'CORONAL'
            z = y;
            y = getAxisInfo(gca,'coord');   
    end
    
else
    
    x = xyzCoord(1);
    y = xyzCoord(2);
    z = xyzCoord(3);
    
end

if ~exist('xyzWidth','var')

    prompt={'Enter the ROI width in Sagital direction (cm):','Enter the ROI width in Coronal direction (cm):', 'Enter the ROI width in Transverse direction (cm):'};
    name='ROI Dimensions';
    numlines=1;
    defaultanswer={'3','3','3'};
    roiSizeC = inputdlg(prompt,name,numlines,defaultanswer);
    xWidth = str2num(roiSizeC{1});
    yWidth = str2num(roiSizeC{2});
    zWidth = str2num(roiSizeC{3});
    if isempty(xWidth) || isempty(yWidth) || isempty(zWidth)
        error('One or all the dimensions entered are invalid')
    end
    
else
    xWidth = xyzWidth(1);
    yWidth = xyzWidth(2);
    zWidth = xyzWidth(3);   
    
end

if ~exist('scanNum','var')
   scanNum = getAxisInfo(gca,'scanSets');
   scanNum = scanNum(1);
end

zMin = z - zWidth/2;
zMax = z + zWidth/2;
xMin = x - xWidth/2;
xMax = x + xWidth/2;
yMin = y - yWidth/2;
yMax = y + yWidth/2;

xV = [xMin xMax xMax xMin xMin];
yV = [yMin yMin yMax yMax yMin];
pointsM = [xV' yV'];

% get min and max slices
zValsV = [planC{indexS.scan}.scanInfo.zValue];
minSliceIndex = findnearest(zValsV,zMin);
maxSliceIndex = findnearest(zValsV,zMax);
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

newStructS.structureName    = ['ROI_',num2str(xWidth),'x',num2str(yWidth),'x',num2str(zWidth)];

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
planC = getRasterSegs(planC, newStructNum);
planC = updateStructureMatrices(planC, newStructNum, slcsV);

% Refresh View
CERRRefresh


