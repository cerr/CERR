function [dose3D, A_z3D, r3D, PB3D] = getInfluence(IM, structNum, PBWeightsV)
%Create 3D dose matrix from PB weigths (PBWeightsV) and
%a list of structures to have dose computed to (structsV).
%JOD, 14 Nov 03.
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

% maskSingle3D = getUniformStr(structNum);

maskSingle3D = getSurfaceExpand(structNum,0.5,1); %%%Expandewd structure

[rowV, colV, sliceV] = find3d(maskSingle3D);

numPBs = size(IM.beamlets,2);

influenceM = sparse(prod(size(maskSingle3D)),numPBs);

s = size(maskSingle3D);

doseInStruct = zeros(s);

sampleRate = IM.beamlets(structNum,1).sampleRate;

if sampleRate ~= 1
    disp('Inflating downsampled dose distribution...')
  if rem(log2(sampleRate),1) ~= 0
    error('Sample factor must (currently) be a power of 2.')
  end
  maskSample3D = getDown3Mask(maskSingle3D, sampleRate, 1);

  tmp3D = maskSample3D .* maskSingle3D;

  [rowV,colV,sliceV] = find3d(tmp3D);

  clear tmp3D

  toInterp3D = ~maskSample3D .* maskSingle3D;

  [rInterpV,cInterpV,sInterpV] = find3d(toInterp3D);

end

dose3D = zeros(s);
 
for PBNum = 1 : size(IM.beamlets,2)       %Loop over beamlets

  if ~isempty(IM.beamlets(structNum,PBNum).influence)

    doseV     = double(IM.beamlets(structNum,PBNum).influence);
    indV      = IM.beamlets(structNum,PBNum).indexV;
    maxVal    = IM.beamlets(structNum,PBNum).maxInfluenceVal;
    sizeParam = IM.beamlets(structNum,PBNum).fullLength;

    doseScaledV = PBWeightsV(PBNum) * (doseV * maxVal) /(2^8 -1);

    %inflate:
    doseInflateV = zeros(1,sizeParam);
    doseInflateV(indV) = doseScaledV;
    

    %Then put into the dose3D matrix:
    ind2V = sub2ind(size(dose3D), rowV, colV, sliceV);
      

    doseInStruct(ind2V) = doseInStruct(ind2V) + doseInflateV(:);

    if strcmpi(IM.params.debug(1),'y')
      ind0V =IM.beamlets(structNum,PBNum).rIndex;
      AInflate = zeros(1,sizeParam);
      rInflate = zeros(1,sizeParam);
      AInflate(ind0V) = PBWeightsV(PBNum) * double(IM.beamlets(structNum,PBNum).A_zV);
      A_z3D(ind2V) = AInflate(:); %overwrite
      rInflate(ind0V) = PBWeightsV(PBNum) * double(IM.beamlets(structNum,PBNum).r);
      r3D(ind2V) = rInflate(:); %overwrite
      PB3D(ind2V) = PBNum * ones(length(rInflate),1);
    end

  end

end

%If sub-sampled, use 3-D interpolation to fill out dose.

if sampleRate ~= 1

  %Now do 3-D interpolation:
  sizeV = size(dose3D);

  doseInterp = doseInStruct;
  %Get rid of all points which are not sampled
  [r3V,c3V,s3V] = find3d(maskSample3D);
  whereV = sub2ind(sizeV,r3V,c3V,s3V);
  doseInterp = doseInterp(whereV);
  doseInterp = reshape(doseInterp,[sizeV(1)/2^log2(sampleRate),sizeV(2)/2^log2(sampleRate),sizeV(3)]);

  rDownV = (rInterpV + 2^log2(sampleRate) - 1)/2^log2(sampleRate);
  cDownV = (cInterpV + 2^log2(sampleRate) - 1)/2^log2(sampleRate);

  fillsV = matInterp3(rDownV,cDownV,sInterpV,doseInterp);

  ind3V = sub2ind(sizeV,rInterpV,cInterpV,sInterpV);  %index for interpolated values
  doseInStruct(ind3V) = fillsV;
  disp('Finished inflating.')
end

dose3D = dose3D + doseInStruct .* [dose3D==0];  %voxel over-adding avoided




