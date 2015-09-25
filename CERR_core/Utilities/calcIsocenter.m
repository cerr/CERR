function [x,y,z] = calcIsocenter(targetsV, method, planC)
%"calcIsocenter"
%   Returns the isocenter for the structure numbers listed in targetsV
%   using the algorithm specified by method.  Currently all structures in
%   targetsV must be part of the same scanSet.
%
%   The planC argument is optional, only use it if the plan is not loaded
%   globally (ie in CERR).
%
%   Current methods: 
%           'COM' - center of mass of uniformized mask composed of all
%                   structsV
%
%Usage:
%   [x,y,z] = calcIsocenter(structsV, method, planC)
%
%ie.
%   [x,y,z] = calcIsocenter([1 3 4], 'COM', planC);
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

if ~exist('planC')
    global planC
end
indexS = planC{end};

if ~exist('method')
    method = 'COM';
end

%Figure out what scan we are registered to.
scanNum = getStructureAssociatedScan(targetsV, planC);
if length(unique(scanNum)) > 1
    error('All structures passed to calcIsocenter must be registered to the same scan.');
else
    scanNum = scanNum(1);
end

switch upper(method)
    case 'COM'
        %Build mask of all structures.
        mask = repmat(logical(0), getUniformScanSize(planC{indexS.scan}(scanNum)));
        for i=1:length(targetsV)      
            mask = mask | getUniformStr(targetsV(i), planC);
        end
        
        %Get r,c,s list of all points in mask.
        [rV,cV,sV] = find3d(mask);
        
        %Take the mean of all points... unweighted as this is a mask.
        rowCOM = mean(rV);
        colCOM = mean(cV);
        slcCOM = mean(sV);
        
        %Convert from rcs, to xyz coordinates.
        [x,y,z] = mtoxyz(rowCOM, colCOM, slcCOM, scanNum, planC, 'uniform');
        
    otherwise
        error('Invalid calcIsocenter method.');
end