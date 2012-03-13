function planC = CERRImportDICOM(study_directory, planC_save_name, defaultSelection)
%"CERRImportDICOM"
%   Calls DICOM routines to import a DICOM directory to CERR file.
%
%   By default use no parameters, which passes the user to a GUI.  To use
%   in batch mode, pass a directory path and save file name.  The directory
%   path must contain ONLY ONE DICOM study, and will have only the first
%   scan,dose,etc extracted.
%
%Last Modified:  28 Aug 03, by ES.
%                added control for proper exit when user cancelled DICOM import 
%
%                7 Feb 05, JRA Added batch mode control.
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


%Start diary and timer for import log.
startTime = now;
tmpFileName = tempname;
diary(tmpFileName);
Ver = version;
tic;

if exist('study_directory')
    [ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi,MRCell,PETCell,SPECTCell]=dicomrt_DICOMimport(study_directory, 'r', defaultSelection);
else
    [ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi,MRCell,PETCell,SPECTCell]=dicomrt_DICOMimport;    
end

if isempty(ap)==1 & ...
        isempty(ap_xmesh)==1 & ...
        isempty(ap_ymesh)==1 & ...
        isempty(ap_zmesh)==1 & ...
        isempty(ap_ct)==1 & ...
        isempty(ap_ct_xmesh)==1 & ...
        isempty(ap_ct_ymesh)==1 & ...
        isempty(ap_ct_zmesh)==1 & ...
        isempty(ap_voi)==1 & ... 
        isempty(MRCell) & ...
        isempty(PETCell) & ...
        isempty(SPECTCell) , ...
        return;
else
    [planC] = dicomrt_dicomrt2cerr(ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,...
        ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi,'CERROptions.m',MRCell,PETCell,SPECTCell);
end

%Stop diary and write it to planC.
diary off;
endTime = now;
logC = file2cell(tmpFileName);
delete(tmpFileName);
indexS = planC{end};
planC{indexS.importLog}(1).importLog = logC;
planC{indexS.importLog}(1).startTime = datestr(startTime);
planC{indexS.importLog}(1).endTime = datestr(endTime);

toc;
% Save plan  -- this line moved out from dicomrt_dicomrt2cerr.  If a passed
% save name was used, save there, else prompt.
if exist('planC_save_name')
    save_planC(planC,planC{indexS.CERROptions}, 'passed', planC_save_name);
else
    save_planC(planC,planC{indexS.CERROptions});
end


