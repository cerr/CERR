function showCERRLegend(hAxis)
%"showCERRLegend"
%   Create the legend in axis hAxis.  'units' property on hAxis should be
%   'pixels'.
%
% APA, 04/08/2010
%
%Usage:
%   function showCERRLegend(hAxis)
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

if ~stateS.planLoaded
    return;
end

indexS = planC{end};

% Set properties correctly
set(hAxis, 'xDir', 'normal','yDir', 'reverse')

%Get userdata for structure contours, contains name and structNum.
% hStructs = findobj(sGv,'tag', 'structContour');
% ud = get(hStructs, 'userdata');
% if isempty(ud)
%     hStructs   = [];
%     hLabels    = {};
% elseif length(ud) == 1
%     hLabels    = {ud.structDesc};
% else
%     ud         = [ud{:}];
%     [jnk, ind] = unique([ud.structNum]);
%     ud         = ud(ind);
%     hStructs   = hStructs(ind);
%     hLabels    = {ud.structDesc};
% end

% Get list of structures visible on all the views
numStructs =  length(planC{indexS.structures});
structIndV = false(1,numStructs);
for i = uint8(1:length(stateS.handle.CERRAxis))
    sG = getAxisInfo(i,'structureGroup');
    for j = 1:length(sG)
        structIndV(sG(j).structNumsV) = true;
    end
end
structNumsV = 1:numStructs;
structNumsV = structNumsV(structIndV);
bool = [planC{indexS.structures}(structIndV).visible];
colors = {planC{indexS.structures}(structIndV).structureColor};
hLabels = {planC{indexS.structures}(structIndV).structureName};

%Get userdata for dose contours, contains doselevel.
colorsDoseC = {};
labelsDoseC = {};
if strcmpi(stateS.optS.dosePlotType,'isodose')
    dGv = [];
    for i = uint8(1:length(stateS.handle.CERRAxis))
        %sG = getAxisInfo(i,'structureGroup');
        dG = getAxisInfo(i,'doseObj');
        for j = 1:length(dG)
            dGv = [dGv; dG(j).handles];
        end
    end    
    hIso = findobj(dGv,'tag', 'isodoseContour');
    if ~isempty(hIso)
        isoValues  = get(hIso, 'userdata');
        [jnk, ind] = unique([isoValues{:}]);
        %hStructs   = [hStructs;hIso(ind)];
        uniqueValues = isoValues(ind);
        type = stateS.optS.isodoseLevelType;
        if strcmp(type,'percent')
            for i=1:length(uniqueValues)
                %hLabels = {hLabels{:},[num2str(uniqueValues{i}*100/(stateS.optS.isodoseNormalizVal)) ' %']};
                labelsDoseC = [labelsDoseC,{[sprintf('%.2f',uniqueValues{i}*100/(stateS.optS.isodoseNormalizVal)) ' %']}];
            end
        elseif strcmp(type,'absolute')
            for i=1:length(uniqueValues)
                if strcmpi(getDoseUnitsStr(stateS.doseSet,planC), 'cgy')
                    %hLabels= {hLabels{:},[num2str(uniqueValues{i}) ' cGy']};
                    labelsDoseC = [labelsDoseC,{[num2str(uniqueValues{i}) ' cGy']}];
                else
                    labelsDoseC = [labelsDoseC,{[num2str(uniqueValues{i}) ' cGy']}];
                    %hLabels = {hLabels{:},[num2str(uniqueValues{i}) ' Gy']};
                end
                colorsDoseC = [colorsDoseC,{get(hIso(ind(i)), 'color')}];
                %colors    = {colors{:},get(hIso(i), 'color')};
            end
        end
    end
end

%Determine if position has changed, redraw if it has.
lastPos = getappdata(hAxis, 'legendAxisLastPos');
currPos  = get(hAxis, 'position');

%Adjust column positions, and indirectly font size based on axis size.
if currPos(4) < 250
    rowHeight = 14;
    colWidth  = 70;
elseif currPos(4) < 400
    rowHeight = 16;
    colWidth  = 80;
elseif currPos(4) < 600
    rowHeight = 18;
    colWidth = 90;
else
    colWidth = 100;
    rowHeight = 20;
end

%udH = get(hAxis,'userdata');
try % to take care of initial call
    %udS=get(udH.legendSlider,'userdata');
    udS = get(stateS.legendSlider,'userdata');    
end

%Repopulate text/line fields if position has changed, or if the old
%lines/text are no longer valid handles
if isempty(lastPos) || ~isequal(lastPos, currPos) || any(~ishandle(stateS.handle.legend.lines)) || any(~ishandle(stateS.handle.legend.text)) || (exist('udS') && ~isempty(udS) && udS{2}(2)<length(planC{indexS.structures})+1) || length(stateS.handle.legend.lines)<=length(planC{indexS.structures})
    
    numCols = 1;
    numRows = length(planC{indexS.structures}) + 9;   % APA: always draw one line, text extra for new structure and 8 for isodose lines

    lines1 = findobj(hAxis,'tag', 'LegendLine');
    text1 = findobj(hAxis,'tag', 'LegendText');
    if ~isempty(lines1)
        delete(lines1)
    end
    if ~isempty(text1)
        delete(text1)
    end
    stateS.handle.legend.lines = [];
    stateS.handle.legend.text = [];
