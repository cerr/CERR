function newData = uint32_to_uint16(data);
%"uint32_to_uint16"
%   Converts a column vector of uint32s to a vector of uint16s that is twice as
%   long but contains the same byte information.
%
%   For example, a vector containing a single uint32, [1000000] would be
%   converted into a vector containing two uint16s, [16960 15], the bitwise
%   equivalent to the original vector.
%
%JRA 07/12/06
%
%Usage:
%   newData = uint32_to_uint16(data);
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

switch class(data)
    case 'uint32'
        
        highBits = bitshift(data, -16);
        lowBits  = bitshift(bitshift(data, 16), -16);
        
        newData(2:2:length(data)*2) = uint16(highBits);
        newData(1:2:length(data)*2) = uint16(lowBits);
        
    otherwise
        error('Input to uint32_to_uint16 must be 32 bits.')
end