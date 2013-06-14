function write_annotation_images_to_disk(absolutePathForImageFiles,cerrFileName,scanNum, annotXYZ, lesionNum, annotColor)

global planC stateS

planC = loadPlanC(cerrFileName,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(cerrFileName, planC);
indexS = planC{end};

% Open planC in CERR viewer
if isfield(stateS,'handle')
    hCSV = stateS.handle.CERRSliceViewer;
else
    hCSV = [];
end
if isempty(hCSV) || ~exist('hCSV') || ~ishandle(hCSV)
    CERR('CERRSLICEVIEWER')
end

stateS.scanSet = 1;

stateS.CTToggle = 1;
stateS.CTDisplayChanged = 1;
sliceCallBack('OPENWORKSPACEPLANC')

% Toggle plane locators
stateS.showPlaneLocators = 0;
CERRRefresh

% Set Dose Alpha value to 1
stateS.doseAlphaValue.trans = 0;
CERRRefresh

% Get coordinates
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(1));

%Show all HUs
CTOffset = planC{indexS.scan}(1).scanInfo(1).CTOffset;
minHU = double(min(planC{indexS.scan}.scanArray(:))) - CTOffset;
maxHU = double(max(planC{indexS.scan}.scanArray(:))) - CTOffset;
widthHU = (maxHU - minHU)/2;
centerHU = minHU + widthHU;
stateS.optS.CTWidth = widthHU*2;
stateS.optS.CTLevel = centerHU;
try
    stateS.optS.CTWidth = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.WindowWidth;
catch
    stateS.optS.CTWidth = 300;
end
try
    stateS.optS.CTLevel = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.WindowCenter;
catch
    stateS.optS.CTLevel = 10;
end

%Toggle dose off
stateS.doseToggle = -1;
stateS.doseSetChanged = 1;

%Toggle scan on
stateS.CTToggle = 1;
stateS.CTDisplayChanged = 1;

%setAxisInfo(stateS.handle.CERRAxis(1), 'scanSelectMode', 'manual', 'scanSets', scanNum, 'doseSelectMode', 'manual', 'doseSets', [] ,'doseSetsLast', [], 'view', viewType);
viewType = 'transverse';
setAxisInfo(stateS.handle.CERRAxis(1), 'view', viewType, 'scanSelectMode', 'auto', 'doseSelectMode', 'auto', 'structSelectMode','auto');

%Set layout to display one large window
stateS.layout = 1;
sliceCallBack('resize',1)

%Toggle structures off
sliceCallBack('VIEWNOSTRUCTURES')

%Set scan to scanNum
currentScanNum = 1;
sliceCallBack('SELECTSCAN',num2str(currentScanNum))

% Zoopin to +/- 5cm around lesion
minX = max(min(annotXYZ(:,1))-10,xVals(1));
maxX = min(max(annotXYZ(:,1))+10,xVals(end));
minY = max(min(annotXYZ(:,2))-10,yVals(end));
maxY = min(max(annotXYZ(:,2))+10,yVals(1));
setAxisInfo(stateS.handle.CERRAxis(1), 'xRange', [minX maxX], 'yRange', [minY maxY]);
zoomToXYRange(stateS.handle.CERRAxis(1));
%Redraw locators
showPlaneLocators;
%Update scale
indAxis = find(stateS.handle.CERRAxis(1) == stateS.handle.CERRAxis);
showScale(stateS.handle.CERRAxis(1), indAxis)

CERRRefresh

drawnow;

zCoord = annotXYZ(1,3);
setAxisInfo(stateS.handle.CERRAxis(1), 'coord', zCoord);
CERRRefresh
drawnow;

for i=1:2:size(annotXYZ,1)
    plot(annotXYZ(i:i+1,1),annotXYZ(i:i+1,2),annotColor,'linewidth',2,'parent',stateS.handle.CERRAxis(1))
end

% Capture image
F = getframe(stateS.handle.CERRAxis(1));
scanUID = planC{indexS.scan}(1).scanUID;
imwrite(F.cdata, fullfile(absolutePathForImageFiles,['scan_',scanUID,'_',num2str(lesionNum),'.png']), 'png','XResolution',47200,'YResolution',47200,'ResolutionUnit','meter');
