function exportDataForHoloLens(cerrFileName,structNamC,scanNum,doseNumV,exportDir)
% function exportDataForHoloLens(cerrFileName,structNamC,doseNumV,exportDir)
%
% This function exports scan and dose matrices to nrrd files and segmentation to stl format.
%
% User inputs:
%   cerrFileName: Name of file containig planC.
%   structNamC: cell array of structure names to visualize. 
%   scanNum: index of scan in planC.
%   doseNumV: Indices of dose distributions in planC.
%   exportDir: export location.
%
% Example:
%
%   cerrFileName =
%   fullfile(getCERRPath,'..','Unit_Testing','data_for_cerr_tests','CERR_plans','lung_ex1_20may03.mat.bz2');
%   structNamC = { 'PTV2','PTV1','GTV1','CTV1','ESOPHAGUS','HEART','LIVER',...
%    'LUNG_CONTRA','LUNG_IPSI','SPINAL_CORD','Initial reference','SKIN','TOTAL_LUNG'}; % CERR Lung example
%   scanNum = 1;
%   doseNumV = [1];
%   exportDir = 'C:\path\to\export\dir\cerr_lung_dataset';
%
% APA, 04/28/2021

% Load planC
planC = loadPlanC(cerrFileName,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(cerrFileName,planC);
%global planC

indexS = planC{end};

% Get Scan, Dose and Structure matrices
strC = {planC{indexS.structures}.structureName};
[scan3M,dose3mC,strMaskC,xyzGridC,strColorC] = ...
    getScanDoseStrVolumes(scanNum,doseNumV,structNamC,planC);

% maskCrop3M = strMaskC{1} | strMaskC{2}; % LUNG_IPSI and LUNG_CNTR
% [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(maskCrop3M);
sizV = size(scan3M);
minr = 1;
maxr = sizV(1);
minc = 1;
maxc = sizV(2);
mins = 1;
maxs = sizV(3);
%mins = 5; % specific to 0617-489880_09-09-2000-50891 dataset

% Voxel size
[xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
dx = xV(2)-xV(1);
dy = yV(1)-yV(2);
dz = zV(2)-zV(1);


%% Export Scan and Dose to nrrd
voxelSizeV = [dx,dy,dz]*10;
originV = [0,0,0];
encoding = 'raw';

scanFilename = fullfile(exportDir,'scan.nrrd');
scan3M = scan3M(minr:maxr, minc:maxc, mins:maxs);
scan3M = permute(scan3M, [2 1 3]);
scan3M = flip(scan3M,3);
scanRes = nrrdWriter(scanFilename, single(scan3M), voxelSizeV, originV, encoding);

for iDose = 1:length(doseNumV)
    doseNum = doseNumV(iDose);
    dose3M = dose3mC{iDose};
    dose3M = dose3M(minr:maxr, minc:maxc, mins:maxs);
    dose3M = permute(dose3M, [2 1 3]);
    dose3M = flip(dose3M,3);
    doseName = planC{indexS.dose}(doseNum).fractionGroupID;
    doseFilename = fullfile(exportDir, [doseName,'.nrrd']);
    maskRes = nrrdWriter(doseFilename, single(dose3M), voxelSizeV, originV, encoding);
end

% Export x,y,x surface points for PTV
xCropV = xV(minc:maxc);
yCropV = yV(minr:maxr);
zCropV = zV(mins:maxs);
for iStr = 1:length(strMaskC)
    pointsFilename = fullfile(exportDir, [structNamC{iStr},'.stl']);
    mask3M = strMaskC{iStr};
    mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
    mask3M = flip(mask3M,1); % flip along Y
    mask3M = flip(mask3M,3); % flip along Z
    [iV,jV,kV] = find3d(mask3M);
    xCtr = xCropV(1); % L-R
    yCtr = yCropV(end); % P-A
    zCtr = zCropV(1); % S-I
    xyzM = 10*[xCropV(jV)-xCtr; yCropV(iV)-yCtr; zCropV(kV)-zCtr]';
    %writematrix(xyzM, pointsFilename, 'FileType', 'text', 'Delimiter', '\t');
    fv = isosurface((xCropV-xCtr)*10,(yCropV-yCtr)*10,(zCropV-zCtr)*10,mask3M, 0.5); % Make patch w. faces "out"
    hFig = figure;
    p = patch(fv);
    numFaces = size(fv.faces,1);
    maxPatchFaces = numFaces; % maxPatchFaces = 2000;
    scaleFactor = min(numFaces,maxPatchFaces)/numFaces;
    reducedFS = reducepatch(p, scaleFactor);
    close(hFig)
    stlwrite1(pointsFilename,reducedFS)
end


