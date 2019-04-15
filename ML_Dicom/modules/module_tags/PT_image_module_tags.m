function tagS = PT_image_module_tags
%"PT_image_module_tags"
%   Return the tags used to represent a PT image as specified by C.8.9.1 in
%   PS3.3 of 2006 DICOM specification.
%
%   Tags are returned in a struct array with 3 fields:
%   
%   Tag: String containing hex DICOM tag of a field.
%  Type: String describing type of field, with 5 options:
%         '1' Field must exist, data must exist and be valid.
%         '2' Field must exist, data can exist and be valid, or be NULL.
%         '3' Field is optional, if the field exists data can exist and be
%             valid or be NULL.
%         '1C' Field must exist under certain conditions and contain valid
%             data.
%         '2C' Field must exist under certain conditions and can contain 
%             valid data or be NULL.
%Children: For sequences, a tagS with the same format as this struct array.
%
%Craig Parkinson 
%

%Initialize the tagS structure.
tagS = struct('tag', {}, 'type', {}, 'children', {});

%Create an empty tagS template for sequence creation.
template = tagS;

%Add tags based on PS3.3 attribute lists.

%Series Date
tagS(end+1) = struct('tag', ['00080021'], 'type', ['1'], 'children', []);

%Series Time
tagS(end+1) = struct('tag', ['00080031'], 'type', ['1'], 'children', []);

%Units
tagS(end+1) = struct('tag', ['00541001'], 'type', ['1'], 'children', []);

%SUV Type
tagS(end+1) = struct('tag', ['00541006'], 'type', ['3'], 'children', []);

%Counts Source
tagS(end+1) = struct('tag', ['00541002'], 'type', ['1'], 'children', []);

%Series Type
tagS(end+1) = struct('tag', ['00541000'], 'type', ['1'], 'children', []);

%Reprojection Method
tagS(end+1) = struct('tag', ['00541004'], 'type', ['2C'], 'children', []);

%Number of R-R Intervals
tagS(end+1) = struct('tag', ['00540061'], 'type', ['1C'], 'children', []);

%Number of Time Slots
tagS(end+1) = struct('tag', ['00540071'], 'type', ['1C'], 'children', []);

%Number of Time Slices
tagS(end+1) = struct('tag', ['00540101'], 'type', ['1C'], 'children', []);

%Number of Slices
tagS(end+1) = struct('tag', ['00540081'], 'type', ['1'], 'children', []);

%Corrected Image
tagS(end+1) = struct('tag', ['00280051'], 'type', ['2'], 'children', []);

%Randoms Correction Method
tagS(end+1) = struct('tag', ['00541100'], 'type', ['3'], 'children', []);

%Attenuation Correction Method
tagS(end+1) = struct('tag', ['00541101'], 'type', ['3'], 'children', []);

%Scatter Correction Method
tagS(end+1) = struct('tag', ['00541105'], 'type', ['3'], 'children', []);

%Decay Correction
tagS(end+1) = struct('tag', ['00541102'], 'type', ['1'], 'children', []);

%Reconstruction Diameter
tagS(end+1) = struct('tag', ['00181100'], 'type', ['3'], 'children', []);

%Convolution Kernel
tagS(end+1) = struct('tag', ['00181210'], 'type', ['3'], 'children', []);

%Reconstruction Method
tagS(end+1) = struct('tag', ['00541103'], 'type', ['3'], 'children', []);

%Detector Lines of Response Used
tagS(end+1) = struct('tag', ['00541104'], 'type', ['3'], 'children', []);

%Acquisition Start Condition
tagS(end+1) = struct('tag', ['00180073'], 'type', ['3'], 'children', []);

%Acquisition Start Condition Data
tagS(end+1) = struct('tag', ['00180074'], 'type', ['3'], 'children', []);

%Acquisition Termination Condition
tagS(end+1) = struct('tag', ['00180071'], 'type', ['3'], 'children', []);

%Acquisition Termination Condition Data
tagS(end+1) = struct('tag', ['00180075'], 'type', ['3'], 'children', []);

%Field of View Shape
tagS(end+1) = struct('tag', ['00181147'], 'type', ['3'], 'children', []);

%Field of View Dimensions
tagS(end+1) = struct('tag', ['00181149'], 'type', ['3'], 'children', []);

