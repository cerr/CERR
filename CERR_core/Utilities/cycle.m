function [newIndex] = cycle(index, cycleLength)
%function [newIndex] = cycle(index, cycleLength)
%function to facilitate indexing on cyclical structures.
%The new index if the index cycled around on a structure of length cycleLength.
%e.g.: cycle(11, 10) = 1, cycle(12, 10) = 2, cycle(9, 10) = 9, etc.
%'index' can be a vector.
%JOD, Feb 02.
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

newIndex = zeros(size(index));

for i = 1 : length(index)
  if index(i) > cycleLength
    newIndex(i) = index(i) - cycleLength;
  elseif index(i) < 1
    newIndex(i) = cycleLength + index(i);
  else
    newIndex(i) = index(i);
  end
end
