function nWritten = export_RS_IOD(planC, filenameRoot, filenumber)
%"export_RS_IOD"
%   Builds a RT Structure attr from the modules specified in part A.19.3
%   of PS 3.3 of the 2006 DICOM standard.  The planC MUST have first been
%   run through the function generate_DICOM_UID_Relationships.m.
%
%JRA 07/05/06
%NAV 07/19/16 updated to dcm4che3
%    Used addAll over copyTo
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

indexS = planC{end};

assocScansV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);

for scanNum = 1:length(planC{indexS.scan})
        
    if length(planC{indexS.scan}) > 1
        destDirPath = fullfile(filenameRoot,['Scan_',num2str(scanNum)]);
    else
        destDirPath = filenameRoot;
    end
    
    scanS = planC{indexS.scan}(scanNum);
    
    matchStructsV = find(assocScansV == scanNum);
    
    if isempty(matchStructsV)
        continue;
    end
    
    %Create empty attr.
    attr = javaObject('org.dcm4che3.data.Attributes');    
    
    structureS = planC{indexS.structures}(matchStructsV);
        
    %Export each module required for the RS IOD, copying the results into the
    %common ssattr container and return.
    ssattr = export_module('patient', 'structures', structureS);
    attr.addAll(ssattr);
    clear ssattr;
    
    ssattr = export_module('general_study', structureS);
    attr.addAll(ssattr);
    clear ssattr;
    
    ssattr = export_module('general_equipment', 'structures', structureS);
    attr.addAll(ssattr);
    clear ssattr;
    
    ssattr = export_module('rt_series', 'structures', structureS);
    attr.addAll(ssattr);
    clear ssattr;
    
    ssattr = export_module('structure_set', structureS, scanS);
    attr.addAll(ssattr);
    clear ssattr;
    
    ssattr = export_module('roi_contour', structureS, scanS); %AI mod
    attr.addAll(ssattr);
    clear ssattr;
    
    ssattr = export_module('rt_roi_observations', structureS);
    attr.addAll(ssattr);
    clear ssattr;
    
    ssattr = export_module('SOP_common', 'structures', structureS);
    attr.addAll(ssattr);
    clear ssattr;
    
    if ischar(filenumber)
        filename = fullfile(filenameRoot,filenumber);
    else
        fileNum  = num2str(filenumber + nWritten);
        filename = fullfile(destDirPath,['RS_', repmat('0', [1 5-length(fileNum)]), fileNum]);
    end
    
    writefile_mldcm(attr, filename);
    
    nWritten = nWritten + 1;
    
    clear attr;
    
end

