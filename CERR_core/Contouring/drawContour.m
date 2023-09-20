function varargout = drawContour(command, varargin)
%"drawContour"
%    Contouring callbacks for a single axis.
%
%JRA 6/23/04
%
%Usage:
%   To begin: drawContour('axis', hAxis);
%   To quit : drawContour('quit', hAxis);
%   Get Data: drawContour('getContours', hAxis);
%   preDraw : drawContour('setContours', hAxis, contour);
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


global stateS planC

switch command
    
    case 'axis'
        %Specify the handle of an axis for contouring, setup callbacks.
        hAxis = varargin{1};
        hFig  = get(hAxis, 'parent');
%         setappdata(hFig, 'contourAxisHandle', hAxis);
%         setappdata(hAxis, 'contourV', {});
%         setappdata(hAxis, 'contourV2', {});
        stateS.contouringMetaDataS.contourAxisHandle = hAxis;
        stateS.contouringMetaDataS.contourV = {};
        stateS.contouringMetaDataS.contourV2 = {};
        hSegment = line(0, 0, 'color', 'red', 'hittest', 'on', ...
            'parent', hAxis, 'ButtonDownFcn', 'drawContour(''contourClicked'')');
        stateS.contouringMetaDataS.hSegment = hSegment;

        noneMode(hAxis);
        %oldAxisProperties = get(hAxis); %Store these to return to original state. Think about this.
        %oldFigureProperties = get(hFig);


        if isfield(stateS.contouringMetaDataS,'oldBtnDown')
        oldBtnDown = stateS.contouringMetaDataS.oldBtnDown;
        else
        oldBtnDown = [];    
        end
        if isempty(oldBtnDown)
            oldBtnDown = get(hAxis, 'buttonDownFcn');
           stateS.contouringMetaDataS.oldBtnDown = oldBtnDown;
        end

        set(hAxis, 'buttonDownFcn', 'drawContour(''btnDownInAxis'')');
        set(hFig, 'WindowButtonUpFcn', 'drawContour(''btnUp'')');
        set(hFig, 'WindowButtonMotionFcn', 'drawContour(''motionInFigure'')');
        set(hFig, 'doublebuffer', 'on');

    case 'quit'
        %Removed passed axis from drawContour mode.
        hAxis = varargin{1};
        hFig  = get(hAxis, 'parent');
        if isfield(stateS.contouringMetaDataS,'hSgment')
        hSgment = stateS.contouringMetaDataS.hSgment;
        delete(hSgment)
        end
        if isfield(stateS.contouringMetaDataS,'hBall')
        ballH = stateS.contouringMetaDataS.hBall;
        delete(ballH)
        end
        noneMode(hAxis);
        stateS.contouringMetaDataS.contourV = [];
        stateS.contouringMetaDataS.contourV2 = [];
        stateS.contouringMetaDataS.segment = [];
        stateS.contouringMetaDataS.hSgment = [];
        stateS.contouringMetaDataS.hBall = [];
        stateS.contouringMetaDataS.clip = [];
        stateS.contouringMetaDataS.contourMask = [];
        stateS.contouringMetaDataS.clipToggles = [];

        drawAll(hAxis);
       
        if isfield(stateS.contouringMetaDataS,'oldBtnDown')
        set(hAxis, 'buttonDownFcn', stateS.contouringMetaDataS.oldBtnDown);
        else
        set(hAxis, 'buttonDownFcn',[]);    
        end
        stateS.contouringMetaDataS.oldBtnDown = [];
        set(hFig, 'WindowButtonUpFcn', '');
        set(hFig, 'doublebuffer', 'on');

    case 'getState'
        varargout{1} = stateS.contouringMetaDataS;

    case 'setState'
        hAxis = varargin{1};
        state = varargin{2};
        fNames = fieldnames(state)
        for i=1:length(fNames)
           stateS.contouringMetaDataS.(fNames{i}) = getfield(state, fNames{i});
        end
        drawAll(hAxis);

    case 'defaultMode'
        %Safely finish all currently edited stuff and return to nonemode.
        hAxis = varargin{1};
        closeSegment(hAxis);
        if isfield(stateS.contouringMetaDataS,'editNum')
        editNum = stateS.contouringMetaDataS.editNum;
        saveSegment(hAxis, editNum);
        end
        noneMode(hAxis);

    case 'editMode'
        %Force edit mode.
        hAxis = varargin{1};
        editMode(hAxis);
        
    case 'noneMode'
        % Force none mode
        hAxis = varargin{1};
        noneMode(hAxis);

    case 'editModeGE'
        %Force edit mode.
        hAxis = varargin{1};
        editModeGE(hAxis);
        
    case 'drawMode'
        %Force draw mode.
        hAxis = varargin{1};
        drawMode(hAxis);

    case 'drawBallMode'
        %Force draw mode.
        hAxis = varargin{1};
        drawBallMode(hAxis);

    case 'thresholdMode'
        %Force threshold mode.
        hAxis = varargin{1};
        thresholdMode(hAxis);
        
    case 'threshMode' % old callback, replaced by thresholdMode
        %Force threshold mode.
        hAxis = varargin{1};
        threshMode(hAxis);

    case 'reassignMode'
        %Force reassign mode.
        hAxis = varargin{1};
        reassignMode(hAxis);
        
        %AI 4/28/17
    case 'flexSelMode'
        %Force flex mode.
        hAxis = varargin{1};
        %Initialize
        drawBallMode(hAxis);
        %Reset mode to 'flex'
        stateS.contouringMetaDataS.mode = 'flexSelMode';
        if nargin>2
            stateS.contouringMetaDataS.forceErase = varargin{2};
        else
            stateS.contouringMetaDataS.forceErase = [];
        end
        
        
    case 'getContours'
        %Return all contours drawn on this axis, in axis coordinates.
        contourV = stateS.contouringMetaDataS.contourV;
        varargout{1} = contourV;

    case 'getContours2'
        %Return all contours2 drawn on this axis, in axis coordinates.
        contourV2 = stateS.contouringMetaDataS.contourV2;
        varargout{1} = contourV2;

    case 'setContours'
        %Wipe out all stored contours for this axis, and replace with
        %input contours.  Input is cell array of [Nx2] coordinates.
        hAxis = varargin{1};
        contourV = varargin{2};
        stateS.contouringMetaDataS.contourV = contourV;
        drawContour('setContourMask', hAxis, contourV);
        noneMode(hAxis);
        
    case 'setContourMask'
        contourV = varargin{2};
        sliceNum = stateS.contouringMetaDataS.ccSlice;
        numRows = stateS.contouringMetaDataS.numRows;
        numCols = stateS.contouringMetaDataS.numCols;
        scanNum = stateS.contouringMetaDataS.ccScanSet;
        segM = false(numRows, numCols);
        for i = 1:length(contourV)
            segment = contourV{i};
            if isempty(segment)
                continue;
            end
            [segRowV, segColV] = xytom(segment(:,1), segment(:,2), sliceNum, planC,scanNum);
            segRowV(segRowV<1) = 1;
            segColV(segColV<1) = 1;
            segRowV(segRowV>numRows) = numRows;
            segColV(segColV>numCols) = numCols;            
            segM = xor(segM, polyFill(numRows, numCols, segRowV, segColV));
        end
        stateS.contouringMetaDataS.contourMask = segM;

    case 'setContours2'
        %Wipe out all stored contours2 for this axis, and replace with
        %input contours.  Input is cell array of [Nx2] coordinates.
        hAxis = varargin{1};
        contourV2 = varargin{2};
        stateS.contouringMetaDataS.contourV2 = contourV2;
        noneMode(hAxis);
        
    case 'btnDownInAxis'
        
        % Set the current axis to be the contouring axis.
        stateS.currentAxis = stateS.contourAxis;
        
        %The action taken depends on current state.
        hAxis = gcbo;
        %         check if zoom is enabled
        %         val = get(stateS.handle.zoom, 'value');
        isZoomON = stateS.zoomState;
        isWindowingON = stateS.scanWindowState;
        if isZoomON || isWindowingON 
            sliceCallBack('axisclicked')
            return
        end        

        %Arg, temporary tie to slice viewer! Remove later.
        % APA: use 1st axis to draw contour
