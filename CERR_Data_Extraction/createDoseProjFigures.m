% createDoseProjFigures.m

% Load structure and dose indices
load('/Volumes/deasylab1/Data/PHI_DATA_STORED_HERE/doseNumers.mat')

dirPath = '/Volumes/deasylab1/Data/PHI_DATA_STORED_HERE/WULung_TCP_ExtraCont';

absolutePathForImageFiles = '/Volumes/deasylab1/Data/PHI_DATA_STORED_HERE/Dose_Proj_Images_for_wustl_TCP_paper';    

%Find all CERR files
fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];

minimumDose = 56.4666;
fileWithMinGTVDose = '972574_set01_aapm';
maximumDose = 88.9317;
fileWithMaxGTVDose = '983000_aapm-structs';

minimumProjDose = 33.2689;
fileWithMinProjGTVDose = '983000_aapm-structs';
maximumProjDose = 88.7412;
fileWithMaxProjGTVDose = '983000_aapm-structs';

minimumProjDose = 48.3504;
fileWithMinProjGTVDose = 'E910421_set01_aapm';
maximumProjDose = 88.7412;
fileWithMaxProjGTVDose = '983000_aapm-structs';



% Load DREES file to obtain outcomes
load('/Volumes/deasylab1/Data/PHI_DATA_STORED_HERE/LungWU_TCP.mat')
dreesPlanNamesC = {dBase.PlanName};
dreesOutcomesV = [dBase.outcome];

%Loop over CERR plans
for iFile=1:length(fileC)
    
    drawnow
    
    global planC stateS
    
    try
        planC = loadPlanC(fileC{iFile},tempdir);
        planC = updatePlanFields(planC);
        indexS = planC{end};
    catch
        continue
    end
    
    if isfield(stateS,'handle')
        hCSV = stateS.handle.CERRSliceViewer;
    else
        hCSV = [];
    end
    if isempty(hCSV) || ~exist('hCSV') || ~ishandle(hCSV)
        CERR('CERRSLICEVIEWER')
    end
    
    stateS.CTToggle = 1;
    stateS.CTDisplayChanged = 1;
    sliceCallBack('OPENWORKSPACEPLANC')
    
    % Quality assurance
    quality_assure_planC
    
    indexS = planC{end};
%         
    [dirName,fileName] = fileparts(fileC{iFile});    
    
    indPlan = getMatchingIndex(fileName,planName);
    
    indDREESPlan = getMatchingIndex(fileName,dreesPlanNamesC);
    
    tcp = dreesOutcomesV(indDREESPlan);
    
    skinIndex = skinIndexs(indPlan);
    cordIndex = spinalCordIndexs(indPlan);
    gtvIndex = GTVIndexs(indPlan);
    doseIndex = doseNumV(indPlan);
    
    % Re Uniformize to create Skin
    planC{indexS.CERROptions}.uniformizeExcludeStructs = '';
    reRasterAndUniformize
    
    % Change color of slin and cord to black
    if tcp == 1
        planC{indexS.structures}(skinIndex).structureColor = [0 1 0];
    else
        planC{indexS.structures}(skinIndex).structureColor = [1 0 0];
    end
    planC{indexS.structures}(cordIndex).structureColor = [0 0 0];  
    
    
    % Set dose colormap
    stateS.optS.doseColormap = 'starinterp';
    doseShadowGui('init')
    ud = get(stateS.handle.doseShadowFig,'userData');
    set(ud.handles.printBox, 'Value',1)
    set(ud.handles.doseSet, 'Value',doseIndex);
    %ud.structure = gtvIndex+1;
    ud.structure = gtvIndex;
    ud.mode = 'min';
    set(stateS.handle.doseShadowFig,'userData',ud);
    doseShadowGui('INITSTRUCTS')
    doseShadowGui('SELECTDOSESET')
    doseShadowGui('STRUCTURETOGGLE',skinIndex)
    doseShadowGui('STRUCTURETOGGLE',cordIndex)
    % doseShadowGui('STRUCTURETOGGLE',gtvIndex)
    doseShadowGui('draw', gtvIndex, 'min', doseIndex);
    doseShadowGui('SETAXISLIMITS')
    
    % Write image to disk    
    F = getframe(ud.handles.axis.upperleft);
    imwrite(F.cdata, fullfile(absolutePathForImageFiles,[fileName,'.png']), 'png');


    
    [xUnifV, yUnifV, zUnifV] = getUniformScanXYZVals(planC{indexS.scan});
    [rowV, colV, slcV] = getUniformStr(gtvIndex);
    xV = xUnifV(colV);
    yV = yUnifV(rowV);
    zV = zUnifV(slcV);
    dosesV = getDoseAt(doseIndex, xV, yV, zV, planC);
    indV = getUniformStr(gtvIndex);
    sizeArray = getUniformScanSize(planC{indexS.scan});
    mask3M = ones(sizeArray);
    mask3M = NaN*mask3M;
    mask3M(indV) = dosesV;
    projMaskM = min(mask3M,[],3);
    minDoseV(iFile) = min(projMaskM(:));
    maxDoseV(iFile) = max(projMaskM(:));
    %minDoseV(iFile) = min(planC{indexS.dose}(doseIndex).doseArray(:));
    %maxDoseV(iFile) = max(planC{indexS.dose}(doseIndex).doseArray(:));
    fileListC{iFile} = fileName;
    v75(iFile) = Vx(planC, gtvIndex, doseIndex, 75, 'Percent');
    gtvVolume(iFile) = getStructureVol(gtvIndex,planC);
    
    delete(stateS.handle.doseShadowFig)   
    delete(stateS.handle.CERRSliceViewer)
    clear global planC stateS
    
