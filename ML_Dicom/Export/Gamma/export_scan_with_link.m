function export_scan_with_link(scanIndx, planC, destDir)
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

prefix = 'DCM';

filenameRoot    = fullfile(destDir, prefix);

nWritten        = 0;

[doseIndx structIndx]= allLink_to_scan(planC, scanIndx);

planD = initializeCERR;

indexS = planC{end};

planD{indexS.scan} = planC{indexS.scan}(scanIndx);

planD{indexS.dose} = planC{indexS.dose}(doseIndx);

planD{indexS.structures} = planC{indexS.structures}(structIndx);

scanType = planD{indexS.scan}.scanInfo(1).scanType;

if any(strfind(upper(scanType), 'CT'))

    % Export the CT IOD.
    nNew     = export_CT_IOD(planD, filenameRoot, nWritten);
    nWritten = nWritten + nNew;

elseif any(strfind(upper(scanType), 'MR'))
    % Export the MR IOD.
    nNew     = export_MR_IOD(planD, filenameRoot, nWritten);
    nWritten = nWritten + nNew;
    % elseif isus
    %
    % elseif ispet
    %
    % elseif isspect
    %
end

%Export the RS IOD.
if ~length(planD{indexS.structures})==0
    nNew     = export_RS_IOD(planD, filenameRoot, nWritten);
    nWritten = nWritten + nNew;
end

%Export the RD IOD.
if ~length(planD{indexS.dose})==0
    nNew     = export_RD_IOD(planD, filenameRoot, nWritten);
    nWritten = nWritten + nNew;
end
clear planD
