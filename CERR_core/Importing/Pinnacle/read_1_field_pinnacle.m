function [fieldname,val] = read_1_field_pinnacle(fid)
%function [fieldname,val] = read_1_field_pinnacle(fid)
%
%This is recursive function to read one field or the entire trial
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

tl = fgetl(fid);

if ~isempty(tl)
    while 1
        if isempty(tl) || tl(1) == '"' || tl(1) == '/'
            tl = fgetl(fid);
        else
            break;
        end
    end
end

val = [];
% fieldname = [];
%%% *********** check this *********
if isnumeric(tl) || isempty(tl) || ~isempty(strfind(tl,'};'))  %(tl(end-1) == '}' && tl(end) == ';') || (tl(1) == '}' && tl(2) == ';')
    fieldname = [];
    val = [];
elseif tl(end-1) == '=' && tl(end) == '{'	% is this a composite field
    fieldname = read_1_value_pinnacle(fid,tl);
    if (strcmpi(fieldname,'points')) || (fieldname(end-1) == '[' && fieldname(end) == ']')
        fieldname = fieldname(1:end-2);
        % this is an array of values
        while 1
            tl = fgetl(fid);
            tl = ddeblank(tl);
            if ~isempty(tl) && ~isempty(strfind(tl,'};')) %(tl(1) == '}' && tl(2) == ';') || (tl(end-1) == '}' && tl(end) == ';')
                break;
            elseif ~isempty(tl)
                %tl = ddeblank(tl);
                %val = [val;sscanf(tl,'%f,')];
                val = [val;str2num(tl)];
            end
        end
    else
        % yes, this is a composite field
        while 1
            [fname,fval] = read_1_field_pinnacle(fid);
            if ~isempty(fname)
                val=add_1_field_to_struct(val,fname,fval);
            else
                break;
            end
        end
    end
else
    [fieldname,val] = read_1_value_pinnacle(fid,tl);
end

return;
