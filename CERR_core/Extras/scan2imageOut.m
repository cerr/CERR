function scanFileNameC = scan2imageOut(planC,scanNumV,tmpDirPath,...
  reorientFlag,extn,dataType,scanFileName)

if ~exist('tmpDirPath','var') || isempty(tmpDirPath) || ~exist(tmpDirPath,'dir')
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
end

if ~exist('reorientFlag','var') || isempty(reorientFlag)
    reorientFlag = 1;
end

if ~exist('extn','var') || isempty(extn)
    extn = 'nii';
end

if ~exist('dataType','var')
    dataType = [];
end

for i = 1:numel(scanNumV)
  scanNum = scanNumV(i);
  [scanUniqName, ~] = genScanUniqName(planC,scanNum);
  [affineMat,scan3M_RAS,voxel_size] = getPlanCAffineMat(planC, scanNum, reorientFlag);
  [~,orientationStr,~] = returnViewerAxisLabels(planC,scanNum);
  if ~isempty(dataType)
    eval(['scan3M_RAS = ' dataType '(scan3M_RAS);']);
  end
  qOffset = affineMat(1:3,end)';
  if strcmpi(extn,'nii')
    if ~exist('scanFileName','var') || isempty(scanFileName)
      scanFileName = fullfile(tmpDirPath, ['scan_' num2str(scanNum) '_' scanUniqName '.nii']);
    else
      scanFileName = fullfile(tmpDirPath,[scanFileName,'.nii']);
    end
    niiC{i} = vol2nii(scan3M_RAS,affineMat,qOffset,voxel_size,[],scanFileName);
  elseif strcmpi(extn,'nrrd')
    if ~exist('scanFileName','var') || isempty(scanFileName)
      scanFileName = fullfile(tmpDirPath, ['scan_' num2str(scanNum) '_' scanUniqName '.nrrd']);
    else
      scanFileName = fullfile(tmpDirPath,[scanFileName,'.nrrd']);
    end
    vol2nrrd(scan3M_RAS,affineMat,qOffset,voxel_size,orientationStr,scanFileName);
  end
  scanFileNameC{i} = scanFileName;
end

