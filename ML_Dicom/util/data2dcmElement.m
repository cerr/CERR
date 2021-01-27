function el = data2dcmElement(data, tag)
%"ml2dcm_Element"
%   Place the passed data into a copy of the passed Java DICOM element.
%
%   TO DO: Consider checking that el is a java DICOM element.
%
%JRA 6/12/06
%
%Usage:
%   el = data2dcmElement(el, data, tag);
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

%Create an empty attr to act as a temporary container for the new element.
%if isempty(el)
    el = javaObject('org.dcm4che3.data.Attributes',1);
%end
    
vr = javaMethod('vrOf','org.dcm4che3.data.ElementDictionary',tag, []);
vrCode = vr.code;
%vrString = char(vr);
%Get the tag for this element.
%tag = el.tag;

%Get the VR, cast to ML char array.
%vr = char(vr.toString);

%%
switch vrCode
%if vr.equals(org.dcm4che3.data.VR.AE) %strcmpi(vr,'AE')
    case 16709
    %case 'AE'
        %Needs implementation
%elseif vr.equals(org.dcm4che3.data.VR.AS) %strcmpi(vr,'AS')
    case 16723
    %case 'AS'
        %Needs implementation
%elseif vr.equals(org.dcm4che3.data.VR.AT) %strcmpi(vr,'AT')
    case 16724
    %case 'AT'
        %Attribute tags may be passed as a hex string, ie '000A003E', or an
        %integer that would be the result of hex2dec('000A003E');
        %if ~isnumeric(data) && ischar(data)
        %    data = hex2dec(data);
        %end
        %el.setInt(tag, vr, data);
        if isnumeric(data)
          data = de2hex(data);
        end
        el.setString(tag, vr, data);
%elseif vr.equals(org.dcm4che3.data.VR.CS) %strcmpi(vr,'CS')
    case 17235
        %case 'CS'
        if ~isempty(data)
            data = upper(strtrim(data));
        end
        el.setString(tag, vr, data);
% elseif vr.equals(org.dcm4che3.data.VR.LO) || vr.equals(org.dcm4che3.data.VR.ST) %any(strcmpi(vr,{'LO', 'ST'}))
    case {19535,21332}
    %case {'LO', 'ST'}
        el.setString(tag, vr, data);
%elseif vr.equals(org.dcm4che3.data.VR.DA) %strcmpi(vr,'DA')
    case 17473
    %case 'DA' 
        %Use builtin dcm4che Date functions.
        el.setDate(tag, vr, []);
        if ~isempty(data)
            jDate = javaObject('org.dcm4che3.util.DateUtils');
            tz = el.getTimeZone();
            date = jDate.parseDA(tz, data, 1);
            el.setString(tag, vr, jDate.formatDA(tz, date));
        end
        %setDate(privateCreator, tmTag, VR.TM, org.dcm4che3.data.DatePrecision;, date);
        %el.setDate(tag, date);

%elseif vr.equals(org.dcm4che3.data.VR.DS) %strcmpi(vr,'DS')
    case 17491
    %case 'DS'
        %if ~isempty(data)
        %    el.setFloat(tag, vr, data);
        %else
        %    el.setFloat(tag, vr, []);
        %end
        if length(data) < 2
          el.setString(tag, vr, num2str(data));
        else
          el.setFloat(tag, vr, data);
        end
        
%elseif vr.equals(org.dcm4che3.data.VR.DT) %strcmpi(vr,'DT')
    case 17492
    %case 'DT'
        %Needs implementation     
%elseif vr.equals(org.dcm4che3.data.VR.FL) %strcmpi(vr,'FL')
    case 17996
    %case 'FL'        
        if length(data) < 2
            el.setString(tag, vr, num2str(data));
        else
            el.setFloat(tag, vr, data);
        end
         
%elseif vr.equals(org.dcm4che3.data.VR.FD) %strcmpi(vr,'FD')
    case 17988
    %case 'FD'
        %Needs implementation   
%elseif vr.equals(org.dcm4che3.data.VR.IS) %strcmpi(vr,'IS')
    case 18771
    %case 'IS'
        if isnumeric(data) || isempty(data)
            if length(data) < 2
                el.setString(tag,vr,num2str(data));
            else              
                el.setInt(tag, vr, data);
            end            
        else
            error('The input should be numeric for "IS" ');
        end
%elseif vr.equals(org.dcm4che3.data.VR.LT) %strcmpi(vr,'LT')
    case 19540
    %case 'LT'
        %Needs implementation     
