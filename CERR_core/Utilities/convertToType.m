function [data, scale] = convertToType(type, data, scale)
%"convertToType"
%   Convert numeric data to type specified, with scaling.  Type can be 'double',
%   'uint8', 'uint16', 'uint32'.  Scale is the value to multiply data
%   by to return to the true values.  If doubles are requested, scale is
%   always 1, ie. the true values are returned.  If no scale is specified 1
%   is assumed.
%
% JRA 1/22/04
%
% [data, scale] = convertToType(type, data, scale)
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

if ~exist('scale')
    scale = 1;
end

dClass = class(data);
if strcmpi(dClass, type)
    return;
end

data = double(data) * scale;
scale = 1;
maxV = max(data(:));

switch lower(type)
    case 'double'
        %nothing... already there.
    case 'uint8'         
        scale = maxV / (2^8 - 1);
        data = uint8(data / scale);
    case 'uint16'
        scale = maxV / (2^16 - 1);        
        data = uint16(data / scale);
    case 'uint32'
        scale = maxV / (2^32 - 1);        
        data = uint32(data / scale);
    otherwise
        warning('No conversion occured.  Bad datatype requested.')
        return;
end
    