%         try
%             global stateS;
%             if ~isequal(stateS.handle.CERRAxis(stateS.handle.contourAxis), hAxis)
%                 sliceCallBack('Focus', hAxis);
%                 return;
%             end
%         end
        if stateS.handle.CERRAxis(stateS.contourAxis) ~= hAxis
            %sliceCallBack('Focus', stateS.handle.CERRAxis(stateS.contourAxis));
            %sliceCallBack('Focus', hAxis);
            return
        end
        
        hFig = get(gcbo, 'parent');
        clickType = get(hFig, 'SelectionType');
        if isfield(stateS.contouringMetaDataS,'lastClickType')
        lastClickType = stateS.contouringMetaDataS.lastClickType;
        else
        lastClickType = '';    
        end
        stateS.contouringMetaDataS.lastClickType = clickType;
        mode = stateS.contouringMetaDataS.mode;
        
        %Setup axis for motion.
        %set(hFig, 'WindowButtonMotionFcn', 'drawContour(''motionInFigure'')');
        stateS.contouringMetaDataS.isButtonDwn = 1;

        %ud = get(stateS.handle.controlFrame,'userdata');
        ud = stateS.handle.controlFrameUd ;
        
        %SWITCH OVER MODES.
        if strcmpi(mode,        'DRAW')
            if strcmpi(clickType, 'normal')
                %Left click: check if a segment has been selected and
                %switch to Edit mode.
                if stateS.contouringMetaDataS.segmentSelected

                    %set(ud.handles.modePopup,'value',2)
                    controlFrame('contour','selectMode',2) % Edit mode
                    
                    segNum = stateS.contouringMetaDataS.editNum;
                    editingMode(hAxis,segNum);
                    cP = get(hAxis, 'currentPoint');
                    addClipPoint(hAxis, cP(1,1), cP(1,2));
                    drawClip(hAxis);
                    stateS.contouringMetaDataS.segmentSelected = 0;
                    drawSegment(hAxis);
                                        
                    %setappdata(hAxis, 'mode','Edit');
                    return;
                end
                %Left click: enter drawing mode and begin new contour.
                drawingMode(hAxis);
                cP = get(hAxis, 'currentPoint');
                addPoint(hAxis, cP(1,1), cP(1,2));
                drawSegment(hAxis);
            elseif strcmpi(clickType, 'extend') || (strcmpi(clickType, 'open') && strcmpi(lastClickType, 'extend'))
            elseif strcmpi(clickType, 'alt')
            end
            
        elseif strcmpi(mode,        'DRAWBALL')
            if strcmpi(clickType, 'normal')
                %Left click+motion: add ball and begin new contour.
                drawingBallMode(hAxis);
                cP = get(hAxis, 'currentPoint');
                ballH = stateS.contouringMetaDataS.hBall;
                angM = stateS.contouringMetaDataS.angles;
                ballRadius = stateS.contouringMetaDataS.ballRadius;
                xV = cP(1,1) + ballRadius*angM(:,1);
                yV = cP(1,2) + ballRadius*angM(:,2);  
                set(ballH,'xData',xV,'ydata',yV,'visible','on')
                addBallPoints(hAxis, xV, yV);
                drawSegment(hAxis);    
                
            elseif strcmpi(clickType, 'extend') || (strcmpi(clickType, 'open') && strcmpi(lastClickType, 'extend'))
            elseif strcmpi(clickType, 'alt')
            end
            

        elseif strcmpi(mode,    'DRAWING')
            if strcmpi(clickType, 'normal')
                %Left click: add point to contour and redraw.
                cP = get(hAxis, 'currentPoint');
                addPoint(hAxis, cP(1,1), cP(1,2));
                drawSegment(hAxis);
            elseif strcmpi(clickType, 'extend') || (strcmpi(clickType, 'open') && strcmpi(lastClickType, 'extend'))            
            elseif strcmpi(clickType, 'alt')
                %Right click: close new contour and return to drawMode.
                set(hAxis,'UIContextMenu',[])
                contourV = stateS.contouringMetaDataS.contourV;
                segmentNum = length(contourV) + 1;
                closeSegment(hAxis);
                saveSegment(hAxis, segmentNum);                
                drawMode(hAxis);            
            end

        elseif strcmpi(mode,    'EDIT')
            if strcmpi(clickType, 'normal')  
                editNum = stateS.contouringMetaDataS.editNum;
                saveSegment(hAxis, editNum); % Save current segment
                drawMode(hAxis); % Set to draw mode on left-click
            elseif strcmpi(clickType, 'extend') || (strcmpi(clickType, 'open') && strcmpi(lastClickType, 'extend'))                                
            elseif strcmpi(clickType, 'alt')
                %Right click: cycle through clips if they exist.
                toggleClips(hAxis);
                drawSegment(hAxis);
            end

        elseif strcmpi(mode,    'EDITING')
            if strcmpi(clickType, 'normal')
            elseif strcmpi(clickType, 'extend') || (strcmpi(clickType, 'open') && strcmpi(lastClickType, 'extend'))
            elseif strcmpi(clickType, 'alt')
                % elseif strcmpi(clickType, 'open')
            end

        elseif strcmpi(mode,    'THRESH');
            if strcmpi(clickType, 'normal')
                %Left click: run threshold.
                cP = get(hAxis, 'currentPoint');
                getThresh(hAxis, cP(1,1), cP(1,2));

            elseif strcmpi(clickType, 'extend') || (strcmpi(clickType, 'open') && strcmpi(lastClickType, 'extend'))
%                 do nothing
            elseif strcmpi(clickType, 'alt')
%                 do nothing
                threshMode(hAxis);
            end
            
        elseif strcmpi(mode,    'THRESHOLD')
            if strcmpi(clickType, 'normal')
                %Left click: run threshold. run when button pushed
                %cP = get(hAxis, 'currentPoint');
                %setappdata(hAxis, 'thresholdStartPoint',cP);
                %getThresh(hAxis, cP(1,1), cP(1,2));                              

            elseif strcmpi(clickType, 'extend') || (strcmpi(clickType, 'open') && strcmpi(lastClickType, 'extend'))
