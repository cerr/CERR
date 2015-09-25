function [influenceM] = getInfluenceM(IM, structNum)
%"getInfluenceM" 
%   Get the influence matrix (dose(:) = influenceM * weights(:)),
%   for a single structure.  The output influenceM is sparse, and has
%   a row for every calculated dose point in the structure.  If a
%   the sampleRate is 1, this is the number of points in the structure,
%   otherwise it is the number of points in the downsampled structure.
%
%   Uses the global influence matrix.  This is not the most efficent
%   system, should be changed later.
%
%   JRA 4/1/04
%
%Usage:
%   function [influenceM] = getInfluenceM(IM, structNum)
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

%Get global influence for all points in plan.
gInfluenceM = getGlobalInfluenceM(IM, structNum);

%Get the structure mask, downsampled if necessary.
mask3M = getUniformStr(structNum);

%get indices of structures stored under beamlets
beamlets = IM.beams(1).beamlets;
structIndV = getAssociatedStr({beamlets(:,1).strUID});
structInd = find(ismember(structIndV,structNum));
sampleRate = beamlets(structInd(1),1).sampleRate;
%sampleRate = IM.beamlets(structNum,1).sampleRate;

mask3M = getDown3Mask(mask3M, sampleRate, 1) & mask3M;

%Find relevant indices into the gInfluenceM.
indV = find(mask3M);

%Extract the influence matrix for this structure.
influenceM = gInfluenceM(indV, :);