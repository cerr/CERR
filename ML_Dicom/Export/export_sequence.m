function dcmobj = export_sequence(function_handle, el, data)
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
%
%Usage:
%   dcmobj = export_sequence(@export_MYSEQUENCE_sequence, el, data)
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

dcmobj = org.dcm4che2.data.BasicDicomObject;

obj = el.getDicomObject;
it = obj.datasetIterator;

while it.hasNext
    
    child = it.next;   
    child_args.tag      = child.tag;
    child_args.data     = data;
    child_args.template = obj;
%     child_args.planC    = planC;
    
    el = feval(function_handle, child_args);
    
    if ~isempty(el)
        dcmobj.add(el);
    end
end