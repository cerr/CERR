function [meanDoseV, stdDoseV, DVHm, volsV, shiftXv, shiftYv, shiftZv] = simulate_organ_motion(planC,structNumV,doseNum, igrtFlag)
%function [DVH_out, DVHm, volsV] = simulate_organ_motion(planC,structNumV,doseNum)
%
%APA, 09/21/2012
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

indexS = planC{end};

%Number of Fractions and Trials
numFractions = 1; % 48
numTrials    = 1; % 200
numStructs   = length(structNumV);

shiftXv = zeros(1,numTrials);
shiftYv = shiftXv;
shiftZv = shiftXv;

structurenamesC = {planC{indexS.structures}.structureName};
rectumIndex = getMatchingIndex('rectum_o',lower(structurenamesC),'exact');
rectalCS = calculate_structure_cross_sectional_area(rectumIndex,planC);
bladderVol = getMatchingIndex('bladder_o',lower(structurenamesC),'exact');

% % Systematic Shifts in cm (Inter-treatment)
% XdispSys_Std = 0; % L-R
% YdispSys_Std = 0; % A-P
% ZdispSys_Std = 0; % S-I
 
% % Random Shifts in cm (inter-fraction)
% XdispRnd_Std = 1; % L-P
% YdispRnd_Std = 1; % A-P
% ZdispRnd_Std = 1; % S-I

%Distances are in cm
XpdfMean = 0; % L-P
YpdfMean = 0; % A-P
ZpdfMean = 0; % S-I

%Get scan associated with doseNum
scanNum = getAssociatedScan(planC{indexS.dose}(doseNum).assocScanUID, planC);

if isempty(scanNum) %Assume dose is associated with this scan
    scanNum = getStructureAssociatedScan(structNumV(1),planC);
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
structCount = 0;
for structNum = structNumV
    structCount = structCount + 1;
    [dosesCurrentV{structCount}, volsV{structCount}] = getDVH(structNum, doseNum, planC);
end

%Divide doseArray into fractions
planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray / numFractions;

