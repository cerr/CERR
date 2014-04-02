function export_planC_to_DICOM(planC, destDir)
%"export_planC_to_DICOM"
%   Export a planC into the DICOM format.
%
%JRA 07/05/06
%
%Usage:
%   export_planC_to_DICOM(planC, destDir)
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

tic;

filenameRoot    = destDir;
nWritten        = 0;

indexS = planC{end};

if length(planC{indexS.scan})> 1
    hButton = questdlg('Is this a Gamma Knife Plan','Export Option','YES','NO','NO');
    waitfor(hButton);
    
    if strcmpi(hButton,'YES')
        export_gammaKnife(planC,destDir)
        return
    else
        %warning('Export not implemented on multiple scan. Load planC with one scan and export');
    end    
end

%Generate UIDs for the planC.  These fields are temporary and will be
%destroyed upon return since planC is not global.
planC = generate_DICOM_UID_Relationships(planC);

% Export the CT IOD.
nNew     = export_CT_IOD(planC, filenameRoot, nWritten);
nWritten = nWritten + nNew;

%Export the RS IOD.
nNew     = export_RS_IOD(planC, filenameRoot, nWritten);
nWritten = nWritten + nNew;

%Export the RD IOD.
nNew     = export_RD_IOD(planC, filenameRoot, nWritten);
nWritten = nWritten + nNew;

toc;