%                 do nothing
            elseif strcmpi(clickType, 'alt')                                
                set(ud.handles.threshold, 'BackgroundColor',[0.8 0.8 0.8], 'Value', 0);                
                noneMode(hAxis);
            end
            
            %ADDED AI 4/28/17
        elseif strcmpi(mode,'FLEXSELMODE')
            if strcmpi(clickType, 'normal')
                %Initialize drawball
                drawingBallMode(hAxis);  
                ballH = stateS.contouringMetaDataS.hBall;
                angM = stateS.contouringMetaDataS.angles;
                ballRadius = stateS.contouringMetaDataS.ballRadius;
                
                %Set flex mode (eraserFlag)
                if ~isempty(stateS.contouringMetaDataS.forceErase)
                    eraserFlag = stateS.contouringMetaDataS.forceErase;
                    cP = getFlexPos(hAxis,eraserFlag);
                    stateS.contouringMetaDataS.forceErase = [];

                else
                    cP = getFlexPos(hAxis);
                end
                if isempty(cP)
                    return 
                end
                xV = cP(1,1) + ballRadius*angM(:,1);
                yV = cP(1,2) + ballRadius*angM(:,2);
                set(ballH,'xData',xV,'ydata',yV,'visible','on')
                addBallPoints(hAxis, xV, yV);
                drawSegment(hAxis);
                %Reset to flexMode
                stateS.contouringMetaDataS.mode = 'flexMode';
            end
            

        elseif strcmpi(mode,    'NONE')
            
        end
        
    case 'motionInFigure'
        %The action taken depends on current state.
        hFig        = stateS.handle.CERRSliceViewer;
        hAxis  = stateS.contouringMetaDataS.contourAxisHandle;
        clickType   = get(hFig, 'SelectionType');
        if isempty(hAxis)
            return
        end
        mode  = stateS.contouringMetaDataS.mode;
        if isfield(stateS.contouringMetaDataS,'isButtonDwn')
        isButtonDwn  = stateS.contouringMetaDataS.isButtonDwn;
        else
        isButtonDwn  = [];
        end
        
        % AI 5/1/17
        if isempty(isButtonDwn)
            isButtonDwn = 0;
        end
        

        if strcmpi(mode,        'DRAWING') && isButtonDwn
            if strcmpi(clickType, 'normal')
                %Left click+motion: add point and redraw.
                pointerLoc = get(0,'PointerLocation');
                cerrPos = get(stateS.handle.CERRSliceViewer,'position');
                axPos = get(hAxis,'position');
                xLim = get(hAxis,'xLim');
                yLim = get(hAxis,'yLim');                
                dx = (xLim(2) - xLim(1)) / (axPos(3));
                dy = (yLim(2) - yLim(1)) / (axPos(4));
                relativePos = pointerLoc - (cerrPos(1:2)+axPos(1:2));
                cP = [xLim(1)+relativePos(1)*dx yLim(1)+relativePos(2)*dy];
                %cP = get(hAxis, 'currentPoint')
                addPoint(hAxis, cP(1,1), cP(1,2));
                drawSegment(hAxis);
            end
            
        elseif strcmpi(mode,        'DRAW')
            pointerLoc = get(0,'PointerLocation');
            cerrPos = get(stateS.handle.CERRSliceViewer,'position');
            axPos = get(hAxis,'position');
            xLim = get(hAxis,'xLim');
            yLim = get(hAxis,'yLim');
            dx = (xLim(2) - xLim(1)) / (axPos(3));
            dy = (yLim(2) - yLim(1)) / (axPos(4));
            relativePos = pointerLoc - (cerrPos(1:2)+axPos(1:2));
            cP = [xLim(1)+relativePos(1)*dx yLim(1)+relativePos(2)*dy];            
            %cP = get(hAxis, 'currentPoint');
            x = cP(1,1);
            y = cP(1,2);
            hContourV = stateS.contouringMetaDataS.hContour;
            set(hContourV,'lineWidth',1.5)
            stateS.contouringMetaDataS.segmentSelected = 0;
            for i = 1:length(hContourV)
                xData = get(hContourV(i),'XData');
                yData = get(hContourV(i),'YData');
                if any((xData - x).^2 + (yData - y).^2 < 0.125)
                    set(hContourV(i),'lineWidth',3)
                    % If in the pencil mode and mouse-up, then toggle to "edit" mode if
                    % user selects a segment
                    %%% getappdata(hAxis, 'mode');
                    stateS.contouringMetaDataS.segmentSelected = 1;
                    seg = [xData(:) yData(:)];
                    stateS.contouringMetaDataS.segment = seg;
                    stateS.contouringMetaDataS.editNum = i;
                    %setappdata(hAxis,'clipToggles',{seg,seg,seg})
                    %setappdata(hAxis,'clipnum',1)                    
                    %drawSegment(hAxis)
                    return;
                end
            end            
            
        elseif strcmpi(mode,        'DRAWINGBALL')
            cP = get(hAxis, 'currentPoint');
            ballH = stateS.contouringMetaDataS.hBall;
            angM = stateS.contouringMetaDataS.angles;
            ballRadius = stateS.contouringMetaDataS.ballRadius;
            xV = cP(1,1) + ballRadius*angM(:,1);
            yV = cP(1,2) + ballRadius*angM(:,2);
            set(ballH,'xData',xV,'ydata',yV,'visible','on')
            
            if strcmpi(clickType, 'normal') && isButtonDwn
                %Left click+motion: add point and redraw.
                addBallPoints(hAxis, xV, yV);
                %drawSegment(hAxis);
                drawContourV(hAxis);
            end
            
            
        elseif strcmpi(mode,        'DRAWBALL')
            %Left click+motion: add point and redraw.
            cP = get(hAxis, 'currentPoint');
            ballH = stateS.contouringMetaDataS.hBall;
            angM = stateS.contouringMetaDataS.angles;
            ballRadius = stateS.contouringMetaDataS.ballRadius;
            xV = cP(1,1) + ballRadius*angM(:,1);
                yV = cP(1,2) + ballRadius*angM(:,2);                
                set(ballH,'xData',xV,'ydata',yV,'visible','on')

        
        elseif strcmpi(mode,    'EDITING') && isButtonDwn
            if strcmpi(clickType, 'normal')
                %Left click+motion: add point to clip and redraw.
                cP = get(hAxis, 'currentPoint');
                addClipPoint(hAxis, cP(1,1), cP(1,2));
                drawClip(hAxis);

                % APA 03/02/2016
                %connectClip(hAxis);
                %toggleClips(hAxis);
                %drawSegment(hAxis);
                % APA 03/02/2016 ends
                
            end
            
        elseif strcmpi(mode,    'EDITINGGE')
            if strcmpi(clickType, 'normal')
                %Left click+motion: add point to clip and redraw.
                cP = get(hAxis, 'currentPoint');
                
                % Find the closest point on the segment to the current mouse click
                % Contour points for the selected segment
                segment  = stateS.contouringMetaDataS.segment;
                xV = segment(:,1);
                yV = segment(:,2);
                
                x = cP(1,1);
                y = cP(1,2);
                
                distM = sepsq([xV(:) yV(:)]', [x; y]);
                [jnk, indMin] = min(distM);
                indMin0 = indMin;
                
                % Get indices on segment that are +-3 indices away from current point
                indicesAll = 1:length(xV);
                indicesAll = [indicesAll indicesAll];
                numVoxels1 = 30;
                numVoxels2 = 25;
                if indMin-numVoxels1 <= 0
                    indMin = indMin + length(xV);
                end
                indToFit = indicesAll([indMin-numVoxels1:indMin-numVoxels2, indMin+numVoxels2:indMin+numVoxels1]);
                xFit = xV([indToFit indMin0]);
                yFit = yV([indToFit indMin0]);
                P = polyfit(xFit,yFit,2);
                yNew = yV;
                xNew = xV;
                yNew(indicesAll([indMin-numVoxels2-1:indMin-1, indMin+1:indMin+numVoxels2-1])) = polyval(P,xV(indicesAll([indMin-numVoxels2-1:indMin-1, indMin+1:indMin+numVoxels2-1])));
                
                xNew(indMin0) = x;
                yNew(indMin0) = y;
                
                segmentNew(:,1) = xNew(:);
                segmentNew(:,2) = yNew(:);
                
                %addClipPoint(hAxis, cP(1,1), cP(1,2));
                %drawClip(hAxis);
                
                %xV() =
                %yV() =
                %contourV{segmentNum} = contourV;
                
                stateS.contouringMetaDataS.segment = segmentNew;

                drawSegment(hAxis);
            end
            
            
        elseif strcmpi(mode, 'FLEXSELMODE')
            cP = get(hAxis, 'currentPoint');
            ballH = stateS.contouringMetaDataS.hBall;
            angM = stateS.contouringMetaDataS.angles;
            ballRadius = stateS.contouringMetaDataS.ballRadius;
            xV = cP(1,1) + ballRadius*angM(:,1);
            yV = cP(1,2) + ballRadius*angM(:,2);
            set(ballH,'xData',xV,'ydata',yV,'visible','on')
            
            
            elseif strcmpi(mode,    'FLEXMODE')
                %cP = get(hAxis, 'currentPoint');
                cP = getFlexPos(hAxis);
                if isempty(cP)
                    return
                end
                ballH = stateS.contouringMetaDataS.hBall;
                angM = stateS.contouringMetaDataS.angles;
                ballRadius = stateS.contouringMetaDataS.ballRadius;
                xV = cP(1,1) + ballRadius*angM(:,1);
                yV = cP(1,2) + ballRadius*angM(:,2);
                set(ballH,'xData',xV,'ydata',yV,'visible','on')
                if strcmpi(clickType, 'normal') && isButtonDwn
                    %Left click+motion: add point and redraw.
                    addBallPoints(hAxis, xV, yV);
                    drawContourV(hAxis);
                end
                
        end
        
    case 'btnUp'
        %The action taken depends on current state.        
        hFig = gcbo;      
        hAxis = stateS.contouringMetaDataS.contourAxisHandle;
        clickType = get(hFig, 'SelectionType');
        mode = stateS.contouringMetaDataS.mode;
        
        if strcmpi(mode, 'EDITING')
            connectClip(hAxis);       
            editMode(hAxis);
            toggleClips(hAxis);
            drawSegment(hAxis);  
        elseif strcmpi(mode, 'DRAWING')
            hFig  = get(hAxis, 'parent');
            hMenu = uicontextmenu('Callback', 'CERRAxisMenu(''update_menu'')', 'userdata', hAxis, 'Tag', 'CERRAxisMenu', 'parent', hFig);
            set(hAxis, 'UIContextMenu', hMenu);   
        elseif strcmpi(mode, 'DRAWINGBALL')
            %ballH = getappdata(hAxis, 'hBall');
            ballH = stateS.contouringMetaDataS.hBall;
            %set(ballH,'visible','off')
            %ballH = getappdata(hAxis, 'hBall');
            %set(ballH,'visible','off')
        elseif strcmpi(mode, 'THRESH_todelete')
            stateS.contouringMetaDataS.minLevel = [];
            stateS.contouringMetaDataS.maxLevel = [];
            hFig  = get(hAxis, 'parent');
            hMenu = uicontextmenu('Callback', 'CERRAxisMenu(''update_menu'')', 'userdata', hAxis, 'Tag', 'CERRAxisMenu', 'parent', hFig);
            set(hAxis, 'UIContextMenu', hMenu);               
        end              
        %set(hFig, 'WindowButtonMotionFcn', '');
        stateS.contouringMetaDataS.isButtonDwn = 0;


    case 'contourClicked'
        hLine = gcbo;
        % hAxis = get(gcbo, 'parent');
        hAxis = stateS.handle.CERRAxis(stateS.contourAxis);
        hFig = get(hAxis, 'parent');
        clickType = get(hFig, 'SelectionType');
        lastClickType = stateS.contouringMetaDataS.lastClickType;
        stateS.contouringMetaDataS.lastClickType = clickType;
        mode = stateS.contouringMetaDataS.mode;

        %Setup axis for motion.
        set(hFig, 'WindowButtonMotionFcn', 'drawContour(''motionInFigure'')');

        %None Mode
        if strcmpi(mode, 'none')

            %Edit mode
        elseif strcmpi(mode,    'EDIT')
            if strcmpi(clickType, 'normal')
                %Left click: select this contour for editing and commence.
                contourV = stateS.contouringMetaDataS.contourV;
                segmentNum = stateS.contouringMetaDataS.editNum;
                segment = stateS.contouringMetaDataS.segment;
                if ~isempty(segment)
                    contourV{segmentNum} = segment;
                    stateS.contouringMetaDataS.contourV = contourV; 
                    stateS.contouringMetaDataS.segment = segment;
                end

                if isequal(stateS.contouringMetaDataS.segment,gcbo)
                    segmentNum = stateS.contouringMetaDataS.editNum;
                else
                    segmentNum = get(gcbo, 'userdata');
                end

                editingMode(hAxis, segmentNum);
                cP = get(hAxis, 'currentPoint');
                addClipPoint(hAxis, cP(1,1), cP(1,2));
                drawClip(hAxis);
                
            elseif strcmpi(clickType, 'alt')
                %nothing but think about cycling clips here?
            end
            
            %Edit mode GE
        elseif strcmpi(mode,    'EDITGE')
            %Left click: select this contour for editing and commence.
            contourV = stateS.contouringMetaDataS.contourV;
            segmentNum = stateS.contouringMetaDataS.editNum;
            segment = stateS.contouringMetaDataS.segment;
            if ~isempty(segment)
                contourV{segmentNum} = segment;
                stateS.contouringMetaDataS.contourV = contourV;
                stateS.contouringMetaDataS.segment = segment;

            end
            
            if isequal(stateS.contouringMetaDataS.hSegment,gcbo)
                segmentNum = stateS.contouringMetaDataS.editNum;
            else
                segmentNum = get(gcbo, 'userdata');
            end
            
            editingModeGE(hAxis, segmentNum);   
            
            segment = stateS.contouringMetaDataS.segment;
            distM = sepsq(segment',segment');
            
            % Make segment-resolution fine
            for i = 1:length(segment(:,1))-1
                P = polyfit(segment(i:i+1,1),segment(i:i+1,2),1);
                N = distM(i,i+1)/0.2;
                N = ceil(N);
                xNewC{i} = [];
                yNewC{i} = [];
                if N > 1
                    xNew = linspace(segment(i,1),segment(i+1,1),N);
                    yNew = polyval(P,xNew);
                    xNewC{i} = xNew;
                    yNewC{i} = yNew;
                end
            end
            
            segmentNew = [];
            indStart = 1;
            for i = 1:length(xNewC)                
               if ~isempty(xNewC{i})
                   segmentNew(indStart:indStart+length(xNewC{i})-1,1) = xNewC{i};
                   segmentNew(indStart:indStart+length(yNewC{i})-1,2) = yNewC{i};
                   indStart = indStart + length(yNewC{i});
               else
                   segmentNew(indStart,:) = segment(i,:);
                   indStart = indStart + 1;
               end                          
            end
            
            stateS.contouringMetaDataS.segment = segmentNew;
            
            %cP = get(hAxis, 'currentPoint');
            
            %setappdata(hAxis, 'contourV', contourV);
            
            drawSegment(hAxis);            

            
            
        elseif strcmpi(mode,    'REASSIGN')
            contourV = stateS.contouringMetaDataS.contourV;
            contourV2 = stateS.contouringMetaDataS.contourV2;
            contourUD = get(gcbo, 'userdata');
            if iscell(contourUD)
                contourV{end+1} = contourV2{contourUD{2}};
                contourV2{contourUD{2}} = [];
            else
                contourV2{end+1} = contourV{contourUD};
                contourV{contourUD} = [];
            end
            stateS.contouringMetaDataS.contourV = contourV;
            stateS.contouringMetaDataS.contourV2 = contourV2;
            reassignMode(hAxis);
        end

    case 'deleteSegment'
        %Delete selected segment if relevant and if in edit mode.
        hAxis = varargin{1};
        mode = stateS.contouringMetaDataS.mode;
        if strcmpi(mode, 'drawing')
            delSegment(hAxis);
            drawMode(hAxis);
        elseif strcmpi(mode, 'edit')
            delSegment(hAxis);
            editMode(hAxis);
        elseif strcmpi(mode, 'thresh')
            delSegment(hAxis);
            threshMode(hAxis);
        end
        
    case 'deleteAllSegments'
        hAxis = varargin{1};
        mode = stateS.contouringMetaDataS.mode;
        if strcmpi(mode,'threshold')
            ud = stateS.handle.controlFrameUd ;
            set(ud.handles.threshold,'Value',0,'BackgroundColor',[0.8 0.8 0.8]);
        end
        delAllSegments(hAxis)            
        
end


%MODE MANAGEMENT
function drawMode(hAxis)
%Next mouse click starts a new contour and goes to drawing mode.
global stateS
contourV = stateS.contouringMetaDataS.contourV;
segment = stateS.contouringMetaDataS.segment;
stateS.contouringMetaDataS.segment = [];

if ~isempty(segment)
    editNum = getappdata(hAxis, 'editNum');
    contourV{editNum} = segment;
    stateS.contouringMetaDataS.contourV = contourV;
end
%APA: mode is set in contourControl.m
stateS.contouringMetaDataS.mode =  'draw';
stateS.contouringMetaDataS.ccMode =  'draw';

editNum = length(contourV) + 1;
stateS.contouringMetaDataS.editNum =  editNum;
hContour = stateS.contouringMetaDataS.hContour;
set(hContour, 'hittest', 'off');
drawSegment(hAxis);
drawContourV(hAxis);

function drawBallMode(hAxis)
%Next mouse click starts a new contour and goes to drawing mode.
global stateS
contourV = stateS.contouringMetaDataS.contourV;
segment = stateS.contouringMetaDataS.segment;
stateS.contouringMetaDataS.segment =  [];
if ~isempty(segment)
    editNum = stateS.contouringMetaDataS.editNum;
    contourV{editNum} = segment;
    stateS.contouringMetaDataS.contourV = contourV;

end
%APA: mode is set in contourControl.m
stateS.contouringMetaDataS.mode = 'drawBall';
editNum = length(contourV) + 1;
stateS.contouringMetaDataS.editNum = editNum;
hContour = stateS.contouringMetaDataS.hContour;
set(hContour, 'hittest', 'off');
drawSegment(hAxis);
drawContourV(hAxis);

function drawingMode(hAxis)
global stateS
%While the button is down or for each click, points are added
%to the contour being drawn.  Right click exists drawing mode.
stateS.contouringMetaDataS.mode = 'drawing';
stateS.contouringMetaDataS.segment = [];


function drawingBallMode(hAxis)
global stateS
%While the button is down or for each click, points are added
%to the contour being drawn.  Right click exists drawing mode.
stateS.contouringMetaDataS.mode = 'drawingBall';
ballH = stateS.contouringMetaDataS.hBall;
set(ballH,'visible','on')
stateS.contouringMetaDataS.segment = [];

function reassignMode(hAxis)
%Draws all contours on the slice and makes them selectable.  When a
%contour is clicked, it is moved to the other contour's list.
%setappdata(hAxis, 'mode', 'reassign');
global stateS
stateS.contouringMetaDataS.mode = 'reassign';
drawContourV(hAxis);
drawContourV2(hAxis);
hContour = stateS.contouringMetaDataS.hContour;
hContour2 = stateS.contouringMetaDataS.hContour2;
set(hContour, 'hittest', 'on');
set(hContour2, 'hittest', 'on');

function editMode(hAxis)
%Draws all contours on the slice and makes them selectable.  When a
%contour is clicked, goes to editingMode and begins drawing a clip.
%If a previous clip has been drawn, right clicking toggles clips.
global stateS
stateS.contouringMetaDataS.mode = 'edit';
drawContourV(hAxis);
drawSegment(hAxis);
stateS.contouringMetaDataS.clip = [];
drawClip(hAxis);
hContour = stateS.contouringMetaDataS.hContour;
set(hContour, 'hittest', 'on');

function editModeGE(hAxis)
%Draws all contours on the slice and makes them selectable.  When a
%contour is clicked, goes to editingMode and begins drawing a clip.
%If a previous clip has been drawn, right clicking toggles clips.
global stateS
%setappdata(hAxis, 'mode', 'editGE');
stateS.contouringMetaDataS.mode = 'editGE';
drawContourV(hAxis);
drawSegment(hAxis);
stateS.contouringMetaDataS.clip = [];
drawClip(hAxis);
hContour = stateS.contouringMetaDataS.hContour;
set(hContour, 'hittest', 'on');


function editingMode(hAxis, segmentNum)
%While the button is down, points are added to the clip being drawn.
%Lifting the mouse button goes to Edit/SelectingClip mode.
global stateS

stateS.contouringMetaDataS.mode = 'editing';
stateS.contouringMetaDataS.clipToggles = {};
contourV = stateS.contouringMetaDataS.contourV;
segment = contourV{segmentNum};
contourV{segmentNum} = [];
stateS.contouringMetaDataS.contourV = contourV;
stateS.contouringMetaDataS.segment = segment;
stateS.contouringMetaDataS.editNum = segmentNum;
%         drawContourV(hAxis);
%         drawSegment(hAxis);  %Considering brining these back, changes
%         color dynamically.

function editingModeGE(hAxis, segmentNum)
%While the button is down, points are added to the clip being drawn.
%Lifting the mouse button goes to Edit/SelectingClip mode.
global stateS
stateS.contouringMetaDataS.mode = 'editingGE';
stateS.contouringMetaDataS.clipToggles = {};
contourV = stateS.contouringMetaDataS.contourV;
segment = contourV{segmentNum};
contourV{segmentNum} = [];
stateS.contouringMetaDataS.contourV = contourV;
stateS.contouringMetaDataS.segment = segment;
stateS.contouringMetaDataS.editNum = segmentNum;
%         drawContourV(hAxis);
%         drawSegment(hAxis);  %Considering brining these back, changes
%         color dynamically.

function noneMode(hAxis)
% 	%Set noneMode
global stateS
stateS.contouringMetaDataS.mode = 'none';
stateS.contouringMetaDataS.ccMode = [];
drawContourV(hAxis);
drawContourV2(hAxis);
drawSegment(hAxis);
hContour = stateS.contouringMetaDataS.hContour;
set(hContour, 'hittest', 'on');
clearUndoInfo(hAxis);
if isfield(stateS.contouringMetaDataS,'hBall')
    hBall = stateS.contouringMetaDataS.hBall;
    if ishandle(hBall)
        delete(hBall)
        stateS.contouringMetaDataS.hBall = [];
    end
end

function threshMode(hAxis) % old function, replaced by thresholdMode
%Set threshMode
global stateS
contourV = stateS.contouringMetaDataS.contourV;
segment = stateS.contouringMetaDataS.segment;
stateS.contouringMetaDataS.segment = [];
if ~isempty(segment)
    editNum = stateS.contouringMetaDataS.editNum;
    contourV{editNum} = segment;
    stateS.contouringMetaDataS.contourV = contourV;
end
stateS.contouringMetaDataS.mode = 'thresh';
editNum = length(contourV) + 1;
stateS.contouringMetaDataS.editNum = editNum;
hContour = getappdata(hAxis, 'hContour');
hContour = stateS.contouringMetaDataS.hContour;
set(hContour, 'hittest', 'off');
drawSegment(hAxis);
drawContourV(hAxis);

function thresholdMode(hAxis)
%Set thresholdMode
global stateS
contourV = stateS.contouringMetaDataS.contourV;
segment = stateS.contouringMetaDataS.segment;
stateS.contouringMetaDataS.segment = [];
if ~isempty(segment)
    editNum = stateS.contouringMetaDataS.editNum;
    contourV{editNum} = segment;
    stateS.contouringMetaDataS.contourV = contourV;
end
stateS.contouringMetaDataS.mode = 'threshold';
editNum = 1;
stateS.contouringMetaDataS.editNum = editNum;
hContour = stateS.contouringMetaDataS.hContour;
set(hContour, 'hittest', 'off');
drawSegment(hAxis);
drawContourV(hAxis);
% Run the activecontour segmentation on clicking the Threshold button
getThreshold(hAxis);


%AI 5/1/17
%Get current point
function cP = getFlexPos(hAxis,eraserFlag)
global planC
global stateS
%Get current mask
maskM = stateS.contouringMetaDataS.contourMask;
%Get current point
cP = get(hAxis, 'currentPoint');
scanSet = getAxisInfo(stateS.handle.CERRAxis(1),'scanSets');
[imSizX,imSizY,~] = size(getScanArray(scanSet,planC));
[r, c, ~] = xyztom(cP(1,1),cP(1,2),0, scanSet, planC);
r = round(r);
c = round(c);
if r < 1 || r > imSizY || c < 1 || c > imSizX
    cP = [];
    return;
end
%Set brush/erase mode
if ~exist('eraserFlag','var')
if sum(maskM(:))==0 || maskM(r,c)==1
    stateS.contouringMetaDataS.eraseFlag = 0;
else
    stateS.contouringMetaDataS.eraseFlag = 1;
end
else
   stateS.contouringMetaDataS.eraseFlag = eraserFlag;
end




%     function freezeMode(hAxis)
% 	%Freezes all callbacks, button down functions etc. Use in
% 	%conjunction with state saving and returning in order to transfer
% 	%control of axis to another routine, and to return control to this.




%CONTOURING FUNCTIONS
function addPoint(hAxis, x, y)
%Add a point to the existing segment, in axis coordinates.
global stateS
segment = stateS.contouringMetaDataS.segment;
segment = [segment;[x y]];
stateS.contouringMetaDataS.segment = segment;


function addBallPoints(hAxis,xV,yV)

global planC stateS
%indexS = planC{end};

%Add a ball points to the existing segment, in axis coordinates.
contoursC = stateS.contouringMetaDataS.contourV;
eraseFlag = stateS.contouringMetaDataS.eraseFlag;
if ~isempty(contoursC)
    %     numRows = planC{indexS.scan}(scanNum).scanInfo(sliceNum).sizeOfDimension1;
    %     numCols = planC{indexS.scan}(scanNum).scanInfo(sliceNum).sizeOfDimension2;
    %     segM = false(numRows, numCols);
    %     for i = 1:length(contoursC)
    %         segment = contoursC{i};
    %         if isempty(segment)
    %             continue;
    %         end
    %         [segRowV, segColV] = xytom(segment(:,1), segment(:,2), sliceNum, planC,scanNum);
    %         [rowV, colV] = xytom(xV, yV, sliceNum, planC,scanNum);
    %         rowV(rowV<1) = 1;
    %         colV(colV<1) = 1;
    %         rowV(rowV>numRows) = numRows;
    %         colV(colV>numCols) = numCols;
    %         segRowV(segRowV<1) = 1;
    %         segColV(segColV<1) = 1;
    %         segRowV(segRowV>numRows) = numRows;
    %         segColV(segColV>numCols) = numCols;
    %
    %         segM = xor(segM, polyFill(numRows, numCols, segRowV, segColV));
    %     end
    sliceNum = stateS.contouringMetaDataS.ccSlice;
    scanNum = stateS.contouringMetaDataS.ccScanSet;
    segM = stateS.contouringMetaDataS.contourMask;
    numRows = stateS.contouringMetaDataS.numRows;
    numCols = stateS.contouringMetaDataS.numCols;

    [rowV, colV] = xytom(xV, yV, sliceNum, planC,scanNum);
    rowV(rowV<1) = 1;
    colV(colV<1) = 1;
    rowV(rowV>numRows) = numRows;
    colV(colV>numCols) = numCols;    
    ballM = polyFill(numRows, numCols, rowV, colV);
    if ~eraseFlag
        maskM = segM | ballM; % paint
    else
        maskM = double(~ballM & segM); % erase
    end
    stateS.contouringMetaDataS.contourMask = maskM;
    % maskM = double(xor(segM & ballM, segM)); % erase        
    contourData = contourc(double(maskM), [.5 .5]);
    len = size(contourData,2);
    currPt = 1;
    newContoursC = {};
    while currPt < len
        numPoints = contourData(2,currPt);
        xyData = contourData(:,currPt+1:numPoints+currPt)';
        cV = xyData(:,1);
        rV = xyData(:,2);
        uniflag = 0;
        [xSegV,ySegV,~] = mtoxyz(rV,cV,sliceNum,scanNum,planC,uniflag);
        
        %setappdata(hAxis, 'segment', [xSegV(:) ySegV(:)])
        
        newContoursC{end+1} = [xSegV(:) ySegV(:)];
        currPt = numPoints + currPt + 1;
    end
    stateS.contouringMetaDataS.contourV = newContoursC;

else
    if ~eraseFlag
        stateS.contouringMetaDataS.contourV = {[xV(:) yV(:)]};
    else
        stateS.contouringMetaDataS.contourV = {};
    end
end
%segment = [segment;[x y]];
%setappdata(hAxis, 'segment', segment);


function closeSegment(hAxis)
%Close the current segment by linking the first and last points.
global stateS
segment = stateS.contouringMetaDataS.segment;
if ~isempty(segment)
    firstPt = segment(1,:);
    segment = [segment;[firstPt]];
    stateS.contouringMetaDataS.segment = segment;
end

function saveSegment(hAxis, segmentNum)
%Save the current segment to the contourV, and exit drawmode.
global stateS
segment = stateS.contouringMetaDataS.segment;
if ~isempty(segment)
    contourV = stateS.contouringMetaDataS.contourV;
    contourV{segmentNum} = segment;
    stateS.contouringMetaDataS.contourV = contourV;
    drawContour('setContourMask', hAxis, contourV);
    stateS.contouringMetaDataS.segment = [];

end

function delSegment(hAxis)
%Delete the segment being edited.
global stateS
stateS.contouringMetaDataS.segment = [];
drawAll(hAxis);

function delAllSegments(hAxis)
global stateS
stateS.contouringMetaDataS.contourV = {};
stateS.contouringMetaDataS.segment = [];
maskM = stateS.contouringMetaDataS.contourMask;
stateS.contouringMetaDataS.contourMask = 0*maskM;
hContour = stateS.contouringMetaDataS.hContour;
toDelV = ishandle(hContour);
delete(hContour(toDelV))
stateS.contouringMetaDataS.editNum = 1;

% Update the ccContours
ccContours = stateS.contouringMetaDataS.ccContours;
ccSlice = stateS.contouringMetaDataS.ccSlice;
ccStruct = stateS.contouringMetaDataS.ccStruct;

if isempty(ccStruct)
    warning('contour name not initialized');
    return
end
ccContours{ccStruct, ccSlice} = {};
stateS.contouringMetaDataS.ccContours = ccContours;
drawAll(hAxis);


%CLIPOUT FUNCTIONS
function addClipPoint(hAxis, x, y)
%Add a point to the existing clipout line, in axis coordinates.
global stateS
clip = stateS.contouringMetaDataS.clip;
clip = [clip;[x y]];
stateS.contouringMetaDataS.clip = clip;

function connectClip(hAxis)
%Connect the drawn clip to the existing segment, generating 3
%combinations of clip and old segment.
global stateS
clip = stateS.contouringMetaDataS.clip;
segment = stateS.contouringMetaDataS.segment;
if ~isempty(segment)
    startCoord = clip(1,:);
    endCoord = clip(end,:);
    [jnk, startPt] = min(sepsq(segment', startCoord'));
    [jnk, endPt] = min(sepsq(segment', endCoord'));
    %             if ~isequal(startPt, endPt)
    part1 = segment(min(startPt, endPt):max(startPt, endPt), :);
    part2 = [segment(max(startPt, endPt):end,:);segment(1:min(startPt, endPt),:)];
    stateS.contouringMetaDataS.clipnum = 2;
    if startPt > endPt
        clipToggles{1} = [clip;part1;clip(1,:)];
        clipToggles{2} = [clip;flipud(part2);clip(1,:)];
        clipToggles{3} = segment;
    elseif startPt < endPt
        clipToggles{1} = [clip;flipud(part1);clip(1,:)];
        clipToggles{2} = [clip;part2;clip(1,:)];
        clipToggles{3} = segment;
    else
        clipToggles{1} = [clip;part1;clip(1,:)];
        clipToggles{2} = [clip;flipud(part2);clip(1,:)];
        clipToggles{3} = segment;
    end

    curveLength1 = 0;
    for i = 1:size(clipToggles{1},1) - 1
        curveLength1 = curveLength1 + sepsq(clipToggles{1}(i,:)', clipToggles{1}(i+1,:)');
    end

    curveLength2 = 0;
    for i = 1:size(clipToggles{2},1) - 1
        curveLength2 = curveLength2 + sepsq(clipToggles{2}(i,:)', clipToggles{2}(i+1,:)');
    end

    if curveLength2 > curveLength1
        tmp = clipToggles{1};
        clipToggles{1} = clipToggles{2};
        clipToggles{2} = tmp;
    end

    
    stateS.contouringMetaDataS.clipToggles = clipToggles;

else
    return;
end

function toggleClips(hAxis)
%Toggle between outcome clips.
global stateS
clipNum = stateS.contouringMetaDataS.clipnum;
clipNum = mod(clipNum + 1,3);
stateS.contouringMetaDataS.clipnum = clipNum;
clipToggles = stateS.contouringMetaDataS.clipToggles;
%segment = stateS.contouringMetaDataS.segment;
clip = clipToggles{clipNum + 1};
stateS.contouringMetaDataS.segment = clip;


%DRAWING FUNCTIONS
function drawContourV(hAxis) %%Maybe set line hittest here?? based on mode??
%Redraw the contour associated with hAxis.
global stateS
if isfield(stateS.contouringMetaDataS,'hContour')
hContour = stateS.contouringMetaDataS.hContour;
toDelete = ishandle(hContour);
delete(hContour(toDelete));
end
hContour = [];

contourV = stateS.contouringMetaDataS.contourV;

if ~isempty(contourV)
    for i = 1:length(contourV)
        segment = contourV{i};
        if ~isempty(segment)
            hContour = [hContour, line(segment(:,1), segment(:,2), ...
                'color', 'blue', 'linewidth', 1.5, 'hittest', 'off',...
                'userdata', i, 'ButtonDownFcn',...
                'drawContour(''contourClicked'')', 'parent', hAxis)];
%             hContour = [hContour, ...
%                 fill(segment(:,1), segment(:,2), 'blue', 'linewidth', 1.5,...
%                 'facealpha',0.2, 'hittest', 'off', 'userdata', i, ...
%                 'ButtonDownFcn', 'drawContour(''contourClicked'')', ...
%                 'EdgeColor', 'blue', 'LineWidth', 1.5, 'parent', hAxis)];
        end
    end
    stateS.contouringMetaDataS.hContour = hContour;

else
    stateS.contouringMetaDataS.hContour = [];

end

function drawContourV2(hAxis) %%Maybe set line hittest here?? based on mode??
%Redraw the contour associated with hAxis.
global stateS

if isfield(stateS.contouringMetaDataS,'hContour2')
hContour2 = stateS.contouringMetaDataS.hContour2;
toDelete = ishandle(hContour2);
delete(hContour2(toDelete));
end
hContour2 = [];

contourV2 = stateS.contouringMetaDataS.contourV2;
if ~isempty(contourV2)
    for i = 1:length(contourV2)
        segment = contourV2{i};
        if ~isempty(segment)
            hContour2 = [hContour2, line(segment(:,1), segment(:,2), 'color', 'green', 'linewidth', 1.5, 'hittest', 'off', 'erasemode', 'normal', 'userdata', {2,i}, 'ButtonDownFcn', 'drawContour(''contourClicked'')', 'parent', hAxis)];
        end
    end
    stateS.contouringMetaDataS.hContour2 = hContour2;
    
else
    stateS.contouringMetaDataS.hContour2 = [];

end

function drawSegment(hAxis)
%Redraw the current segment associated with hAxis
global stateS
hSegment = stateS.contouringMetaDataS.hSegment;
mode = stateS.contouringMetaDataS.mode;
%try
%    delete(hSegment);
%end
%hSegment = [];

if isfield(stateS.contouringMetaDataS,'segment')
    segment = stateS.contouringMetaDataS.segment;
else
    segment = [];
end

if ~isempty(segment) && (strcmpi(mode, 'drawing') || strcmpi(mode, 'draw'))
    %hSegment = line(segment(:,1), segment(:,2), 'color', 'red', 'hittest', 'off', 'parent', hAxis, 'ButtonDownFcn', 'drawContour(''contourClicked'')');
    %setappdata(hAxis, 'hSegment', hSegment);
    set(hSegment,'XData',segment(:,1),'YData',segment(:,2), 'hittest', 'off')    
elseif ~isempty(segment)
    %hSegment = line(segment(:,1), segment(:,2), 'color', 'red', 'hittest', 'on', 'parent', hAxis, 'ButtonDownFcn', 'drawContour(''contourClicked'')');
    %setappdata(hAxis, 'hSegment', hSegment);
    set(hSegment,'XData',segment(:,1),'YData',segment(:,2), 'hittest', 'on')    
else
    %setappdata(hAxis, 'hSegment', []);
    if ishandle(hSegment)
        set(hSegment,'XData',0,'YData',0, 'hittest', 'off')
    end
end

function drawClip(hAxis)
%Redraw the current clipout segment associated with hAxis.

global stateS

mode = stateS.contouringMetaDataS.mode;
if isfield(stateS.contouringMetaDataS,'hClip')
    hClip = stateS.contouringMetaDataS.hClip;
    if ishandle(hClip)
        delete(hClip);
    end
end
hClip = [];

%clip = getappdata(hAxis, 'clip');
clip = stateS.contouringMetaDataS.clip; 
if ~isempty(clip) && strcmpi(mode, 'editing')
    hClip = line(clip(:,1), clip(:,2), 'color', 'red', 'hittest', 'off', 'parent', hAxis);
    stateS.contouringMetaDataS.hClip = hClip;
    
elseif ~isempty(clip)
    hClip = line(clip(:,1), clip(:,2), 'color', 'red', 'hittest', 'off', 'parent', hAxis);
    stateS.contouringMetaDataS.hClip = hClip;
    
else
    stateS.contouringMetaDataS.hClip = [];

end

function drawAll(hAxis)
%Redraw all existing contour graphics.
drawContourV(hAxis);
drawContourV2(hAxis);
drawSegment(hAxis);
drawClip(hAxis);

%THRESHOLDING FUNCTIONS
function getThreshold(hAxis)
%Sets the current segment to the contour of connected region x,y
global planC
global stateS
% indexS = planC{end};
% [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.currentScan));
%[scanSet,coord] = getAxisInfo(stateS.handle.CERRAxis(stateS.contourAxis),'scanSets','coord');
% [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
% [r, c, jnk] = xyztom(x,y,zeros(size(x)), planC);
% [r, c, jnk] = xyztom(x,y,zeros(size(x)), scanSet, planC);
% r = round(r);
% c = round(c);
% if r < 1 || r > length(yV) || c < 1 || c > length(xV)
%     return;
% end

imgM = stateS.contouringMetaDataS.smoothImg; 
ContractionBias = stateS.contouringMetaDataS.ContractionBias; 
scanSet = stateS.contouringMetaDataS.ccScanSet; 
maskM = stateS.contouringMetaDataS.contourMask; %stateS.contouringMetaDataS.InitialMask; 
maskM = logical(maskM);
% maskM = false(length(yV), length(xV));
% delta = 2;
% [rM,cM] = meshgrid(r-delta:r+delta,c-delta:c+delta);
% maskM(rM(:),cM(:)) = 1;
% threshM = false(size(maskM));
% threshM(r-100:r+100,c-100:c+100) = activecontour(imgM(r-100:r+100,c-100:c+100), maskM(r-100:r+100,c-100:c+100), 20, 'Chan-Vese','ContractionBias',ContractionBias);
%threshM = activecontour(imgM, maskM, 30, 'Chan-Vese','ContractionBias',ContractionBias);
imgM = histeq(imgM);
threshM = activecontour(imgM, maskM, 50, 'Chan-Vese'); %,'ContractionBias',ContractionBias);

