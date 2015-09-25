function output = condenseFields(data, regexp, nullData)
% "condenseFields"
%   Search a datastructure (data) recursively for instances of a fieldname 
%   expression (regexp).  If the fields matching the regexp are encountered, 
%   concatenate them together, creating an array, and replace the parent of 
%   this list with the array.  New empty fields are filled with nullData if 
%   it is specified, else they are [].
%   See dissimilarInsert for details on the concatenation.
%
%   JRA 10/28/03
%
% Warning:  This function must be used carefully, it can result in dataloss
% if you do not know beforehand how your data is structured.
%
% For DICOM plans with Item_1, Item_2, ... use 'Item_\d' as the regexp.
%
% Usage:
%   function output = condenseFields(data, regexp, nullData)
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

if ~exist('nullData')
    nullData = [];
end
dataClass = class(data);

switch dataClass

    case 'struct'       
		myFields = fields(data);
		for i=1:length(myFields)
            for j=1:length(data)
                if isstruct(data(j).(myFields{i}))
                    data(j).(myFields{i}) = condenseFields(data(j).(myFields{i}), regexp, nullData);
                end
            end
		end
		matches = regexpi(myFields, regexp);
		if length(matches) == 1;
            matches = {matches};
		end
		index = 1;
		for i=1:length(matches)
            if matches{i} == 1
                if ~exist('temp')
                    temp(index) = data.(myFields{i});
                else
                    temp = dissimilarInsert(temp, data.(myFields{i}), index, nullData);
                end
                index = index+1;
            end
		end       
		if exist('temp')
            output = temp;
		else
            output = data;
		end
        
    case 'cell'
        numCells = length(data);
        for i=1:numCells
            data{i} = condenseFields(data{i}, regexp, nullData);
        end
        output = data;
end