function el = export_DVH_sequence(args)
%"export_DVH_sequence"
%   Subfunction to handle referenced_structure_set sequences within the
%   rt_dvh module.  Uses the same layout and principle as the
%   parent function.
%
%   This function takes a CERR DVHs element.
%
%JRA 07/10/06
%
%Usage:
%   @export_DVH_sequence(args)
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
DVHS        = args.data{1};
template    = args.template;

switch tag
%     case 805568608  %3004,0060  DVH Referenced ROI Sequence
        %Currently not implemented.  MUST BE IMPLEMENTED.
        
    case 805568513  %3004,0001  DVH Type
        data = 'DIFFERENTIAL';    
        el = template.get(tag);
        el = ml2dcm_Element(el, data);            
        
    case 805568514  %3004,0002  Dose Units
        dUnits = DVHS.doseUnits;
        
        %If empty assume GYs
        if isempty(dUnits)
            dUnits = 'GY';
        end
        
        switch upper(dUnits)
            case {'GRAYS', 'GRAY', 'GY'}
                data = 'GY';
            case 'RELATIVE'
                data = 'RELATIVE';
            otherwise %Assume GY but throw a warning.
                data = 'GY';
                warning('Unable to determine if DVH dose units are ''GY'' or ''RELATIVE''.  Assuming ''GY''.');
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, data);             
        
    case 805568516  %3004,0004  Dose Type
        dtype = DVHS.doseType;
        
        %If Dose Type field does not exist, set to ''.
        if isempty(dtype)                        
            dtype = '';
        end
        
        switch upper(dtype)
            case 'ABSOLUTE'
                data = 'PHYSICAL';
            otherwise %Assume PHYSICAL but throw a warning.  Add other cases here as support is added.
                data = 'PHYSICAL';
                warning('Unable to determine if DVH dose type is ''PHYSICAL'', ''EFFECTIVE'', or ''ERROR''.  Assuming ''PHYSICAL''.');
        end
        el = template.get(tag);
        el = ml2dcm_Element(el, data);             
        
    case 805568594  %3004,0052  DVH Dose Scaling
        data = 1; %CERR DVHs have no dose scaling factor.
        el = template.get(tag);
        el = ml2dcm_Element(el, data);         
        
    case 805568596  %3004,0054  DVH Volume Units
        data = 'CM3'; %CERR DVH data is all in cubic cm.
        el = template.get(tag);
        el = ml2dcm_Element(el, data);                 
        
    case 805568598  %3004,0056  DVH Number of Bins
        data = size(DVHS.DVHMatrix, 1);
        el = template.get(tag);
        el = ml2dcm_Element(el, data);                 
        
    case 805568600  %3004,0058  DVH Data
        nBins     = size(DVHS.DVHMatrix, 1);
        
        if nBins == 0            
           data = [];             
        else
            doseBinsV = DVHS.DVHMatrix(:,1);
            volumesV  = DVHS.DVHMatrix(:,2);        
        
            data(1:2:2*nBins) = doseBinsV;
            data(2:2:2*nBins) = volumesV;    
        end
        
        el = template.get(tag);
        el = ml2dcm_Element(el, data);           
                
    case 805568624  %3004,0070  DVH Minimum Dose
        %Currently not implemented.        
    case 805568626  %3004,0072  DVH Maximum Dose
        %Currently not implemented.        
    case 805568628  %3004,0074  DVH Mean Dose
        %Currently not implemented.
        
    otherwise
        warning(['No methods exist to populate DICOM RT Dose module''s export_DVH_sequence field: ' dec2hex(tag,8) '.']);
end