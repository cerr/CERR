function [A_zV, a_zV, B_zV, b_zV] = GetPBConsts(DepthsV, EnergyC, PBDataS, flag);

%       - constantsAaBb(1) - depth
%       - constantsAaBb(2) - A
%       - constantsAaBb(3) - a
%       - constantsAaBb(4) - B
%       - constantsAaBb(5) - b
%
%     Example
%     using Ahnesjoe's notation
%     0.075  2.0958E-02  22.777100  1.8582E-05  0.058308
%     0.225  2.4948E-02  12.957500  2.1138E-05  0.067823
%
%LM:  JOD, 3 Nov 03, allow nearest neighbor indexing.
%JOD, 17 Nov 03, added scale factor, default at 100.
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

scale = 100;
%For convenience, scale up A and B coefficients, so dose values are closer to unity.

if nargin == 4 & strcmp(flag,'nearest')

  Aahn6=PBDataS.aahn6b;
  Aahn18=flipud(PBDataS.aahn18b);

  MaxDepth=50;

  if EnergyC==6
   ParamMat=Aahn6;

  else
   if EnergyC==18
    ParamMat=Aahn18;
   end
  end

  DepthTableV=ParamMat(:,1);

  %our own linear interpolation (faster than Matlab).
  %compute two interpolation indices:
  if any([DepthsV>MaxDepth])
       disp('Warning!  Some depths exceed 50 cm, which is dosimetry limit!')
  end

  DepthsV=DepthsV.*[DepthsV<=MaxDepth]+MaxDepth.*[DepthsV>MaxDepth];

  IndexLow=floor((DepthsV+0.075)/0.15)+1;
  IndexHigh=ceil((DepthsV+0.075)/0.15)+1;

  DepthLow=DepthTableV(IndexLow);
  DepthHigh=DepthTableV(IndexHigh);

  indexV = round((DepthsV+0.075)/0.15)+1;


  A_zV= ParamMat(indexV,2);
  a_zV= ParamMat(indexV,3);
  B_zV= ParamMat(indexV,4);
  b_zV= ParamMat(indexV,5);


  A_zV = A_zV * scale;
  B_zV = B_zV * scale;

  return

end


%-----------code below not currently used (terrible!)---------------------%



Aahn6=PBDataS.aahn6b;
Aahn18=flipud(PBDataS.aahn18b);
Aahn8MCF=flipud(PBDataS.aahn8MMM);

MaxDepth=50;

if EnergyC==6
 ParamMat=Aahn6;
else
 if EnergyC==18
  ParamMat=Aahn18;
 end
end

if EnergyC==8
   ParamMat=Aahn8MCF;
   MaxDepth=20;
end

DepthTableV=ParamMat(:,1);

%our own linear interpolation (faster than Matlab).
%compute two interpolation indices:
if any([DepthsV>MaxDepth])
     warning('Some depths exceed 50 cm, which is dosimetry limit!')
 end

DepthsV=DepthsV.*[DepthsV<=MaxDepth]+MaxDepth.*[DepthsV>MaxDepth];

IndexLow=floor((DepthsV+0.075)/0.15)+1;
IndexHigh=ceil((DepthsV+0.075)/0.15)+1;

if EnergyC==8
    IndexLow=floor((DepthsV)/0.253) + 1;
    IndexHigh=ceil((DepthsV)/0.253) + 1;
    IndexLow(IndexLow > length(ParamMat(:,1))) = length(ParamMat(:,1));
    IndexHigh(IndexHigh > length(ParamMat(:,1))) = length(ParamMat(:,1));
end


DepthLow=DepthTableV(IndexLow);
DepthHigh=DepthTableV(IndexHigh);

A_zV=((ParamMat(IndexLow,2).*(DepthHigh-DepthsV)+...
    ParamMat(IndexHigh,2).*(DepthsV-DepthLow))./(DepthHigh-DepthLow+10*eps)).*...
      [DepthHigh~=DepthLow]+ParamMat(IndexLow,2).*[DepthHigh==DepthLow];
a_zV=((ParamMat(IndexLow,3).*(DepthHigh-DepthsV)+...
    ParamMat(IndexHigh,3).*(DepthsV-DepthLow))./(DepthHigh-DepthLow+10*eps)).*...
      [DepthHigh~=DepthLow]+ParamMat(IndexLow,3).*[DepthHigh==DepthLow];
B_zV=((ParamMat(IndexLow,4).*(DepthHigh-DepthsV)+...
   ParamMat(IndexHigh,4).*(DepthsV-DepthLow))./(DepthHigh-DepthLow+10*eps)).*...
      [DepthHigh~=DepthLow]+ParamMat(IndexLow,4).*[DepthHigh==DepthLow];
b_zV=((ParamMat(IndexLow,5).*(DepthHigh-DepthsV)+...
     ParamMat(IndexHigh,5).*(DepthsV-DepthLow))./(DepthHigh-DepthLow+10*eps)).*...
       [DepthHigh~=DepthLow]+ParamMat(IndexLow,5).*[DepthHigh==DepthLow];

%clear IndexLow IndexHigh DepthLow DepthHigh


%Scale final answers for convenience:

A_zV = A_zV * scale;
B_zV = B_zV * scale;



