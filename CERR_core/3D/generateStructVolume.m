function [scanData, colormap] = generateStructVolume()
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

    sampleRatio = 2;
    scanStruct = planC{indexS.scan}(stateS.scanSet);

    scanData = scanStruct.scanArray(1:sampleRatio:end, 1:sampleRatio:end, 1:sampleRatio:end);
%     scanData=GPReduce2(scanData,2,0);
        
%     scanData(find(scanData<5000)) = 10; %#ok<FNDSB>
    
    structNum = find([planC{indexS.structures}.visible]);
%     for i=1:numel(planC{indexS.structures})
%         if(strcmpi(planC{indexS.structures}(i).structureName, 'Body')||strcmpi(planC{indexS.structures}(i).structureName, 'Skin'))
%            w = structNum(1);
%            structNum(1) = i;
%            structNum(end+1) = w;
%            break;
%         end
%     end
    colormap = [0.0  0.0  0.0  0.0  0.0]; 
%     for i=1:numel(structNum)
% %         tempMask = getUniformStr(structNum(i));
%         [tempMask] = getStructSurface(structNum(i),planC);
%         tempMask = tempMask(1:sampleRatio:end, 1:sampleRatio:end, 1:sampleRatio:end);
%         scanData(logical(tempMask)) = i*100;
%         if (i==1), opacity = 0.05; else opacity = 0.9; end;
%         colormap(end+1,:) = [i*100 planC{indexS.structures}(structNum(i)).structureColor opacity];
%     end

    