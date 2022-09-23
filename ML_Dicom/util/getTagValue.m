function data = getTagValue(attr, tag, varargin)
%"dcm2ml_element"
%   Convert a Java SimpleDicomElement object into a Matlab datatype.
%
%   TO DO: Define VRs labeled "Needs implementation."  All elements require
%   testing on various plans.
%
%   Discription for all the VR types
%     FD => 'double',
%     FL => 'float',
%     OB => 'int8u',
%     OF => 'float',
%     OW => 'int16u',
%     SL => 'int32s',
%     SS => 'int16s',
%     UL => 'int32u',
%     US => 'int16u',
%
%JRA 6/1/06
%NAV 07/19/16 updated to dcm4che3
%   DK
%       Added support for multiple VR types.
%
%Usage:
%   data = dcm2ml_element(Java SimpleDicomElement)
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

%transferSyntaxUID = attr.getString(hex2dec('00020010'));
%Get the VR, cast to ML char array.
%vr = org.dcm4che3.data.ElementDictionary.vrOf(hex2dec(tag), transferSyntaxUID);

% apa - 1/11/21
% vr = org.dcm4che3.data.ElementDictionary.vrOf(hex2dec(tag), []);
% vr = cell(vr.toString);
% vr = vr{1};
% apa - 1/11/21 end

%vr = javaMethod('vrOf','org.dcm4che3.data.ElementDictionary',tag, []);
%vrCode = vr.code;
if attr.contains(tag)
    vr = attr.getVR(tag);
    vrCode = vr.code;
else
    data = '';
    return
end

%Set cache buffer to true.
buf = 1;
cs = [];

