function orientationStruct = readLeksellOrientationFile(filename)
%"readLeksellOrientationFile"
%   Reads a Leksell orientation file using decodeLeksellData and places the
%   fields into a datastructure with meaningful names.  The transformation
%   matrices found in these files have no known use in CERR.
%
%JRA 6/13/05
%
%Usage:
%   orientationStruct = readLeksellOrientationFile(filename)
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

%If data does not have at least two elements it is effectively empty.
if length(data) < 2
    orientationStruct.transM = [];
    orientationStruct(1) = [];
    return;
end

%Get what appears to be transformation matrices.
transMats = data{1};

%Iterate over them, reshape to 3x3 and save.
%However, the purposes of these orientation matrices have not been found.
for i=1:length(transMats)
    orientationStruct(i).transM = reshape(transMats{i}, [3 3]);
end
