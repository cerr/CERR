function volumeStruct = readLeksellVolumeFile(filename)
%"readLeksellVolumeFile"
%   Reads a Leksell volume file using decodeLeksellData and places the
%   fields into a datastructure with meaningful names.  This file contains
%   all contouring information for CERR.
%
%JRA 6/13/05
%
%LM: KRK, 8/11/07,  Added scaling on the xy contour positions to change mm
%                   to cm.
%
%Usage:
%   function volumeStruct = readLeksellVolumeFile(filename)
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

fid = fopen(filename, 'r', 'b');

data = decodeLeksellData(fid);

fclose(fid);

%First iterate over structures included in volume file.
for i = 1:length(data) - 1
   
    rawStruct = data{i};
    
    structureS(i).structName = rawStruct{2};
    structureS(i).registeredTo = rawStruct{1};
    
    allContours = rawStruct{4};    
    
    contourS = [];
    
    %Iterate over contours for this structure
    for j=1:length(allContours)-1
        
        oneContour = allContours{j};

        contourS(j).sliceNum = oneContour{1};
        contourS(j).nVertices = oneContour{2};
        
        cData     = oneContour{3};        
        xyMat = [];
        for k = 1:length(cData)
            xyMat = [xyMat;cData{k}{1}'];
        end
        
        contourS(j).contour = xyMat;
        contourS(j).rowExtent = [oneContour{6} oneContour{7}];
        contourS(j).colExtent = [oneContour{8} oneContour{9}];        
        contourS(j).slcExtent = [oneContour{10} oneContour{11}];                                
        
    end
    
    structureS(i).contour = contourS;
        
end

volumeStruct = structureS;
