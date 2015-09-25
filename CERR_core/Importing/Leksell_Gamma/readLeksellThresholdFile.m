function thresholdStruct = readLeksellThresholdFile(filename)
%"readLeksellThresholdFile"
%   Uses the decodeLeksellData function to read in a Leksell threshold 
%   file.  The valuein this file is undetermined, but it seems that it is
%   unnecessary for importing a plan into CERR.   
%
%KRK 05/29/07
%
%Usage:
%   function thresholdStruct = readLeksellThresholdFile(filename)
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
    thresholdStruct = [];
    return;
end

% Get meaningful data
thresholdData = data{1};

% Unsolved variable (is 0 in all cases viewed)
thresholdStruct.mystery_value_1 = thresholdData{1};
