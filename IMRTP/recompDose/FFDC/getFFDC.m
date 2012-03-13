function planC = getFFDC(planC)
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

leak = 0.035; %0.018; %leakage in per *100

sigma = 0.14; %0.02

kernelSize = 73; %5

indexS = planC{end};

doseNum = 1;
    
i = find(strcmpi({planC{indexS.structures}.structureName}, 'skin'));
if isempty(i)
    error('Skin structure must be defined to generate a uniform CT.');
else
    i = i(1);    
end
    
structNum = i;
    
scanSet = 1;

currentDir = cd;

[FileName,path] = uigetfile('*.*','Select DICOM Dose File, RD');

if path == 0
    errordlg('DICOM Dose File Should exist');
    error('DICOM Dose File Should exist');
end

cd(path);

fileList = dir;

filesToRun = {};

matches = strmatch('RD', {fileList.name});

cd(currentDir);

for i = 1:length(matches)
    [maxDose, dA] = getDICOMMaxDose([path fileList(matches(i)).name]);
    dM(i) = maxDose;
end

for i = 1 : planC{7}.FractionGroupSequence.Item_1.NumberOfBeams

    
    BeamMeterset = planC{7}.FractionGroupSequence.Item_1.ReferencedBeamSequence.(['Item_' num2str(i)]).BeamMeterset;
    
    bs = planC{7}.BeamSequence.(['Item_' num2str(i)]);
    
    LS = getDICOMLeafPositions(bs);
           
    [inflMap, xV, yV, colDividerXCoord, rowDividerYCoord, rowLeafPositions] = getLSInfluenceMapFactor(LS,leak,bs.BeamNumber);
          
    gA = bs.ControlPointSequence.Item_1.GantryAngle;
    iC = bs.ControlPointSequence.Item_1.IsocenterPosition;
    
    isocenter.x = iC(1)/10;
    isocenter.y = -iC(2)/10;
    isocenter.z = -iC(3)/10;
      
    isodistance = bs.SourceAxisDistance/10;
    
    isocenter = [isocenter.x,isocenter.y, isocenter.z];
    
    [DoseF, rDepth, xMin, xMax, yMin, yMax, PBSizeX, PBSizeY, maxFlu] = getDose_UnitD(sigma,kernelSize,bs,inflMap, xV, yV,leak);
    
    [xD, yD, zD] = getDoseXYZVals(planC{indexS.dose}(doseNum));
    
    [xM, yM, zM] = meshgrid(xD, yD, zD);
    
    coll3V = scan2Collimator([xM(:) yM(:) zM(:)], (gA/360)*2*pi, 0, 0, isocenter, isodistance);
    
    distsquared = sepsq(coll3V', [0 0 0]');
    
    coll3V = (coll3V./ repmat(coll3V(:,3), [1 3])) * -isodistance;
    
    toKeep = coll3V(:,1) <= xMax + PBSizeX*(kernelSize+1)/2  & coll3V(:,1) >= xMin - PBSizeX*(kernelSize+1)/2 & coll3V(:,2) >= yMin - PBSizeY*(kernelSize+1)/2  & coll3V(:,2) <= yMax + PBSizeY*(kernelSize+1)/2 ;
    
    pointsToInterpolate = coll3V(toKeep,:);
    
    radDepthV = getRadiologicalDepth(xM(toKeep), yM(toKeep), zM(toKeep), (gA/360)*2*pi, isocenter, isodistance, structNum, scanSet, planC);
    
    dV = finterp3(pointsToInterpolate(:,1), pointsToInterpolate(:,2), radDepthV, DoseF, [(xMin - PBSizeX*(kernelSize+1)/2) PBSizeX (xMax + PBSizeX*(kernelSize+1)/2)], [(yMin - PBSizeY*(kernelSize+1)/2)  PBSizeY (yMax +- PBSizeY*(kernelSize+1)/2)], rDepth, 0);
    
    dV = dV./distsquared(toKeep);
    
    dose3D = zeros(size(xM));
         
    dose3D(toKeep) = dV;
    
    dose3D = dose3D/max(dose3D(:));
    
    %Normalize to max dose  
    %dose3D = dM(i)*(dose3D/max(dose3D(:)));
    
    %Normalize to dose at isocentr
    [maxDose, dA] = getDICOMMaxDose([path fileList(matches(i)).name]);
    
    planC{indexS.dose}(end + 1) = planC{indexS.dose}(1);
    planC{indexS.dose}(end).doseArray = dA;
    
    Dose_Cl = getDoseAt(length(planC{indexS.dose}),isocenter(1),isocenter(2),isocenter(3),planC);
    
    planC{indexS.dose}(end) = [];
    
    planC{indexS.dose}(end + 1) = planC{indexS.dose}(1);
    planC{indexS.dose}(end).doseArray = dose3D;
    
    Dose_N = getDoseAt(length(planC{indexS.dose}),isocenter(1),isocenter(2),isocenter(3),planC);
    
    planC{indexS.dose}(end) = [];
    
    dose3D = (Dose_Cl/Dose_N)*dose3D;
    
    if ~exist('dose')
        dose = dose3D;
    else
        dose = dose + dose3D;
    end
    
    clear xM yM zM dose3D;
        
end

mask = find(planC{8}(1).doseArray);

dose1 = zeros(size(planC{8}(1).doseArray));

dose1(mask) = dose(mask);

%dose1 = dose1/max(dose1(:));

planC{8}(end+1) = planC{8}(1);

%mD = max(planC{8}(1).doseArray(:));

%planC{8}(end).doseArray = mD*dose1;

planC{8}(end).doseArray = dose1;

planC{8}(end).fractionGroupID = 'planCheck_Dose'