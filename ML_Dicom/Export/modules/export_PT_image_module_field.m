function el = export_PT_image_module_field(args)
%"export_CT_image_module_field"
%   Given a single scan, return a properly populated PT_image module tag
%   for use with any Composite Image IOD.  See PT_image_module_tags.m.
%
%   For speed, tag must be a decimal representation of the 8 digit
%   hexidecimal DICOM tag desired, ie instead of '00100010', pass
%   hex2dec('00100010');
%
%   Arguments are passed in a structure, arg:
%       arg.tag         = decimal tag of field to fill
%       arg.data        = CERR structure(s) to fill from
%       arg.template    = an empty template of the module created by the
%                         function build_module_template.m
%
%   This function requires arg.data = {scanInfoS, scanS};
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_CT_image_module_field(args)
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

%Unpack input parameters.
tag         = args.tag;
scanInfoS   = args.data{1};
scanS       = args.data{2};
template    = args.template;

switch tag
    
    case 524321 %Series Date
        data = scanInfoS.DICOMHeaders.SeriesDate;
        el = template.get(tag);
        el = ml2dcm_Element(el,data);
    
    case 524337 %Series Time
        data = scanInfoS.DICOMHeaders.SeriesTime;
        el = template.get(tag);
        el = ml2dcm_Element(el,data);
    
    case 5509121 %Units
        data = scanInfoS.DICOMHeaders.Units;
        el = template.get(tag);
        el = ml2dcm_Element(el,data);
        
    case 5509126 %SUV Type
        el = template.get(tag);
        try
            data = scanInfoS.suvType;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5509122 %Counts Source 
        data = scanInfoS.DICOMHeaders.CountsSource;
        el = template.get(tag);
        el = ml2dcm_Element(el,data);
        
    case 5509120 %Series Type
        data = scanInfoS.DICOMHeaders.SeriesType;
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 5509124 %Reprojection Method
        el = template.get(tag);
        try
            data = scanInfoS.reprojectionMethod;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
        
    case 5505121 %R-R Intervals
        el = template.get(tag);
        try
            data = scanInfoS.rrIntervals;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
        
    case 5505137 %Number of Time Slots
        el = template.get(tag);
        try
            data = scanInfoS.numberOfTimeSlots;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
        
    case 5505281 %Number of Time Slices
        el = template.get(tag);
        try
            data = scanInfoS.numberOfTimeSlices;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
        
    case 5505153 %Number of Slices
        
        el = template.get(tag);
        data = scanInfoS.DICOMHeaders.NumberofSlices;
        el = ml2dcm_Element(el,data);
        
   case 2621521 %Corrected Image
        
        el = template.get(tag);
        try
            data = scanInfoS.correctedImage;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 00541100 %Randoms Correction Method
        
        el = template.get(tag);
        try
            data = scanInfoS.RandomsCorrectionMethod;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 00541105 %Scatter Correction Method
        
        el = template.get(tag);
        try
            data = scanInfoS.scatterCorrectionMethod;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end    
    case 5509378 %Decay Correction
        
        el = template.get(tag);
        data = scanInfoS.DICOMHeaders.DecayCorrection;
        el = ml2dcm_Element(el,data);
        
    case 1577216 %Reconstruction Diameter
        
        el = template.get(tag);
        try
            data = scanInfoS.reconstructionDiameter;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 1577488 %Convolution Kernel
        
        el = template.get(tag);
        try
            data = scanInfoS.convolutionKernel;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5509379 %reconstructionMethod
        
        el = template.get(tag);
        try
            data = scanInfoS.reconstructionMethod;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
     case 5509380 %Detector Lines of Response Used
        
        el = template.get(tag);
        try
            data = scanInfoS.detectorLinesOfResponseUsed;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 1572979 %Acquisition Start Condition
        
        el = template.get(tag);
        try
            data = scanInfoS.acquisitionStartCondition;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 1572980 %Acquisition Start Condition Data
        
        el = template.get(tag);
        try
            data = scanInfoS.acquisitionStartConditionData;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
     case 1572977 %Acquisition Termination Condition
        
        el = template.get(tag);
        try
            data = scanInfoS.acquisitionTerminationCondition;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 1572981 %Acquisition Termination Condition Data
        
        el = template.get(tag);
        try
            data = scanInfoS.acquisitionTerminationConditionData;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 1577287 %Field of View Shape
        
        el = template.get(tag);
        try
            data = scanInfoS.fieldOfViewShape;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end    
    case 1577289 %Field of View Dimensions
        
        el = template.get(tag);
        try
            data = scanInfoS.fieldOfViewDimensions;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 1577248 %Gantry / Detector Tilt
        
        el = template.get(tag);
        try
            data = scanInfoS.gantryDetectorTilt;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end    
    case 1577249 %Gantry / Detector Slew
        
        el = template.get(tag);
        try
            data = scanInfoS.gantryDetectorSlew;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end   
    case 5505538 %Type of Detector Motion
        
        el = template.get(tag);
        try
            data = scanInfoS.typeOfDetectorMotion;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 1577345 %Collimator Type
        
        el = template.get(tag);
        try
            data = scanInfoS.collimatorType;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end    
    case 1577344 %Collimator Grid Name
        
        el = template.get(tag);
        try
            data = scanInfoS.collimatorGridName;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end    
    case 5509632 %Axial Acceptance
        
        el = template.get(tag);
        try
            data = scanInfoS.axialAcceptance;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5509633 %Axial Mash
        
        el = template.get(tag);
        try
            data = scanInfoS.axialMash;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5509634 %Transverse Mash
        
        el = template.get(tag);
        try
            data = scanInfoS.transverseMash;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5509635 %Detector Element Size
        
        el = template.get(tag);
        try
            data = scanInfoS.detectorElementSize;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5509648 %Coincidence Window Width
        
        el = template.get(tag);
        try
            data = scanInfoS.detectorElementSize;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5505046    %0054,0016 Radiopharmaceutical Information Sequence
        templateEl  = template.get(tag);
        fHandle = @export_radiopharmaceutical_info_sequence;
        
        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);
        
        nItems = 1;
        
        for i=1:nItems
            dcmobj = export_sequence(fHandle, templateEl, {scanInfoS});
            el.addDicomObject(i-1, dcmobj);
        end
    case 524296    %Image Type
        el = template.get(tag);
        try
            data = scanInfoS.imageType;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 2621442    %Samples Per Pixel
        el = template.get(tag);
        try
            data = scanInfoS.samplesPerPixel;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 2621444    %Photometric Interpretation
        el = template.get(tag);
        try
            data = scanInfoS.photometricIntpretation;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 2621696    %Bits Allocated
        el = template.get(tag);
        try
            data = scanInfoS.bitsAllocated;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 2621697    %Bits Stored
        el = template.get(tag);
        try
            data = scanInfoS.bitsStored;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 2625618    %Rescale Intercept
        el = template.get(tag);
        try
            data = scanInfoS.rescaleIntercept;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 2625619    %Rescale Slope
        el = template.get(tag);
        try
            data = scanInfoS.rescaleSlope;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    case 5509888    %Frame Reference Time
        el = template.get(tag);
        try
            data = scanInfoS.frameReferenceTime;
            el = ml2dcm_Element(el,data);
        catch
            tmp = org.dcm4che2.data.BasicDicomObject;
            el = tmp.putNull(tag, []);
        end
    otherwise
        warning(['No methods exist to populate DICOM image_pixel module field ' dec2hex(tag,8) '.']);
        return;
end