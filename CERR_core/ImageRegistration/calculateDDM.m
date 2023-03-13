function calculateDDM(basePlanCFile,ddmTemplatePlanCFileName,...
    registeredPlanCFilesDir,vfDir,saveFileLocationWithDDM)

% Linux
basePlanCFile = '/lab/deasylab1/Data/RTOG0617/CERR_files_tcia/rider_template/RIDER-1225316081_First_resampled_1x1x3.mat';
ddmTemplatePlanCFileName = '0617-548359_09-09-2000-30377';
registeredPlanCFilesDir = '/lab/deasylab1/Data/RTOG0617/CERR_files_tcia/dose_mapping_original_plans'; % RTOG0617
vfDir = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/ddm/RTOG0617_to_RIDER_1225316081_First_template'; %RIDER RIDER-1225316081
saveFileLocationWithDDM = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/ddm/RTOG0617_to_RIDER_1225316081_First_template_ddm.mat';

% Windows
% basePlanCFile = 'L:/Data/RTOG0617/CERR_files_tcia/rider_template/RIDER-1225316081_First_resampled_1x1x3.mat';
% ddmTemplatePlanCFileName = '0617-548359_09-09-2000-30377';
% registeredPlanCFilesDir = 'L:/Data/RTOG0617/CERR_files_tcia/dose_mapping_original_plans'; % RTOG0617
% vfDir = 'L:/Data/RTOG0617/registrations_pericardium/ddm/RTOG0617_to_RIDER_1225316081_First_template'; %RIDER RIDER-1225316081
% saveFileLocationWithDDM = 'L:/Data/RTOG0617/registrations_pericardium/ddm/RTOG0617_to_RIDER_1225316081_First_template_ddm.mat';
% 
% basePlanCFile = strrep(basePlanCFile,'/','\');
% ddmTemplatePlanCFileName = strrep(ddmTemplatePlanCFileName,'/','\');
% registeredPlanCFilesDir = strrep(registeredPlanCFilesDir,'/','\');
% vfDir = strrep(vfDir,'/','\');
% saveFileLocationWithDDM = strrep(saveFileLocationWithDDM,'/','\');

[~,basePlanCFileName] = fileparts(basePlanCFile);


% registeredPlanCFilesDir = 'L:\Data\RTOG0617\registrations_pericardium\ddm\RTOG0617_to_RIDER_1225316081_First_template'

% registeredPlanCFilesDir = '/lab/deasylab2/Ishita/Stenosis_ultracentral/00216080_unzipped';
% baseTemplateFile = 'Baseline';
% ddmTemplateFile = '6month';

% baseTemplateFile = fullfile(registeredPlanCFilesDir,[basePlanCFile,'.mat']) ;
% ddmTemplateFile = fullfile(registeredPlanCFilesDir,[ddmTemplatePlanCFile,'.mat']) ;

dirS = dir(registeredPlanCFilesDir);
dirS([dirS.isdir]) = [];
fileNamC = {dirS.name};


% x,y,z coordinates for DDM calculation
planC = loadPlanC(basePlanCFile,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(basePlanCFile,planC);
scanNum = 1;
indexS = planC{end};
siz = getUniformScanSize(planC{indexS.scan}(scanNum));
[xBaseV,yBaseV,zBaseV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
[xBase3M,yBase3M,zBase3M] = meshgrid(xBaseV,yBaseV,zBaseV);
% xBaseV = xBase3M(:);
% yBaseV = yBase3M(:);
% zBaseV = zBase3M(:);

% filesC = fullfile(registeredPlanCFilesDir,fileNamC);

% if ~exist('vfDir','var')
%     vfDir = fullfile(registeredPlanCFilesDir,'registered');
% end

numFiles = length(fileNamC);
xDeformM = [];
yDeformM = [];
zDeformM = [];
for iFile = 1:numFiles
    fName = fileNamC{iFile};
    fullFilePath = fullfile(registeredPlanCFilesDir,fName);
    planC = loadPlanC(fullFilePath,tempdir);
    indexS = planC{end};
    scanNum = 1;
    [xUnifV,yUnifV,zUnifV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    
    if strcmp(basePlanCFileName,strtok(fName,'.'))
        continue;
    end
    vfBaseName = [basePlanCFileName,'~',strtok(fName,'.'),'_vf.mat'];
    vfBaseFile = fullfile(vfDir,vfBaseName);
    if ~exist(vfBaseFile,'file')
        continue;
    end
    
    load(vfBaseFile)    
    xBaseDeform3M = xBase3M + vf(:,:,:,1);
    yBaseDeform3M = yBase3M + vf(:,:,:,2);
    zBaseDeform3M = zBase3M + vf(:,:,:,3);
    
    if strcmp(strtok(fName,'.'),ddmTemplatePlanCFileName)
        xDeformV = xBaseDeform3M(:);
        yDeformV = yBaseDeform3M(:);
        zDeformV = zBaseDeform3M(:);
    else
        vfDdmName = [strtok(fName,'.'),'~',ddmTemplatePlanCFileName,'_vf.mat'];
        vfDdmFile = fullfile(vfDir,vfDdmName);
        if ~exist(vfDdmFile,'file')
            continue;
        end
        load(vfDdmFile)
        
        xFieldV = [xUnifV(1)-1e-6,xUnifV(2)-xUnifV(1),xUnifV(end)+1e-6];
        yFieldV = [yUnifV(end)-1e-6,yUnifV(1)-yUnifV(2),yUnifV(1)+1e-6];
        
        xDeformV = xBaseDeform3M(:) + finterp3(xBaseDeform3M(:),yBaseDeform3M(:),zBaseDeform3M(:),...
            flip(vf(:,:,:,1),1),xFieldV,yFieldV,zUnifV);
        yDeformV = yBaseDeform3M(:) + finterp3(xBaseDeform3M(:),yBaseDeform3M(:),zBaseDeform3M(:),...
            flip(vf(:,:,:,2),1),xFieldV,yFieldV,zUnifV);
        zDeformV = zBaseDeform3M(:) + finterp3(xBaseDeform3M(:),yBaseDeform3M(:),zBaseDeform3M(:),...
            flip(vf(:,:,:,3),1),xFieldV,yFieldV,zUnifV);
    end
    
    xDeformM(:,end+1) = xDeformV;
    yDeformM(:,end+1) = yDeformV;
    zDeformM(:,end+1) = zDeformV;

end

% % Pairwise distance
% numDeforms = size(xDeformM,2);
% pairsM = nchoosek(1:numDeforms,2);
% numPairs = size(pairsM,1);
% distM = zeros(size(xDeformM,1),numPairs);
% for i = 1:numPairs
%     xSquareV = diff(xDeformM(:,pairsM(i,:)),1,2).^2;
%     ySquareV = diff(yDeformM(:,pairsM(i,:)),1,2).^2;
%     zSquareV = diff(zDeformM(:,pairsM(i,:)),1,2).^2;
%     distSquareV = xSquareV + ySquareV + zSquareV;
%     distM(:,i) = distSquareV.^0.5;
% end
% medianDistV = nanmedian(distM,2);

xMeanV = median(xDeformM,2,'omitnan');
yMeanV = median(yDeformM,2,'omitnan');
zMeanV = median(zDeformM,2,'omitnan');
xSquareV = bsxfun(@minus,xDeformM,xMeanV);
ySquareV = bsxfun(@minus,yDeformM,yMeanV);
zSquareV = bsxfun(@minus,zDeformM,zMeanV);

medianDistV = median((xSquareV.^2 + ySquareV.^2 + zSquareV.^2).^0.5,2,...
    'omitnan')/sqrt(2);

dist3M = reshape(medianDistV,siz);

% Add as dose to base planC
planC = loadPlanC(basePlanCFile,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(basePlanCFile,planC);
indexS = planC{end};
scanType = 'UniformCT';
assocScanUID = planC{indexS.scan}(scanNum).scanUID;
planC = dose2CERR(single(dist3M),'','DDM','',...
'',scanType,'','No',assocScanUID,planC);
planC = save_planC(planC,[],'passed',saveFileLocationWithDDM);



