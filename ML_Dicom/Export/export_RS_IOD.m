function nWritten = export_RS_IOD(planC, filenameRoot, filenumber)
%"export_RS_IOD"
%   Builds a RT Structure dcmobj from the modules specified in part A.19.3 
%   of PS 3.3 of the 2006 DICOM standard.  The planC MUST have first been 
%   run through the function generate_DICOM_UID_Relationships.m.
%
%JRA 07/05/06
%
%Usage:
%   nWritten = export_RS_IOD(planC, filenameRoot, filenumber)
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

%Create empty dcmobj.
dcmobj = org.dcm4che2.data.BasicDicomObject;

indexS = planC{end};

%Get required components of planC.
structureS = planC{indexS.structures};

if length(structureS) == 0
    return
end

scanS = planC{indexS.scan};


%Export each module required for the RS IOD, copying the results into the
%common dcmobj container and return.
ssobj = export_module('patient', 'structures', structureS);
ssobj.copyTo(dcmobj);
clear ssobj;

ssobj = export_module('general_study', structureS);
ssobj.copyTo(dcmobj);
clear ssobj;

ssobj = export_module('general_equipment', 'structures', structureS);
ssobj.copyTo(dcmobj);
clear ssobj;

ssobj = export_module('rt_series', 'structures', structureS);
ssobj.copyTo(dcmobj);
clear ssobj;

ssobj = export_module('structure_set', structureS, scanS);
ssobj.copyTo(dcmobj);
clear ssobj;

ssobj = export_module('roi_contour', structureS);
ssobj.copyTo(dcmobj);
clear ssobj;

ssobj = export_module('rt_roi_observations', structureS);
ssobj.copyTo(dcmobj);
clear ssobj;
    
ssobj = export_module('SOP_common', 'structures', structureS);
ssobj.copyTo(dcmobj);
clear ssobj;

fileNum  = num2str(filenumber + nWritten);
filename = [filenameRoot '_RS_' repmat('0', [1 5-length(fileNum)]) fileNum];

writefile_mldcm(dcmobj, filename);

nWritten = nWritten + 1;

clear dcmobj;