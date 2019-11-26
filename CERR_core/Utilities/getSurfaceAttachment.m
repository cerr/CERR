function fractOverlap = getSurfaceAttachment(structNum1,structNum2,margin,planC)
%function min_dist = getSurfaceAttachment(structNum1,structNum2,margin,planC)
%
%This function calculates fractional overlap between the masks of structNum2
% and structNum2 contracted by margin. planC is an optional input argument.
%
%APA, 11/25/2019
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

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% Create Union of the two structure structNum1 (lung) and structNum2 (gtv)
planC = createUnionStructure(structNum1,structNum2,planC);

unionStrNum = length(planC{indexS.structures});

% Get surface mask of contracted unionStrNum
xyDownsampleIndex = 1; % no downsampling
contractedStr1M = getSurfaceContract(unionStrNum,margin,xyDownsampleIndex,planC);

% Remove unionStrNum
maskUnionM = getUniformStr(unionStrNum,planC);
ringMaskM = maskUnionM - contractedStr1M;
planC = deleteStructure(planC,unionStrNum);

% Get mask of structNum2 (gtv)
mask2M = getUniformStr(structNum2,planC);

% Get overlapping fraction of structNum2
overlapM = ringMaskM & mask2M;
fractOverlap = sum(overlapM(:)) / sum(mask2M(:));

