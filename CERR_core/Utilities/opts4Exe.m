function optS = opts4Exe(fileName)
%function optS = opts4Exe(fileName)
%Reads a function which sets fields of a structure array.
%The purpose of this function is to allow compiled stand-alone
%functions to read a user-editable file of option settings.
%This is a compilable command which reads a list of
%commands, one per line, from an ascii file
%which set the structure optsS, e.g.,
%optS.this = 1.
%optS.that = 2.
%optS.word = 'cute'
%This function correctly handles blank lines,
%the function definition line, comment lines,
%comments after assignments, and semicolons.
%LM:  J.O.Deasy, 17 Dec, 2001.
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

% filetext = fileread(fileName);
% optS = jsondecode(filetext);

if isempty(MLVersion) || MLVersion < 9.1
    optS = loadjson(fileName);
else
    filetext = fileread(fileName);
    optS = jsondecode(filetext);
end


% optS = [];
% 
% %Put commands in cells:
% optC = file2cell(fileName);
% 
% %Process each line:
% 
% for i = 1 : length(optC)
%   opt_str = optC{i};
%   if ~isempty(opt_str)
%     optS = setOptsExe(opt_str,optS);
%   end
% end
