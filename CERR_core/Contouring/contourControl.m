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
%hAxis = stateS.handle.CERRSliceViewerAxis;

% Default axis to the current axis
hAxis = stateS.handle.CERRAxis(stateS.contourAxis);

switch command
    
    case 'init'
        %Prepare state data.
        if nargin == 0
            scanSet = getStructureAssociatedScan(1);
        else
            scanSet = varargin{1};
        end
        %axisInfo = get(hAxis, 'userdata');
        axInd = hAxis == stateS.handle.CERRAxis;
        axisInfo = stateS.handle.aI(axInd);
        stateS.contouringMetaDataS.prevScanset = axisInfo.scanSets;
        stateS.contouringMetaDataS.prevScanSelectMode = axisInfo.scanSelectMode;
        stateS.contouringMetaDataS.prevDoseset = axisInfo.doseSets;
        stateS.contouringMetaDataS.prevDoseSelectMode = axisInfo.doseSelectMode;
        
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
        
        stateS.contouringMetaDataS.transMList = transMList;

        
        [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(axisInfo.scanSets));
                
        sliceNum = findnearest(axisInfo.coord, zV);
        axisInfo.coord         = zV(sliceNum);
        axisInfo.scanSets       = scanSet;
        axisInfo.scanSelectMode = 'manual';
        %axisInfo.doseSets      = [];
        %axisInfo.doseSelectMode = 'manual';
        %set(hAxis, 'userdata', axisInfo);
        stateS.handle.aI(axInd) = axisInfo;        
        numStructs = length(planC{indexS.structures});
        assocSacnV = getStructureAssociatedScan(1:numStructs);
        structsV = assocSacnV == scanSet;
        structNumV = find(structsV);    
        if isempty(structNumV)
            initStructNum = [];
        else
            initStructNum = structNumV(1);
        end
        numSlices  = size(getScanArray(planC{indexS.scan}(scanSet)), 3);
        stateS.contouringMetaDataS.ccContours = cell(numStructs, numSlices);
        stateS.contouringMetaDataS.ccSlice = sliceNum;
        stateS.contouringMetaDataS.numRows = planC{indexS.scan}(scanSet).scanInfo(sliceNum).sizeOfDimension1;
        stateS.contouringMetaDataS.numCols = planC{indexS.scan}(scanSet).scanInfo(sliceNum).sizeOfDimension2;
        stateS.contouringMetaDataS.ccStruct = initStructNum;
        stateS.contouringMetaDataS.ccStruct2 = [];
        stateS.contouringMetaDataS.ccContours = [];
        stateS.contouringMetaDataS.ccScanSet = scanSet;
        stateS.contouringMetaDataS.contourSlcLoadedM = false(numStructs, numSlices);
        set(findobj(hAxis, 'tag', 'planeLocator'), 'hittest', 'off');
        %CERRRefresh
        %sliceCallBack('FOCUS', hAxis);
        showScale(hAxis,stateS.contourAxis)
        drawContour('axis', hAxis);
        loadDrawSlice(hAxis);
        
    case 'Save_Slice'
        saveDrawSlice(hAxis);
        
    case 'Axis_Focus_Changed'
        %sliceCallBack has detected an axis click.  If it is the contouring
        %axis, set it's callback to drawContour.  If it isnt, set the
        %contouring axis to send future callbacks through sliceCallBack.
        
        hFig = stateS.handle.CERRSliceViewer;
        if isequal(hAxis, stateS.handle.CERRAxis(stateS.currentAxis))
            set(hAxis, 'buttonDownFcn', 'drawContour(''btnDownInAxis'')');
            set(hFig, 'WindowButtonUpFcn', 'drawContour(''btnUp'')');
            set(hFig, 'WindowButtonMotionFcn', 'drawContour(''motionInFigure'')');
            set(hAxis, 'UIContextMenu','')
        else
            set(hAxis, 'buttondownfcn', 'sliceCallBack(''axisClicked'')');
            set(hFig, 'WindowButtonUpFcn', '');
            set(hFig, 'WindowButtonMotionFcn', '');
            CERRAxisMenu(hAxis);
        end


    case 'copySup'
        % Copy current structs' contours on current slice superior.
        saveDrawSlice(hAxis);
        %sliceNum = getappdata(hAxis, 'ccSlice'); %AICHANGED
        sliceNum = stateS.contouringMetaDataS.ccSlice;
        copyToSlice(hAxis, sliceNum-1);
        sliceCallBack('CHANGESLC','prevslice');
        
    case 'copyInf'
        % Copy current structs' contours on current slice inferior.
        saveDrawSlice(hAxis);
        %sliceNum = getappdata(hAxis, 'ccSlice'); %AICHANGED
        sliceNum = stateS.contouringMetaDataS.ccSlice;
        copyToSlice(hAxis, sliceNum+1);
        sliceCallBack('CHANGESLC','nextslice');
    
    case 'copySl'  
        %Copy current structs' contours to selected slice 
        hAxis = varargin{1};
        destSlice = varargin{2};
        copyToSlice(hAxis, destSlice);
        saveDrawSlice(hAxis);

    case 'getMode'
        %varargout{1} = getappdata(hAxis, 'ccMode'); %AICHANGED
        varargout{1} = stateS.contouringMetaDataS.ccModee;
        
    case 'drawMode'
        %Enter draw mode, using drawContour
        stateS.contouringMetaDataS.ccMode = 'draw';
        drawContour('drawMode', hAxis);
        
    case 'editMode'
        stateS.contouringMetaDataS.ccMode = 'edit';
        drawContour('editMode', hAxis);
        
    case 'editModeGE'
        stateS.contouringMetaDataS.ccMode = 'editGE';
        drawContour('editModeGE', hAxis);
        
    case {'drawBall','eraserBall'}
        % initialize the ball        
        angleV = linspace(0,2*pi,50);
        xV = cos(angleV);
        yV = sin(angleV);
        ballHandle = fill(xV,yV,[1 0.5 0.5],'parent',hAxis,'visible','off',...
            'hittest','off', 'facealpha',0.2,'EdgeColor', [1 0 0]);
        stateS.contouringMetaDataS.hBall = ballHandle;
        stateS.contouringMetaDataS.angles = [xV(:) yV(:)];
        controlFrame('contour','setBrushSize',hAxis)
        stateS.contouringMetaDataS.ccMode = 'drawBall';
        stateS.contouringMetaDataS.mode = 'drawBall';
        drawContour('drawBallMode', hAxis);
        stateS.contouringMetaDataS.eraseFlag = 0;
        if strcmpi(command,'eraserBall')
            stateS.contouringMetaDataS.eraseFlag = 1;
        end
        
    case 'flexSelMode'
        %Enter flex mode
        angleV = linspace(0,2*pi,50);
        xV = cos(angleV);
        yV = sin(angleV);
        ballHandle = fill(xV,yV,[1 0.5 0.5],'parent',hAxis,'visible','off',...
            'hittest','off', 'facealpha',0.2,'EdgeColor', [1 0 0]);
        stateS.contouringMetaDataS.hBall = ballHandle;
        stateS.contouringMetaDataS.angles = [xV(:) yV(:)];
        controlFrame('contour','setBrushSize',hAxis)
        stateS.contouringMetaDataS.ccMode = 'flexSelMode';
        stateS.contouringMetaDataS.mode = 'flexSelMode';
        if nargin>1
            eraseFlag = varargin{1};
            drawContour('flexSelMode',hAxis,eraseFlag);
        else
            drawContour('flexSelMode', hAxis);
        end
        
    case 'thresholdMode'
        % Get threshold levels from the current screen
        hImg =  findobj(hAxis, 'tag', 'CTImage');
        img = get(hImg, 'cData');
        %smoothImgM = imgaussfilt(img,2);
        smoothImgM = img;
        %numLevels = 20; % max allowed is 20 in Matlab
        %threshV = multithresh(smoothImgM, numLevels); 
        %maskM = getappdata(hAxis, 'contourMask'); %AICHANGED
        maskM = stateS.contouringMetaDataS.contourMask; 

        %Enter threshold mode
