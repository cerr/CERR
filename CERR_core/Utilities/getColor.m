function color = getColor(colorNum, colorArray, mode)
%"getColor"
%   Returns a 3 element RGB colorvector by mapping colorNum into
%   colorArray's rows.  By default if colorNum exceeds the length of
%   colorArray, colorNum loops over and repeats the colors. If 'mode'
%   is set to 'gray' colorNums that exceed the colorArray return gray.
%
%   JRA 1/5/03
%
% Usage:
%   color = getColor(colorNum, colorArray)
%   color = getColor(colorNum, colorArray, 'gray')
%   color = getColor(colorNum, colorArray, 'loop')
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

gray = [.5 .5 .5];
switch nargin
    case 2
        mode = 'loop';
    case 3
        %Mode is set, do nothing
    otherwise
        error('Bad call to getStructColor: color = getStructColor(structNum, colorArray, mode)');        
end

switch lower(mode)
    case 'loop'
        color = colorArray( mod(colorNum-1, size(colorArray,1))+1,:);
    case {'gray', 'grey'}
        color = colorArray(mod(colorNum-1, size(colorArray,1))+1,:);
        if colorNum > size(colorArray,1)
            color = gray;    
        end
end