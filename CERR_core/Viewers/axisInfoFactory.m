function axisInfo = axisInfoFactory()
%"axisInfoFactory"
%   Return an empty CERR axisInfo struct, with all fields existing but
%   empty, except for the scan and dose selection modes which are set to
%   'auto'.  The structs that list displayed scan and dose information are
%   given length zero.
%
%   axisInfo is designed to keep track of all the information related to a
%   single, independent axis in CERR's viewer.  Decisions about redrawing,
%   displaying etc are made based on this information.
%
%   If in the future any new types of data are to be displayed in a CERR
%   axis, they should be added as a new element in this struct.
%
%JRA 1/21/05
%
%Usage:
%   function axisInfo = axisInfoFactory()
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

%Axis Display Info.
axisInfo.view               = [];       % 'transverse', 'sagittal', 'coronal', 'legend', 'navigation';
axisInfo.coord              = [];       % coordinate of viewing plane
axisInfo.scanSets           = [];       % Index of scan sets displayed in axis.
axisInfo.doseSets           = [];       % Index of dose sets displayed in axis.
axisInfo.structureSets      = [];       % Index of structure sets (from .associatedScan field) displayed in axis.

axisInfo.scanSetsLast             = [];       % Index of last scan sets displayed in axis.
axisInfo.doseSetsLast             = [];       % Index of last dose sets displayed in axis.
axisInfo.structureSetsLast        = [];       % Index of last structure sets displayed in axis.

axisInfo.scanSelectMode     = 'auto';   % If 'auto', scanSets are chosen to match stateS.scanSet;
axisInfo.doseSelectMode     = 'auto';   % If 'auto', doseSets are chosen to match stateS.doseSet;
axisInfo.structSelectMode   = 'auto';   % If 'auto', structureSets are chosen to match axisInfo.scanSets;

%Individual scan image information.
axisInfo.scanObj.view       = [];       % This image's view, 'transverse', 'sagittal', 'coronal'
axisInfo.scanObj.coord      = [];       % This image's coordinate.
axisInfo.scanObj.scanSet    = [];       % Scanset this image was taken from.
axisInfo.scanObj.transM     = [];       % TransM that used to get this image.
axisInfo.doseObj.dispMode   = '';       % Type of display used for this scan representation.
axisInfo.scanObj.data2M     = [];       % Underlying 2D scan slice data used to make this image.
axisInfo.scanObj.xV         = [];       % Coordinates of cols of data2M
axisInfo.scanObj.yV         = [];       % Coordinates of rows of data2M
axisInfo.scanObj.xMinMax    = [];       % [min max] of x coordinates of this scanObj.  Used to define viewbox size.
axisInfo.scanObj.yMinMax    = [];       % [min max] of y coordinates of this scanObj.  Used to define viewbox size.
axisInfo.scanObj.handles    = {};       % Handles of objects used to display this scan.
axisInfo.scanObj.redraw     = [];       % If 1, redraw but don't recalculate scan data.

%Individual dose image information.
axisInfo.doseObj.view       = [];       % This image's view, 'transverse', 'sagittal', 'coronal'
axisInfo.doseObj.coord      = [];       % This image's coordinate.
axisInfo.doseObj.doseSet    = [];       % doseSet this image was taken from.
axisInfo.doseObj.scanBase   = [];       % The scan numbers that are the base of this image, if any.
axisInfo.doseObj.transM     = [];       % TransM that used to get this image.
axisInfo.doseObj.dispMode   = '';       % Type of display used for this dose representation.
axisInfo.doseObj.data2M     = [];       % Underlying 2D scan slice data used to make this image.
axisInfo.doseObj.xV         = [];       % Coordinates of cols of data2M
axisInfo.doseObj.yV         = [];       % Coordinates of rows of data2M
axisInfo.doseObj.xMinMax    = [];       % [min max] of x coordinates of this doseObj.  Used to define viewbox size.
axisInfo.doseObj.yMinMax    = [];       % [min max] of y coordinates of this doseObj.  Used to define viewbox size.
axisInfo.doseObj.handles    = {};       % Handles of objects used to display this scan.
axisInfo.doseObj.redraw     = [];       % If 1, redraw but don't recalculate dose data.

%Individual structure image information
axisInfo.structureGroup.view            = [];       % This structureGroup's view, 'transverse', 'sagittal', 'coronal'
axisInfo.structureGroup.coord           = [];       % This structureGroup's coordinate.
axisInfo.structureGroup.structureSet    = [];       % Scan associated with this structureGroup.
axisInfo.structureGroup.structNumsV     = [];       % Structures displayed on this view.
axisInfo.structureGroup.transM          = [];       % TransM used to get this structureGroup.
axisInfo.structureGroup.dispMode        = '';       % Type of display used for this structure representation.
axisInfo.structureGroup.xV              = {};       % xCoordinates of contours in this set.
axisInfo.structureGroup.yV              = {};       % yCoordinates of contours in this set.
axisInfo.structureGroup.xMinMax         = [];       % [min max] of x coordinates of this set.  Used to define viewbox size.
axisInfo.structureGroup.yMinMax         = [];       % [min max] of y coordinates of this set.  Used to define viewbox size.
axisInfo.structureGroup.handles         = {};       % Handles of objects used to display this set.
axisInfo.structureGroup.redraw          = [];       % If 1, redraw but don't recalculate struct data.

%Pool of line handles to draw structure
axisInfo.lineHandlePool.lineV           = [];
axisInfo.lineHandlePool.dotsV           = [];
axisInfo.lineHandlePool.currentHandle   = [];

%Any other handles
axisInfo.miscHandles                    = [];       %Used to store any remaining handles that should be kept at redraw.

%Make the length of these structs zero: no images/contours exist yet.  This
%leaves the fields but makes the struct array have NO elements.
axisInfo.scanObj(:) = [];
axisInfo.doseObj(:) = [];
axisInfo.structureGroup(:) = [];
axisInfo.lineHandlePool(:) = [];
