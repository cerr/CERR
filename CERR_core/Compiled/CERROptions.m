function optS = CERROptions
%function optS = CERROptions
%Initialize all user-defined options for CERR.
%See CERRInstructions.doc (or pdf) for more information about options.

%
%Note: option settings must fit on one line and can contain one semicolon at most.
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
	
                 optS.surfPtStructures = {'rect'};  %Any structure whose name matches this name, up to the number
                                                    %of letters given, will have surface points generated
                                                    %during import.  That is, 'lun' will match 'lung' or 'lung_all'.
                                                    

%--Scan uniformization options---------------------------------------------------------%

%Given a set of CT values, we choose the largest block which CT slice spacing which
%falls within the limits of optS.lowerLimitUniformCTSliceSpacing and optS.upperLimitUniformCTSliceSpacing.
%Otherwise we create a set with a spacing equal to optS.alternateUniformCTSliceSpacing.  If the user desires
%a uniformized scan with a spacing of exactly optS.alternateUniformCTSliceSpacing, then set optS.lowerLimitUniformCTSliceSpacing
%to be larger than optS.upperLimitUniformCTSliceSpacing.
	
         optS.createUniformizedDataset = 'yes'      %'yes' or 'no'.  Create uniformized & registered CT and structures datasets
                                                    %during import.  The uniformized scan set has a uniform axial (z) spacing 
                                                    %and the same transverse resolution as the normal CT-scan (usually, but 
                                                    %not always, 512 x 512).
	
	
        optS.uniformizeExcludeStructs  = {'skin','normaltissue'};  
                                                    %cell array of structures to leave out of uniformization process.  In particular, 
                                                    %leaving out skin increases program speed and decreases memory requirements.
	
             optS.uniformizedDataType  =  'uint8';  %'uint8' or 'uint16'.  Datatype for uniformized dataset.
	
  optS.lowerLimitUniformCTSliceSpacing =  0.25;     %Smallest allowed uniformized slice spacing. We take the largest block which is 
                                                    %within the smallest and largest slice spacing requirements, inclusive of the endpoints.
	
   optS.upperLimitUniformCTSliceSpacing =  0.4;      %Largest allowed uniformized slice spacing.
	
optS.alternateLimitUniformCTSliceSpacing = 0.3;      %If there are no initial CT slices between the largest and smallest slice
                                                    %width allowed, make a uniformized dataset with this width.

%--Slice viewer options----------------------------------------------------------------%
	
                    optS.isodoseLevels =  [70, 65, 60, 55, 50, 45, 40, 20, 10];   
                                                    %Isodose levels to show
	
                 optS.isodoseThickness = 1.5;       %Thickness of isodose lines
	
               optS.structureThickness = 1.5        %Thickness of structure lines
	
                 optS.isodoseLevelType = 'absolute' %or 'absolute'
	
	
                  optS.displayDoseSet  = 'final';   %The dose distribution to be displayed.  Defaults to the
                                                    %first dose distribution if this is not available.
	
                   optS.tickInterval   = 1;         %Ruler tick interval in cm.
	
                          optS.CTLevel = 0;         %Beginning CT level and width
	
                          optS.CTWidth = 300;
	
                         optS.fontsize = 8;         %user-interface font size
	
                          optS.UIColor = [1 1 1]*0.9;%Color of ui buttons
	
                       optS.colorOrder = reshape([1.0 0.7 0  0 1 0  1 0 0  0 0.9 0.9  0.75 0 0.75  0.75 0.75 0  0.6 0.75 1 0.8 0.25 0.25 1 0 1 0.75 0.5 0  0 1 0.50 1 0.5 1  0.5 1 0 0.3 0 0.9  0 0.7 0.3  0.7 0.3 0  0 0.8 0.9  0.7 0 0.8 0.9 0.6 0  0.33 0.66 1 1 0.33 0.33 1 0 0.9 0.9 0.5 0  0 1 0.40 0.9 0.6 0.9  0.6 0.9 0 0.7 0.4 0.8  0.6 0.9 0.2] * 0.9,3,28)';
                                                    %set color of contours.  Each 3 number triple is r, g, b.  Note: do not put commas into the colorOrder
	
                 optS.inactiveSegStyle = '--'       %Style for inactive contouring segments
	
                   optS.activeSegStyle = '-'        %Style for active contouring segments
	
               optS.displayPatientName = 0;         %1 ('on') or 0 ('off').
	
                 optS.initialZoomTrans = 1.7;       %Initial transverse zoom factor
	
                   optS.initialZoomSag = 1.0;       %Initial saggital zoom factor
	
                   optS.initialZoomCor = 1.0;       %Initial coronal zoom factor
	
                       optS.zoomFactor = 2.0;       %x-y scale factor when zooming.
	
                       optS.rulerColor = [1 0 0];   %Color of longer ruler and small scale.
	
                     optS.dosePlotType = 'colorwash';%Method of dose distribution display:  'isodose' or 'colorwash'.
	
                     optS.doseColormap = 'jetmod';  %Colormap for dose colorwash.  It is read from CERRColormap.m.
                                                    %Options:  'jetmod' (modified jet), 'full' (full rainbow), 
                                                    %'star (14 non-blending colors)','gray' or 'gray256'.
	
                       optS.CTColormap = 'gray256'; %CT colormap, usually grayscale.  Also read from CERRColormap.m.
                                                    %Same choices as optS.doseColormap.
	
                    optS.colorbarMarks = [45];      %Ticks on colorbar to indicate these doses, in Gy.  Examples: [70], [50,70].
                                                    %To leave it empty, type [].
	
                optS.doseDisplayCutoff =  2;        %[0-any pos number] In colorwash display, do not display doses below 
                                                    %this value in units of Gy. Ignored if the value is 0.
	
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
	
           optS.calcDoseInsideSkinOnly = 1;         %only calculate dose inside the skin on the transverse viewer. Enable for increased speed.  
           
            
