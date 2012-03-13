function volumeRendering(command)
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

global planC stateS;
indexS = planC{end};

[origin, spacing, center] = getScanOriginSpacing(planC{indexS.scan}(stateS.scanSet));

scanData = planC{indexS.scan}(stateS.scanSet).scanArray;
%scanData = planC{indexS.dose}(stateS.doseSet).doseArray;
% spacing = [1 1 3];

switch upper(command)
    
    case 'MIP'
        colormap = [];
%         scanData=GPReduce2(scanData,2,0);
        sampleRatio = 2;
        scanData = scanData(1:sampleRatio:end, 1:sampleRatio:end, 1:sampleRatio:end);
        Render3D_MIP(uint16(permute(scanData,[3,1,2])),colormap', 1, [spacing(3),spacing(1),spacing(2)]*10, 1);
        
    case 'MIP2'
        colormap = [];
        cData3M = scanDoseFusion();
        cData3M = permute(cData3M, [4,1,2,3]);
        [m,n,o,p] = size(cData3M);
        cData3M = reshape(cData3M, [n,o,p*m]);
        alphaRatio = 30;
        Render3D_MIP(uint16(cData3M),colormap', 2, spacing*10, alphaRatio);
        
    case 'VR1'
%         colormap = [  0.0     0.0   0.0   0.0   0.0;  ...
%                        200.0   0     0     0.8   0.02;  ...
%                        400.0   0.0   1.0   0.0   .8;  ...
%                        600.0   1.0   1.0   0.0   .6; ...
%                        800.0   1.0   0.0   0.0   .7; ...
%                       1000.0   0.0   1.0   1.0   1; ]; 

        [strVol, colormap] = generateStructVolume();
        sagOn  = 0;
        axOn   = 1; 
        corOn  = 1;
        skinOn = 0;
        boneOn = 1;
        sagPos = 130; 
        axPos  = 30;
        corPos = 100;
        tRange1 = 2500;
        tRange2 = 1500;
        tRange3 = 1500;
        skinAlpha = 0.3;
        boneAlpha = 0.8;
        Render3D_S(uint16(strVol(:,:,20:end)),colormap', 2, spacing, ...
            sagOn, axOn, corOn, skinOn, boneOn, sagPos, axPos, corPos, tRange1, tRange2, tRange3, skinAlpha, boneAlpha);
        
    case 'VR2'
        colormap = [   0    1    1   1    .0  ...
                      255   1    1   1    .0  ...
                      800   .9   .9  .9   .1  ...
                      1000  .9   .9  .3   .1  ...
                      1010  1   1  1   1  ...
                      1020  1   1  1   1  ...
                      1030  1   1  1   1  ...
                      1040  1   1  1   1  ...
                      1050  .6   .0  .6   .7  ...
                      1060  .6   .0  .6   .7  ...
                      1070  .6   .0  .6   .7  ...
                      1080  .0   .9  .0   1  ...
                      1090  .0   .6  .0   1  ...
                      1100  .0   .3  .0   1  ...
                      1150  .0   .8  .0   .1  ...
                      1200  .0   .4  .0   .9  ...
                      1500  .0   .6  .0   .9  ...
                      2000  .0   .8  .8   .9  ...
                      4000  1    1   1    1.0 ];
              
%         scanData = smooth3(scanData, 'gaussian');
        Render3D_V(uint16(scanData(:,:,40:end)),colormap', 2, spacing);
        
end        