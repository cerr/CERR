function bitsHitV = cumbitor(bitsHitV)
%"cumbitor"
%   Find cumulative bitor of all values in bitsHitV, using a "vectorized"
%   binary tree algorithm to reduce calls to bitor.
%
%JRA 12/15/04
%
%Usage:
%   function bitsHitV = cumbitor(bitsHitV)
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

while length(bitsHitV) >= 2
    len = length(bitsHitV);
    if mod(len, 2) == 1
        last = bitsHitV(end);        
        bitsHitV = bitor(bitsHitV(1:(len-1)/2), bitsHitV((len-1)/2+1:end-1));            
        bitsHitV(1) = bitor(bitsHitV(1), last);
    else
        bitsHitV = bitor(bitsHitV(1:len/2), bitsHitV(len/2+1:end));
    end
end