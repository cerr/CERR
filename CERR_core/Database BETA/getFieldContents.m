function data = getFieldContents(fieldName, extract)
%Returns the contents of the passed fieldString's corresponding field in
%the extract.  IndexS must be present as extract{end}.
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


if iscell(fieldName)
    fieldName = fieldName{:};
end

indexS = extract{end};

%speed optimization, using str2num repeatedly causes a big slowdown. Need
%to check for plans with more than 20 fields.
numberStrings = {'1' '2' '3' '4' '5' '6' '7' '8' '9' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20'};

cellNames = fields(indexS);
for i=1:length(cellNames)
    cellVals(i) = indexS.(cellNames{i});
end

for i=1:length(extract)
    fieldName = strrep(fieldName, ['planC{indexS.' cellNames{i} '}'], ['{' numberStrings{i} '}']);
end

data = getAllMatchingContents(fieldName, extract);