function dcmobj = createEmptyFields(dcmobj, tagS)
%"createEmptyFields"
%   Fill a Java dicom object with the empty fields indicated by the passed
%   tagS structure.  See any file ending in "_module_tags" for details on
%   this structure.
%
%   Sequences always contain a single member, itself populated with empty 
%   fields.
%
%JRA 06/23/06
%
%Usage:
%   dcmobj = createEmptyFields(dcmobj, tagS)
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

%Get the decimal tags.
tags = hex2dec({tagS.tag});

%Create and set passed tag fields to null.
for i=1:length(tags)
    
    %Handle the case of a tag with no children.
    if isempty(tagS(i).children)
       dcmobj.putNull(tags(i), []);
       
    %Handle the case of a tag with children, a sequence.
    elseif strcmpi(toString(dcmobj.vrOf(tags(i))), 'SQ')
       child_obj = org.dcm4che2.data.BasicDicomObject;
       
       el = dcmobj.putNull(tags(i), []);
       
       kids = tagS(i).children;
       child_obj = createEmptyFields(child_obj, kids); 
       el.addDicomObject(child_obj);
       
    %Handle the case of a tag that appears to have children but is not 
    %recognized as a sequence by the data dictionary.    
    else    
        CERRStatusString('Warning !!! A field with child elements is not of type SQ in the DICOM dictionary.\n\t\t Dictionary is out-of-date or module''s tag is incorrect.', 1);
        dcmobj.putNull(tags(i), []);        
    end
    
end