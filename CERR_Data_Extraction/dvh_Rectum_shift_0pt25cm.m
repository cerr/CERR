function DVH_out = dvh_Rectum_shift_0pt25cm(planC,structNum,doseNum)
% function DVH_out = dvh_Rectum_shift_0pt25cm(planC,structNum,doseNum)
%
% This function applies isotropic shift of 0.25cm to the specified structure
% and outputs the resulting DVHs.
%
% APA, 11/11/2010
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

%Number of Fractions and Trials
numFractions = 3;
numTrials    = 2;

% Systematic Shifts in cm (Inter-treatment)
XdispSys_Std = 0;
YdispSys_Std = 0;
ZdispSys_Std = 0;

% Random Shifts in cm (inter-fraction)
XdispRnd_Std = 0.25;
YdispRnd_Std = 0.25;
ZdispRnd_Std = 0.25;

indexS = planC{end};

%Distances are in cm
XpdfMean = 0;

YpdfMean = 0;

ZpdfMean = 0;

%Get scan associated with doseNum
scanNum = getAssociatedScan(planC{indexS.dose}(doseNum).assocScanUID, planC);

if isempty(scanNum) %Assume dose is associated with this scan
    scanNum = getStructureAssociatedScan(structNum,planC);
end

%Get reference transformation matrix for doseNum
if ~isempty(scanNum) && isempty(planC{indexS.dose}(doseNum).transM)
    referenceTransM = planC{indexS.scan}(scanNum).transM;
else
    referenceTransM = planC{indexS.dose}(doseNum).transM;
end

%Store the reference doseArray
referenceDoseArray = planC{indexS.dose}(doseNum).doseArray;

%Try and get a binWidth from stateS.  If it doesnt exist, get it from
%the CERROptions file (allows this function to be called outside CERR)
global stateS;
if ~isempty(stateS) && isfield(stateS, 'optS') && isfield(stateS.optS, 'DVHBinWidth') && ~isempty(stateS.optS.DVHBinWidth)
    binWidth = stateS.optS.DVHBinWidth;
else
    optS = CERROptions;
    binWidth = optS.DVHBinWidth;
end

%Compute DVH at given dose
[dosesCurrentV, volsV] = getDVH(structNum, doseNum, planC);

%Divide doseArray into fractions
planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray / numFractions;

%Get systematic errors
deltaX_systematic = randn(1, numTrials) * XdispSys_Std + XpdfMean;
deltaY_systematic = randn(1, numTrials) * YdispSys_Std + YpdfMean;
deltaZ_systematic = randn(1, numTrials) * ZdispSys_Std + ZpdfMean;

hWait = waitbar(0,'Computing plan robustness...');

if isempty(referenceTransM)
    referenceTransM_matrix = eye(4);
else
    referenceTransM_matrix = referenceTransM;
end


%Obtain DVH calculation points in blocks
optS    = planC{indexS.CERROptions};

ROIImageSize = [planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2];

deltaY = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;

%Get raster segments for structure.
[segmentsM, planC, isError] = getRasterSegments(structNum, planC);

if isempty(segmentsM)
    isError = 1;
end
numSegs = size(segmentsM,1);

%Relative sampling of ROI voxels in this place, compared to CT spacing.
%Set when rasterSegments are generated (usually on import).
sampleRate = optS.ROISampleRate;

%Sample the rows
indFullV =  1 : numSegs;
if sampleRate ~= 1
    rV = 1 : length(indFullV);
    rV([rem(rV+sampleRate-1,sampleRate)~=0]) = [];
    indFullV = rV;
end

%Block process to avoid swamping on large structures
if isfield(optS, 'DVHBlockSize') & ~isempty(optS.DVHBlockSize)
    DVHBlockSize = optS.DVHBlockSize;
else
    DVHBlockSize = 5000;    
end

blocks = ceil(length(indFullV)/DVHBlockSize);

start = 1;