%switch upper(vr)
switch vrCode
    case 16709
        %if vr.equals(org.dcm4che3.data.VR.AE) %strcmpi(vr,'AE')
        %case 'AE'
        %Needs implementation
        data = '';
    case 16723
        %elseif vr.equals(org.dcm4che3.data.VR.AS) %strcmpi(vr,'AS')
        %case 'AS'
        %Needs implementation
        data = '';
    case 16724
        %elseif vr.equals(org.dcm4che3.data.VR.AT) %strcmpi(vr,'AT')
        %case 'AT'
        data = dec2hex(attr.getInts(tag));
    case {17235,19535,21320,21332}
        %elseif vr.equals(org.dcm4che3.data.VR.CS) || vr.equals(org.dcm4che3.data.VR.LO) || ...
        %        vr.equals(org.dcm4che3.data.VR.SH) || vr.equals(org.dcm4che3.data.VR.ST) %any(strcmpi(vr,{'CS', 'LO', 'SH', 'ST'}))
        %case {'CS', 'LO', 'SH', 'ST'}
        data = char(attr.getString(tag,0));
        %data = org.dcm4che3.data.ElementDictionary.keywordOf(hex2dec(tag), []);
        %If more than one string, put in cell array.
        %if numel(data) > 1
        %    data = cell(data);
        %else
        %    data = char(data);
        %end
    case 17473
        %elseif vr.equals(org.dcm4che3.data.VR.DA) %strcmpi(vr,'DA')
        %case 'DA'
        %Date string format: YYYYMMDD
        data = char(attr.getString(tag,0));
    case 17491
        %elseif vr.equals(org.dcm4che3.data.VR.DS) %strcmpi(vr,'DS')
        %case 'DS'
        data = attr.getDoubles(tag);
    case 17492
        %elseif vr.equals(org.dcm4che3.data.VR.DT) %strcmpi(vr,'DT')
        %case 'DT'
        data = attr.getDate(tag);
    case 17996
        %elseif vr.equals(org.dcm4che3.data.VR.FL) %strcmpi(vr,'FL')
        %case 'FL'
        %Needs implementation
        %wy
        %data =  float(attr.getFloat(buf));
        data =  attr.getFloats(tag);
    case 17988
        %elseif vr.equals(org.dcm4che3.data.VR.FD) %strcmpi(vr,'FD')
        %case 'FD'
        data = attr.getDoubles(tag);
    case 18771
        %elseif vr.equals(org.dcm4che3.data.VR.IS) %strcmpi(vr,'IS')
        %case 'IS'
        data = attr.getInts(tag);
    case 19540
        %elseif vr.equals(org.dcm4che3.data.VR.LT) %strcmpi(vr,'LT')
        %case 'LT'
        %data = char(attr.getString(cs, buf));
        data = char(attr.getString(cs, 0));
    case 20290
        %elseif vr.equals(org.dcm4che3.data.VR.OB) %strcmpi(vr,'OB')
        %case 'OB'
        data = attr.getBytes;
        %         %%%%%% Modified to import compressed data AI 02/06/17 %%%%%%%
        %         txSyntax = varargin{1};
        %         switch txSyntax
        %             case {'1.2.840.10008.1.2.4.50'
        %                     '1.2.840.10008.1.2.4.57'
        %                     '1.2.840.10008.1.2.4.70'
        %                     '1.2.840.10008.1.2.4.90'
        %                     '1.2.840.10008.1.2.4.91'
        %                     }
        %                 %Decompress JPEG frame
        %                 nElements = attr.countItems;
        %                 %if nElements>2
        %                 %    warning(' dcm2ml_Element does not support multiple fragments');
        %                 %    return
        %                 %else
        %                 data = [];
        %                 for iFrag = 1:nElements
        %                     fragment = typecast(attr.getFragment(iFrag-1),'uint8');
        %                     if ~isempty(fragment)
        %                         fileName = getTempName;
        %                         fid = fopen(fileName,'w');
        %                         if (fid < 0)
        %                             error('dcm2ml_element:Could not create temp file');
        %                         end
        %                         fwrite(fid,fragment,'uint8');
        %                         fclose(fid);
        %                         %tmp = onCleanup(@() delete(fileName));
        %                         %dataTmpV = imread(fileName).';
        %                         dataTmpV = imread(fileName);
        %                         if ndims(dataTmpV) == 3
        %                             dataTmpV = rgb2gray(dataTmpV); % temp for SM modality
        %                         end
        %                         dataTmpV = permute(dataTmpV,[2,1,3]);
        %                         data = [data;dataTmpV(:)];
        %                     end
        %                 end
        %                 delete(fileName)
        %                 %end
        %
        %             case '1.2.840.10008.1.2.5'
        %
        %                 % To do: Decompress RLE frame
        %
        %             case {'1.2.840.10008.1.2'  %Implicit VR Little Endian (default)
        %                     '1.2.840.10008.1.2.1' %Explicit VR Little Endian
        %                     '1.2.840.10008.1.2.2' %Explicit VR Big Endian
        %                     '1.2.840.113619.5.2' %Implicit VR Big Endian (GE pvt)
        %                     '1.3.46.670589.33.1.4.1'}%Explicit VR Little Endian (Philips pvt)
        %
        %                 %data = el.getBytes;
        %
        %             otherwise
        %                 error('dc2ml_Element : Encoding not supported');
        %         end
        %         %%%%%%%%%%%%%%%%%%% End Modified %%%%%%%%%%%%%%%%%%%%%
    case 20294
        %elseif vr.equals(org.dcm4che3.data.VR.OF) %strcmpi(vr,'OF')
        %case 'OF'
        data = attr.getFloats(tag);
    case 20311
        %elseif vr.equals(org.dcm4che3.data.VR.OW) %strcmpi(vr,'OW')
        %case 'OW'
        %OW contains 16 bit words.  Conversion of this data into meaningful
        %values is the responsibility of the calling function.

        %wy it should be uint16 or int16, which depends on the value in data
        %representation fields, but the data conversion b/w matlab and java is int32.

        %data = uint16(attr.getInts(buf));
        %data = attr.getInts(hex2dec(tag));
        data = cast(attr.getInts(tag),'int16');
    case 20558
        %elseif vr.equals(org.dcm4che3.data.VR.PN) %strcmpi(vr,'PN')
        %case 'PN'
        %nameObj = org.dcm4che3.data.PersonName(attr.getString(tag));
        nameObj = javaObject('org.dcm4che3.data.PersonName',attr.getString(tag));
        %DCM4CHE3 now uses enum 'Component' instead of an array

        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');
        compNamePrefix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NamePrefix');
        compNameSuffix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NameSuffix');

        %The # in get(#) as defined by dcm4che2, PersonName class.
        data.FamilyName = char(nameObj.get(compFamilyName));
        data.GivenName  = char(nameObj.get(compGivenName));
        data.MiddleName = char(nameObj.get(compMiddleName));
        data.NamePrefix = char(nameObj.get(compNamePrefix));
        data.NameSuffix = char(nameObj.get(compNameSuffix));
    case 21324
        %elseif vr.equals(org.dcm4che3.data.VR.SL) %strcmpi(vr,'SL')
        %case 'SL'
        data = attr.getInt(tag, 0);
    case 21329
        %elseif vr.equals(org.dcm4che3.data.VR.SQ) %strcmpi(vr,'SQ')
        %case 'SQ'
        el = attr.getValue(tag);
        if ~isempty(el) && ~el.isEmpty
            nElements = el.size();
        else
            nElements = 0;
        end
        data = [];
        for i=0:nElements-1
            data.(['Item_' num2str(i+1)]) = getTagStruct(el.get(i)); %CHANGE THIS TOO IMPORTANT
        end
    case 21331
        %elseif vr.equals(org.dcm4che3.data.VR.SS) %strcmpi(vr,'SS')
        %case 'SS'
        %Needs implementation
        data = '';
    case 21581
        %elseif vr.equals(org.dcm4che3.data.VR.TM) %strcmpi(vr,'TM')
        %case 'TM'
        %Time string format: HHMMSS.ss where "ss" is fraction of a second.
        % data = char(attr.getString(hex2dec(tag)));
        data = char(attr.getString(tag,0));
        %if ~isempty(data)
        %    data = cell(data);
        %    data = data{1};
        %end
    case 21833
        %elseif vr.equals(org.dcm4che3.data.VR.UI) %strcmpi(vr,'UI')
        %case 'UI'
        % data = char(attr.getString(hex2dec(tag)));
        data = char(attr.getString(tag,0));
        %if ~isempty(data)
        %    data = cell(data);
        %    data = data{1};
        %end
    case 21836
        %elseif vr.equals(org.dcm4che3.data.VR.UL) %strcmpi(vr,'UL')
        %case 'UL'
        data = attr.getInts(tag);
    case 21838
        %elseif vr.equals(org.dcm4che3.data.VR.UN) %strcmpi(vr,'UN')
        %case 'UN'
        data = attr.getBytes(tag);
    case 21843
        %elseif vr.equals(org.dcm4che3.data.VR.US) %strcmpi(vr,'US')
        %case 'US'
        data = attr.getInt(tag, 0);
    case 21844
        %elseif vr.equals(org.dcm4che3.data.VR.UT) %strcmpi(vr,'UT')
        %case 'UT'
        %Needs implementation
        data = '';
        %else
    otherwise
        error('Unrecognized VR type.'); %%Consider more gracious exit.
end


%DEBUGGING: remove this once all DICOM VRs are implemented and fully
%tested.  Until then, reaching this point in the code indicates that a VR
%MUST be defined for proper functioning of a called module.
if ~exist('data', 'var')
    disp(['DEBUGGING: ' vr ' is not defined.  Implement it in dcm2ml_Element.m']);
    data = '';
else
    %Handle empty data situations -- this needs to be tailored to individual
    %VR values if matching MATLAB's dicominfo function output is desired.
    if isempty(data)
        data = '';
    end
end