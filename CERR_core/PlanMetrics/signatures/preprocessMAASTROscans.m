function [planC,hiSuvCtStrV,hiSuvPetStrV] = ...
    preprocessMAASTROscans(structNumV,badSlicesStr,planC)
% function [planC,hiSuvCtStrV,hiSuvPetStrV] = ...
%     preprocessMAASTROscans.m(structNumV,badSlicesStr,planC)
%
% REQUIREMENTS: 
% The function requires that planC contain the following three scans:
% FDG-CT scan at index 1 within planC{indexS.scan}
% FDG-PET scan at index 2 within planC{indexS.scan}
% Additionally, the GTV structures must be defined on CT i.e. scan number 1. 
%
% INPUTS: 
% % Structure numbers defined on scan number 1
% structNumV = [3,4,5];
% % Bad (dental artifact) slices to ignore from planning CT
% badSlicesStrC = '60-62'; % 'None' for no artifact slices
%
% OUTPUTS:
% planC: planC object with structures necessary for Hypoxia calculation.
% hiSuvCtStrV: Structure on FDG-CT containing the GTV above 42% max SUV.
% hiSuvPetStrV: Structure on FDG-PET containing the GTV above 42% max SUV.
%
% APA, 8/28/2018
% based on the "preprocess_scans_fdgct.m" script by MCO.
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

% Define intensity range
minHU = -100;
maxHU = 150;
thresholdSUV = 0.42;

indexS = planC{end};

fdgCT_scanNum = 1;
fdgPET_scanNum = 2;
%planCT_nonDef_scanNum = 3;

% Get bad slices from planning CT
[~,zminBad,zMaxBad,zOffset] = getBadSlicesZs(fdgCT_scanNum, badSlicesStr, planC, indexS);
[fdgCT_badV] = getBadSlicesFromZs(fdgCT_scanNum, zminBad, zMaxBad, zOffset, planC, indexS);

% Initialize structure indices
hiSuvCtStrV = [];
hiSuvPetStrV = [];

for iStr = 1:length(structNumV)
    
    numStructs = length(planC{indexS.structures});
    
    % Get structures of interest
    %planCT_fdgReg_structNum = structNumV(iStr);
    fdgCT_structNum = structNumV(iStr);
    
    % Copy structure from planning to FDG CT
    %planC = copyStrToScan(planCT_fdgReg_structNum, fdgCT_scanNum, planC);
    %fdgCT_structNum = numStructs + 1;
    %numStructs = numStructs + 1;
    
    % Remove badV from structure mask
    maskStruc = getNonUniformStr(fdgCT_structNum, planC);
    noBad_maskStruc = removeSlicesFromMask(fdgCT_badV, maskStruc);
    
    % Clip intensities
    [noBad_maskStruc] = setIntensities(minHU,maxHU,noBad_maskStruc,fdgCT_scanNum,planC,indexS);
    
    % Save as new structure
    strucInfo = planC{indexS.structures};
    %oldName = strucInfo(planCT_fdgReg_structNum).structureName;
    oldName = strucInfo(fdgCT_structNum).structureName;
    newName = strcat(oldName, '_NoBad');
    isUniform = 0;
    planC = maskToCERRStructure(noBad_maskStruc, isUniform, fdgCT_scanNum, newName, planC);
    numStructs = numStructs + 1;
    
    % Copy structure (incl. bad slices) from FDG CT to FDG PET
    % planC = copyStrToScan(planCT_fdgReg_structNum, fdgPET_scanNum, planC);
    planC = copyStrToScan(fdgCT_structNum, fdgPET_scanNum, planC);
    final_strNumPET = numStructs + 1;
    numStructs = numStructs + 1;
    
    % Create structures cutting at FDG threshold ...
    [~, highSUV_maskPET] = setSUV(thresholdSUV,final_strNumPET,fdgPET_scanNum,planC,indexS);
    
    
    newName = strcat(oldName, '_hiSUV');
    isUniform = 0;
    planC = maskToCERRStructure(highSUV_maskPET, isUniform, fdgPET_scanNum, newName, planC);
    numStructs = numStructs + 1;
    hiSuvPetStrV = [hiSuvPetStrV numStructs];
    planC = copyStrToScan(numStructs, fdgCT_scanNum, planC, noBad_maskStruc);
    %planC = copyStrToScan(final_hiSUV_strNumPET, fdgCT_scanNum, noBad_maskStruc, planC);
    numStructs = numStructs + 1;
    hiSuvCtStrV = [hiSuvCtStrV numStructs];    
        
