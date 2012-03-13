function [offset, bbox]=generateCT_uniform(inputCT, ctfilename, scanNum, fillWater);
% inputCT is the uniformized CT scan?
% adapted from Issam/Constantine's code 
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
  
%  [filename, pathname] = uigetfile('*.mat', 'Load a treatment plan');
%load([pathname,filename]);

global planC

indexS = planC{end};
scaleX=planC{indexS.scan}(scanNum).uniformScanInfo.grid1Units;
scaleY=planC{indexS.scan}(scanNum).uniformScanInfo.grid2Units;
scaleZ=planC{indexS.scan}(scanNum).uniformScanInfo.sliceThickness;

if scanNum>1
    i = [find(strcmpi({planC{indexS.structures}.structureName}, [num2str(scanNum),' - skin'])), find(strcmpi({planC{indexS.structures}.structureName}, [num2str(scanNum),' - body'])) ]
else
    i = [find(strcmpi({planC{indexS.structures}.structureName}, 'skin')), find(strcmpi({planC{indexS.structures}.structureName}, 'body')) ];
end
if isempty(i)
    error('Skin structure must be defined to generate a uniform CT.');
else
    i = i(1);    
end
    
structureNumber=i;
skinMask=getUniformStr(structureNumber);
%find the bounding box for the skin contour
bbox=boundingBox(skinMask);

% origin (0, 0, 0) is at the geometrical centre of the CT dataset
n=size(inputCT);
c=(n+1)/2;
%X=((1:n(1))-c(1))*scaleX;
%Y=((1:n(2))-c(2))*scaleY;
%Z=((1:n(3))-c(3))*scaleZ;
X=((1:n(1))-c(1))*scaleX+planC{indexS.scan}(scanNum).uniformScanInfo.xOffset;
%Y=((n(2):-1:1)-c(2))*scaleY+planC{3}.uniformScanInfo.yOffset;
Y=((1:n(2))-c(2))*scaleY+planC{indexS.scan}(scanNum).uniformScanInfo.yOffset;
Z1=planC{indexS.scan}(scanNum).uniformScanInfo.firstZValue;
Z=Z1:scaleZ:Z1+n(3)*scaleZ;

%THIS IS THE FIX:::
Y=Y(end:-1:1);

if fillWater   % Assign everything of skinMask to water
    inputCT = 1000*ones(size(inputCT));
end

% assuming that the max CT values is 4096 ??
% don't want CT values of '0' as this will result in holes 
% in the dose distribution
inputCT(inputCT<0.001*1024)=1024*0.001;
%inputCT(inputCT<eps)=eps;
inputCT=double(inputCT).*double(skinMask);

inputCT=inputCT(bbox(1):bbox(2), bbox(3):bbox(4), bbox(5):bbox(6));

Xnew=X(bbox(3):bbox(4));
Ynew=Y(bbox(1):bbox(2));
Znew=Z(bbox(5):bbox(6));

offset=[Ynew(end) Ynew(1) Xnew(1) Xnew(end) Znew(1) Znew(end)];
%Xnew=Xnew-Xnew(1)+scaleX;
%Ynew=Ynew-Ynew(1)+scaleY;
%Znew=Znew-Znew(1)+scaleZ;

%CTdim=myCTwriteVMC(inputCT,Xnew, Ynew, Znew);

% "real" origin is at the geometrical centre of the CT dataset
%  need to find the offset for the isocentre and collimators

CTdim=myCTwriteVMC(inputCT, scaleY, scaleX, scaleZ, ctfilename);
