function nWritten = export_CT_IOD(planC, filenameRoot, filenumber, scanNum)
%"export_CT_IOD"
%   Writes to disk the specified scan no. (or all scans if not specified)
%   contained in planC by constructing the modules
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
%JRA 07/05/06
%NAV 07/19/16 updated to dcm4che3
%    Used addAll over copyTo
%AI 07/22/20  Added scanNum input (optional)
%Usage:
%   nWritten = export_CT_IOD(planC, filenameRoot, filenumber);
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

%Check for scan no. input
if exist('scanNum','var')
    
    destDirPath = filenameRoot;
    scanS   = planC{indexS.scan}(scanNum);
    %Export specified scan
    nWritten = export_scan(destDirPath,filenumber,scanS);
    
else
    
    %Init number of files written to zero.
    nWritten = 0;
    
    for scanNum = 1:length(planC{indexS.scan})
        
        if length(planC{indexS.scan}) > 1
            destDirPath = fullfile(filenameRoot,['Scan_',num2str(scanNum)]);
        else
            destDirPath = filenameRoot;
        end
        
        %Get the scan we are currently working with
        scanS   = planC{indexS.scan}(scanNum);
        
        %Export current scan
        nCurrent = export_scan(destDirPath,filenumber,scanS);
        
        nWritten = nWritten + nCurrent;
        
    end
    
end

end

%% Sub-function to export scan
function nWritten = export_scan(dst,filenumber,scanS)

%Init number of files written to zero.
nWritten = 0;

if ~exist(dst,'dir')
    mkdir(dst)
end

%Build patient module.
patientattr      = export_module('patient', 'scan', scanS);

%Build general study module.
studyattr        = export_module('general_study', scanS);

%Build general series module.
seriesattr       = export_module('general_series', scanS);

%Build a frame of reference module.
frameattr        = export_module('frame_of_reference', scanS);

%Build a general equipment module.
equipattr        = export_module('general_equipment', 'scan', scanS);

%Get rescale slope
nBits = 16;

%Determine the scaling factor if scanArray is other than uint16
modality = scanS.scanInfo(1).imageType;
if strcmpi(modality,'PT')
    dcmheader = scanS.scanInfo(1).DICOMHeaders;
    if max(scanS.scanArray(:)) < 500 % assume suv
        scanS.scanArray = suvToCounts(scanS.scanArray,dcmheader);
        %scanS.scanArray = scanS.scanArray / dcmheader.RescaleSlope;
    else
        %scanS.scanArray = scanS.scanArray / dcmheader.RescaleSlope;
    end
    dcmHeadAllSlcS = [scanS.scanInfo(:).DICOMHeaders];
    scaleFactorV = [dcmHeadAllSlcS.RescaleSlope];
else
    maxScaled  = 2^nBits;
    maxScan = max([max(scanS.scanArray(:)) maxScaled]);
    scaleFactor = maxScan/maxScaled;
    if scaleFactor < 1
        scaleFactor = 1;
    end
    scaleFactorV = repmat(scaleFactor,size(scanS.scanArray,3));
end

%For slice-specific modules iterate over scaninfo.
for i=1:length(scanS.scanInfo)
    
    %Create a attr to hold a single slice.
    %CHANGE to dcm4che 3attribute
    attr = org.dcm4che3.data.Attributes;
    
    %Get info for the slice we are handling.
    scanInfoS = scanS.scanInfo(i);
    
    %Build an image module from this particular slice (scanInfoS)
    imgattr          = export_module('general_image', 'scan', scanInfoS);
    
    %Build an image plane module from this particular slice (scanInfoS)
    imgplaneattr     = export_module('image_plane', 'scan', scanInfoS, scanS);
    
    %Build an image pixel module from this particular slice (scanInfoS)
    imgpixelattr     = export_module('image_pixel', 'scan', scanInfoS, scanS, scaleFactorV);
    
    %Build an CT image module from this particular slice (scanInfoS)
    if strcmpi(modality,'PT')
        ctimageattr      = export_module('PT_image', scanInfoS, scanS, scaleFactorV);
    else
        ctimageattr      = export_module('CT_image', scanInfoS, scanS, scaleFactorV);
    end
    
    SOPattr = export_module('SOP_common', 'scanInfo', scanInfoS);
    
    %Combine all modules into a single attribute.
    attr.addAll(patientattr);
    attr.addAll(studyattr);
    attr.addAll(seriesattr);
    attr.addAll(frameattr);
    attr.addAll(equipattr);
    attr.addAll(imgattr);
    attr.addAll(imgplaneattr);
    attr.addAll(imgpixelattr);
    attr.addAll(ctimageattr);
    attr.addAll(SOPattr);
    
    clear imgattr imgplaneattr imgpixelattr ctimageattr SOPattr
    
    if ischar(filenumber)
        filename = fullfile(filenameRoot,filenumber);
    else
        fileNum  = num2str(filenumber + nWritten);
        filename = fullfile(dst,['IMG_', repmat('0', [1 5-length(fileNum)]), fileNum]);
    end
    
    writefile_mldcm(attr, filename);
    
    nWritten = nWritten + 1;
    
    clear attr;
    
end

clear patientattr studyattr seriesattr frameattr equipattr

end