%Get systematic errors
% deltaX_systematic = randn(1, numTrials) * XdispSys_Std + XpdfMean;
% deltaY_systematic = randn(1, numTrials) * YdispSys_Std + YpdfMean;
% deltaZ_systematic = randn(1, numTrials) * ZdispSys_Std + ZpdfMean;

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
structCount = 0;
for structNum = structNumV
    
    structCount = structCount + 1;
    
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
    
    blocks{structCount} = ceil(length(indFullV)/DVHBlockSize);
    
    start = 1;
    
    for b = 1 : blocks{structCount}
        
        %Build the interpolation points matrix
        
        dummy = zeros(1,DVHBlockSize * ROIImageSize(1));
        x1V = dummy;
        y1V = dummy;
        z1V = dummy;
        volsSectionV{structCount} =  dummy;
        
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
            volsSectionV{structCount}(mark : mark + len - 1) = v;
            mark = mark + len;
            
        end
        
        %cut unused matrix elements
        x1V = x1V(1:mark-1);
        y1V = y1V(1:mark-1);
        z1V = z1V(1:mark-1);
        volsSectionV{structCount} = volsSectionV{structCount}(1:mark-1);
        
        %Get transformation matrices for both dose and structure.
        transMDose    = getTransM('dose', doseNum, planC);
        transMStruct  = getTransM('struct', structNum, planC);
        
        %Forward transform the structure's coordinates.
        if ~isempty(transMStruct)
            [x1V, y1V, z1V] = applyTransM(transMStruct, x1V, y1V, z1V);
        end
        
        dvhCalcPtsC{structCount}{b} = [x1V', y1V', z1V'];
        
        %Interpolate.
        %   [dosesSectionV] = getDoseAt(doseNum, x1V, y1V, z1V, planC);
        
        %   dosesV = [dosesV, dosesSectionV];
        %   volsV  = [volsV, volsSectionV{structCount}];
        
        start = stop + 1;
        
    end
    
end

%Loop over to generate DVH
for iTrial = 1:numTrials

    [deltaX_systematic, deltaY_systematic, deltaZ_systematic, XdispRnd_Std, YdispRnd_Std, ZdispRnd_Std] = getShiftParameters(rectalCS,bladderVol,igrtFlag);
    deltaX_systematic = min(max(deltaX_systematic,-1.0),1.0);
    deltaY_systematic = min(max(deltaY_systematic,-1.5),1.5);
    deltaZ_systematic = min(max(deltaZ_systematic,-1.0),1.0);
    deltaX = deltaX_systematic + randn(1, numFractions) * XdispRnd_Std + XpdfMean;
    deltaY = deltaY_systematic + randn(1, numFractions) * YdispRnd_Std + YpdfMean;
    deltaZ = deltaZ_systematic + randn(1, numFractions) * ZdispRnd_Std + ZpdfMean;
    
    % To get planned DVH - comment it otherwise
    deltaX = 0;
    deltaY = 0;
    deltaZ = 0;    
    
    shiftXv(1,iTrial) = mean(deltaX);
    shiftYv(1,iTrial) = mean(deltaY);
    shiftZv(1,iTrial) = mean(deltaZ);    
    
    structCount = 0;
    for structNum = structNumV
        
        structCount = structCount + 1;
        
        tmpDoseV = zeros(1,length(dosesCurrentV{structCount}));
        
        for iFraction = 1:numFractions
            
            waitbar(((iTrial-1)*numStructs + structCount)/(numTrials*numStructs),hWait)
            
            transM = referenceTransM_matrix;
            transM(1:3,4) = transM(1:3,4) + [deltaX(iFraction); deltaY(iFraction); deltaZ(iFraction)];
            
            %Apply the new transM to dose
            planC{indexS.dose}(doseNum).transM = transM;
            
            % Convert Dose to Gy
            if max(planC{indexS.dose}(doseNum).doseArray(:)) > 150
                planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray/100;
            end
            
            %Get doses and volumes of points in structure.
            %[dosesV, volsV] = getDVH(structNum, doseNum, planC);
            
            
            volsV{structCount}  = [];
            dosesV{structCount} = [];
            
            for b = 1 : blocks{structCount}
                x1V = dvhCalcPtsC{structCount}{b}(:,1);
                y1V = dvhCalcPtsC{structCount}{b}(:,2);
                z1V = dvhCalcPtsC{structCount}{b}(:,3);
                
                %Back transform the coordinates into the doses' coordinate system.
                [x1V, y1V, z1V] = applyTransM(inv(transM), x1V, y1V, z1V);
                
                %Interpolate.
                [dosesSectionV] = getDoseAt(doseNum, x1V, y1V, z1V, planC);
                
                dosesV{structCount} = [dosesV{structCount}, dosesSectionV];
                volsV{structCount}  = [volsV{structCount}, volsSectionV{structCount}];
            end
            
            tmpDoseV = tmpDoseV + dosesV{structCount};
            
        end
        
        DVHm{structCount}(:,iTrial) = single(tmpDoseV(:));
        
    end
    

end

close(hWait)

%Reassign reference transM and doseArray to doseNum
planC{indexS.dose}(doseNum).transM = referenceTransM;
planC{indexS.dose}(doseNum).doseArray = referenceDoseArray;


%Compute Mean and Std Dev in blocks
structCount = 0;
for structNum = structNumV
    
    structCount = structCount + 1;
    
    numVoxels = length(volsV{structCount});
    DVHBlockSize = 5000;
    blocks = ceil(numVoxels/DVHBlockSize);
    start = 1;
    
    for b = 1 : blocks
        
        if start+DVHBlockSize > numVoxels
            stop = numVoxels;
        else
            stop = start + DVHBlockSize - 1;
        end
        
        DVH_block = DVHm{structCount}(start:stop,:);
        
        meanDoseV{structCount}(start:stop) = mean(DVH_block,2);
        stdDoseV{structCount}(start:stop)  = std(DVH_block,0,2);
        
        start = stop + 1;
        
    end
end

% %Histogram for the expectation of dose over all trials
% [doseBinsV, volsHistV] = doseHist(meanDoseV, volsV, binWidth);
% DVH_out = [doseBinsV(:)'; volsHistV(:)'];

