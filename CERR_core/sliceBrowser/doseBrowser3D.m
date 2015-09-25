function varargout = doseBrowser3D(command, varargin);
%"doseBrowser3D"
%   Creates a 3D dose browser in an axis.
%
%Usage:
%   doseBrowser3D('init', hAxis, doseArray, xV, yV, zV);
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

switch upper(command)
    case 'INIT'
        hAxis = varargin{1};
        dA    = varargin{2};
        xV    = varargin{3};
        yV    = varargin{4};
        zV    = varargin{5};        
        
        hFig = get(hAxis, 'parent');
        hFigRen = get(hFig, 'renderer');
        
        %Cannot use painters, or damaged 3D view results.
        if strcmpi(hFigRen, 'painters')
            set(hFig, 'renderer', 'zbuffer');
        end
        
        %Draw planes without texture.
        [hTrans, hCor, hSag] = drawXYZPlanes(hAxis, [xV(1) xV(end)], [yV(1) yV(end)], [zV(1) zV(end)]);
        
        %Set callbacks for planes.
        set([hTrans hCor hSag], 'buttondownfcn', 'doseBrowser3D(''planeClicked'')');
        
        %Set axis properties: squareness and BG color.
        axis(hAxis, 'square');
        set(hAxis, 'color', [0 0 0], 'Tag', '3D_dose_browser', 'zdir', 'reverse', 'buttondownfcn', 'doseBrowser3D(''axis_clicked'')');
        
        axis(hAxis, 'off');             
        
        xVal = mean(xV);
        yVal = mean(yV);
        zVal = mean(zV);        
        
        %Get the slice requested.
        compareMode = [];
        sagSlc   = slice3DVol(dA, xV, yV, zV, xVal, 1, 'linear',[],compareMode)';
        corSlc   = slice3DVol(dA, xV, yV, zV, yVal, 2, 'linear',[],compareMode)';
        transSlc = slice3DVol(dA, xV, yV, zV, zVal, 3, 'linear',[],compareMode);
        
        %Initialize to center slice.
        applyTextureMap(hSag, sagSlc, xVal);
        applyTextureMap(hCor, corSlc, yVal);        
        applyTextureMap(hTrans, transSlc, zVal);        
        
        %Populate userdata structure, to be associated with axis.
        ud.doseArray = dA;
        ud.xV = xV;
        ud.yV = yV;
        ud.zV = zV;      
        
        %Populate other fields.
        ud.plane_motion_callback = '';
        ud.plane_motion_done_callback = '';
        
        maxDose = max(dA(:));
        minDose = 0;
        
        set(hAxis, 'cLim', [minDose maxDose]);
        
        set(hAxis, 'userdata', ud);
        
        view(hAxis, -35, 75)
        
        axis(hAxis, 'equal');
        
    case 'PLANECLICKED'
        hAxis = get(gcbo, 'parent');
        hFig  = get(hAxis, 'parent');
        
        ud = get(hAxis, 'userdata');
        sT = get(hFig, 'SelectionType');
        
        otherCallbacks = ud.plane_motion_callback;
        otherDoneCallback = ud.plane_motion_done_callback;
        
        switch sT
            case 'normal'
                set(hFig, 'WindowButtonMotionFcn', ['doseBrowser3D(''planeMoving'');' otherCallbacks], 'windowbuttonupfcn', ['doseBrowser3D(''planeMovingDone'');' otherDoneCallback]);
                ud.movingPlane = gcbo;
            case 'open'                
            case 'alt'
                %Right click
                set(hFig, 'WindowButtonMotionFcn', 'doseBrowser3D(''rotationmoving'')', 'windowbuttonupfcn', 'doseBrowser3D(''rotationmovingdone'')');
                cP = get(hFig, 'currentpoint');     
                ud.figure_clickpoint = cP;
                [ud.start_az, ud.start_el] = view(hAxis);
        end  
        set(hAxis, 'userdata', ud);                              
        
    case 'AXIS_CLICKED'
        hFig = get(gcbo, 'parent');
        ud = get(hFig, 'userdata');
        sT = get(hFig, 'SelectionType');
        
        switch sT
            case 'normal'
            case 'open'                
            case 'alt'
                %Right click
                set(hFig, 'WindowButtonMotionFcn', 'doseBrowser3D(''rotationmoving'')', 'windowbuttonupfcn', 'doseBrowser3D(''rotationmovingdone'')');
                cP = get(hFig, 'currentpoint');               
                [ud.start_az, ud.start_el] = view(hAxis);
                ud.figure_clickpoint = cP;
        end                
        set(hAxis, 'userdata', ud);
        
    case 'PLANEMOVING'
        hFig = gcbo;
        hAxes = findobj(hFig, 'Tag', '3D_dose_browser');
        
        for i=1:length(hAxes)
            hAxis = hAxes(i);

            ud = get(hAxis, 'userdata');

            figSize         = get(hFig, 'position');
            currentPoint    = get(hFig, 'currentPoint');
            dx = figSize(3);

            %For slice selection.
            currentRatio = currentPoint(1)/dx;

            if isfield(ud, 'movingPlane');
                planeName = get(ud.movingPlane, 'Tag');
                switch planeName
                    case '3D_Trans_Slice'
                        coord = (ud.zV(end) - ud.zV(1)) * currentRatio + ud.zV(1);
                        %                 currentCoord = get(ud.movingPlane, 'zData');
                        dim = 3;
                        coord = clip(coord, ud.zV(1), ud.zV(end), 'limits');
                        slice = slice3DVol(ud.doseArray, ud.xV, ud.yV, ud.zV, coord, dim, 'linear',[],[]);
                    case '3D_Cor_Slice'
                        coord = (ud.yV(end) - ud.yV(1)) * currentRatio + ud.yV(1);
                        %                 currentCoord = get(ud.movingPlane, 'yData');
                        dim = 2;
                        coord = clip(coord, ud.yV(end), ud.yV(1), 'limits');
                        slice = slice3DVol(ud.doseArray, ud.xV, ud.yV, ud.zV, coord, dim, 'linear',[],[])';
                    case '3D_Sag_Slice'
                        coord = (ud.xV(end) - ud.xV(1)) * currentRatio + ud.xV(1);
                        %                 currentCoord = get(ud.movingPlane, 'xData');
                        dim = 1;
                        coord = clip(coord, ud.xV(1), ud.xV(end), 'limits');
                        slice = slice3DVol(ud.doseArray, ud.xV, ud.yV, ud.zV, coord, dim, 'linear',[],[])';
                end

                applyTextureMap(ud.movingPlane, slice, coord);
                