end


% % Create grid plot with all patients
% dirS = dir(absolutePathForImageFiles);
% dirS = dirS(end-55:end);
% axisNum = 1;
% figure, hold on,
% for rowNum = 1:8
%     for colNum = 1:7
%         imageName = fullfile(absolutePathForImageFiles,dirS(axisNum).name);
%         %subplot(8,7,axisNum)
%         [background, map] = imread(imageName,'png');
%         image(background, 'CDataMapping', 'direct');
%         axis off
%         axis image
%         axisNum = axisNum + 1;
%     end
% end

% Load DREES file to obtain outcomes
load('/Volumes/deasylab1/Data/PHI_DATA_STORED_HERE/LungWU_TCP.mat')
dreesPlanNamesC = {dBase.PlanName};
dreesOutcomesV = [dBase.outcome];

% Load v75 and gtvVolume
load('/Volumes/deasylab1/Data/PHI_DATA_STORED_HERE/v75_and_vol.mat')

% Create grid plot with all patients
dirS = dir(absolutePathForImageFiles);
dirS = dirS(end-55:end);

% Reorder dirS according to v75 and gtvVolume
v75_orderedV = [];
for fileNum = 1:length(dirS)
    fileName = strtok(dirS(fileNum).name,'.');
    indV75 = getMatchingIndex(fileName,fileListC);
    v75_orderedV = [v75_orderedV indV75];
end

%[v75_sorted,indSorted] = sort(v75);
[v75_sorted,indSorted] = sort(gtvVolume,'descend');
indNewV = [];
for i = 1:8:49
    indBin = indSorted(i:i+7);
    %gtv_vols_bin = gtvVolume(indBin);    
    gtv_vols_bin = v75(indBin);    
    [jnk,indGTV] = sort(gtv_vols_bin,'descend');
    indNewV = [indNewV indBin(indGTV)];    
end

indNewV_tmp = reshape(indNewV,8,7);
indNewV_tmp1 = indNewV_tmp';
dirS = dirS(indNewV_tmp1(:));

figure('color',[1 1 1]), delete(gca)
ha = tight_subplot(8,7,[.01 .01],[.01 .01],[.01 .01]);
for axisNum = 1:length(ha)
    imageName = fullfile(absolutePathForImageFiles,dirS(axisNum).name);
    % Get TCP outcome
    fileName = strtok(dirS(axisNum).name,'.');
    indPlan = getMatchingIndex(fileName,dreesPlanNamesC);
    indV75 = getMatchingIndex(fileName,fileListC);
    v75_val = v75(indV75);
    gtvVol_val = gtvVolume(indV75);
    cEUD_val = cEUD(indV75);
    tcp = dreesOutcomesV(indPlan);
    axes(ha(axisNum))
    [background, map] = imread(imageName,'png');
    % image(background, 'CDataMapping', 'direct');
    image(background, 'parent',ha(axisNum));
    xLim = get(ha(axisNum),'xLim');
    yLim = get(ha(axisNum),'yLim');
    xLoc = xLim(1) + (xLim(2)-xLim(1))/2;
    yLoc = yLim(1) + (yLim(2)-yLim(1))*0.2;    
    text(xLoc,yLoc,sprintf('%3.0f',v75_val*100),'HorizontalAlignment','center','fontSize',18) 
    %text(xLoc,yLoc,sprintf('%3.1f',cEUD_val),'HorizontalAlignment','center','interpreter','none','fontSize',14) 
    axis(ha(axisNum),'off')
    axis(ha(axisNum),'equal')
%     if tcp == 1
%         axis(ha(axisNum),'off')
%     else
%         set(ha(axisNum),'XTick',[],'XTickLabel',[],'YTick',[],'YTickLabel',[],'color',[0 0 0])
%         axis image
%         box(ha(axisNum),'on')
%     end
end

