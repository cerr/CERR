function mlObj = getTagStruct(attr)
%"dcm2ml_Object"
%   Converts from a Java DicomObject to a Matlab struct
%
%JRA 6/1/06
%NAV 07/19/16 updated to dcm4che3
%
%Usage:
%   mlObj = dcm2ml_Object(dattr)
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

tagS = attr.tags();

for i=1:length(tagS)

    tag = tagS(i);
    
    %Get the element's name.
    % name = char(org.dcm4che3.data.ElementDictionary.keywordOf(tag, []));
    name = cell(org.dcm4che3.data.ElementDictionary.keywordOf(tag, []));
    name = name{1};
       
    %Convert to a valid ML fieldname.
    name = dcm2ml_Fieldname(name, tag); 
    
    if strcmpi(name, 'PixelData'), continue; end
    
    if strcmpi(name, 'ROIContourSequence'), continue; end
    
    if isempty(name), continue; end;

    if org.dcm4che3.util.TagUtils.isPrivateCreator(tag)
        %Handle the special case of a private creator data element... many
        %may exist so they need to be renamed based on the tag code.
        tagString  = char(org.dcm4che3.util.TagUtils.toString(tag));
        name = ['Private_' tagString(2:5) '_10xx_Creator'];
        
    elseif org.dcm4che3.util.TagUtils.isPrivateTag(tag)
        %Handle the special case of a private data element, requires the 
        %tag to be part of the name.
        tagString  = char(org.dcm4che3.util.TagUtils.toString(tag));        
        name = ['Private_' tagString(2:5) '_' tagString(7:10)];
    end

    if isempty(name) && strcmpi(char(attr.getVR(tag)), 'UN');
        %Handle the case of a tag that is not in the current DICOM 
        %dictionary.
        tagString  = char(org.dcm4che3.util.TagUtils.toString(tag));
        name = ['Unknown_' tagString(2:5) '_' tagString(7:10)];
    end
         
    %Extract the element's value by converting it to a Matlab struct.
    try   
        %data = dcm2ml_Element(el);
        %Replace with this for dcm4che3
        data = getTagValue(attr, dec2hex(tag));
        mlObj.(name) = data;
    catch
        continue;
    end
end

if ~exist('mlObj', 'var')
    mlObj = [];
end