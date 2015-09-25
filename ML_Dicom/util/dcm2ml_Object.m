function mlObj = dcm2ml_Object(dcmObj)
%"dcm2ml_Object"
%   Converts from a Java DicomObject to a Matlab struct
%
%JRA 6/1/06
%
%Usage:
%   mlObj = dcm2ml_Object(dcmObject)
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

it = dcmObj.iterator;

while it.hasNext
    el  = it.next;
    tag = el.tag;
    
    %Get the element's name.
    name = char(dcmObj.nameOf(tag));
       
    %Convert to a valid ML fieldname.
    name = dcm2ml_Fieldname(name, tag); 
    
    if strcmpi(name, 'PixelData'), continue; end;
    
    if isempty(name), continue; end;
    
    if org.dcm4che2.util.TagUtils.isPrivateCreatorDataElement(tag)
        %Handle the special case of a private creator data element... many
        %may exist so they need to be renamed based on the tag code.
        tagString  = char(org.dcm4che2.util.TagUtils.toString(tag));
        name = ['Private_' tagString(2:5) '_10xx_Creator'];
        
    elseif org.dcm4che2.util.TagUtils.isPrivateDataElement(tag)
        %Handle the special case of a private data element, requires the 
        %tag to be part of the name.
        tagString  = char(org.dcm4che2.util.TagUtils.toString(tag));        
        name = ['Private_' tagString(2:5) '_' tagString(7:10)];
    end
    
    if isempty(name) && strcmpi(char(el.vr.toString), 'UN');
        %Handle the case of a tag that is not in the current DICOM 
        %dictionary.
        tagString  = char(org.dcm4che2.util.TagUtils.toString(tag));
        name = ['Unknown_' tagString(2:5) '_' tagString(7:10)];
    end
               
    %Extract the element's value by converting it to a Matlab struct.
    try   
        data = dcm2ml_Element(el);
        mlObj.(name) = data;
    catch
        continue;
    end
end

if ~exist('mlObj', 'var')
    mlObj = [];
end