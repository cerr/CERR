function nWritten = export_GSPS_IOD(planC, filenameRoot, filenumber)
%"export_GSPS_IOD"
%   Writes to disk all scans contained in planC by constructing the modules
%   specified in part A.3.3 of PS 3.3 of the 2006 DICOM standard.  The 
%   planC MUST have first been run through the function:
%
%   generate_DICOM_UID_Relationships.m.
%
%   filenameRoot is the the base path + filename to have file numbers 
%   appended to, ie, "C:\tmp\DCM".  filenumber is the starting filenumber 
%   to append, with results such as "C:\tmp\DCM00000", "C:\tmp\DCM00001" 
%   etc.
%
% APA, 7/12/2019
%
%Usage:
%   nWritten = export_GSPS_IOD(planC, filenameRoot, filenumber);
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

indexS  = planC{end};

%Init number of files written to zero.
nWritten = 0;

    scanNum = 1;
    if length(planC{indexS.scan}) > 1
        destDirPath = fullfile(filenameRoot,['Scan_',num2str(scanNum)]);
        if ~exist(destDirPath,'dir')
            mkdir(destDirPath)
        end
    else
        destDirPath = filenameRoot;
    end

    % Get the associated scanNum
    %scanNum = getStructureAssociatedScan(structNum,planC);
    
    %Get the scan we are currently working with
    scanS   = planC{indexS.scan}(scanNum);
    
    if isempty(planC{indexS.GSPS})
        return;
    end
    
    gspsObjS = planC{indexS.GSPS}(1);

    %Build patient module.
    patientattr      = export_module('patient', 'gsps', gspsObjS);

    %Build general study module.
    studyattr        = export_module('general_study', gspsObjS);

    %Build general series module.
    %seriesattr       = export_module('general_series', gspsObjS);
    seriesattr       = export_module('rt_series', 'gsps', gspsObjS);

    %Build a frame of reference module.
    frameattr        = export_module('frame_of_reference', gspsObjS);
    
    %Build a general equipment module.
    equipattr        = export_module('general_equipment', 'gsps', gspsObjS);
    
    %Build a content module
    contentattr        = export_module('content_identification', gspsObjS);

    %Build Graphic Layer module
    %graphicLayerAttr        = export_module('graphic_layer');
   
    %For slice-specific modules iterate over scaninfo.
    %for i=1:length(planC{indexS.GSPS}) % in future, loop over GSPS objects
    %belonging to a particular scanNum. Currently, we assume all GSPS objects belong
    %only to a single scan.
        
        gspsS = planC{indexS.GSPS};

        %Create a attr to hold a single slice.
        %CHANGE to dcm4che 3attribute
        attr = org.dcm4che3.data.Attributes;

        %Get info for the slice we are handling.
        %scanInfoS = scanS.scanInfo(slcNum);        
        %contourS = planC{indexS.structures}(structNum).contour(slc);
        
        % Build GSPS module from this structure
        gspsattr    =  export_module('gsps', gspsS, scanS);

        SOPattr     = export_module('SOP_common', 'gsps', gspsObjS);

        %Combine all modules into a single attribute.
        attr.addAll(patientattr);
        attr.addAll(studyattr);
        attr.addAll(seriesattr);
        attr.addAll(frameattr);
        attr.addAll(equipattr);
        attr.addAll(contentattr);
        attr.addAll(gspsattr);
        attr.addAll(SOPattr);

        %clear imgattr imgplaneattr imgpixelattr ctimageattr SOPattr

        fileNum  = num2str(filenumber + nWritten);
        filename = fullfile(destDirPath,['GSPS_', repmat('0', [1 5-length(fileNum)]), fileNum]);

        writefile_mldcm(attr, filename);

        nWritten = nWritten + 1;

        clear attr;
    %end

    clear patientattr studyattr seriesattr frameattr equipattr
    
end