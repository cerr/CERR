function attr = export_sequence(function_handle, el, data)
%"export_sequence"
%   Given a fHandle to function of type export_<whatever>_sequence_field,
%   and the data required to execute that function, performs the required
%   legwork to actually populate each field within a template of the
%   sequence.
%
%   el is the parent element of the sequence template.
%
%   data is the information that is used by individual _field functions to
%   populate the fields.
%
%JRA 06/23/06
%NAV 07/19/16 updated to dcm4che3
%
%Usage:
%   attr = export_sequence(@export_MYSEQUENCE_sequence, el, data)
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

attr = javaObject('org.dcm4che3.data.Attributes');
obj = el.get(0);
tagS = obj.tags();
%template = el;
%tagS = el;
for i=1:length(tagS)    

    tag = tagS(i);  
    child_args.tag      = tag;
    child_args.data     = data;
    child_args.template = obj;
    %child_args.template = template;
%     child_args.planC    = planC;

    el = feval(function_handle, child_args);
%% Uncomment to find which function a crash occurs
   % disp(function_handle);
   % disp(tag);
%%
    if ~isempty(el)
        % User Error or dcm4che3 glitch. If number of items
        % greater than 1, than an extra item is included which crashes
        % matlab by filling up the Java memory heap. the remove function
        % prevents a crash be removing extra item
        if (el.size() > 1)
            el.remove(el.size()-1);
            attr.addAll(el.getParent());
        else
            attr.addAll(el);
        end
    end
end