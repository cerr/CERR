function planC = createPlanCFromFiles(fileNamesC, structures_to_extractC, dose_to_extractC)
%function planC = createPlanCFromFiles(fileNamesC, structures_to_extractC, dose_to_extractC)
%
%This function creates a planC data structure from the passed file names.
%This planC is further used to load into CERR.
%
%APA, 10/18/2010

clear global planC
global planC stateS

%parentDir = '/Users/aptea/Documents/MSKCC/Projects/FCCC/FCCC_uncompressed_cerr_plans/';
%parentDir = '\\.psf\MSKCC\Projects\FCCC\FCCC_uncompressed_cerr_plans';


% fileNamesC = {fullfile(parentDir,'1003'),fullfile(parentDir,'1004'),fullfile(parentDir,'1005'),fullfile(parentDir,'1006'),fullfile(parentDir,'1007'),fullfile(parentDir,'1008'),fullfile(parentDir,'1009'),fullfile(parentDir,'1010'),fullfile(parentDir,'1011')};
%fileNamesC = {fullfile(parentDir,'1003'),fullfile(parentDir,'1004'),fullfile(parentDir,'1005'),fullfile(parentDir,'1006'),fullfile(parentDir,'1007'),fullfile(parentDir,'1008'),fullfile(parentDir,'1009'),fullfile(parentDir,'1010'),fullfile(parentDir,'1011'),fullfile(parentDir,'1012'),fullfile(parentDir,'1013'),fullfile(parentDir,'1014'),fullfile(parentDir,'1015'),fullfile(parentDir,'1016'),fullfile(parentDir,'1017'),fullfile(parentDir,'1018')};

