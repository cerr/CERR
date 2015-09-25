%function [W]=myCTwriteVMC(inputCT,Xnew, Ynew, Znew);
function [W]=myCTwriteVMC(inputCT,scaleX, scaleY, scaleZ, str);
  
% Create CT input file *.ct for VMC++ engine from CERR MatLab CT matrix
% scaleX - X voxel size in cm
% scaleY - Y voxel size in cm
% scaleZ - Z voxel size in cm
% numSlice - number of slices in CT matrix
% In this code CERR CT data converted to density from HF (water has 1024).
% CT coordinate system is following that real (Xmin,Ymin,Zmin) is (0,0,0) in all cases here
% Output - *.ct file and dimension
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


CT=inputCT;
W=size(CT);

%[newfile,newpath] = uiputfile('*.ct','Enter CT file name for VMC++ input ');
%str=strcat(newpath,newfile);

fid=fopen(str,'w');

count=fwrite(fid,W(1),'int32');
count=fwrite(fid,W(2),'int32');
count=fwrite(fid,W(3),'int32');

%X=[0 Xnew];
%Y=[0 Ynew];
%Z=[0 Znew];

X(1)=0;
for i=1:W(1),
    X(i+1)=scaleX*i;
end
Y(1)=0;
for i=1:W(2),
    Y(i+1)=scaleY*i;
end
Z(1)=0;
for i=1:W(3),
    Z(i+1)=scaleZ*i;
end

count=fwrite(fid,X,'float32');
count=fwrite(fid,Y,'float32');
count=fwrite(fid,Z,'float32');
scale=1e3;
%h = waitbar(0,'Please wait for CT file writing');
density_max=4;
for k=1:W(3),
    temp=double(CT(:,:,k))/1024; % round up to 2 decimal places
    temp(temp>density_max)=density_max-1e-6; % cut values greater than 3.
    count=fwrite(fid,temp,'float32');
%    waitbar(k/W(3));
end

%close(h);
fclose(fid);

numSlice=W(3);