%         setappdata(hAxis, 'ccMode', 'threshold');
%         setappdata(hAxis, 'smoothImg', smoothImgM);
%         setappdata(hAxis, 'InitialMask', maskM);
%         setappdata(hAxis, 'ContractionBias', 0);
        stateS.contouringMetaDataS.ccMode = 'threshold';
        stateS.contouringMetaDataS.smoothImg = smoothImgM;
        stateS.contouringMetaDataS.InitialMask = maskM;
        stateS.contouringMetaDataS.ContractionBias = 0;
        drawContour('thresholdMode', hAxis);        
        
    case 'threshMode' % OLD callback, replaced by thresholdMode
        versionInfo = ver;
        if any(strcmpi({versionInfo.Name},'Image Processing Toolbox'));
            stateS.contouringMetaDataS.ccMode = 'thresh';
            drawContour('threshMode', hAxis);
        else
            CERRStatusString('Thresholding currently only available with Image Processing Toolbox.');
        end
        
    case 'reassignMode'
        stateS.contouringMetaDataS.ccMode = 'reassign';
        drawContour('reassignMode', hAxis);
        %MMMM Waiting for input here
        
    case 'pointMode'
        %Enter point manipulation mode.  Not implemented.
        
    case 'changeSlice'
        %A new slice has been on some axis in the CERR Viewer.
        scanSet = stateS.contouringMetaDataS.ccScanSet; 
        
        [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
        
        %Get the view/coord in case of linked axes.
        [view, coord] = getAxisInfo(hAxis, 'view', 'coord');
        
        sliceNum = findnearest(coord, zV);
         
        %ccMode = getappdata(hAxis, 'ccMode'); %AICHANGED
        ccMode =  stateS.contouringMetaDataS.ccMode; 
        
        if strcmpi(ccMode, 'draw')
            %If drawing, save contours on current slice and re-init.
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
            drawContour('drawMode', hAxis);
        elseif strcmpi(ccMode, 'drawBall')
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
            %drawContour('drawBallMode', hAxis);
            eraseFlag =  stateS.contouringMetaDataS.eraseFlag;
            
            if eraseFlag
                contourControl('eraserBall')
            else
                contourControl('drawBall')
            end
            % ADDED AI 5/8/17
        elseif strcmpi(ccMode, 'flexSelMode')
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
            contourControl('flexSelMode')
            % END ADDED
        elseif strcmpi(ccMode, 'edit')
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
            %drawContour('editMode', hAxis);
            drawContour('drawMode', hAxis); % initialize new slice in the draw mode.
        elseif strcmpi(ccMode, 'thresh')
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
            drawContour('threshMode', hAxis);
        elseif strcmpi(ccMode, 'threshold')
            %saveDrawSlice(hAxis);
            ud = stateS.handle.controlFrameUd ;
            set(ud.handles.threshold,'Value',0,'BackgroundColor',[0.8 0.8 0.8]);
            drawContour('noneMode', hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
            %drawContour('thresholdMode', hAxis);
            
        elseif strcmpi(ccMode, 'reassign')
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
            drawContour('reassignMode', hAxis);
        elseif isempty(ccMode)
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            loadDrawSlice(hAxis);
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
        ccMode =  stateS.contouringMetaDataS.ccMode;
        ccScanSet =  stateS.contouringMetaDataS.ccScanSet;
        structNum =  stateS.contouringMetaDataS.ccStruct;
        
        %if strcmpi(ccMode, 'draw') || strcmpi(ccMode, 'edit') || ...
        %        strcmpi(ccMode, 'thresh') || strcmpi(ccMode, 'reassign') || ...
        %        strcmpi(ccMode, 'drawBall') 

            %If drawing, save old contours and disp new contours.
            if ~isempty(structNum)
                saveDrawSlice(hAxis);
            end
            newStrNum = varargin{1};
            scanSet = getStructureAssociatedScan(newStrNum);
            numStructs = length(planC{indexS.structures});
            assocScanNumV = getStructureAssociatedScan(1:numStructs);
            numStructsInScan = sum(assocScanNumV == scanSet);
            strSacnIndV(assocScanNumV==scanSet) = 1:numStructsInScan;
            
            %Get the view/coord in case of linked axes.
            coord = getAxisInfo(hAxis, 'coord');
            
            %Snap the axis coordinate to the zV grid.
            [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
            sliceNum = findnearest(coord, zV);
            setAxisInfo(hAxis, 'coord', zV(sliceNum));
            
%             % APA 12-19-05 (in order to assign ccContours correctly)
%             numStructs = length(planC{indexS.structures});
%             numSlices  = size(getScanArray(planC{indexS.scan}(scanSet)), 3);
%             setappdata(hAxis, 'ccContours', cell(numStructs, numSlices));
            
            %sliceCallBack('refresh');
            showStructures(hAxis)
            stateS.contouringMetaDataS.ccSlice = sliceNum;
            stateS.contouringMetaDataS.ccScanSet = scanSet;
            stateS.contouringMetaDataS.ccStruct = varargin{1};
            loadDrawSlice(hAxis);
            drawContour('noneMode', hAxis);
            
            ud = stateS.handle.controlFrameUd;
            set(ud.handles.structPopup, 'value', strSacnIndV(newStrNum));
            return;
            
            switch lower(ccMode)
                case 'draw'
                    drawContour('drawMode', hAxis);
                case 'drawball'
                    drawContour('drawBallMode', hAxis);                    
                case 'edit'
                    drawContour('editMode', hAxis);
                case 'thresh'
                    drawContour('threshMode', hAxis);
                case 'reassign'
                    drawContour('reassignMode', hAxis);
                % AI 5/8/17
                case 'flexselmode' 
                    drawContour('flexMode', hAxis);
            end
        %end
        
    case 'changeStruct2'
        %A new struct2 has been selected.
        %ccMode = getappdata(hAxis, 'ccMode'); %AICHANGED
        ccMode =  stateS.contouringMetaDataS.ccMode;
        
        if strcmpi(ccMode, 'draw') | strcmpi(ccMode, 'edit') | strcmpi(ccMode, 'thresh') | strcmpi(ccMode, 'reassign')
            %If drawing, save old contours and disp new contours.
            saveDrawSlice(hAxis);
            stateS.contouringMetaDataS.ccStruct2 = varargin{1};
            loadDrawSlice(hAxis);
            switch lower(ccMode)
                case 'draw'
                    drawContour('drawMode', hAxis);
                case 'drawball'
                    drawContour('drawBallMode', hAxis);                                        
                case 'edit'
                    drawContour('editMode', hAxis);
                case 'thresh'
                    drawContour('threshMode', hAxis);
                case 'reassign'
                    drawContour('reassignMode', hAxis);
                % AI 5/8/17
                case 'flexselmode'
                    drawContour('flexMode', hAxis);
                    
            end
        end
        
    case 'save'
        %Finished contouring and wish to save changes.
        ud = stateS.handle.controlFrameUd ;
        
        ROIInterVal = get(ud.handles.ROIInterpretedType,'value');
        
        if ROIInterVal == 1
            warndlg('Please Select Category before saving!!','Structure Category','modal')
            return
        end
        
        ccMode =  stateS.contouringMetaDataS.ccMode;
         
        if strcmpi(ccMode, 'draw') || strcmpi(ccMode, 'edit') || ...
                strcmpi(ccMode, 'thresh') || strcmpi(ccMode, 'reassign') ...
                || strcmpi(ccMode, 'drawBall') || strcmpi(ccMode, 'flexSelMode') %AI 5/8/17
            saveDrawSlice(hAxis);
            %drawContour('quit', hAxis); % APA commented
        end
                
        %Rasterize and uniformize contours.
        storeAllContours(hAxis);
        
        % APA: try to stay in contouring mode until the user quits
%         scanSet = getappdata(hAxis,'ccScanSet');  %AICHANGED
%         ccContours = getappdata(hAxis, 'ccContours');  %AICHANGED
%         contourV = getappdata(hAxis,'contourV');  %AICHANGED
%         ccStruct = getappdata(hAxis,'ccStruct');  %AICHANGED
%         ccSlice = getappdata(hAxis,'ccSlice'); %AICHANGED
        scanSet =  stateS.contouringMetaDataS.ccScanSet;
        ccContours =  stateS.contouringMetaDataS.ccContours;
        contourV =  stateS.contouringMetaDataS.contourV;
        ccStruct =  stateS.contouringMetaDataS.ccStruct;
        ccSlice =  stateS.contouringMetaDataS.ccSlice;
        
        
        ccContours{ccStruct, ccSlice} = contourV;
        %setappdata(hAxis, 'ccContours', ccContours);
        stateS.contouringMetaDataS.ccContours = ccContours;
        stateS.structsChanged = 1;
        for i=1:length(stateS.handle.CERRAxis) 
            scanSetonAxis = getAxisInfo(uint8(i),'scanSets');     
            structSets = getAxisInfo(uint8(i),'structureSets');
            if scanSet == scanSetonAxis && ~ismember(scanSet,structSets)
                % force structure set to "manual" for displaying the
                % currently drawn structure
                structSets = [structSets,scanSet];
                setAxisInfo(uint8(i),'structureSets',structSets,...
                    'structSelectMode','manual');
            end
            showStructures(stateS.handle.CERRAxis(i))
        end
        % Set pencil/brush/eraser/flex button colors and states
        %set([ud.handles.flex ud.handles.pencil, ud.handles.brush, ud.handles.eraser],...
        %    'BackgroundColor',[0.8 0.8 0.8], 'value', 0)
        set([ud.handles.flex ud.handles.pencil ud.handles.threshold],'BackgroundColor',[0.8 0.8 0.8], 'value', 0);
        % Delete the ball for brush/eraser/flex mode
        %ballH = getappdata(hAxis, 'hBall'); %AICHANGED
        ballH =  stateS.contouringMetaDataS.hBall;
        
        if ishandle(ballH)
            delete(ballH);
        end
        drawContour('noneMode',stateS.handle.CERRAxis(stateS.currentAxis))
        return;
        % APA: end

        stateS.contouringMetaDataS.ccMode = [];
        % get out of contouring mode
        controlFrame('default');
        stateS.contourState = 0;
        stateS.structsChanged = 1;
        stateS.CTDisplayChanged = 1;
        set(hAxis, 'buttondownfcn', 'sliceCallBack(''axisClicked'')');
        CERRStatusString('');
        
        %Re-enable right click menus;
        for i=1:length(stateS.handle.CERRAxis)
            CERRAxisMenu(stateS.handle.CERRAxis(i));
        end
        
        %Restore transformation matrices.
        transMList =  stateS.contouringMetaDataS.transMList;
        
        for i=1:length(planC{indexS.scan})
            planC{indexS.scan}(i).transM = transMList{i};
        end
        prevScanset =  stateS.contouringMetaDataS.prevScanset;
        prevScanSelectMode =  stateS.contouringMetaDataS.prevScanSelectMode;
        prevDoseset =  stateS.contouringMetaDataS.prevDoseset;
        prevDoseSelectMode =  stateS.contouringMetaDataS.prevDoseSelectMode;
        
        
        %axisInfo                = get(hAxis, 'userdata');
        axInd = hAxis == stateS.handle.CERRAxis;
        axisInfo = stateS.handle.aI(axInd);
        axisInfo.scanSets       = prevScanset;
        axisInfo.scanSelectMode = prevScanSelectMode;
        if isempty(prevDoseset)
            axisInfo.doseSets       = [];
        else
            axisInfo.doseSets       = prevDoseset;
        end
        axisInfo.doseSelectMode = prevDoseSelectMode;
        
        axisInfo.structureSets = getStructureSetAssociatedScan(prevScanset);
        
        %set(hAxis, 'userdata', axisInfo);
        stateS.handle.aI(axInd) = axisInfo;
        
        for i=1:length(stateS.handle.CERRAxis)
            updateAxisRange(stateS.handle.CERRAxis(i),1,'contour');
        end
        sliceCallBack('refresh');
        sliceCallBack('FOCUS', hAxis);
        set(findobj(hAxis, 'tag', 'planeLocator'), 'hittest', 'on');
        
        %close overlay options figure if it exists
        try
            ud = stateS.handle.controlFrameUd ;
            delete(ud.handle.ovrlayFig)
        end
        
        
    case 'revert'
        hControlFrameItemV = findobj('tag', 'controlFrameItem');
        delete(hControlFrameItemV);
        %Finished contouring and wish to discard changes.
        drawContour('quit', hAxis);
        
        stateS.contourState = 0;
        stateS.contouringMetaDataS.ccMode = [];
        stateS.structsChanged = 1;
        stateS.CTDisplayChanged = 1;
        
        set(hAxis, 'buttondownfcn', 'sliceCallBack(''axisClicked'')');
        CERRStatusString('');
        
        %Re-enable right click menus;
        for i=1:length(stateS.handle.CERRAxis)
            CERRAxisMenu(stateS.handle.CERRAxis(i));
        end
        
        %Restore transformation matrices.
        transMList =  stateS.contouringMetaDataS.transMList;
        for i=1:length(planC{indexS.scan})
            planC{indexS.scan}(i).transM = transMList{i};
        end
        prevScanset =  stateS.contouringMetaDataS.prevScanset;
        prevScanSelectMode =  stateS.contouringMetaDataS.prevScanSelectMode;
        prevDoseset =  stateS.contouringMetaDataS.prevDoseset;
        prevDoseSelectMode =  stateS.contouringMetaDataS.prevDoseSelectMode;
        
        
        %axisInfo                = get(hAxis, 'userdata');
        axInd = hAxis == stateS.handle.CERRAxis;
        axisInfo = stateS.handle.aI(axInd);

        axisInfo.scanSets       = prevScanset;
        axisInfo.scanSelectMode = prevScanSelectMode;
        
        if isempty(prevDoseset)
            axisInfo.doseSets       = [];
        else
            axisInfo.doseSets       = prevDoseset;
        end
        axisInfo.doseSelectMode = prevDoseSelectMode;
        
        axisInfo.structureSets = getStructureSetAssociatedScan(prevScanset);
        
        %set(hAxis, 'userdata', axisInfo);
        stateS.handle.aI(axInd) = axisInfo;

        for i=1:length(stateS.handle.CERRAxis)
            updateAxisRange(stateS.handle.CERRAxis(i),1,'CONTOUR');
        end
        
        % Set contouring axis to 0
        stateS.contourAxis = 0;
        
        %close overlay options figure if it exists
        try
            ud = stateS.handle.controlFrameUd ;
            delete(ud.handle.ovrlayFig)
        end

        sliceCallBack('refresh');
        sliceCallBack('FOCUS', hAxis);
        set(findobj(hAxis, 'tag', 'planeLocator'), 'hittest', 'on');
        
                
    case 'undo'
        %Undo last action in drawing, points etc.  Not implemented.
        
    case 'deleteSegment'
        %Request to delete current segment.
        ccMode =  stateS.contouringMetaDataS.ccMode;
        if strcmpi(ccMode, 'draw') || strcmpi(ccMode, 'edit') || strcmpi(ccMode, 'thresh')
            drawContour('deleteSegment', hAxis);
        end
        
    case 'deleteAllSegments'
        drawContour('deleteAllSegments',hAxis)
        %saveDrawSlice(hAxis)
        
    case 'scale'
        %Increase/decrease current contour by scale.  Not implemented.
        
    case 'refresh'
        %Not Implemented.  What the hell is this?
        
end

function saveDrawSlice(hAxis)
%Save the current slice's contours from drawContour
global stateS
drawContour('defaultMode', hAxis);
fieldC = {'ccContours','ccSlice','ccStruct','ccStruct2'};
for i = 1:length(fieldC)
if ~isfield(stateS.contouringMetaDataS,fieldC{i})
stateS.contouringMetaDataS.(fieldC{i}) = [];
end
end

ccStruct2 =  stateS.contouringMetaDataS.ccStruct2;
ccContours =  stateS.contouringMetaDataS.ccContours;
ccSlice =  stateS.contouringMetaDataS.ccSlice;
if ~isempty(ccStruct2)
    contourV2 = drawContour('getContours2', hAxis);
    ccContours{ccStruct2, ccSlice} = contourV2;
end
ccStruct =  stateS.contouringMetaDataS.ccStruct;
if isempty(ccStruct)
    warning('contour name not initialized');
    return
end

%    defaultMode(hAxis);
contourV = drawContour('getContours', hAxis);
ccContours{ccStruct, ccSlice} = contourV;

stateS.contouringMetaDataS.ccContours = ccContours;


function loadDrawSlice(hAxis)
%Load the current slice's contours into drawContour--from the local storage
%if possible, else from the planC.
global planC
global stateS
indexS = planC{end};

ccContours =  stateS.contouringMetaDataS.ccContours;
ccSlice =  stateS.contouringMetaDataS.ccSlice;
ccStruct =  stateS.contouringMetaDataS.ccStruct;
ccStruct2 =  stateS.contouringMetaDataS.ccStruct2;
ccMode =  stateS.contouringMetaDataS.ccMode;
contourSlcLoadedM =  stateS.contouringMetaDataS.contourSlcLoadedM;

loadFromPlanC = 1;
if contourSlcLoadedM(ccStruct, ccSlice)
    loadFromPlanC = 0;
else
    contourSlcLoadedM(ccStruct, ccSlice) = true;
    stateS.contouringMetaDataS.contourSlcLoadedM = contourSlcLoadedM;
end

%Consider changing this to be more modular. Repeated code.
if ~isempty(ccStruct2)
    try
        contourV2 = ccContours{ccStruct2, ccSlice};
    catch
        contourV2 = [];
    end
    %If no previously stored contour2, load from planC.
    try
        if loadFromPlanC % isempty(contourV2)
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
    if loadFromPlanC  % isempty(contourV)
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
global stateS

indexS = planC{end};

ccScanSet =  stateS.contouringMetaDataS.ccScanSet;
ccContours =  stateS.contouringMetaDataS.ccContours;
contourSlcLoadedM =  stateS.contouringMetaDataS.contourSlcLoadedM;
toUpdate = zeros(size(ccContours));

% for mesh library, out of commission
% %set Matlab path to directory containing the Mesh-library
% currDir = cd;
% try
%     meshDir = fileparts(which('libMeshContour.dll'));
%     cd(meshDir)
%     loadlibrary('libMeshContour','MeshContour.h')
% catch
%     warning('Mesh library could not be loaded.')
% end

waitbarH = waitbar(0,'Saving contours for anatomical structures...');

for j = 1:size(ccContours,1)
    if getStructureAssociatedScan(j) ~= ccScanSet
        continue;
    end
    scanNum = getStructureAssociatedScan(j);
    changedV = zeros(size(ccContours, 2),1);
    for k = 1:size(ccContours, 2)
        points = {[]};
        contourV = ccContours{j,k};        
        if contourSlcLoadedM(j,k) %~isempty(contourV)
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
            
%             %If contours have changed, take note of which
%             %structs/slices we need to update uniform/rasterSegs for.
%             try
%                 if ~isequal(points, {planC{indexS.structures}(j).contour(k).segments(1:end).points})
%                     %                     changed = 1;
%                     changedV(k) = 1;
%                     %toUpdate(j,k) = 1;
%                 end
%             catch
%                 changedV(k) = 0;
%             end

            structPointsC = {planC{indexS.structures}(j).contour(k).segments(1:end).points};
            changedV(k) = ~isequal(points, structPointsC);
            
            % [planC{indexS.structures}(j).contour(k).segments(1:length(contourV)).points]
            % = deal(points{:}); % bug
            
            if changedV(k)
                % flush out old segments
                planC{indexS.structures}(j).contour(k).segments(:) = [];
                % add new segments
                for seg = 1:length(points)
                    planC{indexS.structures}(j).contour(k).segments(seg).points = points{seg};
                end
            end
            
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
        
%         % for mesh library, out of commission
%         %Re-generate mesh for mesh-representation
%         if isfield(planC{indexS.structures}(j),'meshRep') && ~isempty(planC{indexS.structures}(j).meshRep) && planC{indexS.structures}(j).meshRep
%             try
%                 structUID   = planC{indexS.structures}(j).strUID;
%                 [rasterSegments, planC, isError]    = getRasterSegments(j);
%                 [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum);
%                 mask3M = permute(mask3M,[2 1 3]);
%                 calllib('libMeshContour','loadVolumeAndGenerateSurface',structUID,scanX, scanY, scanZ(uniqueSlices), double(mask3M),0.5, uint16(10))
%                 %Store mesh under planC
%                 planC{indexS.structures}(i).meshS = calllib('libMeshContour','getSurface',structUID);
%             catch
%                 planC{indexS.structures}(j).meshRep = 0;
%                 warning('Could not generate structure mesh.')
%             end
%         end
        
    end
    waitbar(j/size(ccContours,1),waitbarH)
end
close(waitbarH)
%cd(currDir) % for mesh library, out of commission

return; % activecontour: out of commission for gitHub

ButtonName = questdlg('Apply Activecontour?', ...
    'Refine using activecontour algorithm?', ...
    'Yes', 'No', 'No');

if ~strcmpi(ButtonName,'Yes')
    return
end

% Apply the activecontour method to the current structure
structNum =  stateS.contouringMetaDataS.ccStruct;
[r,c,s] = getUniformStr(structNum);
scanNum = getStructureAssociatedScan(structNum);
scan3M = getUniformizedCTScan(1, scanNum);
minSlc = min(s);
maxSlc = max(s);
mask3M = getUniformStr(structNum);
maxIterations = 50;
siz = size(mask3M);
%updatedMaskM = zeros(siz);
currentSlice =  stateS.contouringMetaDataS.ccSlice;
for slc = currentSlice %minSlc:maxSlc
    scanM = scan3M(:,:,slc);
    structM = single(mask3M(:,:,slc));
    mask3M(:,:,slc) = activecontour(scanM, structM, maxIterations, 'Chan-Vese');
    %updatedMaskM(:,:,slc) = levelSetLi(scanM, structM) > 0;
end

%If registered to uniformized data, use nearest slice neighbor
%interpolation.
[~, ~, zUni] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
[~, ~, zSca] = getScanXYZVals(planC{indexS.scan}(scanNum));

normsiz = size(planC{indexS.scan}(scanNum).scanArray);
tmpM = false(normsiz);

for i=1:normsiz(3)
    zVal = zSca(i);
    uB = find(zUni > zVal, 1 );
    lB = find(zUni <= zVal, 1, 'last' );
    if isempty(uB) || isempty(lB)
        continue
    end
    if abs(zUni(uB) - zVal) < abs(zUni(lB) - zVal)
        tmpM(:,:,i) = logical(mask3M(:,:,uB));
    else
        tmpM(:,:,i) = logical(mask3M(:,:,lB));
    end
end
%Get updated contour from mask
[contr, sliceValues] = maskToPoly(tmpM, 1:normsiz(3), scanNum, planC);
planC{indexS.structures}(structNum).contour = contr;
planC{indexS.structures}(structNum).rasterSegments = [];
planC{indexS.structures}(structNum).rasterized = 0;
planC = updateStructureMatrices(planC,structNum);

slcNum = stateS.contouringMetaDataS.ccSlice;
for seg = 1:length(contr(slcNum).segments)
    if ~isempty(contr(slcNum).segments(seg).points)
        contourV{seg} = contr(slcNum).segments(seg).points;
    end
end
stateS.contouringMetaDataS.contourV = contourV;
stateS.contouringMetaDataS.contourMask = tmpM(:,:,slcNum);
return;

function copyToSlice(hAxis, sliceNum)

global planC stateS

indexS = planC{end};

scanSet = stateS.contouringMetaDataS.ccScanSet;
nSlices = size(getScanArray(planC{indexS.scan}(scanSet)),3);
if sliceNum < 1 | sliceNum > nSlices
    return;
end
ccStruct = stateS.contouringMetaDataS.ccStruct;
srcSlice = stateS.contouringMetaDataS.copySliceNum;
ccContours = stateS.contouringMetaDataS.ccContours;
maskM = stateS.contouringMetaDataS.copyMask;


contourV = ccContours{ccStruct, srcSlice};
if isempty(contourV)
    points = {planC{indexS.structures}(ccStruct).contour(srcSlice).segments.points};
    if ~isempty(points)
        for i=1:length(points)
            tmp = points{i};
            if ~isempty(tmp)
                cV = tmp(:,1);
                rV = tmp(:,2);
                contourV{i} = [cV, rV];
            end
        end
    else
        return
    end
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
end
combinedContourV = {newContourV{:} contourV{:}};
ccContours{ccStruct, sliceNum} = combinedContourV;
stateS.contouringMetaDataS.ccSlice = sliceNum;
stateS.contouringMetaDataS.ccContours = ccContours;
stateS.contouringMetaDataS.contourMask = maskM;
