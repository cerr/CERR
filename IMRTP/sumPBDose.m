%sumPBDose.m:  Compute dose
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

beamNum = 1;

RTOG  = beamletsS(beamNum).RTOGPBVectorsM;

structNum = 1;

n = size(RTOG,1);

sumOverV = 1:n;

weightsV = ones(size(sumOverV));

maskSingle3D = getUniformStr(structNum);

[rowV, colV, sliceV] = find3d(maskSingle3D);

dose3D  = zeros(size(maskSingle3D));


for PBNum = sumOverV

  doseV  = double(beamletsS(beamNum).PBData(PBNum).influence.doseInStruct);
  indV   = beamletsS(beamNum).PBData(PBNum).influence.indexV;
  maxVal = beamletsS(beamNum).PBData(PBNum).influence.maxVal;
  sizeParam = beamletsS(beamNum).PBData(PBNum).influence.sizeParam;

  doseScaledV = weightsV(PBNum) * (doseV * maxVal) /(2^8 -1);

  %inflate:
  doseInflateV = zeros(1,sizeParam);
  doseInflateV(indV) = doseScaledV;

  %Then put into the dose3D matrix:

  indV = sub2ind(size(dose3D), rowV, colV, sliceV);

  dose3D(indV) = dose3D(indV) + doseInflateV(:);

end

[r,c,s] = find3d([dose3D == max(dose3D(:))]);

figure

imagesc(dose3D(:,:,s(1)))

colorbar

[CTUniform3D, CTUniformInfoS] = getUniformizedCTScan;

register = 'UniformCT';
doseError = [];
fractionGroupID = 'CERR test';
doseEdition = 'CERR test';
description = 'Test PB distribution.'
overWrite = 'no';
%dose2CERR(dose3D,doseError,fractionGroupID,doseEdition,description,register,[],overWrite)
dose2CERR(dose3D/max(dose3D(:)),doseError,fractionGroupID,doseEdition,description,register,[],overWrite)

