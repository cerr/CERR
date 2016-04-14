function doseViewer3D(command, varargin);
%"doseFigure3D"
%   Creates a figure containing a 3D dose browser for plancheck.
%
%JRA 07/13/05
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
%
%Usage:
%   3DDoseViewer

global planC;
global stateS;
indexS = planC{end};

if ~exist('command')
    command = 'init';
end

hFig = findobj('Tag', 'CERR_3DDoseViewer');

switch upper(command)
    case 'INIT'
        if ~isempty(hFig)
            delete(hFig);
        end

        % check if atleast one dose exists
        if length(planC{indexS.dose})<1
            msgbox('No dose exist. Please calculate and store dose first')
            return;
        else
            doseSet=1;
        end

        screenSize = get(0,'ScreenSize');
        units = 'pixels';
        y = 480;
        x = 640;

        dy = floor((y-30)/2);
        dx = floor((x-30)/2);

        %Create figure and UI controls.
        hFig = figure('Name','3D Viewer', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERR_3DDoseViewer', 'color', [0 0 0]);

        hAxis = axes('position', [0 0 .7 1], 'color', [0 0 0]);

        hFrame = uicontrol('style', 'frame', 'units', 'normalized', 'position', [.7 .65 .28 .33]);

        %Create controls for structure selection
        structures = {'Select...' planC{indexS.structures}.structureName};
        nStructs = length(structures);
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.71 .90 .1 .05], 'string', 'Structure:');
        uicontrol('style', 'popupmenu', 'units', 'normalized', 'position', [.82 .90 .15 .05], 'string', structures, 'value', 1, 'callback', 'doseViewer3D(''struct_dropdown'')');

        ud.surfaceHandles = cell(nStructs,1);
        ud.surfaceVisible = zeros(nStructs,1);

        doses = {planC{indexS.dose}.fractionGroupID};
        %doses = {doses{:} 'DoseDiff', 'DTA'};
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.71 .84 .1 .05], 'string', 'Dose:');
        uicontrol('style', 'popupmenu', 'units', 'normalized', 'position', [.82 .84 .15 .05], 'string', doses, 'value', 1, 'callback', 'doseViewer3D(''dose_dropdown'')');

        %Alpha Controls

        %Colorbar

        %Snap view:
        views = {'Transverse', 'Sagittal', 'Coronal'};
        uicontrol('style', 'pushbutton', 'units', 'normalized', 'position', [.735 .78 .1 .05], 'string', 'Trans', 'callback', 'doseViewer3D(''view_trans'')');
        uicontrol('style', 'pushbutton', 'units', 'normalized', 'position', [.735 .72 .1 .05], 'string', 'Sag', 'callback', 'doseViewer3D(''view_sag'')');
        uicontrol('style', 'pushbutton', 'units', 'normalized', 'position', [.845 .78 .1 .05], 'string', 'Cor', 'callback', 'doseViewer3D(''view_cor'')');

        %Coordinate info.
        ud.handle.xPos = uicontrol('style', 'text', 'units', 'normalized', 'position', [.71 .66 .09 .05], 'string', 'x=', 'horizontalAlignment', 'left');
        ud.handle.yPos = uicontrol('style', 'text', 'units', 'normalized', 'position', [.80 .66 .09 .05], 'string', 'y=', 'horizontalAlignment', 'left');
        ud.handle.zPos = uicontrol('style', 'text', 'units', 'normalized', 'position', [.89 .66 .09 .05], 'string', 'z=', 'horizontalAlignment', 'left');


        %         uicontrol('style', 'text', 'units', 'normalized', 'position', [.71 .78 .1 .05], 'string', 'View');
        %         uicontrol('style', 'popupmenu', 'units', 'normalized', 'position', [.82 .78 .15 .05], 'string', views, 'value', 1, 'callback', 'doseViewer3D(''view_dropdown'')');
        %
        %Default to doseSet 1.
        %doseSet = 1;
        
        [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseSet));
        dA = getDoseArray(doseSet);
        doseBrowser3D('init', hAxis, dA, xV, yV, zV);

        doseBrowser3D('SETPLANEMOTIONCALLBACK', hAxis, 'doseViewer3D(''PLANE_MOVED'')');
        doseBrowser3D('SETPLANEMOTIONDONECALLBACK', hAxis, 'doseViewer3D(''PLANE_MOTION_DONE'')');

        ud.hAxis = hAxis;
        colormap(hAxis, CERRColorMap(stateS.optS.doseColormap));
        set(hFig, 'userdata', ud);

        doseViewer3D('PLANE_MOVED');

    case 'PLANE_MOVED'
        ud = get(hFig, 'userdata');
        hAxis = ud.hAxis;
        [x,y,z] = doseBrowser3D('GETPLANECOORDINATES', hAxis);
        set(ud.handle.zPos, 'String', ['z=' num2str(z, 3)]);
        set(ud.handle.xPos, 'String', ['x=' num2str(x, 3)]);
        set(ud.handle.yPos, 'String', ['y=' num2str(y, 3)]);

    case 'PLANE_MOTION_DONE'
