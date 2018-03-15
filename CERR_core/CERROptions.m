function optS = CERROptions
%function optS = CERROptions
%Initialize all user-defined options for CERR.
%See CERRInstructions.doc (or pdf) for more information about options.

%
%Note: option settings must fit on one line and can contain one semicolon
%at most.
%Options can be strings, cell arrays of strings, or numerical arrays.
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%Last specifications modified:
%               13 Jan 03, CZ, Added visualReferenceDose.
%               16 Jan 03, JOD, added optS.nudgeDistance.
%               27 Jan 03, JOD, added optS.uniformizeExcludeStructs
%               19 Mar 03, JOD, changed uniformization options (see below).
%               17 Apr 03, CZ, add downsample parameter for 3D display.
%               29 Apr 03, JOD, typo.
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


%--Import options----------------------------------------------------------------------%

optS.loadCT = 'yes';     %('yes' or 'no') Load CT scans into planC?

optS.loadDoseSet = 'any' ;    %'final';      %Fraction Group ID (will match with any Fx Grp ID with the
%same initial letters, independent of case); or to load all this should be 'any'

optS.loadStructures = {'any'};   %{'lung','ipsi','contra','gtv','gvt','esoph','gross'};
%({'any'} or cell array of structure names) to load all this should be {'any'}

optS.CTEndian = 'big';     %('big' or 'little') Byte ordering of CT scans and digital films.

optS.loadFilm = 'none';    %('any' or 'none') Load digital films?

optS.zipSave = 'yes';     % 'yes' or 'no'; zip the resulting planC file using bzip2.

optS.scanStructures = {'any'};   %{'lung','ipsi','contra','gtv','gvt','esoph','gross'};
%{'any'} or {'none'} or a cell array of structure names to convert
%to raster/scan segment format for DVH calculations.

optS.DSHMaxPointInterval = 0.2;       %Maximum interval (in cm) between surface sampling points for dose-surface histograms.

optS.surfPtStructures = {''};  %Any structure whose name matches this name, up to the number
%of letters given, will have surface points generated
%during import.  That is, 'lun' will match 'lung' or 'lung_all'.

%--Dose Import options-------------------------------------------------------------%
optS.downsampleLargeDoses = 'yes';     %If 'yes', downsamples doses that are exceptionally large.  For example, Corvis
%doses are usually defined at all points on the CT, which can lead to dose
%distributions that are 300MB+ in size.

optS.doseSizeThreshold = 100;       %Maximum size in MB of a dose array before it will be downsampled.  Only active if
%optS.downsampleLargeDoses is 'yes'.

optS.promptForNewSize = 'no';     %If 'yes', prompts the user to input a voxel size, to be used for the downsampled
%dose distribution.  If 'no', uses the value specifed in optS.downsampledVoxelSize.

optS.downsampledVoxelSize = [.2 .2 .3];%Size of a voxel in the downsampled dose distribution, [dx, dy, dz].

optS.importDICOMsubDirs = 'no'; %If 'yes', imports DICOM data from within sub-directories, if 'no', imports DICOM data from the passed directory.



%--Scan uniformization options---------------------------------------------------------%

%Given a set of CT values, we choose the largest block which CT slice spacing which
%falls within the limits of optS.lowerLimitUniformCTSliceSpacing and optS.upperLimitUniformCTSliceSpacing.
%Otherwise we create a set with a spacing equal to optS.alternateUniformCTSliceSpacing.  If the user desires
%a uniformized scan with a spacing of exactly optS.alternateUniformCTSliceSpacing, then set optS.lowerLimitUniformCTSliceSpacing
%to be larger than optS.upperLimitUniformCTSliceSpacing.

optS.createUniformizedDataset = 'yes';      %'yes' or 'no'.  Create uniformized & registered CT and structures datasets
%during import.  The uniformized scan set has a uniform axial (z) spacing
%and the same transverse resolution as the normal CT-scan (usually, but
%not always, 512 x 512).

optS.uniformizeExcludeStructs  = {'normaltissue', 'CT_EXTERNAL'};
% optS.uniformizeExcludeStructs  = {'normaltissue', 'skin', 'CT_EXTERNAL'};
%cell array of structures to leave out of uniformization process.  In particular,
%leaving out skin increases program speed and decreases memory requirements.

