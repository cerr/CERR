function filterS = runFilter(filterS, planDB)
%"runFilter"
%   Given a single filter struct and a planDB, return filterS updated with
%filterS.indicies containing indicies of plans that match the filter's 
%parameters.  A filter struct filterS consists of the fields:  
%        Filters   - the user set string "name" of the filter
%        fieldname - the field to be operated on
%        action    - the filtering action ('contains' 'exists' 'isempty')
%        regexp    - regular expression to apply to filter.
%        bool      - AND/OR
%        invert    - 0 or 1, 1 indicates NOT
%        indices   - indicies of plans that match the filter.
%
%   By JRA 12/15/03
%
%   filterS     :    filter struct
%   planDB      :    plan database
%
%   filterS     :    filter struct with indices updated
%
% Usage:
%   filterS = runFilter(filterS, planDB)
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


fieldname = filterS.fieldname;
allFieldNames = {planDB.fieldIndex.fieldname};
isPlanC = [planDB.matFiles.isPlanC];
indices = repmat(logical(0), [1,length(planDB.matFiles)]);

%Get list of plans containing the requested field.
fIndex = find(strcmpi(allFieldNames, fieldname));
plansContaining = planDB.fieldIndex(fIndex).planIndices;

switch lower(filterS.action)
    case 'contains'
        for i = 1:length(plansContaining)
            data = getFieldContents(filterS.fieldname, planDB.matFiles(plansContaining(i)).extract);
            if matches(data, filterS.regexp)
               indices(plansContaining(i)) = 1;
            end
        end        
%     case 'does not contain'
%         for i = 1:length(plansContaining)            
%             data = getFieldContents(filterS.fieldname, planDB.matFiles(plansContaining(i)).extract);
%             if ~matches(data, filterS.regexp)
%                indices(end+1)= plansContaining(i);
%             end
%         end
    case 'exists'
        indices(plansContaining) = logical(1);
%     case 'does not exist'
%         indices = isPlanC;
%         indices(plansContaining) = 0;
%         indices = find(indices);
    case 'is empty'        
        for i = 1:length(plansContaining)            
            data = getFieldContents(filterS.fieldname, planDB.matFiles(plansContaining(i)).extract);
            if isempty([data{:}])
               indices(plansContaining(i)) = 1;
            end
        end
%     case 'is not empty'
%         for i = 1:length(plansContaining)            
%             data = getFieldContents(filterS.fieldname, planDB.matFiles(plansContaining(i)).extract);
%             if ~isempty([data{:}])
%                indices(end+1)= plansContaining(i);
%             end
%         end
end

if filterS.invert
    indices = isPlanC & ~indices;
end
filterS.indices = find(indices);


function bool = matches(data, regexpS)
%Check of a piece of data matches a regexp. Passive, assumes false until
%proven otherwise.
    bool = 0;
    data = data(:);
    for i=1:length(data)
        switch class(data{i})
            case {'cell', 'struct'}
                continue;
            case 'char'
                if regexpi(data{i}, regexpS)
                    bool = 1;
                end
            otherwise
                if ~isnumeric(data{i})
                    continue;
                else
                    result = regexpi(num2str(data{i}), regexpS);
                    for i=1:length(result)
                        if iscell(result)
                            if ~isempty(result{:})
                                bool = 1;
                            end
                        else
                            if ~isempty(result)
                                bool = 1;
                            end
                        end
                    end
                end
        end            
    end