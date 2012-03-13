function fusionsStruct = readLeksellFusionFile(filename)
%"readLeksellFusionFile"
%   Reads a Leksell fusions file using decodeLeksellData and places the
%   fields into a datastructure with meaningful names.
%
%JRA 6/13/05
%
%LM: KRK, 06/08/07, added additional documentation
%
%Usage:
%   fusionsStruct = readLeksellFusionFile(filename)
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

if exist('filename')
    fid = fopen(filename, 'r', 'b');

    data = decodeLeksellData(fid);

    fclose(fid);

    %If data does not have at least two elements it is effectively empty (since
    %one of the elements of a true Leksell file is always an insignificant
    %array of two integers).
    if length(data) < 2
        fusionsStruct = [];
        return;
    end

    realData = data{1};

    %Get fusion information.
    fusionsStruct.state     = realData{1};
    fusionsStruct.modality1 = realData{2};
    fusionsStruct.modality2 = realData{3};
    fusionsStruct.zShift1   = realData{4};
    fusionsStruct.zShift2   = realData{5};
else
    fusionsStruct.state = [];
    fusionsStruct.modality1 = [];
    fusionsStruct.modality2 = [];
    fusionsStruct.zShift1   = [];
    fusionsStruct.zShift2   = [];
end