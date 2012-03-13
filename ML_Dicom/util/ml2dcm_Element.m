function el = ml2dcm_Element(el, data)
%"ml2dcm_Element"
%   Place the passed data into a copy of the passed Java DICOM element.
%
%   TO DO: Consider checking that el is a java DICOM element.
%
%JRA 6/12/06
%
%Usage:
%   el = ml2dcm_Element(el, data);
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

%Set cache buffer to true.
buf = 1;

%Set character set to [] for now.
cs = [];

%Create an empty dcmobj to act as a temporary container for the new element.
dcmobj = org.dcm4che2.data.BasicDicomObject;

%Get the tag for this element.
tag = el.tag;

%Get the VR, cast to ML char array.
vr = char(el.vr.toString);

switch upper(vr)
    case 'AE'
        %Needs implementation
    case 'AS'
        %Needs implementation
    case 'AT'
        %Attribute tags may be passed as a hex string, ie '000A003E', or an
        %integer that would be the result of hex2dec('000A003E');
        if ~isnumeric(data) & ischar(data)
            data = hex2dec(data);
        end
        dcmobj.putInts(tag, el.vr, data);
    case {'CS', 'LO', 'ST'}
        dcmobj.putStrings(tag, el.vr, data);
    case 'DA' 
        %Use builtin dcm4che Date functions.
        jDate = org.dcm4che2.util.DateUtils.parseDA(data, 1);
        dcmobj.putDate(tag, el.vr, jDate);
    case 'DS'
        dcmobj.putFloats(tag, el.vr, data);        
    case 'DT'
        %Needs implementation        
    case 'FL'
        %Needs implementation        
    case 'FD'
        %Needs implementation        
    case 'IS'
        if isnumeric(data)
            dcmobj.putInts(tag, el.vr, data);
        else
            error('The input should be numeric for "IS" ');
        end
    case 'LT'
        %Needs implementation        
    case 'OB'
        %Needs implementation        
    case 'OF'
        %Needs implementation        
    case 'OW'
         dcmobj.putInts(tag, el.vr, double(data));  %Incorrect. Requires putBytes unless LUT data.
%          dcmobj.putBytes(tag, el.vr, 1, data);         

    case 'PN' 
         nameObj = org.dcm4che2.data.PersonName(el.getString(cs, buf));
         
         %The # in get(#) as defined by dcm4che2, PersonName class.
         nameObj.set(0, data.FamilyName);
         nameObj.set(1, data.GivenName);
         nameObj.set(2, data.MiddleName);
         nameObj.set(3, data.NamePrefix);
         nameObj.set(4, data.NameSuffix);         
         
         dcmobj.putString(tag, el.vr, nameObj.toString);
    case 'SH'
        %SH requires that all strings are <= 16 characters.
        switch class(data)
            case 'cell'
                %Do nothing, looks good.
            case 'char'
                data = {data};
            otherwise
                error('Invalid datatype passed to ml2dcm_Element.');
        end
            
        for i=1:length(data)                

            if length(data{i}) > 16
                warning(['String ''' data{i} ''' is too long to fit in the 16 char SH field ' dec2hex(tag) ', truncating.']);
                data{i} = data{i}(1:16);
            end
            
        end                  
        dcmobj.putStrings(tag, el.vr, data);
    case 'SL'
        %Needs implementation        
    case 'SQ'
        %Implementation currently unnecessary.
    case 'SS'
        %Needs implementation
    case 'TM'   
        %Use builtin dcm4che Time functions.
        jDate = org.dcm4che2.util.DateUtils.parseTM(data, 1);
        dcmobj.putDate(tag, el.vr, jDate);
    case 'UI'
          dcmobj.putString(tag, el.vr, data);
    case 'UL'
        %Needs implementation
    case 'UN'
        %Needs implementation
    case 'US'
        dcmobj.putInts(tag, el.vr, data);
    case 'UT'
        %Needs implementation        
    otherwise
        error('Unrecognized VR type.'); %%Consider more gracious exit.
end

%DEBUGGING CODE: remove this once all VRs are implemented.
if dcmobj.isEmpty
    warning(['DEBUGGING: ' vr ' is not defined.  Implement it in ml2dcm_Element.m']);
    el = [];
else
    it = dcmobj.iterator;
    el = it.next;
end

clear dcmobj;
clear it;