%                 switch dim
%                     case 3
%                         delete(findobj(hAxis, 'Tag', 'TransStructLine'));
%                     case 2
%                          delete(findobj(hAxis, 'Tag', 'CorStructLine'));
%                     case 1
%                         delete(findobj(hAxis, 'Tag', 'SagStructLine'));
%                 end
%                 
%                 colors = stateS.optS.colorOrder;
%                 
%                 contourC = getStructureContours(dim, coord, planC);
%                 for structNum = 1:length(contourC)
%                     contour = contourC{structNum};
%                     color = getColor(structNum, colors, 'loop');
%                     if ~isempty(contour)
%                         for segNum = 1:length(contour)
%                            seg = contour{segNum};
%                            switch dim
%                                case 3
%                                     line(seg.X, seg.Y, coord*ones(size(seg.Y)), 'parent', hAxis, 'tag', 'TransStructLine', 'color', color); 
%                                case 2
%                                     line(seg.X, coord*ones(size(seg.Y)), seg.Y, 'parent', hAxis, 'tag', 'CorStructLine', 'color', color); 
%                                case 1
%                                    line(coord*ones(size(seg.Y)), seg.X, seg.Y, 'parent', hAxis, 'tag', 'SagStructLine', 'color', color);
%                            end
%                         end
%                     end
%                 end
                    
                
            end
        end
        
    case 'PLANEMOVINGDONE'
        hFig = gcbo;
        set(hFig, 'windowbuttonmotionfcn', '', 'windowbuttonupfcn', '');        
        
    case 'ROTATIONMOVING'
        hFig = gcbo;
        hAxis = findobj(hFig, 'Tag', '3D_dose_browser');
        ud = get(hAxis, 'userdata');
        cP = get(hFig, 'currentPoint');
                     
        firstPoint = ud.figure_clickpoint;
        
        dx = firstPoint(1)-cP(1);
        dy = firstPoint(2)-cP(2);
        
        az = mod((dx/50)*180 + ud.start_az + 180,360) - 180;
        ele = mod((dy/50)*180 + ud.start_el, 360);
        
        if ele >= 0 & ele < 90
            ele = ele;
            az = az;
        elseif ele >= 90 & ele < 180
            ele = ele;
            az = az;
        elseif ele >= 180 & ele < 270
            ele = ele;
            az = az;
        elseif ele >= 270 & ele < 360
            ele = ele;
            az = az;
        end
        
        view(hAxis, az, ele);                        
        
    case 'ROTATIONMOVINGDONE'
        hFig = gcbo;
        set(hFig, 'windowbuttonmotionfcn', '', 'windowbuttonupfcn', '');        
        
    case 'SETPLANEMOTIONCALLBACK'
        hAxis = varargin{1};
        ud = get(hAxis, 'userdata');
        
        callback = varargin{2};
        
        ud.plane_motion_callback = callback;

        set(hAxis, 'userdata', ud);
        
    case 'SETPLANEMOTIONDONECALLBACK'
        hAxis = varargin{1};
        ud = get(hAxis, 'userdata');
        
        callback = varargin{2};
        
        ud.plane_motion_done_callback = callback;

        set(hAxis, 'userdata', ud);
        
    case 'GETPLANECOORDINATES'
        %Returns the coordinates of the 3 planes.
        hAxis = varargin{1};
        hTrans = findobj(hAxis, 'Tag', '3D_Trans_Slice');
        hSag = findobj(hAxis, 'Tag', '3D_Sag_Slice');
        hCor = findobj(hAxis, 'Tag', '3D_Cor_Slice');
        
        x = get(hSag, 'xData');
        y = get(hCor, 'yData');
        z = get(hTrans, 'zData');
        
        varargout = {x(1),y(1),z(1)};        
        
    case 'NEWDOSE'
        %Assigns a new doseArray to be displayed.
        hAxis   = varargin{1};
        dA      = varargin{2};
        xV      = varargin{3};
        yV      = varargin{4};
        zV      = varargin{5};
        
        ud = get(hAxis, 'userdata');
        ud.doseArray = dA;
        ud.xV = xV;
        ud.yV = yV;
        ud.zV = zV;
        
        set(hAxis, 'userdata', ud);
        doseBrowser3D('REDRAW_ALL_PLANES', hAxis);
        
        %Set axis color limits.
        maxDose = max(dA(~isinf(dA(:))));
        minDose = 0;
        set(hAxis, 'cLim', [minDose maxDose]);
        
    case 'REDRAW_ALL_PLANES'
        %Deletes and redraws all of the planes.
        hAxis = varargin{1};
        ud = get(hAxis, 'userdata');
                
        %Get old plane's positions.
        [x,y,z] = doseBrowser3D('GETPLANECOORDINATES', hAxis);
        
        %Delete old planes.
        surfaceV = findobj(hAxis, 'Type', 'surface');
        delete(surfaceV);
        
        %Draw planes without texture.
        [hTrans, hCor, hSag] = drawXYZPlanes(hAxis, [ud.xV(1) ud.xV(end)], [ud.yV(1) ud.yV(end)], [ud.zV(1) ud.zV(end)]);
        
        %Set callbacks for planes.
        set([hTrans hCor hSag], 'buttondownfcn', 'doseBrowser3D(''planeClicked'')');
        
        surfaceV = findobj(hAxis, 'Type', 'surface');
        
        for i=1:length(surfaceV);
            planeName = get(surfaceV(i), 'Tag');
            switch planeName
                case '3D_Trans_Slice'
                    dim = 3;
                    coord = clip(z, ud.zV(1), ud.zV(end), 'limits');
                    slice = slice3DVol(ud.doseArray, ud.xV, ud.yV, ud.zV, coord, dim, 'linear',[],[]);
                case '3D_Cor_Slice'                   
                    dim = 2;
                    coord = clip(y, ud.yV(end), ud.yV(1), 'limits');
                    slice = slice3DVol(ud.doseArray, ud.xV, ud.yV, ud.zV, coord, dim, 'linear',[],[])';
                case '3D_Sag_Slice'
                    dim = 1;
                    coord = clip(x, ud.xV(1), ud.xV(end), 'limits');
                    slice = slice3DVol(ud.doseArray, ud.xV, ud.yV, ud.zV, coord, dim, 'linear',[],[])';
            end

            applyTextureMap(surfaceV(i), slice, coord);
        end
        
end