%Gantry/Detector Tilt
tagS(end+1) = struct('tag', ['00181120'], 'type', ['3'], 'children', []);

%Gantry/Detector Slew
tagS(end+1) = struct('tag', ['00181121'], 'type', ['3'], 'children', []);

%Type of Detector Motion
tagS(end+1) = struct('tag', ['00540202'], 'type', ['3'], 'children', []);

%Collimator Type
tagS(end+1) = struct('tag', ['00181181'], 'type', ['2'], 'children', []);

%Collimator/Grid Name
tagS(end+1) = struct('tag', ['00181180'], 'type', ['3'], 'children', []);

%Axial Acceptance
tagS(end+1) = struct('tag', ['00541200'], 'type', ['3'], 'children', []);

%Axial Mash
tagS(end+1) = struct('tag', ['00541200'], 'type', ['3'], 'children', []);

%Transverse Mash
tagS(end+1) = struct('tag', ['00541202'], 'type', ['3'], 'children', []);

%Detector Element Size
tagS(end+1) = struct('tag', ['00541203'], 'type', ['3'], 'children', []);

%Concidence Window Width
tagS(end+1) = struct('tag', ['00541210'], 'type', ['3'], 'children', []);

%Energy Window Range Sequence
tagS(end+1) = struct('tag', ['00540013'], 'type', ['3'], 'children', []);

%Energy Window Lower Limit
tagS(end+1) = struct('tag', ['00540014'], 'type', ['3'], 'children', []);

%Energy Window Upper Limit
tagS(end+1) = struct('tag', ['00540015'], 'type', ['3'], 'children', []);

%Secondary Counts Type
tagS(end+1) = struct('tag', ['00541220'], 'type', ['3'], 'children', []);

%Scan Progression Direction
tagS(end+1) = struct('tag', ['00540501'], 'type', ['3'], 'children', []);

%0054,0016 Radiopharmaceutical Information Sequence
tagS(end+1) = struct('tag', ['00540016'], 'type', ['2'], 'children', []);
child_1     = template;

    %Radionuclide Code Sequence
    child_1(end+1) = struct('tag', ['00540300'], 'type', ['2'], 'children', []);
    
    %Radiopharmaceutical Route
    child_1(end+1) = struct('tag', ['00181070'], 'type', ['3'], 'children', []);
    
    %Administration Route Code Sequence
    child_1(end+1) = struct('tag', ['00540302'], 'type', ['3'], 'children', []);
    
    %Radiopharmaceutical Volume
    child_1(end+1) = struct('tag', ['00181071'], 'type', ['3'], 'children', []);  
    
    %Radiopharmaceutical Start Time
    child_1(end+1) = struct('tag', ['00181072'], 'type', ['3'], 'children', []);
    
    %Radiopharmaceutical Start DateTime
    child_1(end+1) = struct('tag', ['00181078'], 'type', ['3'], 'children', []);
    
    %Radiopharmaceutical Stop Time
    child_1(end+1) = struct('tag', ['00181073'], 'type', ['3'], 'children', []);
    
    %Radiopharmaceutical Stop DateTime
    child_1(end+1) = struct('tag', ['00181079'], 'type', ['3'], 'children', []);

    %Radionuclide Total Dose
    child_1(end+1) = struct('tag', ['00181074'], 'type', ['3'], 'children', []);
    
    %Radiopharmaceutical Administration Event UID
    child_1(end+1) = struct('tag', ['00083012'], 'type', ['3'], 'children', []);
    
    %Radionuclide Half Life
    child_1(end+1) = struct('tag', ['00181075'], 'type', ['3'], 'children', []);
    
    %Radionuclide Positrion Fraction
    child_1(end+1) = struct('tag', ['00181076'], 'type', ['3'], 'children', []);
    
    %Radiopharmaceutical Specific Activity
    child_1(end+1) = struct('tag', ['00181077'], 'type', ['3'], 'children', []);
    
    %Radiopharmaceutical
    child_1(end+1) = struct('tag', ['00180031'], 'type', ['3'], 'children', []);

    %Radiopharmaceutical Code Sequence
    child_1(end+1) = struct('tag', ['00540304'], 'type', ['3'], 'children', []);
    
    %Intervention Drug Information Sequence
    child_1(end+1) = struct('tag', ['00180026'], 'type', ['3'], 'children', []);
    
    %Intervention Drug Name
    child_1(end+1) = struct('tag', ['00180034'], 'type', ['3'], 'children', []);
    
    %Intervention Drug Code Sequence
    child_1(end+1) = struct('tag', ['00180029'], 'type', ['3'], 'children', []);
    
    %Intervention Drug Start Time
    child_1(end+1) = struct('tag', ['00180035'], 'type', ['3'], 'children', []);
    
    %Intervention Drug Stop Time
    child_1(end+1) = struct('tag', ['00180027'], 'type', ['3'], 'children', []);
    
    %Intervention Drug Dose
    child_1(end+1) = struct('tag', ['00180028'], 'type', ['3'], 'children', []);

