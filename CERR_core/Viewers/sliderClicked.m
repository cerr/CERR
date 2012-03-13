function sliderClicked()
% this function is activated when the slider on the Legend Axis is clicked.
% Created DK 9 Dec 2005
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

global stateS

hAxis = stateS.handles.CERRLegend;
stateS.sliderValue.current = get(stateS.handle.sliderLegend,'value');
stateS.sliderValue.Max =  get(stateS.handle.sliderLegend,'Max');
if stateS.sliderValue.current == get(stateS.handle.sliderLegend,'Max')
    showCERRLegend(hAxis);
else
    axisInfo = get(hAxis,'userdata');
    hStructs  = axisInfo.hStruct;
    numCols  = axisInfo.numCols;
    numRows  = axisInfo.numRows;
    count    = axisInfo.count;
    fontsize = axisInfo.fontsize;
    hLabels  = axisInfo.hLabels;
    ud       = axisInfo.ud;
    delete(findobj('tag', 'LegendLines'));delete(findobj('tag', 'LegendText'));

%     % String wraper part
%     if numCols > 1
%         stringLength = floor(colWidth/fontsize)-1;
%     else
%         stringLength = [];
%     end

    for i=1:numCols
        for j=1:numRows
            count = count + 1;
            if count <= length(hStructs)
                stateS.handle.legend.lines(count) = rectangle('position',[0+(i-1)*7,j+0.5,0.5,0.5],'parent', hAxis, 'tag', 'LegendLines');
                stateS.handle.legend.text(count) = text(1+(i-1)*7, j+1, '', 'HorizontalAlignment', 'left', 'fontsize', fontsize, 'parent', hAxis, 'tag', 'LegendText');
            end
        end
    end
    try
    visV      = get(hStructs, 'visible');
    colors    = get(hStructs, 'color');
    catch
        return
    end

    for i=axisInfo.count+1:min(length(hStructs), length(stateS.handle.legend.text))
        bool = strcmpi(visV, 'off');
        if bool(i) == 1;
            set(stateS.handle.legend.text(i), 'Color', [.5 .5 .5]);
        else
            set(stateS.handle.legend.text(i), 'Color', [1 1 1]);
        end
        if strcmpi(get(hStructs(i), 'tag'), 'structContour')
            set(stateS.handle.legend.text(i), 'string', hLabels{i}, 'buttondownfcn', ['sliceCallBack(''toggleSingleStruct'',''', num2str(ud(i).structNum) ,''')']);
        else
            set(stateS.handle.legend.text(i), 'string', hLabels{i}, 'buttondownfcn', '');
        end
        set(stateS.handle.legend.lines(i), 'FaceColor', colors{i,:}, 'visible', 'on');
    end
end