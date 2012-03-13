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
indexS = planC{end};

% Set properties correctly
set(hAxis, 'xDir', 'normal','yDir', 'reverse')

%Get userdata for structure contours, contains name and structNum.
hStructs = findobj('tag', 'structContour');
ud = get(hStructs, 'userdata');
if isempty(ud)
    hStructs   = [];
    hLabels    = {};
elseif length(ud) == 1
    hLabels    = {ud.structDesc};
else
    ud         = [ud{:}];
    [jnk, ind] = unique([ud.structNum]);
    ud         = ud(ind);
    hStructs   = hStructs(ind);
    hLabels    = {ud.structDesc};
end

%Get userdata for dose contours, contains doselevel.
hIso = findobj('tag', 'isodoseContour');
if ~isempty(hIso)
    isoValues  = get(hIso, 'userdata');
    [jnk, ind] = unique([isoValues{:}]);
    hStructs   = [hStructs;hIso(ind)];
    uniqueValues = isoValues(ind);
    type = stateS.optS.isodoseLevelType;
    if strcmp(type,'percent')
        for i=1:length(uniqueValues)
            hLabels= {hLabels{:},[num2str(uniqueValues{i}*100/(stateS.optS.isodoseNormalizVal)) ' %']};
        end
    elseif strcmp(type,'absolute')
        for i=1:length(uniqueValues)
            if strcmpi(getDoseUnitsStr(stateS.doseSet,planC), 'cgy')
                hLabels= {hLabels{:},[num2str(uniqueValues{i}) ' cGy']};
            else
                hLabels= {hLabels{:},[num2str(uniqueValues{i}) ' Gy']};
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

udH = get(hAxis,'userdata');
try % to take care of initial call
    %udS=get(udH.legendSlider,'userdata');
    udS=get(stateS.legendSlider,'userdata');
end

%Repopulate text/line fields if position has changed, or if the old
%lines/text are no longer valid handles
if isempty(lastPos) | ~isequal(lastPos, currPos) | any(~ishandle(stateS.handle.legend.lines)) | any(~ishandle(stateS.handle.legend.text)) | (exist('udS') & ~isempty(udS) & udS{2}(2)<length(planC{indexS.structures})+1) | length(stateS.handle.legend.lines)<=length(planC{indexS.structures})
    
    numCols = 1;
    numRows = length(planC{indexS.structures}) + 7;   % APA: always draw one line, text extra for new structure and 6 for isodose lines

    try
        lines1 = findobj(hAxis,'tag', 'LegendLines');
        text1 = findobj(hAxis,'tag', 'LegendText');
        if ~isempty(lines1)
            delete(lines1)
        end
        if ~isempty(text1)
            delete(text1)
        end
        delete(stateS.handle.legend.lines)
        delete(stateS.handle.legend.text)
        stateS.handle.legend.lines = setdiff(stateS.handle.legend.lines,lines1);
        stateS.handle.legend.text = setdiff(stateS.handle.legend.text,text1);

    catch
        stateS.handle.legend.lines = [];
        stateS.handle.legend.text = [];
    end

    if ispc
        fontsize = round(rowHeight/2);
    else
        fontsize = round(rowHeight*3/4);
    end
    for i=1:numCols
        for j=1:numRows
            lineH = rectangle('parent',hAxis,'Position', [1+(i-1)*6, j+0.65 0.7 0.7],'Curvature', [1 1]);
            stateS.handle.legend.lines = [stateS.handle.legend.lines lineH];
            stateS.handle.legend.text = [stateS.handle.legend.text text(2.2+(i-1)*6, j+1, '', 'HorizontalAlignment', 'left', 'fontsize', fontsize, 'parent', hAxis, 'tag', 'LegendText','Clipping','on')];
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

%Store new position.
setappdata(hAxis, 'legendAxisLastPos', currPos);

%Prepare field values for each contour line.
visV      = get(hStructs, 'visible');
colors    = get(hStructs, 'color');
linestyle = get(hStructs, 'linestyle');
linewidth = get(hStructs, 'linewidth');
if length(linewidth) == 1
    colors    = {colors};
    linestyle = {linestyle};
    linewidth = {linewidth};
end

%For each unique contour make a text/line object visible and label it.
for i=1:min(length(linewidth), length(stateS.handle.legend.text))
    bool = strcmpi(visV, 'off');
    if bool(i) == 1;
        set(stateS.handle.legend.text(i), 'Color', [.5 .5 .5]);
    else
        set(stateS.handle.legend.text(i), 'Color', [1 1 1]);
    end
    if strcmpi(get(hStructs(i), 'tag'), 'structContour')
        set(stateS.handle.legend.text(i), 'string', hLabels{i}, 'buttondownfcn', ['sliceCallBack(''toggleSingleStruct'',''', num2str(ud(i).structNum) ,''')']);
        set(stateS.handle.legend.lines(i), 'facecolor', colors{i,:}, 'edgecolor', colors{i,:}, 'visible', 'on', 'buttondownfcn', ['sliceCallBack(''toggleSingleStruct'',''', num2str(ud(i).structNum) ,''')']);
    else
        set(stateS.handle.legend.text(i), 'string', hLabels{i}, 'buttondownfcn', '');
        set(stateS.handle.legend.lines(i), 'facecolor', colors{i,:}, 'edgecolor', colors{i,:}, 'visible', 'on', 'buttondownfcn', '');
    end    
end
for i=min(length(linewidth), length(stateS.handle.legend.text))+1:length(stateS.handle.legend.lines)
    set(stateS.handle.legend.text(i), 'string', '');
    set(stateS.handle.legend.lines(i), 'visible', 'off');
end

ySliderCallL
