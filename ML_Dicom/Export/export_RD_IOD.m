function nWritten = export_RD_IOD(planC, filenameRoot, filenumber)
%"export_RD_IOD"
%   Builds a RD structure dcmobj from the modules specified in part A.18.3 
%   of PS 3.3 of the 2006 DICOM standard.  The planC MUST have first been 
%   run through the function generate_DICOM_UID_Relationships.m.
%
%JRA 07/05/06
%
%Usage:
%   nWritten = export_RD_IOD(planC, filenameRoot, filenumber)
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

%Init number of files written to zero.
nWritten = 0;

indexS = planC{end};

%Get required components of planC.
structureS = planC{indexS.structures};
scanS = planC{indexS.scan};
DVHS  = planC{indexS.DVH};

for i = 1:length(planC{indexS.dose});
    
    %Get the dose we are currently exporting.
    doseS = planC{indexS.dose}(i);    
    
    %Create empty dcmobj.
    dcmobj = org.dcm4che2.data.BasicDicomObject;    

    %Export each module required for the RD IOD, copying the results into the
    %common dcmobj container and return.
    if isfield(scanS.scanInfo(1).DICOMHeaders,'PatientID')
        doseS(1).DICOMHeaders.PatientID = scanS.scanInfo(1).DICOMHeaders.PatientID;
    end
    ssobj = export_module('patient', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;
    
    ssobj = export_module('general_study', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    ssobj = export_module('general_equipment', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    ssobj = export_module('rt_series', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    ssobj = export_module('frame_of_reference', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    ssobj = export_module('general_image', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    ssobj = export_module('image_plane', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    ssobj = export_module('image_pixel', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;
    
    ssobj = export_module('multi_frame', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;    

    doseUnits = getDoseUnitsStr(i, planC);
    ssobj = export_module('rt_dose', doseS, doseUnits);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    %Determine if DVHs must be exported.  If any DVHs reference the dose
    %being exported, they are exported in the rt_dvh module.
    dInd = [];
    for dvhNum = 1:length(DVHS)
        if DVHS(dvhNum).doseIndex == i & ~isempty(DVHS(dvhNum).doseIndex)
            dInd = [dInd dvhNum];
        end
    end
        
    %Call the rt_dvh export with only the relevant DVHs.
    if length(dInd) > 0        
        ssobj = export_module('rt_dvh', i, DVHS(dInd));
        ssobj.copyTo(dcmobj);
        clear ssobj;
    end
        
    ssobj = export_module('SOP_common', 'dose', doseS);
    ssobj.copyTo(dcmobj);
    clear ssobj;

    fileNum  = num2str(filenumber + nWritten);
    filename = fullfile(filenameRoot,['RD_', repmat('0', [1 5-length(fileNum)]), fileNum]);

    writefile_mldcm(dcmobj, filename);

    nWritten = nWritten + 1;

    clear dcmobj;

end