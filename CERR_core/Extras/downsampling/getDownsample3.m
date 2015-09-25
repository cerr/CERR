function [maskDown3M] = getDownsample3(mask3M, sampleTrans, sampleAxis)
%Downsample a 3D matrix.
%JOD.
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

sV  = size(mask3M);

sampleSlices = ceil(sV(3)/sampleAxis);

maskDown3M = zeros(sV(1)/sampleTrans,sV(2)/sampleTrans,ceil(sV(3)/sampleAxis));

indV = 1 : sampleAxis: sampleSlices;
for i = 1 : length(indV)
  maskM = getDownsample2(mask3M(:,:,indV(i)),sampleTrans);
  maskDown3M(:,:,i) = maskM;
end

