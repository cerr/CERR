function planC = dose2scan(doseNum,scanType,gridType,planC)
% dose2scan.m converts dose "doseNum" to pseudo-CT scan.
%--------------------------------------------------------------------------
% INPUTS
% doseNum  : Dose no.
% scanType : Scan description
% gridType : 'dose' or 'assocScan'
% planC     
%--------------------------------------------------------------------------
%AI 06/10/21

if ~exist('planC','var')
    global planC
end
global stateS

indexS = planC{end};

%Get associated scan
assocScan = getDoseAssociatedScan(doseNum,planC);

%Initialize scanInfo
scanInfoS = initializeScanInfo;

%Get dose array on dose/scan grid
switch gridType
    
    case 'dose'
        
        %Get x,y,z grid for doseNum
        [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
        
        %Get grid size
        spacingX = median(abs(diff(xV)));
        spacingY = median(abs(diff(yV)));
        spacingZ = median(abs(diff(zV)));
        spacingV = [spacingX,spacingY,spacingZ];
        
        %---TBD---
%         % Apply transformation matrix
%         transM = getTransM(planC{indexS.dose}(doseNum),planC);
%         if ~isempty(transM)
%             [rotation, xT, yT, zT] = isrotation(transM);
%         else
%             rotation=0;
%             xT=[0 0];
%             yT=[0 0];
%             zT=[0 0];
%         end
%         
%         if ~isempty(transM)
%             %Get coordinates of corners
%             [xCorn, yCorn, zCorn] = meshgrid([min(xV) max(xV)],...
%                 [min(yV) max(yV)], [min(zV) max(zV)]);
%             
%             %Add ones to the corners so we can apply a transformation matrix.
%             corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];
%             
%             %Apply transform to corners, so we know boundary of the slice.
%             newCorners = transM * corners';
%             newZLims = [min(newCorners(3,:)) max(newCorners(3,:))];
%             deltaZ = ?
%             zV = min(newZLims): deltaZ: max(newZLims);
%         else
%             newZLims = [zV(1) zV(end)] + zT;
%         end
        
        %% Populate scan array
        scan3M = getDoseArray(doseNum,planC);
        newScanSizeV = size(scan3M);

        %% Initialize scanInfo
        scanInfoS(1).grid2Units = spacingV(1);
        scanInfoS(1).grid1Units = spacingV(2);
        scanInfoS(1).xOffset = planC{indexS.dose}(doseNum).coord1OFFirstPoint...
            + newScanSizeV(1)*scanInfoS(1).grid2Units/2;
        scanInfoS(1).yOffset = planC{indexS.dose}(doseNum).coord2OFFirstPoint...
            + newScanSizeV(2)*scanInfoS(1).grid1Units/2;
        
        slcThicknessV = diff(zV);
        slcThicknessV = [slcThicknessV;slcThicknessV(end)];
        
    case 'assocScan'
        
        %Get assoc. scan grid
        [~, ~, zV] = getScanXYZVals(planC{indexS.scan}(assocScan));
        
        %Get dose array on scan grid
        scan3M = getDoseOnCT(doseNum, assocScan,'normal', planC);
        newScanSizeV = size(scan3M);

        %% Initialize scanInfo
        scanInfoS(1).xOffset = planC{indexS.scan}(assocScan).scanInfo(1).xOffset;
        scanInfoS(1).yOffset = planC{indexS.scan}(assocScan).scanInfo(1).yOffset;
        scanInfoS(1).grid2Units = planC{indexS.scan}(assocScan).scanInfo(1).grid2Units;
        scanInfoS(1).grid1Units = planC{indexS.scan}(assocScan).scanInfo(1).grid1Units;
        slcThicknessV = [planC{indexS.scan}(assocScan).scanInfo(:).sliceThickness];
        
end


%% Initialize scan
newScanNum = length(planC{indexS.scan}) + 1;

scanNewS = initializeCERR('scan');
scanNewS(1).scanType = scanType;
scanNewS(1).scanUID = createUID('scan');

scanNewS(1).scanArray  = scan3M;
CToffset = 0;
datamin = min(scan3M(:));
if datamin < 0
    CToffset = -datamin;
end

scanInfoS(1).sizeOfDimension1 = newScanSizeV(2);
scanInfoS(1).sizeOfDimension2 = newScanSizeV(1);
scanInfoS(1).imageType = scanType;
scanInfoS(1).CTOffset = CToffset;
scanInfoS(1).zValues = zV;

for i=1:length(zV)
    scanInfoS(1).sliceThickness = slcThicknessV(i);
    scanInfoS(1).zValue = zV(i);
    scanNewS.scanInfo(i) = scanInfoS(1);
end

planC{indexS.scan} = dissimilarInsert(planC{indexS.scan},scanNewS,newScanNum,[]);


%% Update min/max scan value in stateS
if ~isempty(stateS)
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(newScanNum).scanUID(max(1,end-61):end))];
    minScan = single(min(planC{indexS.scan}(newScanNum).scanArray(:)));
    maxScan = single(max(planC{indexS.scan}(newScanNum).scanArray(:)));
    stateS.scanStats.CTLevel.(scanUID) = (minScan + maxScan - 2*CToffset) / 2;
    stateS.scanStats.CTWidth.(scanUID) = maxScan - minScan;
    stateS.scanStats.windowPresets.(scanUID) = 1;
    stateS.scanStats.Colormap.(scanUID) = 'gray256';
end


% Uniformize scan
planC = setUniformizedData(planC, planC{indexS.CERROptions}, newScanNum);


return
%% ---------------- Supporting functions -------------------------
function [bool, xT, yT, zT] = isrotation(transM)
%"isrotation"
%   Returns true if transM includes rotation.  If it doesn't include
%   rotation, bool=0. xT,yT,zT are the translations in x,y,z
%   respectively.

xT = transM(1,4);
yT = transM(2,4);
zT = transM(3,4);

transM(1:3,4) = 0;
bool = ~isequal(transM, eye(4));