%         ud = get(hFig, 'userdata');
%         hAxis = ud.hAxis;
%         [x,y,z] = doseBrowser3D('GETPLANECOORDINATES', hAxis);

%         setAxisInfo(stateS.handle.CERRAxis(1), 'coord', z);
%         setAxisInfo(stateS.handle.CERRAxis(4), 'coord', x);
%         setAxisInfo(stateS.handle.CERRAxis(6), 'coord', y);
%         plancheckCallback('refresh');        
        
%         for i=1:length(stateS.handle.CERRAxis)
%             viewAx = getAxisInfo(stateS.handle.CERRAxis(i),'view');
%             if strcmpi('transverse',viewAx)
%                 setAxisInfo(stateS.handle.CERRAxis(i), 'coord', z);
%             elseif strcmpi('sagittal',viewAx)
%                 setAxisInfo(stateS.handle.CERRAxis(i), 'coord', x);
%             elseif strcmpi('coronal',viewAx)
%                 setAxisInfo(stateS.handle.CERRAxis(i), 'coord', y);
%             end
%         end
%         
%         sliceCallback('refresh')
            
            

    case 'VIEW_DROPDOWN'
        ud = get(hFig, 'userdata');
        hAxis = ud.hAxis;

        viewNum = get(gcbo, 'value');
        switch viewNum
            case 1
                view(hAxis, 0, 90);
            case 2
                view(hAxis, -90, 0);
            case 3
                view(hAxis, 0, 0);
            case 4
                %Do nothing: floating view.
        end

    case 'VIEW_TRANS'
        ud = get(hFig, 'userdata');
        hAxis = ud.hAxis;
        view(hAxis, 0, 90);

    case 'VIEW_SAG'
        ud = get(hFig, 'userdata');
        hAxis = ud.hAxis;
        view(hAxis, -90, 0);

    case 'VIEW_COR'
        ud = get(hFig, 'userdata');
        hAxis = ud.hAxis;
        view(hAxis, 0, 0);

    case 'STRUCT_DROPDOWN'
        ud = get(hFig, 'userdata');
        hAxis = ud.hAxis;

        %Get selected struct.
        structNum = get(gcbo, 'value') - 1;

        if structNum == 0
            return;
        end

        %Toggle surface visible.
        ud.surfaceVisible(structNum) = xor(ud.surfaceVisible(structNum),1);

        %Draw surface if necessary.
        if isempty(ud.surfaceHandles{structNum})
            p = isoStruct(structNum);
            ud.surfaceHandles{structNum} = p;
        else
            p = ud.surfaceHandles{structNum};
        end

        %Add/remove star to denote struct is on/off
        structList = get(gcbo, 'string');
        switch ud.surfaceVisible(structNum);
            case 0
                structList{structNum+1} = [planC{indexS.structures}(structNum).structureName];
                set(p, 'visible', 'off');
            case 1
                structList{structNum+1} = ['*' planC{indexS.structures}(structNum).structureName];
                set(p, 'visible', 'on');
        end
        set(gcbo, 'string', structList);
        set(hFig, 'userdata', ud);

    case 'DOSE_DROPDOWN'
        ud = get(hFig, 'userdata');
        hAxis = ud.hAxis;

        doseNum = get(gcbo, 'value');
        strings = get(gcbo, 'string');

        switch strings{doseNum}
            case 'DTA'
                dS = [getAxisInfo(stateS.handle.CERRAxis(1), 'doseSets') ...
                    getAxisInfo(stateS.handle.CERRAxis(2), 'doseSets')];
                if length(dS) == 2
                    [xV1, yV1, zV1] = getDoseXYZVals(planC{indexS.dose}(dS(1)));
                    [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(dS(2)));
                    dose3M1 = getDoseArray(dS(1));
                    dose3M2 = getDoseArray(dS(2));
                    [dA, ptc] = calculateGammaFcn1(dose3M1, dose3M2, [abs(yV1(2)-yV1(1)) abs(xV1(2)-xV1(1)) abs(zV1(2)-zV1(1))]);
                    colormap(hAxis, CERRColorMap('DTA'));
                else
                    return;
                end
            case 'DoseDiff'
                if doseNum == 0
                    dS = [];
                else
                    dS = [getAxisInfo(stateS.handle.CERRAxis(1), 'doseSets') ...
                    getAxisInfo(stateS.handle.CERRAxis(2), 'doseSets')];
                end
                [xV1, yV1, zV1] = getDoseXYZVals(planC{indexS.dose}(dS(1)));
                [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(dS(2)));
                dose3M1 = getDoseArray(dS(1));
                dose3M2 = getDoseArray(dS(2));
                dA = dose3M1 - dose3M2;

            otherwise
                dA = getDoseArray(doseNum, planC);
                [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
                colormap(hAxis, CERRColorMap(stateS.optS.doseColormap));
        end
        doseBrowser3D('NEWDOSE', hAxis, dA, xV, yV, zV);
end
