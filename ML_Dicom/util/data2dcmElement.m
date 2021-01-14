function el = data2dcmElement(el, data, tag)
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

%Create an isempty attr to act as a temporary container for the new element.
attr = org.dcm4che3.data.Attributes;
vr = org.dcm4che3.data.ElementDictionary.vrOf(tag, []);
vrString = char(vr);
%Get the tag for this element.
%tag = el.tag;

%Get the VR, cast to ML char array.
%vr = char(vr.toString);

%%
switch upper(vrString)
    case 'AE'
        %Needs implementation
    case 'AS'
        %Needs implementation
    case 'AT'
        %Attribute tags may be passed as a hex string, ie '000A003E', or an
        %integer that would be the result of hex2dec('000A003E');
        if ~isnumeric(data) && ischar(data)
            data = hex2dec(data);
        end
        attr.setInt(tag, vr, data);
    case 'CS'
        if ~isempty(data)
            data = upper(strtrim(data));
        end
        attr.setString(tag, vr, data);
    case {'LO', 'ST'}
        attr.setString(tag, vr, data);
    case 'DA' 
        %Use builtin dcm4che Date functions.
        attr.setDate(tag, vr, []);
        if ~isempty(data)
            jDate = org.dcm4che3.util.DateUtils;
            tz = attr.getTimeZone();
            date = jDate.parseDA(tz, data, 1);
            attr.setString(tag, vr, jDate.formatDA(tz, date));
        end
        %setDate(privateCreator, tmTag, VR.TM, org.dcm4che3.data.DatePrecision;, date);
        %attr.setDate(tag, date);

    case 'DS'
        if ~isempty(data)
            attr.setFloat(tag, vr, data);
        else
            attr.setFloat(tag, vr, []);
        end
    case 'DT'
        %Needs implementation        
    case 'FL'        
        attr.setFloat(tag, vr, data);        
    case 'FD'
        %Needs implementation        
    case 'IS'
        if isnumeric(data)
            attr.setInt(tag, vr, data);
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
         attr.setInt(tag, vr, double(data));  %Incorrect. Requires putBytes unless LUT data.
%          attr.putBytes(tag, vr, 1, data);         

    case 'PN' 
         %nameObj = org.dcm4che3.data.PersonName(el.getString(tag));
         nameObj = org.dcm4che3.data.PersonName(dec2hex(tag));
         
         %DCM4CHE3 now uses enum 'Component' instead of an array
        
        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');
        compNamePrefix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NamePrefix');
        compNameSuffix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NameSuffix');
        
         %The # in get(#) as defined by dcm4che2, PersonName class.
         nameObj.set(compFamilyName, data.FamilyName);
         nameObj.set(compGivenName, data.GivenName);
         nameObj.set(compMiddleName, data.MiddleName);
         nameObj.set(compNamePrefix, data.NamePrefix);
         nameObj.set(compNameSuffix, data.NameSuffix);         
         
         attr.setString(tag, vr, nameObj.toString);

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
        attr.setString(tag, vr, data);
    case 'SL'
        %Needs implementation       
        attr.setInt(tag, vr, data);
    case 'SQ'
        
         fN = fieldnames(data);
         sz = size(fN,1);
        
         seq = attr.newSequence(tag, sz);
  
         %RADIOPHARMA INFO SEQ
         if tag == 5505046
             
             %RADIOPHARACEUTICAL
             el = data2dcmElement(el,data.Radiopharmaceutical,1572913);
             if ~isempty(el)
                 seq.add(el);
             end
             
             %RADIO VOLUME
             el = data2dcmElement(el,data.RadiopharmaceuticalVolume,1577073);
             if ~isempty(el)
                 seq.add(el);
             end
             
             %RADIO START TIME
             el = data2dcmElement(el,data.RadiopharmaceuticalStartTime,1577074);
             if ~isempty(el)
                 seq.add(el);
             end
           
             %RADIO STOP TIME
             el = data2dcmElement(el,data.RadiopharmaceuticalStopTime,1577075);
             if ~isempty(el)
                 seq.add(el);
             end
             
             %RADIO TOTAL DOSE
             el = data2dcmElement(el,data.RadionuclideTotalDose,1577076);
             if ~isempty(el)
                 seq.add(el);
             end
             
             
             %RADIO HALF LIFE
             el = data2dcmElement(el,data.RadionuclideHalfLife,1577077);
             if ~isempty(el)
                 seq.add(el);
             end
             
             
             %RADIO POS FRAC
             el = data2dcmElement(el,data.RadionuclidePositronFraction,1577078);
             if ~isempty(el)
                 seq.add(el);
             end
             
             %RADIOPHARMA START DATE TIME
             el = data2dcmElement(el,data.RadiopharmaceuticalStartDateTime,1577080);
             if ~isempty(el)
                 seq.add(el);
             end
            
             %RADIOPHARMA STOP DATE TIME
             el = data2dcmElement(el,data.RadiopharmaceuticalStopDateTime,1577081);
             if ~isempty(el)
                 seq.add(el);
             end
             
             %RADIONUCLIDE CODE SEQ
             el = data2dcmElement(el,data.RadionuclideCodeSequence.Item_1,5505792);  
             if ~isempty(el)
                 seq.add(el);
             end
             
             %RADIONUCLIDE CODE SEQ
             el = data2dcmElement(el,data.RadiopharmaceuticalCodeSequence.Item_1,5505796);
             if ~isempty(el)
                 seq.add(el);
             end
         elseif tag == 5505792 || 5505796
            %code value = 0008 0100 VR = SH
            el = data2dcmElement(el,data.CodeValue,524544);
            if ~isempty(el)
                seq.add(el);
            end
            
            %coding scheme designator 0008 0102 VR = SH
            el = data2dcmElement(el,data.CodingSchemeDesignator,524546);
            if ~isempty(el)
                seq.add(el);
            end
            
            %code meaning 0008 0104 VR = LO
            el = data2dcmElement(el,data.CodeMeaning,524548);
            if ~isempty(el)
                seq.add(el);
            end
            
         end
         
         attr.setValue(tag,vr,seq);
        
    case 'SS'
        %Needs implementation
    case 'TM'   
        %Use builtin dcm4che Time functions.
        jDate = org.dcm4che3.util.DateUtils;
        tz = attr.getTimeZone();
        precision = org.dcm4che3.data.DatePrecision;
        try
            date = jDate.parseTM(tz, data, 1, precision);
            attr.setDate(tag, vr, []);
            attr.setString(tag, vr, jDate.formatTM(tz, date));
        catch
            attr.setDate(tag,vr,[]);
        end
    case 'UI'
          attr.setString(tag, vr, data);
    case 'UL'
        %Needs implementation
    case 'UN'
        %Needs implementation
    case 'US'
        attr.setInt(tag, vr, data);
    case 'UT'
        %Needs implementation        
    otherwise
        error('Unrecognized VR type.'); %%Consider more gracious exit.
end

%DEBUGGING CODE: remove this once all VRs are implemented.
if attr.isempty
    warning(['DEBUGGING: ' vrString ' is not defined.  Implement it in data2dcmElement.m']);
    el = [];

else
    el = attr;
end

clear attr;