optS.uniformizedDataType  =  'uint16';  %'uint8' or 'uint16'.  Datatype for uniformized dataset.

optS.structureArrayDataType = 'uint32';  %'uint32' or 'double'.  Datatype used to create uniformized structure array.  Effectively sets
%max structures in a plan to 32 or 52 -- the number of bits in the respective datatypes.

optS.lowerLimitUniformCTSliceSpacing =  0.005;     %Smallest allowed uniformized slice spacing. We take the largest block which is
%within the smallest and largest slice spacing requirements, inclusive of the endpoints.

optS.upperLimitUniformCTSliceSpacing =  10;      %Largest allowed uniformized slice spacing.

optS.alternateLimitUniformCTSliceSpacing = 0.3;      %If there are no initial CT slices between the largest and smallest slice
%width allowed, make a uniformized dataset with this width.

%--Slice viewer options----------------------------------------------------------------%

optS.useOpenGL = 1;         %1 to use openGL, 0 to avoid openGL.

optS.isodoseLevelMode  = 'auto';    %'auto' or 'manual'.  Auto calculates isodose lines automatically.

optS.isodoseLevels = [70, 65, 60, 55, 50, 45, 40, 20, 10]; %Isodose levels to show if optS.isodoseLevelMode = 'manual'.

optS.autoIsodoseLevels = 6;         %Number of levels displayed if optS.isodoseLevelMode = 'auto'.

optS.autoIsodoseRangeMode = 1;         %Range used for autoIsodoseLevels.  Takes 1 or 2, where 1 is max/min, and 2 is user defined.

optS.autoIsodoseRange = [0 100];    %Default range used for autoIsodoseLevels if optS.autoIsodoseRangeMode = 'User'.

optS.isodoseLevelType = 'absolute'; %or 'absolute'

optS.isodoseUseColormap = 1;         %1 if isodose lines should take use colorbar values to determine their color.

optS.isodoseThickness = 1;         %Thickness of isodose lines

optS.structureThickness = 2;         %Thickness of structure lines

optS.structureDots = 1;         %Set to 0 to disable black dots on structure lines.

optS.displayDoseSet  = '';   %The dose distribution to be displayed.  Defaults to the
%first dose distribution if this is not available.

optS.doseInterpolationMethod = 'linear'; %How to interpolate dose on to CT grid. 'linear' or 'nearest'

optS.tickInterval   = 1;         %Ruler tick interval in cm.

optS.CTLevel = 0;         %Beginning CT level and width

optS.CTWidth = 300;

optS.fontsize = 8;         %user-interface font size

optS.UIColor = [1 1 1]*0.9;%Color of ui buttons

optS.colorOrder = reshape([1.0 0.7 0  0 1 0  1 0 0  0 0.9 0.9  0.75 0 0.75  0.75 0.75 0  0.6 0.75 1 0.8 0.25 0.25 1 0 1 0.75 0.5 0  0 1 0.50 1 0.5 1  0.5 1 0 0.3 0 0.9  0 0.7 0.3  0.7 0.3 0  0 0.8 0.9  0.7 0 0.8 0.9 0.6 0  0.33 0.66 1 1 0.33 0.33 1 0 0.9 0.9 0.5 0  0 1 0.40 0.9 0.6 0.9  0.6 0.9 0 0.7 0.4 0.8  0.6 0.9 0.2] * 0.9,3,28)';
%set color of contours.  Each 3 number triple is r, g, b.  Note: do not put commas into the colorOrder

optS.contourToSliceTolerance = 0.005; % Snap contour to slice located within this distance (cm).

optS.inactiveSegStyle = '--';       %Style for inactive contouring segments

optS.activeSegStyle = '-';        %Style for active contouring segments

optS.displayPatientName = 0;         %1 ('on') or 0 ('off').

optS.initialZoomTrans = 1.7;       %Initial transverse zoom factor

optS.initialZoomSag = 1.0;       %Initial saggital zoom factor

optS.initialZoomCor = 1.0;       %Initial coronal zoom factor

optS.zoomFactor = 2.0;       %x-y scale factor when zooming.

optS.dosePlotType = 'colorwash';%Method of dose distribution display:  'isodose' or 'colorwash'.

