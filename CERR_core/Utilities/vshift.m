function outV = vshift(inV, shift)
%vshift is a drop-in CERR replacement for wshift, which is
%available only in the wavelet toolbox. vshift, unlike wshift
%handles only the 1-D vector shift case.
%outV = vshift(inV,shift)
%performs a p-circular shift of vector inV.
%The shift p must be an integer, positive for right to left
%shift and negative for left to right shift.
%example: outV = vshift([1,2,3,4],1)
%outV =  2     3     4     1
%
%%JOD, 24 Jan 02.
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

sV = size(inV);

inV = inV(:);

if abs(shift) > length(inV)
  error('Shift is larger than input vector')
end

if shift < 0
  outV = [inV(end + shift + 1: end) ; inV(1 : end + shift) ];
else
  outV = [inV(1 + shift : end) ; inV(1 : shift) ];
end


outV = reshape(outV, sV);