labelM = labelmatrix(bwconncomp(threshM,4));
% labelVal = labelM(r,c);
labelToKeepV = unique(labelM(maskM));
labelToKeepV = labelToKeepV(labelToKeepV > 0);
segM = false(size(maskM));
for iLabel = 1:length(labelToKeepV)
    segM = segM | labelM == labelToKeepV(iLabel);
end

% get slceValues
%sliceValues = findnearest(zV,coord);
sliceValues = 1; % dummy, since 2d
contr = maskToPoly(segM, sliceValues, scanSet, planC);
segment = contr.segments(1).points(:,1:2);
contourV = {};
for seg = 1:length(contr.segments)
    if ~isempty(contr.segments(seg).points)
        contourV{seg} = contr.segments(seg).points;
    end
end
stateS.contouringMetaDataS.contourV = contourV;
stateS.contouringMetaDataS.contourMask = segM;
stateS.contouringMetaDataS.segment = segment;

drawSegment(hAxis);


function getThresh(hAxis, x, y) % old function, replaced by getThreshold
%Sets the current segment to the contour of connected region x,y
global planC
global stateS
indexS = planC{end};
% [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.currentScan));
[scanSet,coord] = getAxisInfo(stateS.handle.CERRAxis(stateS.contourAxis),'scanSets','coord');
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
% [r, c, jnk] = xyztom(x,y,zeros(size(x)), planC);
[r, c, jnk] = xyztom(x,y,zeros(size(x)), scanSet, planC);
r = round(r);
c = round(c);
if r < 1 || r > length(yV) || c < 1 || c > length(xV)
    return;
