function skullStruct = readLeksellSkullFile(filename)
%"readLeksellSkullFile"
%   Uses the docodeLeksellData function to decode the data from the Leksell
%   files and places the data into meaningful structures. This 
%   information is not currently used in CERR.
%
%KRK 05/30/07
%
%Usage:
%   function skullStruct = readLeksellSkullFile(filename)
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

fid = fopen(filename, 'r', 'b');

data = decodeLeksellData(fid);

fclose(fid);

% If data only has one cell, it's empty since there is always one cell that 
%   contains no meaningful data
if length(data) < 2
    skullStruct = [];
    return;
end

% Get meaningful data
skullData = data{1};

% Get the row size of the skull data
skullStruct.colLen = skullData{1};
% Get the column size of the skull data
skullStruct.rowLen = skullData{2};
% Get the spherical coordinate angles (theta = colAngles, phi =
%   rowAngles).  Ex: rowAngles(2) corresponds to the entire 2nd row
%   in the skullStruct.radii matrix
skullStruct.rowAngles = skullData{3};
skullStruct.colAngles = skullData{4};
% Get the sphereical coordinate radii (rho)
skullStruct.radii = reshape(skullData{5}, [skullData{2}, skullData{1}])';
% skullData{6} is unknown, it is the same size as skullData{5}, but is
%   filled with small floating point numbers.
skullStruct.mystery_value_1 = reshape(skullData{6}, [skullData{2}, skullData{1}])';