numFiles = length(fileNamesC);
hWait = waitbar(0,'Opening scans...');
maxDoseVal = 0;
for fileNum = 1:numFiles
    planD = openPlanCFromFile(fileNamesC{fileNum});
    
    
    %Crop Scan based on structure selected
    %cropScan(scanNum,structureNum,margin)
    
    indexSD = planD{end};
    
    %     indMatchV = getMatchingIndex('prostate',{planD{indexSD.structures}.structureName});
    %
    %     if length(indMatchV) == 1
    %        structureNum = indMatchV;
    %     else
    %         structureNum = 1;
    %     end
    
    
    if length(structures_to_extractC{fileNum}) == 1
        structureNum = structures_to_extractC{fileNum};
    else
        structureNum = 1;
    end
    
    toDelete = 1:length(planD{indexSD.structures});
    toDelete(structureNum) = [];
    
    scanNum = 1;
    margin = 0.5;
    
    %Record associated Doses to reassign UIDs later
    assocScanV = getDoseAssociatedScan(1:length(planD{indexSD.dose}), planD);
    assocDoseV = find(assocScanV == scanNum);
    
    %Get associated scan number
    assocScanNum = getStructureAssociatedScan(structureNum, planD);
    tmAssocScan = getTransM('scan',assocScanNum,planD);
    tmScan = getTransM('scan',scanNum,planD);
    if ~isequal(tmAssocScan,tmScan)
        error('This function currently supports dose and structure with same transformation matrix')
    end
    
    %Get scan grid
    [xScanVals, yScanVals, zScanVals] = getScanXYZVals(planD{indexSD.scan}(scanNum));
    
    %Get structure boundary
    rasterSegments = getRasterSegments(structureNum,planD);
    zMin = min(rasterSegments(:,1)) - margin;
    zMax = max(rasterSegments(:,1)) + margin;
    xMin = min(rasterSegments(:,3)) - margin;
    xMax = max(rasterSegments(:,4)) + margin;
    yMin = min(rasterSegments(:,2)) - margin;
    yMax = max(rasterSegments(:,2)) + margin;
    
    %Get min, max indices of scanArray
    [JLow, jnk] = findnearest(xScanVals, xMin);
    [jnk, JHigh] = findnearest(xScanVals, xMax);
    [jnk, ILow] = findnearest(yScanVals, yMin);
    [IHigh, jnk] = findnearest(yScanVals, yMax);
    [KLow, jnk] = findnearest(zScanVals, zMin);
    [jnk, KHigh] = findnearest(zScanVals, zMax);
    
    %Crop scanArray
    planD{indexSD.scan}(scanNum).scanArray = planD{indexSD.scan}(scanNum).scanArray(IHigh:ILow,JLow:JHigh,KLow:KHigh);
    
    sizeDim1 = length(IHigh:ILow);
    sizeDim2 = length(JLow:JHigh);
    xOffset = xScanVals(JLow) + (sizeDim2*planD{indexSD.scan}(scanNum).scanInfo(1).grid2Units)/2;
    yOffset = yScanVals(ILow) + (sizeDim1*planD{indexSD.scan}(scanNum).scanInfo(1).grid1Units)/2;
    
    %Reassign zvalues
    for i=1:length(KLow:KHigh)
        %planD{indexSD.scan}(scanNum).scanInfo(i).zValue = zScanVals(KLow+i-1);
        planD{indexSD.scan}(scanNum).scanInfo(KLow+i-1).sizeOfDimension1 = sizeDim1;
        planD{indexSD.scan}(scanNum).scanInfo(KLow+i-1).sizeOfDimension2 = sizeDim2;
        planD{indexSD.scan}(scanNum).scanInfo(KLow+i-1).xOffset = xOffset;
        planD{indexSD.scan}(scanNum).scanInfo(KLow+i-1).yOffset = yOffset;
    end
    
    planD{indexSD.scan}(scanNum).scanInfo([1:KLow-1, KHigh+1:end]) = [];
    
    assocScanV = getStructureAssociatedScan(1:length(planD{indexSD.structures}), planD);
    
    indAssocV = find(assocScanV == scanNum);
    
    %Retain only structure slices which are present on new scan
    for structNum = indAssocV
        planD{indexSD.structures}(structNum).contour([1:KLow-1, KHigh+1:end]) = [];
        planD{indexSD.structures}(structNum).rasterSegments = [];
    end
    
    %Create new UID since this scan has changed
    planD{indexSD.scan}(scanNum).scanUID = createUID('scan');
    for structNum = indAssocV
        planD{indexSD.structures}(structNum).assocScanUID = planD{indexSD.scan}(scanNum).scanUID;
        planD{indexSD.structures}(structNum).strUID = createUID('structure');
    end
    
    planD{indexSD.structures}(toDelete) = [];
    
    %Retain only the selected dose
    planD{indexSD.dose} = planD{indexSD.dose}(dose_to_extractC{fileNum});   
    
    maxDoseVal = NaN;
    
    %Reassociate Dose to cropped scan
    if ~isempty(planD{indexSD.dose})
        planD{indexSD.dose}(1).assocScanUID = ...
            planD{indexSD.scan}(scanNum).scanUID;
        maxDoseVal = max([maxDoseVal, max(planD{indexSD.dose}.doseArray(:))]);  
    end
    
    if fileNum == 1
        planC = planD;
    elseif fileNum > 1
        scanIndV = 1;
        structIndV = 1:length(planD{indexSD.structures});
        doseIndV = dose_to_extractC{fileNum};
        planC = planMerge(planC, planD, scanIndV, doseIndV, structIndV, fileNamesC{fileNum});
    end
    
    waitbar(fileNum/numFiles,hWait)

end

close(hWait);

stateS.CTDisplayChanged = 1;
stateS.doseDisplayChanged = 1;
stateS.structsChanged = 1;
stateS.doseDisplayRange = [0 maxDoseVal];
stateS.colorbarRange = [0 maxDoseVal];
stateS.doseArrayMaxValue = maxDoseVal;
stateS.colorbarFrameMax = maxDoseVal;

clear planD

planC = reRasterAndUniformize(planC);

