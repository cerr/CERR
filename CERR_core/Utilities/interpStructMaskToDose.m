function [interpMask3M,newXgrid,newYgrid,newZgrid] = interpStructMaskToDose(structNum,doseNum,planC)
% function [interpMask3M,newXgrid,newYgrid,newZgrid] = interpStructMaskToDose(structNum,doseNum,planC)
%
% This function interpolates structure mask to dose grid.
%
% INPUTS:
% structNum - structure index within planC{indexS.structures}
% doseNum - dose index planC{indexS.dose}
% planC - CERR's planC data structure
%
% OUTPUTS:
% interpMask3M - binary mask interpolated to the dose grid.
% newXgrid,newYgrid,newZgrid - x,y,z dose-grid
%
% APA, 11/27/2018

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% Dose grid coordinates
[newXgrid, newYgrid, newZgrid] = getDoseXYZVals(planC{indexS.dose}(doseNum));
numRows = length(newYgrid);
numCols = length(newXgrid);
numSlcs = length(newZgrid);

% Get structure mask
mask3M = getUniformStr(structNum,planC);

% Get slices with mask.
[~,~,kV] = find3d(mask3M);
kV = unique(kV);

% Interpolate structure mask to dose grid
interpMask3M = zeros(numRows,numCols,numSlcs,'logical');
assocScanNum = getStructureAssociatedScan(structNum,planC);
[xV,yV,zV] = getUniformScanXYZVals(planC{indexS.scan}(assocScanNum));
kMin = max(find(newZgrid < zV(min(kV))));
kMax = min(find(newZgrid > zV(max(kV))));
inputTM = eye(4);
for slcNum=kMin:kMax %1:length(newZgrid)
    disp(['Interpolating slice ', num2str(kMin), '/', num2str(kMin)])
    strTmpM = slice3DVol(mask3M, xV, yV, zV, newZgrid(slcNum), 3, 'linear', inputTM, [], newXgrid, newYgrid);
    if ~isempty(strTmpM)
        interpMask3M(:,:,slcNum) = strTmpM > 0.5;
    end
end
