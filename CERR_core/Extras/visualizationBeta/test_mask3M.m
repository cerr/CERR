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

%mask3M = double(mask3MU2);

sampleTrans = 4;
sampleAxis  = 2;

[maskDown3M] = getDownsample3(mask3MU, sampleTrans, sampleAxis);

sV = size(maskDown3M);
[x,y,z] = meshgrid(1:sV(1),1:sV(2),1:sV(3));
%spd = sqrt(u.*u + v.*v + w.*w);
daspect([1 1 1]);
p = patch(isosurface(x,y,z,maskDown3M,0.5));
isonormals(x,y,z,maskDown3M,p);
set(p,'FaceColor','red','EdgeColor','None','FaceAlpha',.3);

%m2 = mask3MU4;

%[m3] = getDownsample3(mask3MUb, sampleTrans, sampleAxis);
%p = patch(isosurface(x,y,z,m3,0.5));
%isonormals(x,y,z,m3,p);
%set(p,'FaceColor','cyan','EdgeColor','None','FaceAlpha',.5);


axis tight; box on
camproj perspective; camva(5);
camlight left; lighting gouraud