%elseif vr.equals(org.dcm4che3.data.VR.OB) %strcmpi(vr,'OB')
    case 20290
    %case 'OB'
        %Needs implementation  
%elseif vr.equals(org.dcm4che3.data.VR.OF) %strcmpi(vr,'OF')
    case 20294
    %case 'OF'
        %Needs implementation  
%elseif vr.equals(org.dcm4che3.data.VR.OW) %strcmpi(vr,'OW')
    case 20311
    %case 'OW'
         el.setInt(tag, vr, double(data));  %Incorrect. Requires putBytes unless LUT data.
%          el.putBytes(tag, vr, 1, data);         
%elseif vr.equals(org.dcm4che3.data.VR.PN) %strcmpi(vr,'PN')
    case 20558
        %case 'PN'
        %nameObj = org.dcm4che3.data.PersonName(el.getString(tag));
        nameObj = javaObject('org.dcm4che3.data.PersonName','');
        
        %DCM4CHE3 now uses enum 'Component' instead of an array
        
        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');
        compNamePrefix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NamePrefix');
        compNameSuffix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NameSuffix');
        
        %The # in get(#) as defined by dcm4che2, PersonName class.
        if isfield(data,'FamilyName')
            nameObj.set(compFamilyName, data.FamilyName);
            nameObj.set(compGivenName, data.GivenName);
            nameObj.set(compMiddleName, data.MiddleName);
            nameObj.set(compNamePrefix, data.NamePrefix);
            nameObj.set(compNameSuffix, data.NameSuffix);
        else
            nameObj.setValue(data); % check this
        end
        
         el.setString(tag, vr, nameObj.toString);
%elseif vr.equals(org.dcm4che3.data.VR.SH) %strcmpi(vr,'SH')
    case 21320
    %case 'SH'
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
        el.setString(tag, vr, data);
%elseif vr.equals(org.dcm4che3.data.VR.SL) %strcmpi(vr,'SL')
    case 21324
    %case 'SL'
        %Needs implementation       
        if length(data) < 2
            el.setString(tag, vr, num2str(data));
        else
            el.setInt(tag, vr, data);
        end        
%elseif vr.equals(org.dcm4che3.data.VR.SQ) %strcmpi(vr,'SQ')
    case 21329
    %case 'SQ'
        %Implementation currently unnecessary.
%elseif vr.equals(org.dcm4che3.data.VR.SS) %strcmpi(vr,'SS')
    case 21331
    %case 'SS'
        %Needs implementation
%elseif vr.equals(org.dcm4che3.data.VR.TM) %strcmpi(vr,'TM')
    case 21581
    %case 'TM'   
        %Use builtin dcm4che Time functions.
        jDate = javaObject('org.dcm4che3.util.DateUtils');
        tz = el.getTimeZone();
        precision = javaObject('org.dcm4che3.data.DatePrecision');
        try
            date = jDate.parseTM(tz, data, 1, precision);
            el.setDate(tag, vr, []);
            el.setString(tag, vr, jDate.formatTM(tz, date));
        catch
            el.setDate(tag,vr,[]);
        end
%elseif vr.equals(org.dcm4che3.data.VR.UI) %strcmpi(vr,'UI')
    case 21833
    %case 'UI'
          el.setString(tag, vr, data);
%elseif vr.equals(org.dcm4che3.data.VR.UL) %strcmpi(vr,'UL')
    case 21836
    %case 'UL'
        %Needs implementation
%elseif vr.equals(org.dcm4che3.data.VR.UN) %strcmpi(vr,'UN')
    case 21838
    %case 'UN'
        %Needs implementation
%elseif vr.equals(org.dcm4che3.data.VR.US) %strcmpi(vr,'US')
    case 21843
    %case 'US'
        if length(data) < 2
            el.setString(tag, vr, num2str(data));
        else
            el.setInt(tag, vr, data);
        end       
      
%elseif vr.equals(org.dcm4che3.data.VR.UT) %strcmpi(vr,'UT')
    case 21844
    %case 'UT'
        %Needs implementation 
%else
    otherwise
        error('Unrecognized VR type.'); %%Consider more gracious exit.
end

%DEBUGGING CODE: remove this once all VRs are implemented.
if el.isEmpty
    warning(['DEBUGGING: ' vr ' is not defined.  Implement it in data2dcmElement.m']);
    el = [];

else
    %el = attr;
end

%clear attr;