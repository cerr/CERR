function dcmdirS = parse_DICOMDIR_Object(r, dcmobj)
%"parse_DICOMDIR_Object"
%   Given a DICOMDIR reader and a dcmobj that came from the reader,
%   construct the heirarchy contained in the reader's original DICOMDIR
%   file inside the MATLAB struct dcmdirS.
%
%JRA 06/08/06
%
%Usage:
%   dcmdirS = parse_DICOMDIR_Object(reader, dcmobj)
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

%Set the tag used to discover the type of this element.
typeTag = hex2dec('00041430');

%Set the tag used to determine a dcmobj's parent file.
filenameTag = hex2dec('00041500');

while ~isempty(dcmobj)
    %Get the type of this element
    objType = char(dcmobj.getString(typeTag));
    
    %Get the filename of this element.
    filename = char(dcmobj.getString(filenameTag));
    
    %Convert the object type to a valid ML struct name.
    fieldName = dcm2ml_Fieldname(objType);

    %Get the next child of this record, [] if it does not exist.
    childObj = r.findFirstChildRecord(dcmobj);
    
    %Parse children and store them in the field corresponding to this obj.
    if ~exist('dcmdirS', 'var') || ~isfield(dcmdirS, fieldName)
        dcmdirS.(fieldName){1} = parse_DICOMDIR_Object(r, childObj);
    else
        dcmdirS.(fieldName){end+1} = parse_DICOMDIR_Object(r, childObj);
    end
    
    %Save a copy of the DICOM object representing this level of the
    %heirarchy.
    dcmdirS.(fieldName){end}.info = dcmobj;
    
    if ~isempty(filename)
       dcmdirS.(fieldName){end}.file = filename; 
    end
    
    %Continue to the next record at this level of the heirarchy.
    dcmobj = r.findNextSiblingRecord(dcmobj);
    
end

%Return [] if the dcmobj was empty from the beginning.
if ~exist('dcmdirS', 'var')
    dcmdirS = [];
end