function structRenameGUI(command,varargin)
% Rename the structures
%
% Written DK.
%
% LM: APA, 9/16/09 Removed limit on number of structures displayed by using ceil and
% automating getStructDispLen
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

indexS = planC{end};

switch upper(command)

    case 'INIT'

        units = 'pixels';

        x = 340; y = 700;

        hFig = figure('Menu','None','Position',[100,100,x,y],'Name','Structure Rename', 'units', 'pixels',...
            'NumberTitle', 'off', 'resize', 'off', 'Tag', 'structRenameGUI');

        statusFrame = uicontrol(hFig, 'units',units ,'Position', [10 10 x-18 y-18], 'style', 'frame');

        frameColor = get(statusFrame,'backgroundcolor');

        uicontrol(hFig, 'units',units,'Position',[x/2-75,670,150,20], 'style', 'text', 'String', 'Structure Renaming',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',10);

        numRows = 31;

        for i=1:numRows
            ud.handles.strNum(i) = uicontrol(hFig, 'units',units,'Position',[10+3    y-18-20-i*20   20   15], 'style', 'text',...
                'String', num2str(i), 'backgroundcolor', frameColor,'Visible','Off');
            ud.handles.strName(i)  = uicontrol(hFig, 'units',units,'Position',[10+40   y-18-20-i*20   100  15], 'style', 'text',...
                'String', 'struct Name', 'backgroundcolor', frameColor,'Visible','Off');
            ud.handles.newName(i) = uicontrol(hFig, 'units',units,'Position',[10+185  y-18-20-i*20   100  20], 'style', 'edit', 'backgroundcolor', frameColor,...
                'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'newStructName','Visible','Off');
        end

        ud.numStructRows = numRows;

        for j =  1:length(planC{indexS.structures})
            ud.struct(j).newName = '';
        end

        ud.handles.structsSlider = uicontrol(hFig, 'units',units,'Position',[x-18-10 10 20 y-10-10], 'style', 'slider',...
            'enable', 'off','tag','structSlider','callback','structRenameGUI(''sliderRefresh'')');

        ud.handles.merge = uicontrol(hFig, 'units',units, 'Position', [x/2-30 12 60 20], 'style', 'pushbutton', ...
            'string', 'Rename', 'callback', 'structRenameGUI(''rename'')');

        set(hFig,'Userdata',ud);

        structRenameGUI('refresh')

    case 'REFRESH'

        hFig = findobj('Tag','structRenameGUI');

        ud = get(hFig,'Userdata');

        structLen = length(planC{indexS.structures});

        if structLen > ud.numStructRows
            % Enable Slider
            set(ud.handles.structsSlider,'Enable','On');
        end

        if structLen > 31
            set(ud.handles.structsSlider,'enable', 'on','BackgroundColor',[0 0 0]);
            
            max = ceil(structLen/31);

            try
                value = ud.sliderValue;
            catch
                value = max;
                ud.slider.oldValue = value;
            end

            set(ud.handles.structsSlider,'min',1,'max',max,'value',value,'sliderstep',[1/(max-1) 1/(max-1)]);
            % initialize structure slider
            set(hFig,'Userdata',ud);

            structRenameGUI('sliderRefresh','init');

        else
            if length(planC{indexS.structures})> 31
                numStruct = 31;
            else
                numStruct = length(planC{indexS.structures});
            end

            for i=1:numStruct
                structNum  = i;
                structName = planC{indexS.structures}(structNum).structureName;
                set(ud.handles.strName(structNum), 'string', structName, 'visible', 'on');
                set(ud.handles.strNum(structNum) , 'visible','on');
                set(ud.handles.newName(structNum) , 'visible','on');
            end

        end

    case 'SLIDERREFRESH'
        ud = get(findobj('Tag','structRenameGUI'),'Userdata');
        oldValue = ud.slider.oldValue;
        oldStructNum = getStructDispLen(oldValue);

        for jj = 1: length(oldStructNum)
            ud.struct(oldStructNum(jj)).newName = get(ud.handles.newName(jj),'string');
        end

        value = get(ud.handles.structsSlider,'value');
        value = round(value);
        set(ud.handles.structsSlider,'value',value);

        ud.slider.oldValue = value;
        set(findobj('Tag','structRenameGUI'),'Userdata',ud);

        numStruct = getStructDispLen(value);

        for i = 1:length(numStruct)
            structNum  = numStruct(i);
            structName = planC{indexS.structures}(structNum ).structureName;
            set(ud.handles.strName(i), 'string', structName, 'visible', 'on');
            set(ud.handles.strNum(i) , 'visible','on','String',structNum);
            editName =  ud.struct(numStruct(i)).newName;
            set(ud.handles.newName(i) , 'string', editName,'visible','on');
        end

        for j = length(numStruct)+1:31
            set(ud.handles.strName(j), 'visible','off');
            set(ud.handles.strNum(j) , 'visible','off');
            set(ud.handles.newName(j), 'visible','off');
        end

    case 'RENAME'
        hFig = findobj('Tag','structRenameGUI');
        ud = get(hFig,'Userdata');

        sliderVis = get(ud.handles.structsSlider,'enable');

        if strcmpi(sliderVis,'off')
            for i = 1:length(ud.handles.newName)
                structNum = i;
                if structNum <= length(planC{indexS.structures})
                    newName = get(ud.handles.newName(structNum),'string');
                    if ~isempty(newName)
                        planC{indexS.structures}(structNum).structureName = newName;
                    end
                end
            end
        else
            oldValue = ud.slider.oldValue;
            oldStructNum = getStructDispLen(oldValue);

            for jj = 1: length(oldStructNum)
                ud.struct(oldStructNum(jj)).newName = get(ud.handles.newName(jj),'string');
            end
            
            for i = 1:length(planC{indexS.structures})
                newName = ud.struct(i).newName;
                if ~isempty(newName)
                    planC{indexS.structures}(i).structureName = newName;
                end
            end
        end

        delete(hFig);
end

function numStruct = getStructDispLen(value)
global planC

indexS = planC{end};

ud = get(findobj('Tag','structRenameGUI'),'Userdata');
max = get(ud.handles.structsSlider,'max');

if value == 1
    numStruct = (max-value)*31+1 : length(planC{indexS.structures});
else
    numStruct = (max-value)*31 + (1:31);
end
