function targetframeStruct = readLeksellTargetframeFile(filename)
%"readLeksellTargetframeFile"
%   Uses the decodeLeksellData function to read in a Leksell target frame 
%   file.  These values are still completely undetermined, but it seems 
%   they are unnecessary for importing a plan into CERR.   
%
%KRK 05/29/07
%
%Usage:
%   function targetframeStruct = readLeksellTargetframeFile(filename)
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
    targetframeStruct = [];
    return;
end

% Get meaningful data
targetframeData = data{1};

% Unsolved variables, still unsure of what data "TargetFrame.1" should contain
try
targetframeStruct.mystery_value_1 = targetframeData{1};
targetframeStruct.mystery_value_2 = targetframeData{2};
targetframeStruct.mystery_value_3 = targetframeData{3};
targetframeStruct.mystery_value_4 = targetframeData{4};
targetframeStruct.mystery_value_5 = targetframeData{5};
targetframeStruct.mystery_value_6 = targetframeData{6};
targetframeStruct.mystery_value_7 = targetframeData{7};
targetframeStruct.mystery_value_8 = targetframeData{8};
targetframeStruct.mystery_value_9 = targetframeData{9};
targetframeStruct.mystery_value_10 = targetframeData{10};
targetframeStruct.mystery_value_11 = targetframeData{11};
targetframeStruct.mystery_value_12 = targetframeData{12};
targetframeStruct.mystery_value_13 = targetframeData{13};
targetframeStruct.mystery_value_14 = targetframeData{14};
catch
   % Some error happened 
end