function planC = checkUniformXYVoxelSize(planC)
%"checkUniformXYVoxelSize"
%   Checks to be sure that every slice in the scan has the same voxel size
%   in x and y, as well as the same x and y offsets.
%
%   If voxel sizes are not consistent over all slices, all slices are 
%   reinterpolated to the smallest square voxel size.  If the offsets are
%   different an error is currently thrown.
%
%JRA 1/6/05
%
%Usage:
%   function planC = checkUniformXYVoxelSize(planC)
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

indexS = planC{end};

%Accumulate x,y voxel sizes for each scan.
for i=1:length(planC{indexS.scan})
    xyVoxSizes = [];    
    xyOffsets  = [];
    for j=1:length(planC{indexS.scan}(i).scanInfo)
        xyVoxSizes = [xyVoxSizes;planC{indexS.scan}(i).scanInfo(j).grid1Units planC{indexS.scan}(i).scanInfo(j).grid2Units];                
        xyOffsets  = [xyOffsets;planC{indexS.scan}(i).scanInfo(j).xOffset planC{indexS.scan}(i).scanInfo(j).yOffset];                
    end
    
    if ~isequal(xyVoxSizes(:,1), xyVoxSizes(:,2))
        error('A CT Slice has non-square voxels in x,y.  Invalid voxel size, quitting.')
    end    
    
    uniqueSizes   = unique(xyVoxSizes, 'rows');    
    uniqueOffsets = unique(xyOffsets, 'rows');        
    
    if size(uniqueOffsets, 1) > 1
        error('Offset values differs between slices.  Cannot construct scanArray.');
    end
    
    if size(uniqueSizes, 1) > 1
        warning(['Not all slices in scan set ' num2str(i) ' have the same x,y coordinates or x,y voxel sizes, resampling.']);

        h = waitbar(0,'Reinterpolating scan...');
        
        [newGridInterval, goodSlice] = min(xyVoxSizes(:,1));
        
        % make scan available to memory in case it is remote
        if isLocal(planC{indexS.scan}(i))
            planC{indexS.scan}(i).scanArray = getScanArray(planC{indexS.scan}(i));
        end
        
        for j=1:length(planC{indexS.scan}(i).scanInfo)
            
            waitbar(j/length(planC{indexS.scan}(i).scanInfo),h);
            
            sI = planC{indexS.scan}(i).scanInfo(j);
            slc = planC{indexS.scan}(i).scanArray(:,:,j);
            
            CTDatatype = class(slc);
            
            [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(i), j);
            
            sI.grid1Units = newGridInterval(1);
            sI.grid2Units = newGridInterval(1);            
            planC{indexS.scan}(i).scanInfo(j) = sI;
            [xVnew, yVnew, zVnew] = getScanXYZVals(planC{indexS.scan}(i), goodSlice);            
            
            newSlc = finterp2(xV, yV, double(slc), xVnew, yVnew, 1);
            newSlc = reshape(newSlc, [length(xVnew) length(yVnew)]);
            
            switch CTDatatype
                case 'uint8'
                    newSlc = uint8(newSlc);
                case 'uint16'
                    newSlc = uint16(newSlc);
                case 'uint32'
                    newSlc = uint32(newSlc);
            end            
            planC{indexS.scan}(i).scanArray(:,:,j) = newSlc;          
        end
        close(h);
    end    
end