indexS = planC{end};

%Obtain COM and apply transM
[xRef,yRef,zRef] = calcIsocenter(1, 'COM', planC);
transM = eye(4);
xTref = 0;
yTref = 0;
zTref = 0;
transM(1,4) = xTref;
transM(2,4) = yTref;
transM(3,4) = zTref;
planC{indexS.scan}(1).transM = transM;
for structNum = 1:16
    [xC,yC,zC] = calcIsocenter(structNum, 'COM', planC);
    %Create transM based on difference between COM
    xT = xRef - xC;
    yT = yRef - yC;
    zT = zRef - zC;
    transM = eye(4);
    transM(1,4) = xT;
    transM(2,4) = yT;
    transM(3,4) = zT;
    planC{indexS.scan}(structNum).transM = transM;
end



% ------------------ Open plan in CERR
if isfield(stateS,'handle')
    hCSV = stateS.handle.CERRSliceViewer;
else
    hCSV = [];
end
if isempty(hCSV) || ~exist('hCSV') || ~ishandle(hCSV)
    %CERR('CERRSLICEVIEWER')
    sliceCallBack('init');
end
sliceCallBack('OPENWORKSPACEPLANC')
set(stateS.handle.CERRSliceViewer,'visible','off');
hWait = waitbar(0.5,'Starting Viewer...');

numAxesOld = length(stateS.handle.CERRAxis);

scanNumsV = 1:16; % can be passed as input

cohortAxesIndexV = 1:16; % default to first 16 if layout is 8

if stateS.layout ~= 8
    
    % ------------------ Duplicate Transverse Axis 15 times to create 4x4 grid
    for indAxis = 1:length(stateS.handle.CERRAxis)
        aI = getAxisInfo(stateS.handle.CERRAxis(indAxis));
        if strcmpi(aI.view,'transverse')
            break;
        end
    end
    
    bottomAxes = 1:numAxesOld;
    bottomAxes(indAxis) = [];
    
    
    for iDuplicate = 1:15
        sliceCallBack('DUPLICATELINKAXIS', stateS.handle.CERRAxis(indAxis))
    end   
    
    
    %Order Axes
    cohortAxesIndexV = [indAxis numAxesOld+1:length(stateS.handle.CERRAxis)];
    CERRAxis_tmp = [stateS.handle.CERRAxis(cohortAxesIndexV) stateS.handle.CERRAxis(bottomAxes)];
    CERRAxisLabel1_tmp = [stateS.handle.CERRAxisLabel1(cohortAxesIndexV) stateS.handle.CERRAxisLabel1(bottomAxes)];
    CERRAxisLabel2_tmp = [stateS.handle.CERRAxisLabel2(cohortAxesIndexV) stateS.handle.CERRAxisLabel2(bottomAxes)];
    CERRAxisLabel3_tmp = [stateS.handle.CERRAxisLabel3(cohortAxesIndexV) stateS.handle.CERRAxisLabel3(bottomAxes)];
    CERRAxisLabel4_tmp = [stateS.handle.CERRAxisLabel4(cohortAxesIndexV) stateS.handle.CERRAxisLabel4(bottomAxes)];
    CERRAxisPlnLoc_tmp = [stateS.handle.CERRAxisPlnLoc(cohortAxesIndexV) stateS.handle.CERRAxisPlnLoc(bottomAxes)];
    CERRAxisPlnLocSdw_tmp = [stateS.handle.CERRAxisPlnLocSdw(cohortAxesIndexV) stateS.handle.CERRAxisPlnLocSdw(bottomAxes)];
    CERRAxisScale1_tmp = [stateS.handle.CERRAxisScale1(cohortAxesIndexV) stateS.handle.CERRAxisScale1(bottomAxes)];
    CERRAxisScale2_tmp = [stateS.handle.CERRAxisScale2(cohortAxesIndexV) stateS.handle.CERRAxisScale2(bottomAxes)];
    CERRAxisTicks1_tmp = [stateS.handle.CERRAxisTicks1(cohortAxesIndexV,:); stateS.handle.CERRAxisTicks1(bottomAxes,:)];
    CERRAxisTicks2_tmp = [stateS.handle.CERRAxisTicks2(cohortAxesIndexV,:); stateS.handle.CERRAxisTicks2(bottomAxes,:)];
    aI_tmp = [stateS.handle.aI(cohortAxesIndexV) stateS.handle.aI(bottomAxes)];
    
    stateS.handle.CERRAxis = CERRAxis_tmp;
    stateS.handle.CERRAxisLabel1 = CERRAxisLabel1_tmp;
    stateS.handle.CERRAxisLabel2 = CERRAxisLabel2_tmp;
    stateS.handle.CERRAxisLabel3 = CERRAxisLabel3_tmp;
    stateS.handle.CERRAxisLabel4 = CERRAxisLabel4_tmp;

    stateS.handle.CERRAxisPlnLoc = CERRAxisPlnLoc_tmp;
    stateS.handle.CERRAxisPlnLocSdw = CERRAxisPlnLocSdw_tmp;
    stateS.handle.CERRAxisScale1 = CERRAxisScale1_tmp;
    stateS.handle.CERRAxisScale2 = CERRAxisScale2_tmp;
    stateS.handle.CERRAxisTicks1 = CERRAxisTicks1_tmp;
    stateS.handle.CERRAxisTicks2 = CERRAxisTicks2_tmp;
    
    stateS.handle.aI = aI_tmp;
    