end

% threshV = getappdata(hAxis, 'threshLevelV');
% minLevel = getappdata(hAxis, 'minLevel');
% maxLevel = getappdata(hAxis, 'maxLevel');
% %hImg =  findobj(hAxis, 'tag', 'CTImage');
% %imgM = get(hImg, 'cData');
% imgM = getappdata(hAxis, 'smoothImg');
% pixVal = imgM(r, c);
% ind1 = find(threshV > pixVal, 1, 'first');
% if isempty(ind1)
%     ind1 = length(threshV);
% end
% if isempty(minLevel)
%     minLevel = ind1 - 1;
%     setappdata(hAxis, 'minLevel', minLevel-1);
% end
% minLevel = max(1,minLevel);
% if isempty(maxLevel)
%     maxLevel = ind1;
%     setappdata(hAxis, 'maxLevel', maxLevel+1);
% end
% maxLevel = min(maxLevel,length(threshV));

% indAbove = max(1,ind1 - 1);
% indBelow = min(indAbove + currentLeveldiff,length(threshV));
% threshM = imgM >= threshV(indAbove) & imgM < threshV(indBelow);

% threshM = imgM >= threshV(minLevel) & imgM < threshV(maxLevel);

imgM = stateS.contouringMetaDataS.smoothImg; 
ContractionBias = stateS.contouringMetaDataS.ContractionBias; 
scanSet = stateS.contouringMetaDataS.ccScanSet; 
maskM = stateS.contouringMetaDataS.InitialMask; 
% maskM = false(length(yV), length(xV));
% delta = 2;
% [rM,cM] = meshgrid(r-delta:r+delta,c-delta:c+delta);
% maskM(rM(:),cM(:)) = 1;
% threshM = false(size(maskM));
% threshM(r-100:r+100,c-100:c+100) = activecontour(imgM(r-100:r+100,c-100:c+100), maskM(r-100:r+100,c-100:c+100), 20, 'Chan-Vese','ContractionBias',ContractionBias);
% threshM = activecontour(imgM, maskM, 30, 'Chan-Vese','ContractionBias',ContractionBias);
threshM = activecontour(imgM, maskM, 30, 'edge','ContractionBias',ContractionBias);

