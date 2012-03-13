function planC = readScanFromDir(scan_dir)
%INPUT: scan_dir is the directory containing DICOM files for scan
%OUTPUT: planC with scan field populated
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


% scan_dir = 'C:\Projects\PinnacleReader\PinnacleWholePatientPlanExample\ImageSet_0.DICOM';
hWaitbar = waitbar(0,'Scanning Directory Please wait...');
try
    patient = scandir_mldcm(scan_dir, hWaitbar, 1);
catch
    close(hWaitbar);
end
close(hWaitbar);
planC = dcmdir2planC(patient.PATIENT);