for b = 1 : blocks

  %Build the interpolation points matrix

  dummy = zeros(1,DVHBlockSize * ROIImageSize(1));
  x1V = dummy;
  y1V = dummy;
  z1V = dummy;
  volsSectionV =  dummy;

  if start+DVHBlockSize > length(indFullV)
    stop = length(indFullV);
  else
    stop = start + DVHBlockSize - 1;
  end

  indV = indFullV(start:stop);

  mark = 1;
  for i = indV

    tmpV = segmentsM(i,1:10);
    delta = tmpV(5) * sampleRate;
    xV = tmpV(3): delta : tmpV(4);
    len = length(xV);
    rangeV = ones(1,len);
    yV = tmpV(2) * rangeV;
    zV = tmpV(1) * rangeV;
    sliceThickness = tmpV(10);
    %v = delta^2 * sliceThickness;
    v = delta * (deltaY*sampleRate) * sliceThickness;
    x1V(mark : mark + len - 1) = xV;
    y1V(mark : mark + len - 1) = yV;
    z1V(mark : mark + len - 1) = zV;
    volsSectionV(mark : mark + len - 1) = v;
    mark = mark + len;

  end

  %cut unused matrix elements
  x1V = x1V(1:mark-1);
  y1V = y1V(1:mark-1);
  z1V = z1V(1:mark-1);
  volsSectionV = volsSectionV(1:mark-1);

  %Get transformation matrices for both dose and structure.
  transMDose    = getTransM('dose', doseNum, planC);
  transMStruct  = getTransM('struct', structNum, planC);  
  
  %Forward transform the structure's coordinates.
  if ~isempty(transMStruct)
      [x1V, y1V, z1V] = applyTransM(transMStruct, x1V, y1V, z1V);
  end

  dvhCalcPtsC{b} = [x1V', y1V', z1V'];
  
  %Interpolate.
%   [dosesSectionV] = getDoseAt(doseNum, x1V, y1V, z1V, planC);

%   dosesV = [dosesV, dosesSectionV];
%   volsV  = [volsV, volsSectionV];

  start = stop + 1;

end


%Loop over to generate DVH
for iTrial = 1:numTrials

    deltaX = deltaX_systematic(iTrial) + randn(1, numFractions) * XdispRnd_Std + XpdfMean;
    deltaY = deltaY_systematic(iTrial) + randn(1, numFractions) * YdispRnd_Std + YpdfMean;
    deltaZ = deltaZ_systematic(iTrial) + randn(1, numFractions) * ZdispRnd_Std + ZpdfMean;
    
    tmpDoseV = zeros(1,length(dosesCurrentV));
    
    for iFraction = 1:numFractions

        waitbar(((iTrial-1)*numFractions + iFraction)/(numTrials*numFractions),hWait)
        
        transM = referenceTransM_matrix;
        transM(1:3,4) = transM(1:3,4) + [deltaX(iFraction); deltaY(iFraction); deltaZ(iFraction)];

        %Apply the new transM to dose
        planC{indexS.dose}(doseNum).transM = transM;

        %Get doses and volumes of points in structure.
        %[dosesV, volsV] = getDVH(structNum, doseNum, planC);

        volsV  = [];
        dosesV = [];
        
        for b = 1 : blocks
            x1V = dvhCalcPtsC{b}(:,1);
            y1V = dvhCalcPtsC{b}(:,2);
            z1V = dvhCalcPtsC{b}(:,3);

            %Back transform the coordinates into the doses' coordinate system.            
            [x1V, y1V, z1V] = applyTransM(inv(transM), x1V, y1V, z1V);
            
            %Interpolate.
            [dosesSectionV] = getDoseAt(doseNum, x1V, y1V, z1V, planC);

            dosesV = [dosesV, dosesSectionV];
            volsV  = [volsV, volsSectionV];
        end
        
        tmpDoseV = tmpDoseV + dosesV;

    end

    DVHm(:,iTrial) = single(tmpDoseV(:));

    %Compute Mean and Std for binned dose
    %for iTrial=1:numTrials
        doseTrialV = DVHm(:,iTrial);
        [doseBinsV, volsHistV] = doseHist(doseTrialV, volsV, binWidth);
        doseBinsTmpV = doseBinsV;
        volsHistTmpV = volsHistV;
        if iTrial > 1
            AddToCurrent = ~ismember(doseBins{1},doseBinsV);
            AddToPrevious = ~ismember(doseBinsV,doseBins{1});
            doseBinsV = [doseBinsV doseBins{1}(AddToCurrent)];
            volsHistV = [volsHistV volsHist{1}(AddToCurrent)];
            for jTrial = 1:iTrial-1
                doseBins{jTrial} = [doseBins{jTrial} doseBinsTmpV(AddToPrevious)];
                volsHist{jTrial} = [volsHist{jTrial} volsHistTmpV(AddToPrevious)];
                [doseBins{jTrial},indSort] = sort(doseBins{jTrial});
                volsHist{jTrial} = volsHist{jTrial}(indSort);
            end
        end
        doseBins{iTrial} = doseBinsV;
        volsHist{iTrial} = volsHistV;
        [doseBins{iTrial},indSort] = sort(doseBins{iTrial});
        volsHist{iTrial} = volsHist{iTrial}(indSort);
    %end


end

close(hWait)

%Compute Std of binned volumes
blockSize = 100;
for iBlock = 1:ceil(length(volsHist{1})/blockSize)
    if iBlock == ceil(length(volsHist{1})/blockSize)
        indicesV = (iBlock-1)*blockSize+1:length(volsHist{1});
    else
        indicesV = (iBlock-1)*blockSize+1:iBlock*blockSize;
    end
    volsHistStdM = [];
    for iTrial = 1:length(volsHist)
        volsHistStdM(:,iTrial) = volsHist{iTrial}(indicesV);
    end
    volsHistStdV(indicesV) = std(volsHistStdM,0,2)';
end

%Reassign reference transM and doseArray to doseNum
planC{indexS.dose}(doseNum).transM = referenceTransM;
planC{indexS.dose}(doseNum).doseArray = referenceDoseArray;


%Compute Mean and Std Dev in blocks
numVoxels = length(volsV);
DVHBlockSize = 5000;
blocks = ceil(numVoxels/DVHBlockSize);
start = 1;

for b = 1 : blocks

  if start+DVHBlockSize > numVoxels
    stop = numVoxels;
  else
    stop = start + DVHBlockSize - 1;
  end

  DVH_block = DVHm(start:stop,:);
  
  meanDoseV(start:stop) = mean(DVH_block,2);
  stdDoseV(start:stop)  = std(DVH_block,0,2);
  
  start = stop + 1;
  
end

%Histogram for the expectation of dose over all trials
[doseBinsV, volsHistV] = doseHist(meanDoseV, volsV, binWidth);

% Output the Expectation of DVH
% DVH_out = [doseBinsV(:)'; volsHistV(:)'];

% Output all the trials
for iTrial = 1:numTrials
    [doseBinsTmpV, volsHistTmpV] = doseHist(DVHm(:,iTrial), volsV, binWidth);
    doseBinsC{iTrial} = [doseBinsTmpV(:)'; volsHistTmpV(:)'];
end
% Output mean, mean+1*std, mean+2*std, mean+3*std, mean-1*std, mean-2*std, mean-3*std
[doseBinsMinus1Sigma, volsHistMinus1Sigma] = doseHist(max(0,meanDoseV - 1*stdDoseV), volsV, binWidth);
[doseBinsMinus2Sigma, volsHistMinus2Sigma] = doseHist(max(0,meanDoseV - 2*stdDoseV), volsV, binWidth);
[doseBinsMinus3Sigma, volsHistMinus3Sigma] = doseHist(max(0,meanDoseV - 3*stdDoseV), volsV, binWidth);

[doseBinsPlus1Sigma, volsHistPlus1Sigma] = doseHist(max(0,meanDoseV + 1*stdDoseV), volsV, binWidth);
[doseBinsPlus2Sigma, volsHistPlus2Sigma] = doseHist(max(0,meanDoseV + 2*stdDoseV), volsV, binWidth);
[doseBinsPlus3Sigma, volsHistPlus3Sigma] = doseHist(max(0,meanDoseV + 3*stdDoseV), volsV, binWidth);

DVH_out.allTrialsC = doseBinsC;

DVH_out.meanM = [doseBinsV(:)'; volsHistV(:)'];

DVH_out.Minus1SigmaM = [doseBinsMinus1Sigma(:)'; volsHistMinus1Sigma(:)'];
DVH_out.Minus2SigmaM = [doseBinsMinus2Sigma(:)'; volsHistMinus2Sigma(:)'];
DVH_out.Minus3SigmaM = [doseBinsMinus3Sigma(:)'; volsHistMinus3Sigma(:)'];

DVH_out.Plus1SigmaM = [doseBinsPlus1Sigma(:)'; volsHistPlus1Sigma(:)'];
DVH_out.Plus2SigmaM = [doseBinsPlus2Sigma(:)'; volsHistPlus2Sigma(:)'];
DVH_out.Plus3SigmaM = [doseBinsPlus3Sigma(:)'; volsHistPlus3Sigma(:)'];