labelM = labelmatrix(bwconncomp(threshM,4));
labelVal = labelM(r,c);
ROI = labelM == labelVal;

% BW = roicolor(img,pixVal);
% L = bwlabel(BW, 4);
% region = L(r,c);

% ROI = L == region;
% [contour, sliceValues] = maskToPoly(ROI, 1, planC);
% get slceValues
sliceValues = findnearest(zV,coord);
[contr, sliceValues] = maskToPoly(ROI, sliceValues, scanSet, planC);
% if(length(contour.segments) > 1)
%     longestDist = 0;
%     longestSeg =  [];
%     for i = 1:length(contour.segments)
%         segmentV = contour.segments(i).points(:,1:2);
%         curveLength = 0;
%         for j = 1:size(segmentV,1) - 1
%             curveLength = curveLength + sepsq(segmentV(j,:)', segmentV(j+1,:)');
%         end
%         if curveLength > longestDist
%             longestDist = curveLength;
%             longestSeg = i;
%         end
%     end
%     segment = contour.segments(longestSeg).points(:,1:2);
% else
%     segment = contour.segments.points(:,1:2);
% end
segment = contr.segments(1).points(:,1:2);
contourV = {};
for seg = 1:length(contr.segments)
    if ~isempty(contr.segments(seg).points)
        contourV{seg} = contr.segments(seg).points;
    end
