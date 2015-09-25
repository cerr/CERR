function dcmObj = ml2dcm_Object(mlObj, template)
%"ml2dcm_Object"
%   Converts from a Matlab representation of a dicom datastructure to a
%   Java DICOM object.  An arbitrary mlObj cannot be used: the struct must
%   have fieldnames that match those contained within the passed Java DICOM
%   template object.
%
%JRA 6/12/06
%
%Usage:
%   dcmObj = ml2dcm_Object(mlObj, template)
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

%Create the output dcmobj.
dcmObj = org.dcm4che2.data.BasicDicomObject;

%First handle all fields that match the template.
it = template.iterator;

while it.hasNext
    el  = it.next;
    tag = el.tag;
    
    %Get the element's name.
    name = char(template.nameOf(tag));
       
    %Convert to a valid ML fieldname.  In a properly formatted mlObj, this
    %fieldname will contain the data that belongs in this element.
    name = dcm2ml_Fieldname(name, tag);    
    
    %Check and see if this field exists in the mlObj and extract the data.
    if isfield(mlObj, name)
        data = mlObj.(name);
        
        %Pass the empty template element along with the data for
        %processing.
        el = ml2dcm_Element(el, data);
        
        if isempty(el)
           error('Unable to convert'); 
        else
           dcmObj.add(el); 
        end        
        
    end    
%     if org.dcm4che2.util.TagUtils.isPrivateCreatorDataElement(tag)
%         %Handle the special case of a private creator data element... many
%         %may exist so they need to be renamed based on the tag code.
%         tagString  = char(org.dcm4che2.util.TagUtils.toString(tag));
%         name = ['Private_' tagString(2:5) '_10xx_Creator'];
%         
%     elseif org.dcm4che2.util.TagUtils.isPrivateDataElement(tag)
%         %Handle the special case of a private data element, requires the 
%         %tag to be part of the name.
%         tagString  = char(org.dcm4che2.util.TagUtils.toString(tag));        
%         name = ['Private_' tagString(2:5) '_' tagString(7:10)];
%     end
%     
%     if isempty(name) & strcmpi(char(el.vr.toString), 'UN');
%         %Handle the case of a tag that is not in the current DICOM 
%         %dictionary.
%         tagString  = char(org.dcm4che2.util.TagUtils.toString(tag));
%         name = ['Unknown_' tagString(2:5) '_' tagString(7:10)];
%     end
%                
%     %Extract the element's value by converting it to a Matlab struct.
%     mlEl = dcm2ml_Element(el);
%     
%     mlObj.(name) = mlEl.val;
   
end