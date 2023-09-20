function [scanOut3M,bbox3M] = cropAroundCOM(scanNum,strName,outputImgSizeV,...
                              bkgVal,planC)
% cropAroundCOM.m
% Crop input scan to specified dimensions around center of mass.
%--------------------------------------------------------------------------
% INPUTS
% scanNum            : Input scan no.
% strName            : Structure to crop around
% outputImgSizeV     : Output dimensions [rows, cols, slcs]
% bkgVal             : User-input intensity assigned to voxels outside  
%                      strName. Leave empty to skip.
% planC
%--------------------------------------------------------------------------
% AI 04/22/22

%% Get input scan array
indexS = planC{end};
scan3M = double(getScanArray(scanNum,planC));
CToffset = double(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
scan3M = scan3M - CToffset;
origSizV = size(scan3M);

if length(outputImgSizeV)==2
    outputImgSizeV(3) = size(scan3M,3);
end

%% Get structure mask
strNum = getMatchingIndex(strName,...
    {planC{indexS.structures}.structureName},'exact');
assocScanV = getStructureAssociatedScan(strNum,planC);

% Check for associated scan num
if isempty(strNum)
    error('Structure ''%s'' not found.',strName)
else
    strNum = strNum(assocScanV == scanNum);
    if isempty(strNum)
        error('Structure ''%s'' not found.',strName);
    end
end
cropStr3M = getStrMask(strNum,planC);

%Assign bkg intensity
if ~isempty(bkgVal)
   scan3M(~cropStr3M) = bkgVal;
end

%% Crop around COM

%Compute COM (3D)
bbox3M = false(origSizV);
%[x3M, y3M, z3M] = ndgrid(1:origSizV(1), 1:origSizV(2), 1:origSizV(3));
%COMv = round(mean([x3M(cropStr3M), y3M(cropStr3M), z3M(cropStr3M)]));
[rV, cV, sV] = find3d(cropStr3M);
COMv = round(mean([rV; cV; sV],2));

%Compute crop extents around COM
rStart = max(1, COMv(1) - round(outputImgSizeV(1)/2));
cStart = max(1, COMv(2) - round(outputImgSizeV(2)/2));

rEnd = min(COMv(1) + round(outputImgSizeV(1)/2), origSizV(1));
cEnd = min(COMv(2) + round(outputImgSizeV(2)/2), origSizV(2));

if ~isequal(outputImgSizeV(3),origSizV(3))
    sEnd = min(COMv(3) + round(outputImgSizeV(3)/2), origSizV(3));
    sStart = max(1,COMv(3) - round(outputImgSizeV(3)/2));
else
    sStart = 1;
    sEnd = outputImgSizeV(3) + 1;
end

%% Calc. padding required for specified output dimensions where needed
cropSizV = [rEnd - rStart, cEnd - cStart, sEnd - sStart];
if cropSizV(1)<outputImgSizeV(1)
    xPad = floor(outputImgSizeV(1)/2 - cropSizV(1)/2);
else
    xPad = 1;
end
if cropSizV(2)<outputImgSizeV(2)
    yPad = floor(outputImgSizeV(2)/2 - cropSizV(2)/2);
else
    yPad = 1;
end
if cropSizV(3)<outputImgSizeV(3)
    zPad = floor(outputImgSizeV(3)/2 - cropSizV(3)/2);
else
    zPad = 1;
end


%% Populate output scan
% Initialize output scan array
cornerCube = scan3M(1:5,1:5,1:5);
bgMean = mean(cornerCube(:));
scanOut3M = bgMean*ones([outputImgSizeV(1:2),size(scan3M,3)]);

%Populate with cropped scan
bbox3M(rStart:rEnd-1,cStart:cEnd-1,sStart:sEnd-1) = true;
scanCropM = scan3M(rStart:rEnd-1,cStart:cEnd-1,sStart:sEnd-1);
scanOut3M(xPad:xPad+cropSizV(1)-1,yPad:yPad+cropSizV(2)-1,...
    zPad:zPad+cropSizV(3)-1) = scanCropM;


end