%     if isfield(stateS.handle,'legend')
%         %delete(stateS.handle.legend.lines)
%         %delete(stateS.handle.legend.text)
%         stateS.handle.legend.lines = setdiff(stateS.handle.legend.lines,lines1);
%         stateS.handle.legend.text = setdiff(stateS.handle.legend.text,text1);
%     else
%         stateS.handle.legend.lines = [];
%         stateS.handle.legend.text = [];
%     end
    
    if ispc
        fontsize = round(rowHeight/2);
    else
        fontsize = round(rowHeight*3/4);
    end
    for i=1:numCols
        for j=1:numRows
            lineH = rectangle('parent',hAxis,'Position', [1+(i-1)*6, j+0.65 0.7 0.7],'Curvature', [1 1], 'tag', 'LegendLine','Clipping','on');
            stateS.handle.legend.lines = [stateS.handle.legend.lines lineH];
            stateS.handle.legend.text = [stateS.handle.legend.text text(2.2+(i-1)*6, j+1, '', 'HorizontalAlignment', 'left', 'fontsize', fontsize, 'parent', hAxis, 'tag', 'LegendText','Clipping','on', 'interpreter','none')];
        end
    end

    set(hAxis, 'xlim', [0 (colWidth/rowHeight)*currPos(3) / colWidth], 'ylim', [0 currPos(4) / rowHeight]);
    posYall = [0 numRows+3];
    hf = get(hAxis,'parent');
    dXY = axis(hAxis);
    dispY = axis(hAxis);
    posYall(1) = posYall(1) + dXY(4)-dXY(3);
    posY = get(hAxis,'position');
    unitsU = get(hAxis,'units');
    try % to take care of initial call
        delete(stateS.legendSlider)
        stateS.legendSlider = [];
    catch
        if ~isfield(stateS,'legendSlider')
            stateS.legendSlider = [];
        end
    end
    if posYall(2)>posYall(1)
        dxSlider = max(10,min(15,0.08*posY(3)));
        hs = uicontrol(hf,'units',unitsU,'position',[posY(1)+posY(3)-dxSlider posY(2) dxSlider posY(4)],...
            'min',posYall(1),'max',posYall(2),'value',posYall(2),'sliderstep',[0.1 0.2]...
            ,'callback','ySliderCallL','ButtonDownFcn','ySliderCallL','style','slider','BackgroundColor',[0 0 0],'tag','legendSlider','userdata',{hAxis posYall});
        stateS.legendSlider = hs;
    end
end

yLim = get(hAxis,'yLim');
if abs(yLim(2)-yLim(1) - currPos(4) / rowHeight) > 1e-5
    set(hAxis, 'xlim', [0 (colWidth/rowHeight)*currPos(3) / colWidth], 'ylim', [0 currPos(4) / rowHeight]);
end
xLim = get(hAxis,'xLim');
if xLim(1) < 0
    xLim(2) = xLim(2)-xLim(1);
    xLim(1) = 0;
    set(hAxis, 'xlim', xLim);
end

%Store new position.
setappdata(hAxis, 'legendAxisLastPos', currPos);

% %Prepare field values for each contour line.
% visV      = get(hStructs, 'visible');
% bool = strcmpi(visV, 'off');
% colors    = get(hStructs, 'color');
% %linestyle = get(hStructs, 'linestyle');
% %linewidth = get(hStructs, 'linewidth');
% if length(hStructs) == 1
%     colors    = {colors};
%     %linestyle = {linestyle};
%     %linewidth = {linewidth};
% end

%For each unique contour make a text/line object visible and label it.
numStructsAvailable = length(bool);
for i=1:numStructsAvailable %1:min(length(hStructs), length(stateS.handle.legend.text))    
    if bool(i) == 1
        col = [0.9 0.9 0.5];
    else
        col = [.5 .5 .5];
    end
    
    structStr = sprintf('%d',structNumsV(i));
    set(stateS.handle.legend.text(i), 'string', hLabels{i}, 'buttondownfcn',...
        ['sliceCallBack(''toggleSingleStruct'',''', structStr ,''')'], 'color', col);
    set(stateS.handle.legend.lines(i), 'facecolor', colors{i}, 'edgecolor', colors{i},...
        'visible', 'on', 'buttondownfcn', ['sliceCallBack(''toggleSingleStruct'',''', structStr ,''')']);

    %     if strcmpi(get(hStructs(i), 'tag'), 'structContour')
%         structStr = sprintf('%d',ud(i).structNum);
%         set(stateS.handle.legend.text(i), 'string', hLabels{i}, 'buttondownfcn', ['sliceCallBack(''toggleSingleStruct'',''', structStr ,''')']);
%         set(stateS.handle.legend.lines(i), 'facecolor', colors{i}, 'edgecolor', colors{i}, 'visible', 'on', 'buttondownfcn', ['sliceCallBack(''toggleSingleStruct'',''', structStr ,''')']);
%     else
%         set(stateS.handle.legend.text(i), 'string', hLabels{i}, 'buttondownfcn', '');
%         set(stateS.handle.legend.lines(i), 'facecolor', colors{i}, 'edgecolor', colors{i}, 'visible', 'on', 'buttondownfcn', '');
%     end    
end
for i = 1:length(colorsDoseC)
    j = numStructsAvailable + i;
    set(stateS.handle.legend.text(j), 'string', labelsDoseC{i}, 'buttondownfcn', '', 'Color', [0.9 0.9 0.5]);
    set(stateS.handle.legend.lines(j), 'facecolor', colorsDoseC{i}, 'edgecolor', colorsDoseC{i}, 'visible', 'on', 'buttondownfcn', '');
end

%indOff = min(length(hStructs), length(stateS.handle.legend.text))+1:length(stateS.handle.legend.lines);
indOff = min(numStructsAvailable+length(colorsDoseC), length(stateS.handle.legend.text))+1:length(stateS.handle.legend.lines);

%for i=min(length(hStructs), length(stateS.handle.legend.text))+1:length(stateS.handle.legend.lines)
set(stateS.handle.legend.text(indOff), 'string', '');
set(stateS.handle.legend.lines(indOff), 'visible', 'off');
%end


ySliderCallL