end

%Assign scans, doses and structures to all axes
for iAxis = 1:length(scanNumsV)
    dosesV = getScanAssociatedDose(scanNumsV(iAxis));
    if isempty(dosesV)
        setAxisInfo(stateS.handle.CERRAxis(iAxis), 'structureSets', scanNumsV(iAxis) , 'structSelectMode', 'manual',...
            'scanSelectMode', 'manual', 'scanSets', scanNumsV(iAxis), 'doseSelectMode', 'manual');
    else
        setAxisInfo(stateS.handle.CERRAxis(iAxis), 'structureSets', scanNumsV(iAxis) , 'structSelectMode', 'manual',...
            'scanSelectMode', 'manual', 'scanSets', scanNumsV(iAxis), 'doseSelectMode', 'manual', 'doseSets',dosesV(1) ,'doseSetsLast', dosesV(1));
    end
end

stateS.layout = 8;
sliceCallBack('resize',8)

CERRRefresh

%--- Change window level

presetWindowNum = 1;  %Custom preset option  

%change windowing across all axes
for n = 1:length(stateS.handle.CERRAxis)
    
    scanSet = stateS.handle.aI(n).scanSets;
    
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
    
    stateS.scanStats.CTLevel.(scanUID) = stateS.optS.windowPresets(presetWindowNum).center;
    stateS.scanStats.CTWidth.(scanUID) = stateS.optS.windowPresets(presetWindowNum).width;
    
    stateS.scanStats.windowPresets.(scanUID) = presetWindowNum;
    
    %Set intensity window
    pct = 0.80;
    sAv = planC{indexS.scan}(scanSet).scanArray(:);
    indV = find(sAv);
    sA_no_empty = sAv(indV);
    sA_no_empty = sort(sA_no_empty);
    intensityPct = double(sA_no_empty(round(pct*length(indV))));
    intensityCtr = double(sA_no_empty(round(0.3*length(indV))));
    stateS.scanStats.CTLevel.(scanUID) = intensityCtr;
    stateS.scanStats.CTWidth.(scanUID) = intensityPct;
    
end

updateScanColorbar(scanSet);

stateS.CTDisplayChanged = 1;

stateS.showPlaneLocators = xor(stateS.showPlaneLocators, 1);
close(hWait);
CERRRefresh
set(stateS.handle.CERRSliceViewer,'visible','on');


end