optS.doseColormap = 'weather';  %Colormap for dose colorwash.  It is read from CERRColormap.m.
%Options:  'jetmod' (modified jet), 'full' (full rainbow), 'ppt'
%(powerpoint based) 'star (14 non-blending colors)', 'starinterp', 'gray' or 'gray256'.

optS.CTColormap = 'gray256'; %CT colormap, usually grayscale.  Also read from CERRColormap.m.
%Same choices as optS.doseColormap.

optS.colorbarChoices = {'coolwarm','jetmod', 'ppt', 'full', 'full2', 'star', 'starinterp', 'gray', 'gray256', 'grayud64', 'doublecolorinvert', 'thedrewspecial', 'graycenter0width300', 'hotcold', 'copper', 'weather'};

optS.staticColorbar = 0;         %Set to 1 to have the same colors represent the same dose values when switching between does distributions.

optS.colorbarMin = '';             % Colorbar minimum value. Set to '' to default to minimum dose value.

optS.colorbarMax = '';             % Colorbar maximum value. Set to '' to default to maximum dose value.

optS.transparentZeroDose = 1;         %If 1, dose that is zero is always transparent even if the colorbar suggests it should have color.

optS.doubleSidedColorbar = 0;         %If 1, the colorbar is inverted onto itself to create a double headed colorbar that is useful for viewing negative values.

optS.negativeTexture = 1;         %If 1, negative values (those < doseOffset) are displayed with a raster texture.

optS.colorbarMarks = [];        %Ticks on colorbar to indicate these doses, in Gy.  Examples: [70], [50,70].
%To leave it empty, type [].

optS.visualRefColormapRows = 256;       %Number of rows in visual reference colorwash colormap.

optS.visualRefTopColormap  = 'grayud64';%Colormap between optS.visualRefDose and max dose.

optS.visualRefBottomColormap = 'full2';   %Colormap between zero dose and optS.visualRefDose.

optS.visualRefDose = 65;        %If optS.visualReferenceDoseMode is 'on', the color in the dose colorwash
%at this dose will be white.  The colormap above this dose will be modified.
%That is, it will be easy to pick out this dose.

optS.visualRefDoseMode = 'off';     %['on' or 'off']  If 'on', the color in the dose colorwash at
%optS.visualReferenceDose will be white.  The colormap above that dose will be
%modified.  That is, it will be easy to pick out the reference dose.

optS.initialTransparency = .5;        %0-1, percentage of alpha for colorwash. 1 is opaque, 0 transparent. Allows
%CT to be seen through wash.

optS.calcDoseInsideSkinOnly = 0;         %only calculate dose inside the skin on the transverse viewer. Enable for increased speed.

optS.CERRStatusStringEnabled = 1;         %Change to zero to mute all CERRStatusString outputs to GUI and Matlab prompt.

%--Image Fusion options----------------------------------------------------------------%

optS.fusionDisplayMode = 'colorblend';  %'colorblend', 'checked', 'max', or 'canny'.

optS.fusionCheckSize = 2;             %size in cm of each side of checkerboard elements.

optS.fusionAlgorithms = {'Manual', 'ControlPts - Affine', 'ControlPts - Perspective', 'Exhaustive Search - MI', 'Stocastic - MI', 'Contour Based'};
optS.fusionTemplates = {@Manual, @CTP_Affine, @CTP_Perspective, @Exhaustive, @Stocastic, @ContourBased};


%--3D display option-------------------------------------------------------------------%

optS.visual3DxyDownsampleIndex = 128;       %e.g., 128.  Downsample to this resolution in the transverse plane for 3D display

%--Dose Profile option-----------------------------------------------------------------%

optS.numDoseProfileSamples = 200;    %The number of samples to take along dose profile lines.


%--DVH/DSH options---------------------------------------------------------------------%

optS.ROISampleRate = 1;         %(integer >= 1) Rate of ROI sampling compared to CT spacing, for DVH computations.


optS.DVHBinWidth = 0.2;       %Store and display DVHs with this width, in units of Gy.


optS.DVHBlockSize = 5000;      %Block processing parameter.  5000 is the default.  This results in much less temporary
%storage for large structure DVH computations.  If there is disk-thrashing during
%the DVH calculation, try reducing this number first.

optS.DVHLineWidth  = 1.5;       %Line thickness of DVH and DSH lines.

%--IVH (Intensity Volume Histogram) options---------------------------------------------------------------------%

