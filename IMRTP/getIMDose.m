function [dose3D] = getIMDose(IM, PBWeightsV, structsV)
%Create 3D dose matrix from PB weigths (PBWeightsV) and
%a list of structures to have dose computed to (structsV).
%JOD, 14 Nov 03.
%JRA, 27 Feb 04.
%JOD, 6 Sept 05, added single string option to replace structsV,
%e.g., 'skin'. If structsV is a single str, just show dose for that structure.
%JOD, 20 Dec 05, small mods for speed.
%JJW, 20 Jun 06, MCflag removed
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

global planC
indexS = planC{end};

if ischar(structsV)

  %loop to match structure names
  indexS = planC{end};
  ind = indexS.structures;
  numStructs = length(planC{ind});

  toMatch = structsV;
  match = 0;
  for j = 1 : numStructs
    strName = planC{ind}(j).structureName;
    if strcmpi(toMatch,strName)==1
      structsV = j;
      match = 1;
    end
  end
  if match ~=1
    error('Structure not found')
  end

end

%create beamlets structure Array out of all beams
beamlets = [IM.beams(:).beamlets];

%get indices of structures stored under beamlets
structIndV = getAssociatedStr({beamlets(:,1).strUID});

dose3D = [];

%If PBWeights is empty, go to default: evenly weighted
if isempty(PBWeightsV)
    numPBs = size(beamlets,2);
    PBWeightsV = ones(numPBs,1);
end

%Make sure PB is a column vector, for matrix multiplication.
PBWSize = size(PBWeightsV);
if PBWSize(1) == 1;
    PBWeightsV = PBWeightsV';
end

%Shuffle structs to always add highest resolution
%structures first, and don't overwrite - this way hi-res structures are never
%overwritten by low-res structures:
ratesV = [];
for i = 1 : length(structsV)
    strBmletInd = find(structsV(i)==structIndV);
    ratesV = [ratesV, beamlets(strBmletInd,1).sampleRate];
end
[ratesV, iV] = sort(ratesV);
structsV = structsV(iV);

%obtain associated scanNum for structures. It is assumed that all the
%structures are associated to same scan (which is checked in IMRTP.m)
scanNumV = getStructureAssociatedScan(structsV);
scanNum = scanNumV(1);

%For each struct...
for structNum = structsV
    strBmletInd = find(structNum==structIndV);
    if isempty(dose3D)
        %sV = getUniformizedSize(planC);
        sV = getUniformScanSize(planC{indexS.scan}(scanNum));
        dose3D = zeros(sV);
    end
    
    sampleRate = beamlets(strBmletInd,1).sampleRate;
    
    % check if downsampled indices are fractions
    sizeV = size(dose3D);
    if any(mod(sizeV(1)/2^log2(sampleRate),1)) | any(mod(sizeV(2)/2^log2(sampleRate),1))
        errordlg('Size of downsampled dose is a fraction! Cannot Proceed. Please choose a different downsampling rate or choose 1 and solve again','Dose Downsampling Error')
        return
    end

    disp('Getting influence matrix...');
    [inflM] = getGlobalInfluenceM(IM, structNum);
    doseInStruct = inflM * PBWeightsV;

    %If sub-sampled, use 3-D interpolation to fill out dose.
    if sampleRate ~= 1
        
        disp('Inflating downsampled dose distribution...')
        if rem(log2(sampleRate),1) ~= 0
            error('Sample factor must (currently) be a power of 2.')
        end

        %Get interpolation coords.
        maskSample3D = getDown3Mask(dose3D, sampleRate, 1);
        maskStruct3D = getUniformStr(structNum);
        [rInterpV, cInterpV, sInterpV] = find3d(maskStruct3D & ~maskSample3D);
        
        %Now do 3-D interpolation:
        sizeV = size(dose3D);        

        doseInterp = doseInStruct;
        whereV = find(maskSample3D(:));
        clear maskSample3D;
        doseInterp = doseInterp(whereV);
        doseInterp = reshape(doseInterp,[sizeV(1)/2^log2(sampleRate),sizeV(2)/2^log2(sampleRate),sizeV(3)]);

        rDownV = (rInterpV + 2^log2(sampleRate) - 1)/2^log2(sampleRate);
        cDownV = (cInterpV + 2^log2(sampleRate) - 1)/2^log2(sampleRate);

        fillsV = matInterp3(rDownV,cDownV,sInterpV,doseInterp);
        clear doseInterp;

        ind3V = sub2ind(sizeV,rInterpV,cInterpV,sInterpV);  %index for interpolated values
        doseInStruct(ind3V) = fillsV;
        doseInStruct(~maskStruct3D) = 0;
        clear maskStruct3D;
        disp('Finished inflating.')
    end


    for i = 1:size((dose3D),3),
        tmp = [dose3D(:,:,i)==0];
        indStart = sub2ind(sV,1,1,i);
        indStop  = sub2ind(sV,sV(1),sV(2),i);
        doseSlice = reshape(doseInStruct(indStart:indStop),sV(1),sV(2));
        tmp1 = doseSlice .* tmp;  %voxel over-adding avoided
        tmp2 = dose3D(:,:,i) + tmp1;
        dose3D(:,:,i) = tmp2;
    end
    clear doseInStruct;
    % dose3D = dose3D + doseInStruct.* [dose3D==0];
end