end

function [theMask] = removeSlicesFromMask(badV, theMask)
theMask(:,:,badV) = false;

function [badV,zMinBad,zMaxBad,zOffset] = getBadSlicesZs(scanNum, badSlicesStr, planC, indexS)
badV = [];
zMinBad = [];
zMaxBad = [];
zValsPlannCTV = [planC{indexS.scan}(scanNum).scanInfo.zValue];
if ~strcmpi(badSlicesStr,'None')
    [set1,set2] = strtok(badSlicesStr,',');
    [minBadStr,maxBadStr] = strtok(set1,'-');
    minBad = str2num(minBadStr);
    maxBad = str2num(maxBadStr(2:end));
    if isempty(maxBad)
        maxBad = minBad;
    end
    zMinBad = zValsPlannCTV(minBad);
    zMaxBad = zValsPlannCTV(maxBad);
    badV = minBad:maxBad;
    if ~isempty(set2)
        [minBadStr,maxBadStr] = strtok(set2,'-');
        minBad = str2num(minBadStr);
        maxBad = str2num(maxBadStr(2:end));
        if isempty(maxBad)
            maxBad = minBad;
        end
        zMinBad = [zMinBad zValsPlannCTV(minBad)];
        zMaxBad = [zMaxBad zValsPlannCTV(maxBad)];
        badV = [badV, minBad:maxBad];
    end
    zMinBad = zMinBad;
    zMaxBad = zMaxBad;
end

if ~isempty(planC{indexS.scan}(scanNum).transM)
    zOffset = planC{indexS.scan}(scanNum).transM(3,4);
else
    zOffset = 0;
end


function [badV] = getBadSlicesFromZs(scanNum, zMinBad, zMaxBad, zOffset, planC, indexS)
zValsV = [planC{indexS.scan}(scanNum).scanInfo.zValue];
badV = [];
for iBad = 1:length(zMinBad)
    iMin = findnearest(zValsV,zMinBad(iBad)+zOffset);
    iMax = findnearest(zValsV,zMaxBad(iBad)+zOffset);
    badV = [badV iMin:iMax];
end


function [planC, zValsReslcPlannCTV] = resliceScan(scanNum, resol, planC, indexS)
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
dFdgCor = abs(xVals(2)-xVals(1));
dFdgSag = abs(yVals(2)-yVals(1));
dFdgTrans = abs(zVals(2)-zVals(1));
if max([abs(dFdgCor-resol.dCor),abs(dFdgSag-resol.dSag),abs(dFdgTrans-resol.dTrans)]) > 0.001
    planC = reSliceScan(scanNum,resol.dSag,resol.dCor,resol.dTrans,planC);
end
zValsReslcPlannCTV = [planC{indexS.scan}(scanNum).scanInfo.zValue];

function [theMask] = setIntensities(minI,maxI,theMask,scanNum,planC,indexS)
scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
scanArray3M = double(scanArray3M) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
intensityInMask = theMask.*scanArray3M;
theMask( intensityInMask<minI | intensityInMask>maxI ) = false;

function [loMask, hiMask] = setSUV(thresholdSUV,structNum,scanNum,planC,indexS)
% Get structure
theMask = getNonUniformStr(structNum, planC);

% Get scan
scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
scanArray3M = double(scanArray3M) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
suvInMask = theMask.*scanArray3M;
maxSUV = max(suvInMask(theMask));
minSUV = min(suvInMask(theMask));
thresholdAbsSUV = thresholdSUV*maxSUV;

% Bisect structure
loMask = theMask;
loMask( suvInMask>thresholdAbsSUV ) = false;
hiMask = theMask;
hiMask( suvInMask<thresholdAbsSUV ) = false;


function [fullMask] = getNonUniformStr(structNum, planC)
scanNum = getStructureAssociatedScan(structNum, planC);
indexS = planC{end};
[rasterSegments, planC, isError] = getRasterSegments(structNum, planC);
[mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
fullMask = false(size(scanArray3M));
fullMask(:,:,uniqueSlices) = mask3M;

