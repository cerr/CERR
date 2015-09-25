function ApplyQiB()
%A rountine to execute the QIB on a computer cluster
% Written By: Issam El Naqa    Date: 10/3/03
% Revised by:                  Date:  
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

% read a treatment plan in "mat" format
[filename, pathname] = uigetfile('*.mat', 'Load a treatment plan');
load([pathname,filename]);
D=1; % downsample factor (optional)
indexS = planC{end};
scaleX=planC{indexS.scan}.scanInfo(1).grid1Units*D;
scaleY=planC{indexS.scan}.scanInfo(1).grid2Units*D;
scaleZ=planC{indexS.scan}.scanInfo(1).sliceThickness;
% get the CT file
inputCT=planC{indexS.scan}.scanArray;
% apply down sampling and cropping
vecx=145:D:394; vecy=126:D:375; vecz=40:99;
inputCTc=inputCT(vecx,vecy,vecz);  clear inputCT 
CTdim=size(inputCTc);
% add margins of 1 cm to the targets
Margin=1;
TargetStructNum=[17,18];
inputMask1 = getMask3D(TargetStructNum(1),planC);
inputMask2 = getMask3D(TargetStructNum(2),planC);
inputMask=inputMask1 | inputMask2;
inputMasks=inputMask(vecx,vecy,vecz); % just cropping
clear planC inputMask1 inputMask2 inputMask
b=genball(7,Margin/2,[scaleX,scaleY,scaleZ]); % plan specific
% treat the targets separately!
inputMaskb=convn(inputMasks,b,'same'); 
einputMask=uint8(inputMaskb>0);
ind=regexp(filename,'.mat');
maskfile=filename(1:ind-1);
%save([pathname,maskfile,'_targetmask.mat'],'inputMasks','einputMask','CTdim','scaleX','scaleY','scaleZ');
gridX_distance100=1; gridY_distance100=1;
Energy=6; % plan specific and is inversely proportional to the squared uncertainity
Nbeams=9; % plan specific
Source_Distance=100;
[x,y]=circle([0,0], Source_Distance,Nbeams);
SCRCM=[x(1:Nbeams);y(1:Nbeams);zeros(1,Nbeams)];
% not clear about conventions?!
for N=1:Nbeams
    beam_num=N
    % need to be worked out?!
    [targetBeamGridCoor, numberPB(N),OSC]=mybeamgridcoordinatesVMC(einputMask,scaleX,scaleY,scaleZ,gridX_distance100,gridY_distance100,SCRCM(:,N)); % this is wrong!
    for i=1:numberPB(N)
        [DoseF, downCT, vCT, depthCor] = get_PB_3D(Energy,gridX_distance100,gridX_distance100,Source_Distance,angle,shift,planC);
        %temporal saving! need to be changed to other format?!
        str=[filename,'_beam',num2str(N),'_pb',num2str(i)];
        fid=fopen(str,'w');
        fwrite(fid,CTdim(1),'int32'); fwrite(fid,CTdim(2),'int32');  fwrite(fid,CTdim(3),'int32');
        fwrite(fid,downCT,'float32'); fwrite(fid,vCT,'float32');  fwrite(fid,depthCor,'float32');
        fwrite(fid,DoseF,'float32');
    end
end

function b=genball(N,r,Scale)
% make a ball of dimension NxNxN and radius r, scaled by Scale
Lc=floor(N/2);
vec=-Lc:Lc;
[x,y,z]=meshgrid(vec*Scale(1),vec*Scale(2),vec*Scale(3));
r2=x.^2+y.^2+z.^2;
b=zeros(N,N,N);
b(find(r2<r^2))=1;
return

function [x,y]=circle(c, r, nsides)
% a poly circle routine with center c, radius r, and nsides
nsides = round(nsides);  % make sure it is an integer
a = [0:2*pi/nsides:2*pi];
x=r*cos(a)+c(1);
y=r*sin(a)+c(2);
%line(x,y); uncomment for plotting
return







