function el = export_rt_dose_module_field(args)
%"export_rt_dose_module_field"
%   Given a single planC.dose and a tag in the RT_Dose module, return a 
%   properly populated and formatted instance of that tag.  
%
%   For speed, tag must be a decimal representation of the 8 digit
%   hexidecimal DICOM tag desired, ie instead of '00100010', pass
%   hex2dec('00100010');
%
%   Arguments are passed in a structure, arg:
%       arg.tag         = decimal tag of field to fill
%       arg.data        = CERR structure(s) to fill from
%       arg.template    = an empty template of the module created by the
%                         function build_module_template.m
%
%   This function requires arg.data is a single doseS.
%
%JRA 06/19/06
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
%
%Usage:
%   dcmobj = export_rt_dose_module_field(args)
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

%Init output element to empty.
el = [];

%Unpack input data.
tag         = args.tag;
doseS       = args.data{1};
doseUnits   = args.data{2};
template    = args.template;

switch tag
    case   2621442  %0028,0002  Samples per Pixel
        data = 1;
        el = data2dcmElement(template, data, tag); 
        
    case   2621444  %0028,0004  Photometric Interpretation
        data = 'MONOCHROME2';
        el = data2dcmElement(template, data, tag); 
        
    case   2621696  %0028,0100  Bits Allocated
        data = 32;
        el = data2dcmElement(template, data, tag); 
        
    case   2621697  %0028,0101  Bits Stored
        data = 32;
        el = data2dcmElement(template, data, tag); 
        
    case   2621698  %0028,0102  High Bit
        data = 32 - 1;
        el = data2dcmElement(template, data, tag);         
        
    case   2621699  %0028,0103  Pixel Representation
%wy         switch upper(doseS.doseType)
%             case 'ERROR'
%                 data = 1; %Two's Compliment Integer -- for ERROR does types, which may contain negative values.                
%             otherwise
%                 data = 0; %Unsigned Integer -- for all other dose types.
%         end
        if strcmpi(doseS.doseType, 'error')
            data = 1;
        else
            data = 0;
        end
%wy
        el = data2dcmElement(template, data, tag);               
        
    case 805568514  %3004,0002  Dose Units
        if isempty(doseUnits)
            doseUnits = 'relative';
        end
        switch upper(doseUnits);
            case 'GY' %Add more cases here if required.
                data = 'GY';
            case 'CGY' %Add more cases here if required.
                data = 'CGY';                
            otherwise
                data = 'RELATIVE';
        end
        el = data2dcmElement(template, data, tag);                         
        
    case 805568516  %3004,0004  Dose Type
        if ~isempty(doseS.doseType)
            switch upper(doseS.doseType)
                case 'PHYSICAL'
                    data = 'PHYSICAL';                
                case 'EFFECTIVE'
                    data = 'EFFECTIVE'; %Currently Unimplemented in CERR.               
                case 'ERROR'
                    data = 'ERROR';     %Consider doseType to ERROR for dose differences in CERR.           
                otherwise
                    data = 'PHYSICAL';  %Default to PHYSICAL if field is not set or unknown.
            end
        else
            data = 'PHYSICAL';
        end
        
        el = data2dcmElement(template, data, tag);                        
        
    case   2097171  %0020,0013  Instance Number
        %Currently unimplemented.
        
    case 805568518  %3004,0006  Dose Comment
        %Currently unimplemented.
        
    case 805568520  %3004,0008  Normalization Point
        %[x,y,z] coordinate of the normalization point, if it is defined.
        if ~isempty(doseS.xcoordOfNormaliznPoint) & ~isempty(doseS.ycoordOfNormaliznPoint) & ~isempty(doseS.zcoordOfNormaliznPoint)
           data = [doseS.xcoordOfNormaliznPoint doseS.ycoordOfNormaliznPoint doseS.zcoordOfNormaliznPoint];
           
           %Convert from CERR cm to DICOM mm.                
           data = data * 10;           
           el = data2dcmElement(template, data, tag); 
        end
        
    case 805568522  %3004,000A  Dose Summation Type
        %Currently insufficent data in CERR's doseS structure to determine
        %this value, so defaulting to PLAN for all doseS.
        data = 'PLAN';
        el = data2dcmElement(template, data, tag);        
        
    case 806092802  %300C,0002  Referenced RT Plan Sequence
        templateEl = template.getValue(tag);
        fHandle = @export_referenced_rt_plan_sequence;

        tmp = org.dcm4che3.data.Attributes;
        el = tmp.newSequence(tag, 0);
       
        dcmobj = export_sequence(fHandle, templateEl, {doseS});
        %Converted to dcm4che3
        el.add(0, dcmobj);
        
        el = el.getParent();
    case 805568524  %3004,000C  Grid Frame Offset Vector
        %Vector of monotonically varying values starting at zero,
        %indicating offset of Z coordinate from image position (patient)
        %firstZ = doseS.zValues(1);
        %lastZ  = doseS.zValues(end);
        %numZ   = length(doseS.zValues);      
        %data   = linspace(firstZ, lastZ, numZ) - firstZ;
        
        % (-)ve z-values to go back to DICOM coordinates
        zDicomV = -doseS.zValues; % tested only for non-oblique dose HFS
        data = zDicomV(1) - zDicomV;
                
        %Convert from CERR cm to DICOM mm.                
        data = data * 10;
        
        el = data2dcmElement(template, data, tag);              
        
    case 805568526  %3004,000E  Dose Grid Scaling
        nBits = 31;
        data = permute(doseS.doseArray, [2 1 3]);
        data = data(:);
        maxABSDose = max(abs(data(:)));
        maxScaled  = 2^nBits;

        data = maxABSDose ./ maxScaled;
        el = data2dcmElement(template, data, tag);                       
        
    case 805568532  %3004,0014  Tissue Heterogeneity Correction
        %Currently unimplemented.
                       
    otherwise
        warning(['No methods exist to populate DICOM rt_dose module field ' dec2hex(tag,8) '.']);
end