%optS.ROISampleRate = 1;         Uses the same as DVH


optS.IVHBinWidth = 0.02;       %Store and display IVHs with this width, in units of Gy.


optS.IVHBlockSize = 5000;      %Block processing parameter.  5000 is the default.  This results in much less temporary
%storage for large structure IVH computations.  If there is disk-thrashing during
%the IVH calculation, try reducing this number first.

optS.IVHLineWidth  = 1.5;       %Line thickness of IVH lines.

%List of standard VOI names for renaming DVH's for export.
optS.defaultVOINames = {'GTV', 'CTV', 'PTV', 'spinal cord', 'heart', 'total lung', 'rt kidney', 'lt kidney','aaaaaaaaaaaaaaaaaaaaa','b','c','d','e','f','g','h','i','j','k','l','m'};


%--Contouring options------------------------------------------------------------------%

optS.nudgeDistance = 0.5;       %Number of voxel widths to nudge the active contour.


%--Navigation montage options----------------------------------------------------------%

optS.navigationMontageColormap = 'grayCenter0Width300';
optS.navigationMontageOnImport = 'no';     %'yes' or 'no'.  Do or do not create thumbnails on import.
optS.navigationMontage = 'no';     %'yes' or 'no'.  Do or do not display navigation montage when the CERR viewer is started.


%--Wavelet dose compression options----------------------------------------------------%

optS.wavletcompresthreshpersent = 1;         % CZ add wavelet compression parameters 04-24-03
optS.wavletcompressiondecomplevel = 5;


%--IMRT options------------------------------------------------------------------------%
optS.IMRTCheckResolution = 'on';      %If original plan is 512x512, downsample by factor of 2 if 'on'.

%List of installed dose calculation algorithms.  First is the string to
%describe the algorithm, second is a function handle pointing to code
%that returns a template of options required for the algorithm, and last
%is the function handle to execute the algorithm.  The function will get
%an IM structure and the structure of its options on execution.
optS.IMRTDoseCalculationAlgorithms = {'QIB', 'VMC++'};
optS.IMRTDoseCalculationTemplates = {@getQIBTemplate, @getVMCTemplate};
optS.IMRTDoseCalculationFunction  = {@generateQIBInfluence, @generateVMCInfluence};

optS.IMRTScatterReductionAlgorithms = {'Exponential', 'Probabilistic', 'Threshold', 'None'};
optS.IMRTScatterReductionTemplates = {@ExponentialTemplate, @ProbabilisticTemplate, @ThresholdTemplate, @NoneTemplate};

optS.IMRTAutoIsocenterAlgorithms = {'GeometricCOM','Manual'};
optS.IMRTAutoIsocenterFunctions = {@isocenterGeometricCOM, @isocenterManual};




%--planMetrics options-----------------------------------------------------------------%

optS.planMetrics = {'meanDose', 'maxDose', 'minDose', 'Vx', 'Dx', 'EUD', 'ERP', 'LKB', 'stdDevDose','MOCx','MOHx'};
%Installed metrics. Metrics must be added to metricSelection.m in the "%function"
%command for the compiled version