end
stateS.contouringMetaDataS.contourV = contourV;
stateS.contouringMetaDataS.contourMask = ROI;
stateS.contouringMetaDataS.segment = segment;

drawSegment(hAxis);

% sliceNum = getappdata(hAxis, 'ccSlice');
% scanNum = getappdata(hAxis, 'ccScanSet');
% segM = getappdata(hAxis,'contourMask');
% numRows = getappdata(hAxis, 'numRows');
% numCols = getappdata(hAxis, 'numCols');
% [rowV, colV] = xytom(xV, yV, sliceNum, planC,scanNum);
% rowV(rowV<1) = 1;
% colV(colV<1) = 1;
% rowV(rowV>numRows) = numRows;
% colV(colV>numCols) = numCols;
% contourData = contourc(double(ROI), [.5 .5]);
% len = size(contourData,2);
% currPt = 1;
% newContoursC = {};
% while currPt < len
%     numPoints = contourData(2,currPt);
%     xyData = contourData(:,currPt+1:numPoints+currPt)';
%     cV = xyData(:,1);
%     rV = xyData(:,2);
%     uniflag = 0;
%     [xSegV,ySegV,~] = mtoxyz(rV,cV,sliceNum,scanNum,planC,uniflag);
%     
%     %setappdata(hAxis, 'segment', [xSegV(:) ySegV(:)])
%     
%     newContoursC{end+1} = [xSegV(:) ySegV(:)];
%     currPt = numPoints + currPt + 1;
% end
% %setappdata(hAxis, 'contourV', newContoursC)
% setappdata(hAxis, 'segment', segment);
% drawSegment(hAxis);


%SEGMENT UNDO FUNCTIONS
function saveUndoInfo(hAxis)
%Save the current segment to the undo info list.

glovbal stateS
segment = stateS.contouringMetaDataS.segment; 
undoList = stateS.contouringMetaDataS.undoList; 
if isempty(undoList)
    undoList = {};
end
undoList = {undoList{:} segment};
stateS.contouringMetaDataS.undoList = undoList;


function undoLast(hAxis)
%Revert segment to before the last action.
global stateS
undoList = stateS.contouringMetaDataS.undoList; 
if isempty(undoList)
    return;
end
segment = undoList{end};
undoList(end) = [];
stateS.contouringMetaDataS.segment = segment;
stateS.contouringMetaDataS.undoList = undoList;


function clearUndoInfo(hAxis)
%Clears undo info, useful if beginning new segment, or leaving draw mode.
global stateS
stateS.contouringMetaDataS.undoList = [];

