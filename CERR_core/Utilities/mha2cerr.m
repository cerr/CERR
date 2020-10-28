function planC = mha2cerr(infoS,data3M,movScanOffset,movScanName,planC,save_flag)
%"mha2cerr"
%   Create an scan based mha header and 3D volume. 
%
%   APA, 07/05/2012
%
%   Usage: planC = mha2cerr(infoS,data3M)
%
%   Example:
%         mhdFilePath = 'D:\path\to\ctScan.mhd'
%         
%         [data3M,infoS] = readmha(mhdFilePath);
%         datamin = min(data3M(:));
%         movScanOffset = 0;
%         if datamin < 0
%             movScanOffset = -datamin;
%         end
%         movScanName = 'CT';
% 
%         if ~exist('planC','var')
%             planC = initializeCERR;
%         end
% 
%         indexS = planC{end};
%         save_flag = 1;
%         planC  = mha2cerr(infoS,data3M,movScanOffset,movScanName, planC, save_flag);
%         
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

% Initialize planC

global stateS

CTOffset = double(movScanOffset);
%save_flag = 0;
if ~exist('planC','var') || (exist('planC','var') && isempty(planC))
    planC = initializeCERR;
    %save_flag = 1;
end

indexS = planC{end};

xValsV = infoS.Offset(1)/10  : infoS.PixelDimensions(2)/10 : infoS.Offset(1)/10 + infoS.PixelDimensions(2)*(infoS.Dimensions(1)-1)/10;
yValsV = -infoS.Offset(2)/10  :-infoS.PixelDimensions(2)/10 : -infoS.Offset(2)/10 - infoS.PixelDimensions(1)*(infoS.Dimensions(2)-1)/10;

zValsV = -infoS.Offset(3)/10: -infoS.PixelDimensions(3)/10 : -infoS.Offset(3)/10 - infoS.PixelDimensions(3)*(infoS.Dimensions(3)-1)/10;
zValsV = fliplr(zValsV);

ind = length(planC{indexS.scan}) + 1; 

%Create array of all zeros, size of y,x,z vals.
%planC{indexS.scan}(ind).scanArray = uint16(flipdim(permute(data3M,[2,1,3]),3) + CTOffset);
data3M = flipdim(permute(data3M,[2,1,3]),3) + CTOffset;
if strcmpi(class(data3M),'int16')
    data3M = uint16(data3M);
end
planC{indexS.scan}(ind).scanArray = data3M;
planC{indexS.scan}(ind).scanType = movScanName;
planC{indexS.scan}(ind).scanUID = createUID('scan'); 
%planC{indexS.scan}(ind).uniformScanInfo = [];
%planC{indexS.scan}(ind).scanArrayInferior = [];
%planC{indexS.scan}(ind).scanArraySuperior = [];
%planC{indexS.scan}(ind).thumbnails = [];

scanInfo = initializeScanInfo;

scanInfo(1).grid2Units = infoS.PixelDimensions(2)/10;
scanInfo(1).grid1Units = infoS.PixelDimensions(1)/10;
scanInfo(1).sizeOfDimension1 = infoS.Dimensions(2);
scanInfo(1).sizeOfDimension2 = infoS.Dimensions(1);
scanInfo(1).imageType = movScanName;
scanInfo(1).CTOffset = CTOffset;

%Calculate the correct scan offset values based on x,y,z vals.
scanInfo(1).xOffset = xValsV(1) + (scanInfo(1).sizeOfDimension2-1)*scanInfo(1).grid2Units/2;
scanInfo(1).yOffset = yValsV(end) + (scanInfo(1).sizeOfDimension1-1)*scanInfo(1).grid1Units/2;
scanInfo(1).zValue = 0;

sliceThickness = infoS.PixelDimensions(3)/10;

%Populate scanInfo(1) array.
for i=1:length(zValsV)
    scanInfo(1).sliceThickness = sliceThickness;
    scanInfo(1).zValue = zValsV(i);
    planC{indexS.scan}(ind).scanInfo(i) = scanInfo(1);
end

if ~isempty(stateS) 
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(ind).scanUID(max(1,end-61):end))];
    %stateS.scanStats.minScanVal.(scanUID) = single(min(planC{indexS.scan}(ind).scanArray(:)));
    %stateS.scanStats.maxScanVal.(scanUID) = single(max(planC{indexS.scan}(ind).scanArray(:)));
    minScan = single(min(planC{indexS.scan}(ind).scanArray(:)));
    maxScan = single(max(planC{indexS.scan}(ind).scanArray(:)));    
    scanDiff = maxScan - minScan;
    scanCenter = (minScan + maxScan - 2*CTOffset) / 2;
    stateS.scanStats.CTLevel.(scanUID) = scanCenter;
    stateS.scanStats.CTWidth.(scanUID) = scanDiff;
    stateS.scanStats.Colormap.(scanUID) = 'gray256';
    stateS.scanStats.windowPresets.(scanUID) = 1;
end

% Populate CERR Options
planC{indexS.CERROptions} = opts4Exe([getCERRPath,'CERROptions.json']);

planC = setUniformizedData(planC);

pause(0.05)

if save_flag
    save_planC(planC);
end