%--Window presets - name, center, width   !do not remove Manual dummy preset! (#1) ----%

optS.windowPresets = [struct('name', '--Manual--', 'center', 0, 'width', 0) struct('name', 'Abd/Med', 'center', -10, 'width', 330) struct('name', 'Head', 'center', 45, 'width', 125) struct('name', 'Liver', 'center', 80, 'width', 305) struct('name', 'Lung', 'center', -500, 'width', 1500) struct('name', 'Spine', 'center', 30, 'width', 300)    struct('name', 'Vrt/Bone', 'center', 400, 'width', 1500)   struct('name', 'PET', 'center', 4500, 'width', 11000) struct('name', 'MR', 'center', -500, 'width', 1350) struct('name', 'SPECT', 'center', 400, 'width', 1000) struct('name', 'Top 90', 'center', 400, 'width', 1000)];

%--Color Map base scan----------------------------------------------------%
optS.scanColorMap = [struct('name', 'gray256') struct('name', 'copper') struct('name', 'Red') struct('name', 'Green') struct('name', 'Blue') struct('name', 'StarInterp') struct('name', 'hotCold') struct('name', 'weather')];

%--Caching Options--------------------------------------------------------%
optS.cachingEnabled = 0; % set to 1 to enable caching, 0 to disable.
optS.colorWashCacheSize = 64; %Amount of memory to use per dose for caching colorwash. In megabytes.


%--Matlab 7 compatibility Options-----------------------------------------%
optS.saveFormat = '-v6'; %'-V7.3'; %Set to [] to use default, '-V6' to save all files in Matlab6 readable format.
%V6 is used to maintain Matlab 7 backwards compatibility with version 6+.

optS.plotObjFormat = 'v6';  %Flags for plotObjects that changed, and introduced incompability between
%Matlab 7 and old versions.


%--Lab Book email options-------------------------------------------------%
% setpref('Internet', 'E_mail', 'jalaly@radonc.wustl.edu');
% setpref('Internet', 'SMTP_Server', 'mail.artsci.wustl.edu');
% optS.emailAddresses = {'dkhullar@radonc.wustl.edu','aapte@radonc.wustl.edu','deasy@radonc.wustl.edu'};

%--microRT options--------------------------------------------------------%
optS.chkMicroRT = 0;

%--Compression-type options-----------------------------------------------%
optS.CompressType = 'bz2'; %set to 'zip' or 'bz2'

%--Batch Process----------------------------------------------------------%
optS.format = 'DICOM';

%--Initial Panel Layout--------------------------------------------------------------%
optS.layout = 5; %1:1-Large, 2:1-Large+Bar, 3:2-Medium, 4:4-Medium, 5:1-Large+3-Small, 9: Perfusion/Diffusion

%--Generate Log on Start-up--------------------------------------------------------------%
optS.logOnStartup = 0; %1:yes - generate log, 0:No - don't generate log

%--Temporary Directory to extract bz2--------------------------------------------------------------%
optS.tmpDecompressDir = ''; %'': tempdir, 'C:\tempCERRExtract'

%--ROI Interpreted Type
optS.ROIInterpretedType = initROIInterpretedType;
%--RPC film options-------------------------------------------------------%

%-- Option to convert PET to SUV
optS.convert_PET_to_SUV = 0; % 0: Do not convert to SUV, 1: Convert to SUV

%-- Option to overwrite CERR file if a bug is found during QA
optS.overwrite_CERR_File = 0; % 0: Do not overwrite, 1: overwrite

%-- Option to overwrite CERR file if a bug is found during QA
optS.sinc_filter_on_display = 0; % 0: Do not apply sinc, 1: apply sinc

%-- Filename for plastimatch commands
% this file must be stored under ...\CERR\CERR_core\ImageRegistration\plastimatch_command
optS.plastimatch_command_file = 'bspline_register_cmd_dir.txt'; %'malcolm_pike_mr_breast_data.txt'; %'mr_ct_edge_based.txt';

%-- Size of pool of line handles. 
% Set this value based on anticipated structure segments per view
optS.linePoolSize = 300;

%-- Paths to protocol, model, and criteria files for ROE
optS.ROEProtocolPath = 'M:/Aditi/OutcomesModels/ROE/Protocols'; 
optS.ROEModelPath = 'M:/Aditi/OutcomesModels/ROE/Models';
optS.ROECriteriaPath = 'M:/Aditi/OutcomesModels/ROE/Criteria';

%-- Radiomics features calculation parameters

% number of rows/cols/slcs ...
% to upsample the roi
optS.shape_rcsV = [100, 100, 100]; 

optS.higherOrder_minIntensity = -140;
optS.higherOrder_maxIntensity = 100;
optS.higherOrder_numGrLevels = 100;
optS.higherOrder_patchRadius2dV = [1 1 0];
optS.higherOrder_patchRadius3dV = [1 1 1];
optS.higherOrder_imgDiffThresh = 0;

optS.peakValley_peakRadius = [2 2 0]; % [2 2 2] for 3d, for example

optS.ivh_xForIxV = 10:10:90; % percentage volume
optS.ivh_xAbsForIxV = 10:20:200; % absolute volume [cc]
optS.ivh_xForVxV = 10:10:90; % percent intensity cutoff
optS.ivh_xAbsForVxV =  -140:10:100; % CT eg., absolute intensity cutoff (image units)
                                    % 0:2:28; % PET

                                    
%-------------------------------------------fini--------------------------%
                                    