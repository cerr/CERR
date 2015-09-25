function struct3Dvisualmenu(callFlag)
%Callback to the 3D visualization menu.
%CZ.
%Latest modifications: 17 Apr 03, JOD, changed button size.
%#function Surf3DCallBack
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

indexS = planC{end};

dy2 = 1.2;   %vertical increment between structure labels

vert = (length(planC{indexS.structures}) + 2) * 0.2;

x1 = 8;
y1 = vert * 7; %38;   %%JOD, changed to '* 8'.
dx1 = 25;
dy1 = 1.5;

color2V = get(stateS.handle.CERRSliceViewer, 'Color');
colorV =  color2V + (1 - color2V) * 0.5;

OptSurf = struct('Box3D','Trans','DoseL','DoseT');

if strcmp(callFlag,'update')

    hSurface = findobj('tag','3D Structure Visualization');
    if isempty(hSurface)
        hSurface = figure('units','inches','position',[5, 1, 3.7, vert+0.2],'numbertitle','off','name','3D Structure Visualization',...
            'color', color2V,'menubar','none','tag','CERRLegend');
        set(gca,'visible','off')
        stateS.handle.CERRSurf = hSurface;
    end

    uicontrol(hSurface,'style','text','units','characters','FontWeight','bold',...
        'position',[dx1+6, y1 - dy2+dy1+0.2, dx1-2.7, dy1+0.2],'string','3D visualization');

    uicontrol(hSurface,'style','text','units','characters','FontWeight','bold',...
        'position',[dx1+26, y1 - dy2+dy1+0.2, dx1-2.7, dy1+0.2],'string','Transparency');

    uicontrol(hSurface,'style','text','units','characters','FontWeight','bold',...
        'position',[x1, y1 - dy2+dy1+0.2, dx1-2.7, dy1+0.2],'string','Structure');

    uicontrol(hSurface,'style','text','units','characters','FontWeight','bold',...
        'position',[dx1+8, y1 - dy2 *length(planC{indexS.structures})-2.2, dy1+17, dy1],'string','Dose Level, Gr');

    uicontrol(hSurface,'style','text','units','characters','FontWeight','bold',...
        'position',[dx1+29, y1 - dy2 *length(planC{indexS.structures})-2.2, dy1+15, dy1],'string','Transparency');



    for i = 1 : length(planC{indexS.structures})
        str = planC{indexS.structures}(i).structureName;
        if ~strcmp(str,'')
            %colorV = stateS.optS.colorOrder(i,:);
            color2V = setCERRLabelColor(i);
            colorV = planC{indexS.structures}(i).structureColor;

            %List structures
            uicontrol(hSurface,'style','text','units','characters', ...
                'position',[x1 - 6, y1 - dy2 * i, 4, dy1],'string',[num2str(i) '.  ']);

            uicontrol(hSurface,'style','text','units','characters', 'backgroundcolor', colorV, 'foregroundcolor', color2V, ...
                'position',[x1, y1 - dy2 * i, dx1, dy1],'string',str);


            OptSurf(i).Box3D = uicontrol(hSurface,'style','checkbox','units','characters',...
                'position',[dx1+18, y1 - dy2 * i, dy1+2, dy1],'string','');


            OptSurf(i).Trans = uicontrol(hSurface,'style','edit','units','characters',...
                'position',[dx1+35, y1 - dy2 * i, dy1+5, dy1]);

            OptSurf(i).DoseL = uicontrol(hSurface,'style','edit','units','characters',...
                'position',[dx1+15, y1 - dy2 *length(planC{indexS.structures})-3.5, dy1+5, dy1]);


            OptSurf(i).DoseT = uicontrol(hSurface,'style','edit','units','characters',...
                'position',[dx1+35, y1 - dy2 *length(planC{indexS.structures})-3.5, dy1+5, dy1]);

        end
    end

    set(gca,'visible','off');

    set(hSurface,'userdata',OptSurf);

    uicontrol(hSurface,'style','pushbutton','String','Start 3D Visualization',...
        'Position', [x1+4, y1 - dy2 * length(planC{indexS.structures}), 135 25],'callback',['Surf3DCallBack']);

end
