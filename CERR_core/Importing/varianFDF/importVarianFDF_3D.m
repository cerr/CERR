function planC = importVarianFDF_3D(dirT,optFile)
% function planC = importVarianFDF_3D(dirT,optFile)
% Input: directory containing multi-frame FDF file and CERRoptions
% file or optS structure
% Output: CERR plan (planC)
% Example:
% dirT = 'C:\Projects\FDF reader\Test_data_Joel\3D-Large';
% optFile = 'CERROptions.m';
% planC = importVarianFDF_3D(dirT,optFile);
%
% APA, 05/15/2007
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


% Check the format of optFile.
if ~isstruct(optFile)
    optS = opts4Exe(optFile);
else
    optS = optFile;
end

planC = initializeCERR;
indexS = planC{end};
planC{indexS.CERROptions} = optS;
planC{indexS.indexS}     = indexS;


pathT=[dirT,'/'];

%%%% Import Transverse slices and interpolate

% 1> Read [X,Y,Z,f] from transverse slices

%%%%% Extract Data for Transverse Section
contents = dir(fullfile(pathT,'*.fdf'));
[header, data] = readVarianFDF_3D(pathT, contents(1).name);
for i=1:size(data,3)
    H{i}=header; DATA{i}=data(:,:,i);
    %%% Extract info from header
    fbr1=find(header=='{');
    fbr2=find(header=='}');
    MatrixDim(i,:)=str2num(header(fbr1(1)+1:fbr2(1)-1));
    span(i,:)=str2num(header(fbr1(4)+1:fbr2(4)-1));
    offset(i,:)=str2num(header(fbr1(5)+1:fbr2(5)-1));
    sliceCenter(i,:)=str2num(header(fbr1(8)+1:fbr2(8)-1));
    xC(i)=sliceCenter(i,1); yC(i)=sliceCenter(i,2);
    %zC(i)=sliceCenter(i,3);
    roi(i,:)=str2num(header(fbr1(9)+1:fbr2(9)-1));
    orientation(i,:)=str2num(header(fbr1(10)+1:fbr2(10)-1));
end
zC = linspace(0,span(1,3),MatrixDim(1,3));
sizeOfDimension1=MatrixDim(1,1);
sizeOfDimension2=MatrixDim(1,2);
sizeOfDimension1U=sizeOfDimension1; sizeOfDimension2U=sizeOfDimension2;
sizeDim1 = sizeOfDimension1-1;
sizeDim2 = sizeOfDimension2-1;
xSpan=span(1,1); ySpan=span(1,2);
xOffset=sliceCenter(1,1); yOffset=sliceCenter(1,2);
xOffsetU=xOffset; yOffsetU=yOffset;
grid2Units=xSpan/sizeDim2;
grid1Units=ySpan/sizeDim1;
voxelThickness=zC(2)-zC(1);

% xVals = xOffset - (sizeDim2*grid2Units)/2 : grid2Units : xOffset + (sizeDim2*grid2Units)/2;
% yVals = yOffset - (sizeDim1*grid1Units)/2 : grid1Units : yOffset + (sizeDim1*grid1Units)/2;
% zVals = zC;
% [Xt,Yt] = meshgrid(xVals,yVals);
% XXt=Xt(:); YYt=Yt(:);
% XTrans=[]; DD=[]; DDt=[];
% for i=1:length(zVals)
%     XTrans=[XTrans;
%         XXt, YYt, zVals(i)*XXt.^0];
%         DD1=DATA{i};
%     DD=[DD;
%         DD1(:)];
%     DDt=[DDt;
%         DD1(:)];
% end
% 
% %% Reshape Data
% DDT3=reshape(DDt,[sizeOfDimension1,sizeOfDimension2,length(zVals)]);

DDT3 = data;

for i=1:length(zC)
    scanInfo(i).grid1Units=grid1Units;
    scanInfo(i).grid2Units=grid2Units;
    scanInfo(i).sizeOfDimension1=sizeOfDimension1U;
    scanInfo(i).sizeOfDimension2=sizeOfDimension2U;
    scanInfo(i).xOffset=xOffsetU;
    scanInfo(i).yOffset=yOffsetU;
    scanInfo(i).voxelThickness=voxelThickness;
    scanInfo(i).zValue=zC(i);
    scanInfo(i).CTOffset=1000;
    scanInfo(i).sliceThickness=[];    
    scanInfo(i).imageType = 'MR Scan';
end
planC{3}(1).scanInfo = scanInfo;

minScanArray = min(DDT3(:));
maxScanArray = max(DDT3(:));
scanArray = (DDT3-minScanArray)/maxScanArray*4095;
planC{3}.scanArray = scanArray;
planC{3}.scanType = 'MRI';
planC{3}.scanUID = createUID('scan');
planC = setUniformizedData(planC,optS);


return