%--3D display option-------------------------------------------------------------------%

        optS.visual3DxyDownsampleIndex = 128;       %e.g., 128.  Downsample to this resolution in the transverse plane for 3D display
        

%--DVH/DSH options---------------------------------------------------------------------%

                    optS.ROISampleRate = 1;         %(integer >= 1) Rate of ROI sampling compared to CT spacing, for DVH computations.


                      optS.DVHBinWidth = 0.1;       %Store and display DVHs with this width, in units of Gy.


                     optS.DVHBlockSize = 5000;      %Block processing parameter.  5000 is the default.  This results in much less temporary 
                                                    %storage for large structure DVH computations.  If there is disk-thrashing during 
                                                    %the DVH calculation, try reducing this number first.

                    optS.DVHLineWidth  = 1.5;       %Line thickness of DVH and DSH lines.
                    

%--Contouring options------------------------------------------------------------------%

                    optS.nudgeDistance = 0.5;       %Number of voxel widths to nudge the active contour.


%--Navigation montage options----------------------------------------------------------%

        optS.navigationMontageColormap = 'grayCenter0Width300';
        optS.navigationMontageOnImport = 'yes';     %'yes' or 'no'.  Do or do not create thumbnails on import.
                optS.navigationMontage = 'yes';     %'yes' or 'no'.  Do or do not display navigation montage when the CERR viewer is started.


%--Wavelet dose compression options----------------------------------------------------%
             
       optS.wavletcompresthreshpersent = 1;         % CZ add wavelet compression parameters 04-24-03
     optS.wavletcompressiondecomplevel = 5;


%--planMetrics options-----------------------------------------------------------------%

                      optS.planMetrics = {'meanDose', 'maxDose', 'minDose', 'Vx', 'Dx', 'EUD'};
                                                    %Installed metrics. Metrics must be added to metricSelection.m in the "%function" 
                                                    %command for the compiled version

                                                    
%--Window presets - name, center, width   !do not remove Manual dummy preset! (#1) ----%

                    optS.windowPresets = [struct('name', '--Manual--', 'center', 0, 'width', 0) struct('name', 'Abd/Med', 'center', -10, 'width', 330) struct('name', 'Head', 'center', 45, 'width', 125) struct('name', 'Liver', 'center', 80, 'width', 305) struct('name', 'Lung', 'center', -500, 'width', 1500) struct('name', 'Spine', 'center', 30, 'width', 300) struct('name', 'Vrt/Bone', 'center', 400, 'width', 1500)];


%--Caching Options---------------------------------------------------------------------%

                   optS.cachingEnabled = 1; % set to 1 to enable caching, 0 to disable.
               optS.colorWashCacheSize = 64; %Amount of memory to use per dose for caching colorwash. In megabytes.
            
            
%-------------------------------------------fini---------------------------------------%