tagS(end).children = child_1;
 
%Image Type
tagS(end+1) = struct('tag', ['524296524296'], 'type', ['1'], 'children', []);

%Samples per Pixel
tagS(end+1) = struct('tag', ['00280002'], 'type', ['1'], 'children', []);

%Photometric Interpretation
tagS(end+1) = struct('tag', ['00280004'], 'type', ['1'], 'children', []);

%Bits Allocated
tagS(end+1) = struct('tag', ['00280100'], 'type', ['1'], 'children', []);

%Bits Stored
tagS(end+1) = struct('tag', ['00280101'], 'type', ['1'], 'children', []);

%High Bit
tagS(end+1) = struct('tag', ['00280102'], 'type', ['1'], 'children', []);

%Rescale Intercept
tagS(end+1) = struct('tag', ['00281052'], 'type', ['1'], 'children', []);

%Rescale Slope
tagS(end+1) = struct('tag', ['00281053'], 'type', ['1'], 'children', []);

%Frame Reference Time
tagS(end+1) = struct('tag', ['00541300'], 'type', ['1'], 'children', []);

%Trigger Time
tagS(end+1) = struct('tag', ['00181060'], 'type', ['1C'], 'children', []);

%Frame Time
tagS(end+1) = struct('tag', ['00181063'], 'type', ['1C'], 'children', []);

%Low R-R Value
tagS(end+1) = struct('tag', ['00181081'], 'type', ['1C'], 'children', []);

%High R-R Value
tagS(end+1) = struct('tag', ['00181082'], 'type', ['1C'], 'children', []);

%Lossy Image Compression
tagS(end+1) = struct('tag', ['00282110'], 'type', ['1C'], 'children', []);

%Image Index
tagS(end+1) = struct('tag', ['00541330'], 'type', ['1'], 'children', []);

%Acquisition Date
tagS(end+1) = struct('tag', ['00080022'], 'type', ['2'], 'children', []);

%Acquisition Time
tagS(end+1) = struct('tag', ['00080032'], 'type', ['2'], 'children', []);

%Actual Frame Duration
tagS(end+1) = struct('tag', ['00181242'], 'type', ['2'], 'children', []);

%Nominal Interval
tagS(end+1) = struct('tag', ['00181062'], 'type', ['3'], 'children', []);

%Intervals Acquired
tagS(end+1) = struct('tag', ['00181083'], 'type', ['3'], 'children', []);

%Intervals Rejected
tagS(end+1) = struct('tag', ['00181084'], 'type', ['3'], 'children', []);

%Primary Counts Accumulated
tagS(end+1) = struct('tag', ['00541310'], 'type', ['3'], 'children', []);

%Secondary Counts Accumulated
tagS(end+1) = struct('tag', ['00541311'], 'type', ['3'], 'children', []);

%Slice Sensitivity Factor
tagS(end+1) = struct('tag', ['00541320'], 'type', ['3'], 'children', []);

%Decay Factor
tagS(end+1) = struct('tag', ['00541321'], 'type', ['1C'], 'children', []);

%Dose Calibration Factor
tagS(end+1) = struct('tag', ['00541322'], 'type', ['3'], 'children', []);

%Scatter Fraction Factor
tagS(end+1) = struct('tag', ['00541323'], 'type', ['3'], 'children', []);

%Dead Time Factor
tagS(end+1) = struct('tag', ['00541324'], 'type', ['3'], 'children', []);

%Isocenter Position
tagS(end+1) = struct('tag', ['300A012C'], 'type', ['3'], 'children', []);
