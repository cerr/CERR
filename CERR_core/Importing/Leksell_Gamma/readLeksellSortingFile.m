function sortingStruct = readLeksellSortingFile(filename)
%"readLeksellSortingFile"
%   Uses the docodeLeksellData function to decode the data from the Leksell
%   files and places the data into a data structure.  However, these values
%   seem to have no significance on the importing of a Leksell plan into
%   CERR, and thus are not used inside of CERR.
%
%KRK 05/30/07
%
%Usage:
%   function sortingStruct = readLeksellSortingFile(filename)
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
    sortingStruct = [];
    return;
end

% Get meaningful data
sortingData = data{1};

% Unsolved variables
sortingStruct.mystery_value_1 = sortingData{1};
sortingStruct.mystery_value_2 = sortingData{2};
sortingStruct.mystery_value_3 = sortingData{3};
sortingStruct.mystery_value_4 = sortingData{4};
sortingStruct.mystery_value_5 = sortingData{5};
sortingStruct.mystery_value_6 = sortingData{6};
