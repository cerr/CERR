function cellOut = getAllMatchingContents(fieldname, varargin)
%Returns a cell array containing the contents of all fields that match the
%fieldname in structure(s) varargin.
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


cellOut = {};

if isempty(fieldname)
    cellOut = varargin;
    return;
end

for i=1:(nargin-1)    
    data = varargin{i};
	switch class(data)
        case 'cell'
            [fieldStart, fieldEnd, indices] = regexp(fieldname, '\{(.*)\}', 'once');            
            
            if ~isempty(indices)
                cellIndex = fieldname(indices{1}(1):indices{1}(2));
            else
                error('Error indexing');
            end
            cellIndex = str2double(cellIndex);
            if isnan(cellIndex)
                cellOut = {'DNE'};
                return;
            end
            contents = getAllMatchingContents(fieldname(fieldEnd+1:end), data{cellIndex});
            
        case 'struct'
            periods = [strfind(fieldname, '.') length(fieldname)+1];
            range = periods(1)+1:periods(2)-1;
            
            nextFieldName = fieldname(range);
            
            if isfield(data, nextFieldName)
                contents = getAllMatchingContents(fieldname(periods(2):end), data.(nextFieldName));    
            else
                contents = {'DNE'}; %%The string for nonexistant fields.
            end
            
        otherwise
            contents = {'DNE'}; %used to be contents = data;
	end
if isempty(contents)
    contents = {[]}
end
[cellOut{end+1:end+length(contents)}] = deal(contents{:});
end