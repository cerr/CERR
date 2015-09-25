function varargout = contourControl(command, varargin)
%"contourControl"
%   Master control function for contouring in CERR.  Actual drawing is
%   handled by drawContour function, and the contour data is extracted by
%   contourControl and cached every time a slice changes, or the currently
%   edited structure changes.  Operates only on transverse axis.
%
%JRA 6/23/04
%   LM DK 10/24/2005
%      Corrected Error if contouring was done from scratch.
%   LM DK 4/3/2006
%       Fixed display bug where scan is associated with transformation matrix
%Usage:
%   contourControl('init')
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


global planC
global stateS
indexS = planC{end};

%For the moment, axis defaults to main.
hAxis = stateS.handle.CERRSliceViewerAxis;

switch command
    
    case 'init'
        %Prepare state data.
        if nargin == 0
            scanSet = getStructureAssociatedScan(1);
        else
            scanSet = varargin{1};
        end
        axisInfo = get(hAxis, 'userdata');
        setappdata(hAxis, 'prevScanset', axisInfo.scanSets);
        setappdata(hAxis, 'prevScanSelectMode', axisInfo.scanSelectMode);
        setappdata(hAxis, 'prevDoseset', axisInfo.doseSets);
        setappdata(hAxis, 'prevDoseSelectMode', axisInfo.doseSelectMode);
        
        transM0 = getTransM('scan', scanSet, planC);
        if isempty(transM0)
            transM0 = eye(4);
        end
        
        for i=1:length(planC{indexS.scan})
            transMList{i} = getTransM('scan', i, planC);
            if ~isempty(transMList{i})
                transM = transMList{i} * inv(transM0);
            else
                transM = inv(transM0);
            end
            planC{indexS.scan}(i).transM = transM;
        end
        
        setappdata(hAxis, 'transMList', transMList);
        
        [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(axisInfo.scanSets));
        
        % axisInfo = getAxisInfo(hAxis);
        
        sliceNum = findnearest(axisInfo.coord, zV);
        axisInfo.coord         = zV(sliceNum);
        axisInfo.scanSets       = scanSet;
        axisInfo.scanSelectMode = 'manual';
        axisInfo.doseSets      = [];
        axisInfo.doseSelectMode = 'manual';
        set(hAxis, 'userdata', axisInfo);
        numStructs = length(planC{indexS.structures});
        numSlices  = size(getScanArray(planC{indexS.scan}(scanSet)), 3);
        setappdata(hAxis, 'ccContours', cell(numStructs, numSlices));
        setappdata(hAxis, 'ccSlice', sliceNum);
        setappdata(hAxis, 'ccStruct', 1);
        setappdata(hAxis, 'ccStruct2', []);
        setappdata(hAxis, 'ccScanSet', scanSet);
        set(findobj(hAxis, 'tag', 'planeLocator'), 'hittest', 'off');
        CERRRefresh
        sliceCallBack('FOCUS', hAxis);
        drawContour('axis', hAxis);
        loadDrawSlice(hAxis);
        
    case 'Axis_Focus_Changed'
        %sliceCallBack has detected an axis click.  If it is the contouring
        %axis, set it's callback to drawContour.  If it isnt, set the
        %contouring axis to send future callbacks through sliceCallBack.
        if isequal(hAxis, stateS.handle.CERRAxis(stateS.currentAxis))
            set(hAxis, 'buttondownfcn', 'drawContour(''btnDownInAxis'')');
        else
            set(hAxis, 'buttondownfcn', 'sliceCallBack(''axisClicked'')');
        end
        
    case 'copySup'
        % Copy current structs' contours on current slice superior.
        saveDrawSlice(hAxis);
        sliceNum = getappdata(hAxis, 'ccSlice');
        copyToSlice(hAxis, sliceNum-1);
        sliceCallBack('CHANGESLC','prevslice');
        
    case 'copyInf'
        % Copy current structs' contours on current slice inferior.
        saveDrawSlice(hAxis);
        sliceNum = getappdata(hAxis, 'ccSlice');
        copyToSlice(hAxis, sliceNum+1);
        sliceCallBack('CHANGESLC','nextslice');
        
    case 'getMode'
        varargout{1} = getappdata(hAxis, 'ccMode');
        
    case 'drawMode'
        %Enter draw mode, using drawContour
        setappdata(hAxis, 'ccMode', 'draw');
        drawContour('drawMode', hAxis);
        
    case 'editMode'
        setappdata(hAxis, 'ccMode', 'edit');
        drawContour('editMode', hAxis);
        
    case 'editModeGE'
        setappdata(hAxis, 'ccMode', 'editGE');
        drawContour('editModeGE', hAxis);
        
    case 'threshMode'
        versionInfo = ver;
        if any(strcmpi({versionInfo.Name},'Image Processing Toolbox'));
            setappdata(hAxis, 'ccMode', 'thresh');
            drawContour('threshMode', hAxis);
        else
            CERRStatusString('Thresholding currently only available with Image Processing Toolbox.');
        end
        
    case 'reassignMode'
        setappdata(hAxis, 'ccMode', 'reassign');
        drawContour('reassignMode', hAxis);
        %MMMM Waiting for input here
        
    case 'pointMode'
        %Enter point manipulation mode.  Not implemented.
        
    case 'changeSlice'
        %A new slice has been on some axis in the CERR Viewer.
        scanSet = getappdata(hAxis, 'ccScanSet');
        
        [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
        
        %Get the view/coord in case of linked axes.
        [view, coord] = getAxisInfo(hAxis, 'view', 'coord');
        
        sliceNum = findnearest(coord, zV);
        
        ccMode = getappdata(hAxis, 'ccMode');
        if strcmpi(ccMode, 'draw')
            %If drawing, save contours on current slice and re-init.
            saveDrawSlice(hAxis);
            setappdata(hAxis, 'ccSlice', sliceNum);
            loadDrawSlice(hAxis);
            drawContour('drawMode', hAxis);
        elseif strcmpi(ccMode, 'edit')
            saveDrawSlice(hAxis);
            setappdata(hAxis, 'ccSlice', sliceNum);
            loadDrawSlice(hAxis);
            drawContour('editMode', hAxis);
        elseif strcmpi(ccMode, 'thresh')
            saveDrawSlice(hAxis);
            setappdata(hAxis, 'ccSlice', sliceNum);
            loadDrawSlice(hAxis);
            drawContour('threshMode', hAxis);
        elseif strcmpi(ccMode, 'reassign')
            saveDrawSlice(hAxis);
            setappdata(hAxis, 'ccSlice', sliceNum);
            loadDrawSlice(hAxis);
            drawContour('reassignMode', hAxis);
        end
        
        if ~isempty(ccMode)
            set(findobj(hAxis, 'tag', 'planeLocator'), 'hittest', 'off');
        end
        
        %If the current axis is not the main axis, set its callback.
        if isequal(hAxis, stateS.handle.CERRAxis(stateS.currentAxis))
            set(hAxis, 'buttondownfcn', 'drawContour(''btnDownInAxis'')');
        else
            set(hAxis, 'buttondownfcn', 'sliceCallBack(''axisClicked'')');
        end
        
    case 'changeStruct'
        %A new struct has been selected.
        ccMode = getappdata(hAxis, 'ccMode');
        
        ccScanSet = getappdata(hAxis, 'ccScanSet');
        if strcmpi(ccMode, 'draw') | strcmpi(ccMode, 'edit') | strcmpi(ccMode, 'thresh') | strcmpi(ccMode, 'reassign')
            %If drawing, save old contours and disp new contours.
            saveDrawSlice(hAxis);
            newStrNum = varargin{1};
            scanSet = getStructureAssociatedScan(newStrNum);
            
            %Get the view/coord in case of linked axes.
            coord = getAxisInfo(hAxis, 'coord');
            
            %Snap the axis coordinate to the zV grid.
            [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
            sliceNum = findnearest(coord, zV);
            setAxisInfo(hAxis, 'coord', zV(sliceNum));
            
            % APA 12-19-05 (in order to assign ccContours correctly)
            numStructs = length(planC{indexS.structures});
            numSlices  = size(getScanArray(planC{indexS.scan}(scanSet)), 3);
            setappdata(hAxis, 'ccContours', cell(numStructs, numSlices));
            
            sliceCallBack('refresh');
            
            setappdata(hAxis, 'ccSlice', sliceNum);
            setappdata(hAxis, 'ccScanSet', scanSet);
            setappdata(hAxis, 'ccStruct', varargin{1});
            loadDrawSlice(hAxis);
            switch lower(ccMode)
                case 'draw'
                    drawContour('drawMode', hAxis);
                case 'edit'
                    drawContour('editMode', hAxis);
                case 'thresh'
                    drawContour('threshMode', hAxis);
                case 'reassign'
                    drawContour('reassignMode', hAxis);
                    
            end
        end
        
    case 'changeStruct2'
        %A new struct2 has been selected.
        ccMode = getappdata(hAxis, 'ccMode');
        if strcmpi(ccMode, 'draw') | strcmpi(ccMode, 'edit') | strcmpi(ccMode, 'thresh') | strcmpi(ccMode, 'reassign')
            %If drawing, save old contours and disp new contours.
            saveDrawSlice(hAxis);
            setappdata(hAxis, 'ccStruct2', varargin{1});
            loadDrawSlice(hAxis);
            switch lower(ccMode)
                case 'draw'
                    drawContour('drawMode', hAxis);
                case 'edit'
                    drawContour('editMode', hAxis);
                case 'thresh'
                    drawContour('threshMode', hAxis);
                case 'reassign'
                    drawContour('reassignMode', hAxis);
            end
        end
        
    case 'save'
        %Finished contouring and wish to save changes.
        
        hFrame = stateS.handle.controlFrame;
        ud = get(hFrame, 'userdata');
        
        ROIInterVal = get(ud.handles.ROIInterpretedType,'value');
        
        if ROIInterVal == 1
            warndlg('Please Select Category before saving!!','Structure Category','modal')
            return
        end
        
        ccMode = getappdata(hAxis, 'ccMode');
        if strcmpi(ccMode, 'draw') | strcmpi(ccMode, 'edit') | strcmpi(ccMode, 'thresh') |strcmpi(ccMode, 'reassign');
            saveDrawSlice(hAxis);
            drawContour('quit', hAxis);
        end
        
        stateS.contourState = 0;
        
        %Rasterize and uniformize contours.
        storeAllContours(hAxis);
        setappdata(hAxis, 'ccMode', []);
        controlFrame('default');
        stateS.structsChanged = 1;
        stateS.CTDisplayChanged = 1;
        set(hAxis, 'buttondownfcn', 'sliceCallBack(''axisClicked'')');
        CERRStatusString('');
        
        %Re-enable right click menus;
        for i=1:length(stateS.handle.CERRAxis)
            CERRAxisMenu(stateS.handle.CERRAxis(i));
        end
        
        %Restore transformation matrices.
        transMList = getappdata(hAxis, 'transMList');
        for i=1:length(planC{indexS.scan})
            planC{indexS.scan}(i).transM = transMList{i};
        end
        
        prevScanset = getappdata(hAxis, 'prevScanset');
        prevScanSelectMode = getappdata(hAxis, 'prevScanSelectMode');
        prevDoseset = getappdata(hAxis, 'prevDoseset');
        prevDoseSelectMode = getappdata(hAxis, 'prevDoseSelectMode');
        
        
        axisInfo                = get(hAxis, 'userdata');
        axisInfo.scanSets       = prevScanset;
        axisInfo.scanSelectMode = prevScanSelectMode;
        if isempty(prevDoseset)
            axisInfo.doseSets       = [];
        else
            axisInfo.doseSets       = prevDoseset;
        end
        axisInfo.doseSelectMode = prevDoseSelectMode;
        
        axisInfo.structureSets = getStructureSetAssociatedScan(prevScanset);
        
        set(hAxis, 'userdata', axisInfo);
        
        for i=1:length(stateS.handle.CERRAxis)
            updateAxisRange(stateS.handle.CERRAxis(i),1,'contour');
        end
        sliceCallBack('refresh');
        sliceCallBack('FOCUS', hAxis);
        set(findobj(hAxis, 'tag', 'planeLocator'), 'hittest', 'on');
        
        %close overlay options figure if it exists
        try
            hFrame = stateS.handle.controlFrame;
            ud = get(hFrame, 'userdata');
            delete(ud.handle.ovrlayFig)
        end
        
        
    case 'revert'
        delete(findobj('tag', 'controlFrameItem'));
        %Finished contouring and wish to discard changes.
        drawContour('quit', hAxis);
        
        stateS.contourState = 0;
        
        setappdata(hAxis, 'ccMode', []);
        stateS.structsChanged = 1;
        stateS.CTDisplayChanged = 1;
        
        set(hAxis, 'buttondownfcn', 'sliceCallBack(''axisClicked'')');
        CERRStatusString('');
        
        %Re-enable right click menus;
        for i=1:length(stateS.handle.CERRAxis)
            CERRAxisMenu(stateS.handle.CERRAxis(i));
        end
        
        %Restore transformation matrices.
        transMList = getappdata(hAxis, 'transMList');
        for i=1:length(planC{indexS.scan})
            planC{indexS.scan}(i).transM = transMList{i};
        end
        
        prevScanset = getappdata(hAxis, 'prevScanset');
        prevScanSelectMode = getappdata(hAxis, 'prevScanSelectMode');
        prevDoseset = getappdata(hAxis, 'prevDoseset');
        prevDoseSelectMode = getappdata(hAxis, 'prevDoseSelectMode');
        
        axisInfo                = get(hAxis, 'userdata');
        axisInfo.scanSets       = prevScanset;
        axisInfo.scanSelectMode = prevScanSelectMode;
        
        if isempty(prevDoseset)
            axisInfo.doseSets       = [];
        else
            axisInfo.doseSets       = prevDoseset;
        end
        axisInfo.doseSelectMode = prevDoseSelectMode;
        
        axisInfo.structureSets = getStructureSetAssociatedScan(prevScanset);
        
        set(hAxis, 'userdata', axisInfo);
        
        for i=1:length(stateS.handle.CERRAxis)
            updateAxisRange(stateS.handle.CERRAxis(i),1,'CONTOUR');
        end
        sliceCallBack('refresh');
        sliceCallBack('FOCUS', hAxis);
        set(findobj(hAxis, 'tag', 'planeLocator'), 'hittest', 'on');
        
        %close overlay options figure if it exists
        try
            hFrame = stateS.handle.controlFrame;
            ud = get(hFrame, 'userdata');
            delete(ud.handle.ovrlayFig)
        end
        
    case 'undo'
        %Undo last action in drawing, points etc.  Not implemented.
        
    case 'deleteSegment'
        %Request to delete current segment.
        ccMode = getappdata(hAxis, 'ccMode');
        if strcmpi(ccMode, 'draw') | strcmpi(ccMode, 'edit') | strcmpi(ccMode, 'thresh')
            drawContour('deleteSegment', hAxis);
        end
        
    case 'scale'
        %Increase/decrease current contour by scale.  Not implemented.
        
    case 'refresh'
        %Not Implemented.  What the hell is this?
        
end

function saveDrawSlice(hAxis)
%Save the current slice's contours from drawContour
drawContour('defaultMode', hAxis);
ccContours = getappdata(hAxis, 'ccContours');
ccSlice = getappdata(hAxis, 'ccSlice');
ccStruct = getappdata(hAxis, 'ccStruct');
ccStruct2 = getappdata(hAxis, 'ccStruct2');

if ~isempty(ccStruct2)
    contourV2 = drawContour('getContours2', hAxis);
    ccContours{ccStruct2, ccSlice} = contourV2;
end
if isempty(ccContours)
    warning('contour name not initialized');
    return
end

%    defaultMode(hAxis);
contourV = drawContour('getContours', hAxis);
ccContours{ccStruct, ccSlice} = contourV;
setappdata(hAxis, 'ccContours', ccContours);

function loadDrawSlice(hAxis)
%Load the current slice's contours into drawContour--from the local storage
%if possible, else from the planC.
global planC
global stateS
indexS = planC{end};

ccContours = getappdata(hAxis, 'ccContours');
ccSlice = getappdata(hAxis, 'ccSlice');
ccStruct = getappdata(hAxis, 'ccStruct');
ccMode = getappdata(hAxis, 'ccMode');
ccStruct2 = getappdata(hAxis, 'ccStruct2');

%Consider changing this to be more modular. Repeated code.
if ~isempty(ccStruct2)
    try
        contourV2 = ccContours{ccStruct2, ccSlice};
    catch
        contourV2 = [];
    end
    %If no previously stored contour2, load from planC.
    try
        if isempty(contourV2)
            points = {planC{indexS.structures}(ccStruct2).contour(ccSlice).segments.points};
            for i=1:length(points)
                tmp = points{i};
                if ~isempty(tmp)
                    cV = tmp(:,1);
                    rV = tmp(:,2);
                    contourV2{i} = [cV, rV];
                end
            end
        end
    end
    
    ccContours{ccStruct2, ccSlice} = contourV2;
end
%%End reassign Mode special case.

try
    contourV = ccContours{ccStruct, ccSlice};
catch
    contourV = [];
end

%If no previously stored contours, load from planC.
try
    if isempty(contourV)
        points = {planC{indexS.structures}(ccStruct).contour(ccSlice).segments.points};
        for i=1:length(points)
            tmp = points{i};
            if ~isempty(tmp)
                cV = tmp(:,1);
                rV = tmp(:,2);
                contourV{i} = [cV, rV];
            end
        end
    end
end

% ccContours{ccStruct, ccSlice} = contourV;
%Quit to clear incomplete contours/callbacks.
drawContour('quit', hAxis);
drawContour('axis', hAxis);
drawContour('setContours', hAxis, contourV);
if ~isempty(ccStruct2)
    drawContour('setContours2', hAxis, contourV2);
end
saveDrawSlice(hAxis);


function storeAllContours(hAxis)

global planC

indexS = planC{end};

ccScanSet = getappdata(hAxis, 'ccScanSet');
ccContours = getappdata(hAxis, 'ccContours');
toUpdate = zeros(size(ccContours));

%set Matlab path to directory containing the Mesh-library
currDir = cd;
try
    meshDir = fileparts(which('libMeshContour.dll'));
    cd(meshDir)
    loadlibrary('libMeshContour','MeshContour.h')
catch
    warning('Mesh library could not be loaded.')
end
waitbarH = waitbar(0,'Saving contours for anatomical structures...');

for j = 1:size(ccContours,1)
    scanNum = getStructureAssociatedScan(j);
    changedV = zeros(size(ccContours, 2),1);
    for k = 1:size(ccContours, 2)
        changed = 0;
        points = [];
        contourV = ccContours{j,k};
        if ~isempty(contourV)
            for i=1:length(contourV)
                tmp = contourV{i};
                if ~isempty(tmp)
                    if length(planC{indexS.scan}(scanNum).scanInfo) > 1
                        zVal = interp1(1:length(planC{indexS.scan}(scanNum).scanInfo), [planC{indexS.scan}(scanNum).scanInfo.zValue], k);
                    else
                        zVal = planC{indexS.scan}(scanNum).scanInfo.zValue;
                    end
                    points{i} = [tmp(:,1), tmp(:,2), repmat(zVal, [size(tmp, 1) 1])];
                else
                    points{i} = [];
                end
            end
            
            %If contours have changed, take note of which
            %structs/slices we need to update uniform/rasterSegs for.
            try
                if ~isequal(points, {planC{indexS.structures}(j).contour(k).segments(1:end).points});
                    %                     changed = 1;
                    changedV(k) = 1;
                    %toUpdate(j,k) = 1;
                end
            catch
                changedV(k) = 0;
            end
            
            [planC{indexS.structures}(j).contour(k).segments(1:length(contourV)).points] = deal(points{:});
        end
    end
    if any(changedV)
        scanNum = getStructureAssociatedScan(j);
        planC = getRasterSegs(planC, j, find(changedV));
        if isempty(planC{indexS.scan}(scanNum).uniformScanInfo)
            planC = setUniformizedData(planC);
        else
            [xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
            [scanX, scanY, scanZ] = getScanXYZVals(planC{indexS.scan}(scanNum));
            scanSlicesChanged = find(changedV);
            uniformSliceNums = [];
            for q=1:length(scanSlicesChanged)
                if scanSlicesChanged(q) == 1 && length(scanZ) == 1
                    scanZs = scanZ;
                elseif scanSlicesChanged(q) == 1
                    scanZs = scanZ([scanSlicesChanged(q) scanSlicesChanged(q)+1]);
                elseif scanSlicesChanged(q) == length(changedV)
                    scanZs = scanZ([scanSlicesChanged(q)-1 scanSlicesChanged(q)]);
                else
                    scanZs = scanZ([scanSlicesChanged(q)-1 scanSlicesChanged(q)+1]);
                end
                uniformSliceNums = [uniformSliceNums find(zV >= min(scanZs) & zV <= max(scanZs))];
            end
            changedSlices = unique(uniformSliceNums);
            planC = updateStructureMatrices(planC, j, changedSlices);
        end
        
        %Re-generate mesh for mesh-representation
        if isfield(planC{indexS.structures}(j),'meshRep') && ~isempty(planC{indexS.structures}(j).meshRep) && planC{indexS.structures}(j).meshRep
            try
                structUID   = planC{indexS.structures}(j).strUID;
                [rasterSegments, planC, isError]    = getRasterSegments(j);
                [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum);
                mask3M = permute(mask3M,[2 1 3]);
                calllib('libMeshContour','loadVolumeAndGenerateSurface',structUID,scanX, scanY, scanZ(uniqueSlices), double(mask3M),0.5, uint16(10))
                %Store mesh under planC
                planC{indexS.structures}(i).meshS = calllib('libMeshContour','getSurface',structUID);
            catch
                planC{indexS.structures}(j).meshRep = 0;
                warning('Could not generate structure mesh.')
            end
        end
        
    end
    waitbar(j/size(ccContours,1),waitbarH)
end
close(waitbarH)
cd(currDir)
return;

function copyToSlice(hAxis, sliceNum);

global planC

indexS = planC{end};

scanSet = getappdata(hAxis, 'ccScanSet');
nSlices = size(getScanArray(planC{indexS.scan}(scanSet)),3);
if sliceNum < 1 | sliceNum > nSlices
    return;
end
ccStruct = getappdata(hAxis, 'ccStruct');
ccSlice = getappdata(hAxis, 'ccSlice');
ccContours = getappdata(hAxis, 'ccContours');

contourV = ccContours{ccStruct, ccSlice};
if isempty(contourV)
    return;
end
newContourV = ccContours{ccStruct, sliceNum};
if isempty(newContourV)
    newContourV = {};
    points = {planC{indexS.structures}(ccStruct).contour(sliceNum).segments.points};
    for i=1:length(points)
        tmp = points{i};
        if ~isempty(tmp)
            cV = tmp(:,1);
            rV = tmp(:,2);
            newContourV{i} = [cV, rV];
        end
    end
    combinedContourV = {contourV{:}};
end
combinedContourV = {newContourV{:} contourV{:}};
ccContours{ccStruct, sliceNum} = combinedContourV;
setappdata(hAxis, 'ccContours', ccContours);