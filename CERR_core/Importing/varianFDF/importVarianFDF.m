function planC = importVarianFDF(dirT,optFile)
% function scanS = importVarianFDF(dirT,optFile)
% Input: directory containing FDF files and CERRoptions
% file or optS structure
% Output: CERR plan (planC)
% Example
% dirT = 'C:\Projects\FDF reader\Test_data_Joel\gems_trans_pre-CA.dat';
% optFile = 'CERROptions.m';
% planC = importVarianFDF(dirT,optFile);
%
%  Written DK 02/16/2010
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


if exist('dirT')
    pathT=dirT;
else
    pathT = uigetdir(pwd','Select Single Data FDF directory:');
    if pathT == 0
        return
    end
end

contents = dir(fullfile(pathT,'*.fdf'));

hWait = waitbar(0,'Reading Slice');
for i=1:length(contents)
    waitbar(i/length(contents),hWait,['Reading Slice ',num2str(i)]);
    [outheader, data] = readVarianFDF(pathT, contents(i).name);
    header(i)=outheader;
    scanArray(:,:,i) = data;
end
close(hWait)


% Check the format of optFile.
if exist('optFile')
    if ~isstruct(optFile)
        optS = opts4Exe(optFile);
    else
        optS = optFile;
    end
else
    optS = CERROptions;
end

planC = initializeCERR;
indexS = planC{end};
planC{indexS.CERROptions} = optS;
planC{indexS.indexS}     = indexS;

scanInfo = initializeScanInfo;

[ZSlice, zOrder]   = sort([header.zValue]);
header(1:end) = header(zOrder);
scanArray(:,:,1:end) = scanArray(:,:,zOrder);

for i=1:length(header)
    scanInfo(i).grid1Units=header(i).grid1Units;
    scanInfo(i).grid2Units=header(i).grid2Units;
    scanInfo(i).sizeOfDimension1=header(i).sizeOfDimension1;
    scanInfo(i).sizeOfDimension2=header(i).sizeOfDimension2;
    scanInfo(i).xOffset=header(i).xOffset;
    scanInfo(i).yOffset=header(i).yOffset;
    scanInfo(i).zValue=header(i).zValue;
    scanInfo(i).CTOffset=1000;
    scanInfo(i).sliceThickness=[];
    scanInfo(i).imageType = header(i).imageType;
    scanInfo(i).patientName = 'FDF^Scan';
end

minScanArray = min(scanArray(:));
maxScanArray = max(scanArray(:));
scanArray = (scanArray-minScanArray)/maxScanArray*4095;

planC{indexS.scan}(1).scanInfo = scanInfo;
planC{indexS.scan}.scanArray = scanArray;
planC{indexS.scan}.scanType = 'MRI';
planC{indexS.scan}.scanUID = createUID('scan');
planC = setUniformizedData(planC,optS);

if nargout == 1
    return
else
    save_planC(planC,optS);
end