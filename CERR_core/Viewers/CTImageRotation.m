function varargout = CTImageRotation(varargin)
%"CTImageRotation"
%   Used to rotate and translate CT images in a CERR axis with 2 images.
%
%   Has two seperate algorithms, one for handling images and one for
%   handling surfaces with an image mapped to it.  The surface algorithm
%   has better performance but may require openGL to function properly.
%
%JRA 12/7/04
%
%Usage:
%   function CTImageRotation('init', hAxis, imageToMove);
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


persistent centerOfRotation;
persistent image;
persistent xLimOrig;
persistent yLimOrig;
persistent transM;
persistent tmptransM;
persistent pointsM;
persistent fused;
persistent limSize;
persistent hImage;
persistent UISUSPENDDATA;
persistent isDifference;
persistent isNewchecker;
persistent refPt;
persistent prevAngle
persistent hAxis
persistent radius
persistent prevDownAngle

% These parameters used for Image type
persistent xres;
persistent yres;
persistent corners;

global stateS planC

switch lower(varargin{1})
    case 'init'
        %Process inputs, determine imagetype.
        hAxis   = varargin{2};
        
        %dynamic difference view
        if stateS.optS.difference
            isDifference = 1;
            stateS.optS.difference = 0;
            set(gcf,'Pointer','watch');
            drawnow;
            CERRRefresh;
            set(gcf,'Pointer','arrow');
        else
            isDifference = 0;
        end
        
        if stateS.optS.newchecker
            isNewchecker = 1;
            stateS.optS.newchecker = 0;
            set(gcf,'Pointer','watch');
            drawnow;
            CERRRefresh;
            set(gcf,'Pointer','arrow');
        else
            isNewchecker = 0;
        end

        %axisInfo = get(hAxis, 'userdata');
        axNum = stateS.handle.CERRAxis == hAxis;

        movData      = stateS.imageRegistrationMovDataset;
        movDataType  = stateS.imageRegistrationMovDatasetType;
        switch movDataType
            case 'scan'
                %indV = find([axisInfo.scanObj.scanSet] == movData);
                %hImage = axisInfo.scanObj(indV).handles;
                indV = [stateS.handle.aI(axNum).scanObj.scanSet] == movData;
                hImage = stateS.handle.aI(axNum).scanObj(indV).handles;
            case 'dose'
                %indV = find([axisInfo.doseObj.doseSet] == movData);
                %hImage = axisInfo.doseObj(indV).handles(1);
                indV = [stateS.handle.aI(axNum).doseObj.doseSet] == movData;
                hImage = stateS.handle.aI(axNum).doseObj(indV).handles;                
        end

        hFig    = get(hAxis, 'parent');

        if isempty(hImage)
            warndlg('Image is not in the view. Please use auto tracking...');
            return;
        end
        imageType = get(hImage, 'type');

        %UISUSPENDDATA = uisuspend(hFig);

        xLimOrig = get(hImage, 'xData');
        yLimOrig = get(hImage, 'yData');

        %Prepare persistent variables differently for each method.
        switch imageType
            case 'surface'
                %Disable xor erase modes to eliminate flashing.
                hCERRAxes = stateS.handle.CERRAxis;
                for i = 1:length(hCERRAxes)
                    %axisKids = get(hCERRAxes(i), 'children');
                    %set(axisKids, 'erasemode', 'normal');

                    %Store original image points.
                    pointsM = [xLimOrig(:) yLimOrig(:) ones(size(yLimOrig(:)))];
                end
                limSize = size(xLimOrig);

            case 'image'
                image  = get(hImage, 'cData');
                %[xM, yM] = meshgrid(xLimOrig, yLimOrig);

                xV = linspace(xLimOrig(1), xLimOrig(2), size(image, 2));
                yV = linspace(yLimOrig(1), yLimOrig(2), size(image, 1));

                xres = xV(2) - xV(1);
                yres = yV(2) - yV(1);

                corners(1,1:3) = [xLimOrig(1) yLimOrig(1) 1];
                corners(2,1:3) = [xLimOrig(1) yLimOrig(end) 1];
                corners(3,1:3) = [xLimOrig(end) yLimOrig(1) 1];
                corners(4,1:3) = [xLimOrig(end) yLimOrig(end) 1];
        end

        %Prepare motion callback and axis parameters.
        set(hAxis, 'nextplot', 'add', 'xLimMode', 'manual', 'yLimMode', 'manual', 'zLimMode', 'manual');
        set(hAxis, 'buttondownfcn', 'CTImageRotation(''down'')');
        set(hFig, 'windowbuttonmotionfcn', '', 'windowbuttonupfcn', '');

        %Initalize this axis's LOCAL transM variable.
        transM = eye(3);
        tmptransM = getTransM(movDataType,movData,planC);        
        if isempty(tmptransM)
            tmptransM = eye(3);
        else
            tmptransM = tmptransM(1:3,1:3);
        end
        fused = 0;        
        
        prevAngle = 0;
        prevDownAngle = 0;
        refPt = [];
        centerOfRotation = [];
        %prevDownAngle = acos(transM(1,1));
        stateS.rotation_first_click = 0;
        stateS.rotation_down = 0;       
        
        
    case 'down'
        %Button pressed in an axis initalized for fusion: Store location
        %where button was first pressed and setup callbacks.  
        if isempty(hImage), return; end
        if nargin > 1
            hAxis = varargin{2};
        else
            hAxis = gcbo;
        end
        hFig    = get(hAxis, 'parent');
        cP = get(hAxis, 'currentPoint');
        %centerOfRotation = [cP(1,1) cP(2,2)];
        %refPt = [];
        prevAngle = acos(transM(1,1));

        if stateS.toggle_rotation ==1 && ~stateS.rotation_down
            prevAngle = 0;
            xLim = get(hAxis,'xLim');
            yLim = get(hAxis,'yLim');
            centerOfRotation = [cP(1,1) cP(2,2)];
            xMin = xLim(2) - centerOfRotation(1);
            xMin = [xMin centerOfRotation(1)-xLim(1)];
            yMin = yLim(2) - centerOfRotation(2);
            yMin = [yMin centerOfRotation(2)-yLim(1)];
            radius = min([xMin yMin]);
            theta = linspace(0,360*pi/180,50);
            cosTheta = cos(theta);
            sinTheta = sin(theta);
            %Center of Rotation
            stateS.handle.rotationS.hRotCenter = plot(centerOfRotation(1), centerOfRotation(2),'parent',hAxis,...
                'marker', '+', 'lineWidth', 1, 'color','r' , 'markerSize',8,'tag','rotCenter');
            %Circle
            stateS.handle.rotationS.hRotCircle1 = plot(centerOfRotation(1)+0.96*radius*cosTheta,...
                centerOfRotation(2)+0.96*radius*sinTheta,'parent',hAxis,...
                'lineWidth', 1, 'color','y' , 'tag','rotCircle1');
            %Handle
            %prevDownAngle = 0;
            stateS.handle.rotationS.hRotHandleRef = plot([centerOfRotation(1) centerOfRotation(1)+0.98*radius*cosTheta(1)],...
                [centerOfRotation(2) centerOfRotation(2)],'parent',hAxis,...
                'lineWidth', 1, 'color','y', 'LineStyle','--', 'tag','rotHandleRef','hittest','off');
            stateS.handle.rotationS.hRotHandle = plot([centerOfRotation(1) centerOfRotation(1)+0.98*radius*cosTheta(1)],...
                [centerOfRotation(2) centerOfRotation(2)],'parent',hAxis,...
                'lineWidth', 1, 'color','y', 'tag','rotHandle','hittest','off');
            stateS.handle.rotationS.handleCenter = plot(centerOfRotation(1)+0.98*radius*cosTheta(1),...
                centerOfRotation(2)+0.98*radius*sinTheta(1),'parent',hAxis,...
                'marker', 'o', 'MarkerSize', 2, 'lineWidth',3, 'color','y',...
                'markerSize',10,'tag','handleCenter','hittest','off');
            strRotate = 'Grab & Rotate handle';
            stateS.handle.rotationS.hRotMsgString = text('parent',hAxis, 'string',strRotate, 'position', [.25 .04 0],...
                'color', [1 0 0], 'units', 'normalized','fontSize',12,...
                'fontWeight','bold','tag','rotMsgString');
            stateS.rotation_first_click = 1;
            stateS.rotation_down = 1;

        elseif ~stateS.toggle_rotation
            tmptransM = eye(3);
            transM = tmptransM;
            set(hFig, 'windowbuttonmotionfcn', 'CTImageRotation(''moving'')');
            set(hFig, 'windowbuttonupfcn', 'CTImageRotation(''up'')');
            centerOfRotation = [cP(1,1) cP(2,2)];
        elseif stateS.toggle_rotation == 1 && stateS.rotation_down
            set(hFig, 'windowbuttonmotionfcn', 'CTImageRotation(''moving'')');
            set(hFig, 'windowbuttonupfcn', 'CTImageRotation(''up'')');
        end

    case 'moving'
        hAxis = gca;
        imageType = get(hImage, 'type');

        %Get current mouse position.
        cP = get(hAxis, 'currentPoint');
        x = cP(1,1);
        y = cP(2,2);
        
        %Left click ('normal') is translation, right click ('alt') is rotation.
        if ~stateS.toggle_rotation
            deltaX = x - centerOfRotation(1);
            deltaY = y - centerOfRotation(2);
            rotM = [1 0 -deltaX;0 1 -deltaY; 0 0 1];
            tmptransM = transM*rotM;           
        elseif stateS.toggle_rotation ==1 && ~isempty(refPt) && stateS.rotation_first_click
            % rotHandleH = findobj(hAxis,'tag','rotHandle');
            rotHandleH = stateS.handle.rotationS.hRotHandle;
            %set(rotHandleH,'xData',[x centerOfRotation(1)],'yData',[y centerOfRotation(2)])
            % handleCenterH = findobj(hAxis,'tag','handleCenter');            
            handleCenterH = stateS.handle.rotationS.handleCenter;            
            %set(handleCenterH,'xData',x,'yData',y)

            angle1 = atan2((centerOfRotation(2) - y), (centerOfRotation(1) - x));
            angle2 = atan2((centerOfRotation(2) - refPt(2)), (centerOfRotation(1) - refPt(1)));
            angle = angle1 - angle2;
            angle = (2*pi - angle); 
            angle = prevAngle + angle;
            prevAngle = angle;
            
            rotM = [cos(angle) -sin(angle) 0; sin(angle) cos(angle) 0; 0 0 1];

            coR = transM * [centerOfRotation 1]';

            movM = [1 0 -coR(1);0 1 -coR(2);0 0 1];
            backmovM = [1 0 coR(1);0 1 coR(2);0 0 1];
            tmptransM = backmovM*rotM*movM*transM;
            refPt = [x y];

            angHandle = angle + prevDownAngle - 2*pi ;
            angHandle = -angHandle;

            set(rotHandleH,'xData',[centerOfRotation(1)+0.98*radius*cos(angHandle) centerOfRotation(1)],...
                'yData',[centerOfRotation(2)+0.94*radius*sin(angHandle) centerOfRotation(2)])
            set(handleCenterH,'xData',centerOfRotation(1)+0.98*radius*cos(angHandle),...
                'yData',centerOfRotation(2)+0.94*radius*sin(angHandle))

            CERRStatusString('Rotate handle','gui')

        elseif stateS.toggle_rotation ==1 && isempty(refPt) && stateS.rotation_first_click %&& ((centerOfRotation(1)-x)^2 + (centerOfRotation(2)-y)^2)^0.5 < 0.05 %cm
            % rotHandleH = findobj(hAxis,'tag','rotHandle');
            % set(rotHandleH,'xData',[x centerOfRotation(1)],'yData',[y centerOfRotation(2)])
            % handleCenterH = findobj(hAxis,'tag','handleCenter');
            % set(handleCenterH,'xData',x,'yData',y)
            %CERRStatusString('Drag mouse away from center of rotation to define handle.','gui')
            CERRStatusString('Rotate handle.','gui')
            refPt = [x y];
            return;

        end

        %If using a surface, no need to reinterpolate, simple rotation.
        switch imageType
            case 'surface'
                newCorners = inv(tmptransM) * pointsM';
                newXLim = newCorners(1,:);
                newYLim = newCorners(2,:);
                set(hImage, 'xData', reshape(newXLim, limSize), 'yData', reshape(newYLim, limSize));
                if ~fused
                    fused = 1;
                    axisfusion(hAxis, stateS.optS.fusionDisplayMode, stateS.optS.fusionCheckSize);
                end
                
            case 'image'
                corners = (inv(tmptransM) * corners')';
                newXLim = corners(:,1);
                newYLim = corners(:,2);
                image  = get(hImage, 'cData');
                xV = linspace(newXLim(1), newXLim(3), size(image, 2));
                yV = linspace(newYLim(1), newYLim(2), size(image, 1));                
                set(hImage, 'xData', xV, 'yData', yV);
                
                if ~fused
                    fused = 1;
                    axisfusion(hAxis, stateS.optS.fusionDisplayMode, stateS.optS.fusionCheckSize);
                end
                
                
        end

    case 'up'
        
        ud = stateS.handle.controlFrameUd ;
        hObject = ud.handles.rotateButton;
        button_state = get(hObject,'Value');
        hFig    = get(hAxis, 'parent');
             
        set(hFig, 'windowbuttonmotionfcn', '', 'windowbuttonupfcn', '');

        xLimOrig = get(hImage, 'xData');
        yLimOrig = get(hImage, 'yData');

        %Prepare persistent variables differently for each method.
        imageType = get(hImage, 'type');
        switch imageType
            case 'surface'
                %Disable xor erase modes to eliminate flashing.
                hCERRAxes = stateS.handle.CERRAxis;
                for i = 1:length(hCERRAxes)
                    %axisKids = get(hCERRAxes(i), 'children');
                    %set(axisKids, 'erasemode', 'normal');

                    %Store original image points.
                    pointsM = [xLimOrig(:) yLimOrig(:) ones(size(yLimOrig(:)))];
                end
                limSize = size(xLimOrig);
            case 'image'
                image  = get(hImage, 'cData');
                
                xV = linspace(xLimOrig(1), xLimOrig(2), size(image, 2));
                yV = linspace(yLimOrig(1), yLimOrig(2), size(image, 1));

                xres = xV(2) - xV(1);
                yres = yV(2) - yV(1);

                corners(1,1:3) = [xLimOrig(1) yLimOrig(1) 1];
                corners(2,1:3) = [xLimOrig(1) yLimOrig(2) 1];
                corners(3,1:3) = [xLimOrig(2) yLimOrig(1) 1];
                corners(4,1:3) = [xLimOrig(2) yLimOrig(2) 1];

        end
        prevDownAngle = prevAngle + prevDownAngle - 2*pi;
        transM = tmptransM;            
        controlFrame('fusion', 'apply', hAxis);
        %if button_state == get(hObject,'Min')
            %transM = tmptransM;            
            %controlFrame('fusion', 'apply', hAxis);
            set(hAxis,'buttondownfcn', 'sliceCallBack(''axisClicked'')')
            % Delete rotation handles
            %uirestore(UISUSPENDDATA);
            %hRotCenter = findobj('tag','rotCenter');
            if ~isempty(stateS.handle.rotationS)
            hRotCenter = stateS.handle.rotationS.hRotCenter;
            %hRotCircle1 = findobj('tag','rotCircle1');
            hRotCircle1 = stateS.handle.rotationS.hRotCircle1;
            % hRotHandleRef = findobj(hAxis, 'tag','rotHandleRef');
            hRotHandleRef = stateS.handle.rotationS.hRotHandleRef;
            % hRotHandle = findobj(hAxis, 'tag','rotHandle');
            hRotHandle = stateS.handle.rotationS.hRotHandle;
            % handleCenter = findobj(hAxis, 'tag','handleCenter');
            handleCenter = stateS.handle.rotationS.handleCenter;
            % hRotMsgString = findobj(hAxis, 'tag','rotMsgString');
            hRotMsgString = stateS.handle.rotationS.hRotMsgString;
            
            delete([hRotCenter, hRotCircle1, hRotHandleRef, hRotHandle, ...
                handleCenter, hRotMsgString])
            stateS.handle.rotationS = [];
            end            
        %end
        
        %         %hAxis = gca;
%         transM = tmptransM;
%         uirestore(UISUSPENDDATA);
%         controlFrame('fusion', 'apply', hAxis);

        %dynamic difference view
        if isDifference
            stateS.optS.difference = 1;
            CERRRefresh;
        end
        if isNewchecker
            stateS.optS.newchecker = 1;
            CERRRefresh;
        end
        
        if ~stateS.imageFusion.lockMoving
            CTImageRotation('init',hAxis)
        end
       
        %Return this axis's local transM value.
    case 'gettransm'
        varargout{1} = transM;
        return;
end