function structColorGUI(command,varargin)
%function structColorGUI(command,varargin)
%GUI to change structure color
%
%APA, 01/25/08, based on structColorGUI
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

global planC stateS

indexS = planC{end};

switch upper(command)

    case 'INIT'

        units = 'pixels';

        x = 340; y = 700;

        hFig = figure('Menu','None','Position',[100,100,x,y],'Name','Reassign Color', 'units', 'pixels',...
            'NumberTitle', 'off', 'resize', 'off', 'Tag', 'structColorGUI','WindowButtonDownFcn','structColorGUI(''BTDWN'')',...
            'WindowButtonUpFcn','structColorGUI(''BTUP'')');

        statusFrame = uicontrol(hFig, 'units',units ,'Position', [10 10 x-18 y-18], 'style', 'frame','HitTest','off');
        frameColor = get(statusFrame,'backgroundcolor');
        ud.frameColor = frameColor;
        
        %frameColor = [0.9 0.9 0.9];

        uicontrol(hFig, 'units',units,'Position',[x/2-100,670,200,20], 'style', 'text', 'String', 'Reassign Structure Color',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',10);

        uicontrol(hFig, 'units',units,'Position',[12,650,300,20], 'style', 'text', 'String', '(Hold color, Drag, Drop over another to swap)',...
            'backgroundcolor', frameColor,'fontweight', 'normal','fontsize',8);

        uicontrol(hFig, 'units',units,'Position',[10+40,630,150,20], 'style', 'text', 'String', 'Current Color',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',9);
        
        uicontrol(hFig, 'units',units,'Position',[10+180,630,90,20], 'style', 'text', 'String', 'New Color',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',9);
        
        numRows = 28;

        for i=1:numRows
            ud.handles.strNum(i) = uicontrol(hFig, 'units',units,'Position',[10+3    y-18-50-i*20   20   15], 'style', 'text',...
                'String', num2str(i), 'backgroundcolor', frameColor,'Visible','Off');
            ud.handles.strName(i)  = uicontrol(hFig, 'units',units,'Position',[10+40   y-18-50-i*20   150  15], 'style', 'text',...
                'String', 'struct Name', 'backgroundcolor', frameColor,'Visible','Off');
            ud.handles.strSelectColor(i)  = uicontrol(hFig, 'units',units,'Position',[10+240   y-18-50-i*20   40  15], 'style', 'push',...
                'String', 'Pick', 'backgroundcolor', frameColor,'Visible','Off', 'callback',['structColorGUI(''pickColor'',''' num2str(i) ''')']);
            ud.handles.newName(i) = uicontrol(hFig, 'units',units,'Position',[10+210  y-18-50-i*20   20  15], 'style', 'text', 'backgroundcolor', stateS.optS.colorOrder(i,:),...
                'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'newStructName','Visible','Off','enable','off');
            ud.handles.newNamePos{i} = get(ud.handles.newName(i),'position');
        end

        ud.numStructRows = numRows;

        %Get structure numbers associated with the passed scan
        scanNum = str2num(varargin{1});
        [assocScansV, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
        assocStructs = find(assocScansV == scanNum);
        ud.assocStructs = assocStructs;
        
        for j =  1:length(ud.assocStructs)
            ud.struct(j).newName = '';
        end

        ud.handles.structsSlider = uicontrol(hFig, 'units',units,'Position',[x-18-10 65 20 y-10-125], 'style', 'slider',...
            'enable', 'off','tag','structSlider','callback','structColorGUI(''sliderRefresh'')','backgroundcolor', ud.frameColor);

%         ud.handles.undo = uicontrol(hFig, 'units',units, 'Position', [30 15 60 20], 'style', 'pushbutton', ...
%             'string', 'Undo', 'callback', 'structColorGUI(''undo'')');
        
        ud.handles.reset = uicontrol(hFig, 'units',units, 'Position', [100 15 60 20], 'style', 'pushbutton', ...
            'string', 'Reset', 'callback', 'structColorGUI(''reset'')');

        ud.handles.save = uicontrol(hFig, 'units',units, 'Position', [170 15 60 20], 'style', 'pushbutton', ...
            'string', 'Save', 'callback', 'structColorGUI(''save'')');

        ud.handles.exit = uicontrol(hFig, 'units',units, 'Position', [240 15 60 20], 'style', 'pushbutton', ...
            'string', 'Exit', 'callback', 'structColorGUI(''exit'')');

        %Store structure colors in ud
        strColorM = stateS.optS.colorOrder;
        numRepeat = ceil(length(ud.assocStructs)/size(strColorM,1));
        strColorM = repmat(strColorM,[numRepeat 1]);
        for j =  1:length(ud.assocStructs)
            strColorM(j,:) = planC{indexS.structures}(ud.assocStructs(j)).structureColor;
        end
        ud.strColorM = strColorM;
        ud.strColorOldM = strColorM;
        
        ud.handles.currentColor = [];
        
        structLen = length(ud.assocStructs);
        if (structLen/28) < 2
            max = 2;
        elseif (structLen/28) > 2
            max = 3;
        elseif (structLen/28) > 3
            max = 4;
        end
        
        try
            value = ud.sliderValue;
        catch
            value = max;
            ud.slider.oldValue = value;
        end
        if max == 2
            sliderstep = 1;
        else
            sliderstep = 1/max;
        end
        set(ud.handles.structsSlider,'min',1,'max',max,'value',max,'sliderstep',[sliderstep sliderstep]);
        
        %Log
        ud.swapHistory = [];

        set(hFig,'Userdata',ud);

        structColorGUI('refresh')

    case 'REFRESH'

        hFig = findobj('Tag','structColorGUI');

        ud = get(hFig,'Userdata');

        %structLen = length(planC{indexS.structures});
        structLen = length(ud.assocStructs);

        if structLen > ud.numStructRows
            % Enable Slider
            set(ud.handles.structsSlider,'Enable','On');
        end

        if structLen > 28
            set(ud.handles.structsSlider,'enable', 'on');

            % initialize structure slider
            set(hFig,'Userdata',ud);

            structColorGUI('sliderRefresh','init');

        else
            if length(ud.assocStructs)> 28
                numStruct = 28;
            else
                numStruct = length(ud.assocStructs);
            end

            for i=1:numStruct
                structNum  = i;
                structName = planC{indexS.structures}(ud.assocStructs(structNum)).structureName;
                set(ud.handles.strName(structNum), 'string', structName, 'visible', 'on','foregroundcolor',ud.strColorOldM(i,:));
                set(ud.handles.strSelectColor(structNum),'visible', 'on')
                set(ud.handles.strNum(structNum) , 'visible','on');
                set(ud.handles.newName(structNum) , 'visible','on','backgroundcolor',ud.strColorM(i,:));                
            end
            
            %Provide Additional color-Selections
            if numStruct<28
                for i=numStruct+1:28
                    set(ud.handles.newName(i) , 'visible','on','backgroundcolor',ud.strColorM(i,:));
                end
            end

        end

    case 'SLIDERREFRESH'
        ud = get(findobj('Tag','structColorGUI'),'Userdata');
       
        value = round(get(ud.handles.structsSlider,'value'));
        set(ud.handles.structsSlider,'value',value)
        ud.slider.oldValue = value;
        set(findobj('Tag','structColorGUI'),'Userdata',ud);
        assocStructs = ud.assocStructs;

        numStruct = getStructDispLen(value,assocStructs);

        for i = 1:length(numStruct)
            structNum  = assocStructs(numStruct(i));
            structName = planC{indexS.structures}(structNum).structureName;
            set(ud.handles.strName(i), 'string', structName, 'visible', 'on','foregroundcolor',ud.strColorOldM(numStruct(i),:));
            set(ud.handles.strSelectColor(i),'visible', 'on')
            set(ud.handles.strNum(i) , 'visible','on','String',structNum);            
            set(ud.handles.newName(i) ,'visible','on','backgroundcolor',ud.strColorM(numStruct(i),:));
        end

        for j = length(numStruct)+1:28
            set(ud.handles.strName(j), 'visible','off');
            set(ud.handles.strSelectColor(j),'visible', 'off')
            set(ud.handles.strNum(j) , 'visible','off');
            set(ud.handles.newName(j), 'visible','off');
        end
        
        %Provide Additional color-Selections
        for i = length(numStruct)+1:28
            set(ud.handles.newName(i) , 'visible','on','backgroundcolor',stateS.optS.colorOrder(i,:));
        end

    case 'BTDWN'
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');
        %Get the color object (static text) clicked
        currentPt = get(hFig,'currentPoint');
        hObject = [];
        for i=1:length(ud.handles.newName)
            pos = get(ud.handles.newName(i),'position');
            if currentPt(1)>=pos(1) && currentPt(1)<=pos(1)+pos(3) && currentPt(2)>=pos(2) && currentPt(2)<=pos(2)+pos(4)
                hObject = ud.handles.newName(i);
                break
            end
        end
        if ~isempty(hObject)
            ud.handles.currentColor = hObject;
            ud.handles.currentColorPos = get(hObject,'position');
            indColor = find(ud.handles.newName==hObject);
            set(ud.handles.strName,'FontWeight','normal')
            set(ud.handles.strName(indColor),'FontWeight','bold')
            set(ud.handles.strName(indColor),'backgroundcolor', 'y')
            set(hFig,'Userdata',ud);
            set(hFig,'WindowButtonMotionFcn','structColorGUI(''BTMTN'')')
        end

        
        %Set the structure name string font to boldface
        
    case 'BTMTN'
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');
        set(ud.handles.strName,'fontWeight','normal')
        set(ud.handles.strName,'backgroundcolor', ud.frameColor)
        movingColorInd = find(ud.handles.newName == ud.handles.currentColor);
        set(ud.handles.strName(movingColorInd),'fontWeight','bold')
        set(ud.handles.strName(movingColorInd),'backgroundcolor', 'y')
        %Get the structure object under cursor
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');
        currentPt = get(hFig,'currentPoint');
        set(ud.handles.currentColor,'position',[currentPt 20 15])
        %Set the structure name string font to boldface        
        %Get the structure object under cursor
        currentPt = get(hFig,'currentPoint');
        for i=1:length(ud.handles.newName)
            colorPos = ud.handles.newNamePos{i};
            if (currentPt(1) >= colorPos(1)) && (currentPt(1) <= colorPos(1)+colorPos(3)) && (currentPt(2) >= colorPos(2)) && (currentPt(2) <= colorPos(2)+colorPos(4))
                baseColorInd = i;
                set(ud.handles.strName(baseColorInd),'fontWeight','bold')
                set(ud.handles.strName(baseColorInd),'backgroundcolor', 'y')
                drawnow
                break
            end
        end        

        
    case 'BTUP'
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');
        set(ud.handles.strName,'fontWeight','normal')
        set(ud.handles.strName,'backgroundcolor', ud.frameColor)
        if isempty(ud.handles.currentColor)
            return;
        end
        %Get the structure object under cursor
        movingColorInd = find(ud.handles.newName == ud.handles.currentColor);
        currentPt = get(hFig,'currentPoint');
        if strcmpi(get(ud.handles.structsSlider ,'enable'),'off')
            sliderVal = 1;
            sliderMax = 1;
        else
            sliderVal = get(ud.handles.structsSlider ,'value');
            sliderMax = get(ud.handles.structsSlider ,'max');
        end
        val = sliderMax - sliderVal + 1;
        movingColorInd = (val-1)*ud.numStructRows + movingColorInd;        
        baseColorInd = [];
        for i=1:length(ud.handles.newName)
            colorPos = ud.handles.newNamePos{i};
            if (currentPt(1) >= colorPos(1)) && (currentPt(1) <= colorPos(1)+colorPos(3)) && (currentPt(2) >= colorPos(2)) && (currentPt(2) <= colorPos(2)+colorPos(4))
                baseColorInd = (val-1)*ud.numStructRows + i;
                break
            end
        end

        %Swap the structure colors        
        if ~isempty(baseColorInd)
            baseColorTmp = ud.strColorM(baseColorInd,:);
            ud.strColorM(baseColorInd,:) = ud.strColorM(movingColorInd,:);
            ud.strColorM(movingColorInd,:) = baseColorTmp;
            ud.swapHistory = [ud.swapHistory; movingColorInd baseColorInd];
        end
        
        set(ud.handles.currentColor,'position',ud.handles.currentColorPos)        
        set(hFig,'WindowButtonMotionFcn','');
        
        set(hFig,'Userdata',ud);
        if strcmp(get(ud.handles.structsSlider,'Enable'),'on')
            structColorGUI('sliderrefresh')            
        else
            structColorGUI('refresh')
        end
        
    case 'PICKCOLOR'
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');
        %Get structure index
        currentPt = get(hFig,'currentPoint');
        if strcmpi(get(ud.handles.structsSlider ,'enable'),'off')
            sliderVal = 1;
            sliderMax = 1;
        else
            sliderVal = get(ud.handles.structsSlider ,'value');
            sliderMax = get(ud.handles.structsSlider ,'max');
        end
        val = sliderMax - sliderVal + 1;
        structIndex = (val-1)*ud.numStructRows + str2num(varargin{1});        
        drawnow;
        newColorVal = uisetcolor;
        drawnow;
        prevColorVal = ud.strColorM(structIndex,:);
        ud.strColorM(structIndex,:) = newColorVal;
        set(hFig,'Userdata',ud);
        if strcmp(get(ud.handles.structsSlider,'Enable'),'on')
            structColorGUI('sliderrefresh')            
        else
            structColorGUI('refresh')
        end        
        
    case 'UNDO'
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');
        if ~isempty(ud.swapHistory)
            baseColorInd = ud.swapHistory(end,1);
            movingColorInd = ud.swapHistory(end,2);
            %Swap the structure colors
            baseColorTmp = ud.strColorM(baseColorInd,:);
            ud.strColorM(baseColorInd,:) = ud.strColorM(movingColorInd,:);
            ud.strColorM(movingColorInd,:) = baseColorTmp;
            ud.swapHistory(end,:) = [];
            set(hFig,'Userdata',ud);
            structColorGUI('refresh')
        end
        
    case 'RESET'
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');
        
        ud.strColorM = ud.strColorOldM;
        
        %Clear Log
        ud.swapHistory = [];

        set(hFig,'Userdata',ud);

        structColorGUI('refresh')

    case 'SAVE'
        hFig = findobj('Tag','structColorGUI');
        ud = get(hFig,'Userdata');

        sliderVis = get(ud.handles.structsSlider,'enable');

        if strcmpi(sliderVis,'off')
            
            %Store color in planC
            for j =  1:length(ud.assocStructs)
                planC{indexS.structures}(ud.assocStructs(j)).structureColor = ud.strColorM(j,:);
            end
        else
            oldValue = ud.slider.oldValue;
            oldStructNum = getStructDispLen(oldValue,ud.assocStructs);

            for jj = 1: length(oldStructNum)
                planC{indexS.structures}(ud.assocStructs(oldStructNum(jj))).structureColor = ud.strColorM(oldStructNum(jj),:);
            end            
        end
        ud.strColorOldM = ud.strColorM;
        
        stateS.structsChanged = 1;
        CERRRefresh
        

    case 'EXIT'
        hFig = findobj('Tag','structColorGUI');
        delete(hFig)
        
end

function numStruct = getStructDispLen(value,structsV)
global planC

indexS = planC{end};

ud = get(findobj('Tag','structColorGUI'),'Userdata');
max = get(ud.handles.structsSlider,'max');

if max == 2
    if value == 2
        numStruct = 1:28;
    elseif value == 1
        numStruct = 29:length(structsV);
    end
elseif max == 3
    if value == 3
        numStruct = 1:28;
    elseif value == 2
        numStruct = 29:56;
    elseif value == 1
        numStruct = 57:length(structsV);
    end
end
