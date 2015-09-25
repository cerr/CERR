function superStruct = readLeksellSuperFile(filename)
%"readLeksellSuperFile"
%   Uses the decodeLeksellData function to read in a Leksell Super file.
%   Many of these values are still undetermined, however the ones necessary
%   for importing a Leksell plan into CERR have been discovered.
%
%KRK 05/31/07
%
%Usage:
%   function superStruct = readLeksellSuperFile(filename)
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
    superStruct = [];
    return;
end

% Get meaningful data
superData = data{1};

% Dose at the global max in the doseMatrix (Gy)
superStruct.globalMaxDose = superData{3};
% Global max point (x,y,z) in matrix
superStruct.maxPointInMatrix = superData{7};
% Prescription Isodose (percent)
superStruct.prescriptionIsodose = superData{8};
% Prescription Dose (Gy)
superStruct.prescriptionDose = superData{9};

% Unsolved variables
superStruct.mystery_value_1 = superData{1};
superStruct.mystery_value_2 = superData{2};
superStruct.mystery_value_4 = superData{4};
superStruct.mystery_value_5 = superData{5};
superStruct.mystery_value_6 = superData{6};
superStruct.mystery_value_10 = superData{10};
superStruct.mystery_value_11 = superData{11};
