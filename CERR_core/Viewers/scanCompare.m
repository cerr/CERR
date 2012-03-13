function scanCompare(command,varargin)
% scanComparison
% changes the display on CERR to a scan comparison mode if there are more
% than two scans present. The scans are linked in transverse slice so if
% you move one scan other also moves
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

if length(planC{3})<2
    warndlg('Need to have more than one scan to use this mode')
    return
end

switch lower(command)
    case 'init'
        if stateS.layout == 7
            doseCompare('exit');
        end
        
        hCSV = stateS.handle.CERRSliceViewer;
        hCSVA = stateS.handle.CERRSliceViewerAxis;
        stateS.layout = 6;
        stateS.Oldlayout = 6;
        if length( stateS.handle.CERRAxis)>4
            delete(stateS.handle.CERRAxis(5:end));
            stateS.handle.CERRAxisLabel1(5:end)=[];
            stateS.handle.CERRAxisLabel2(5:end)=[];
            stateS.handle.CERRAxis(5:end)=[];
        end
        stateS.handle.CERRAxis(end+1)=axes('parent',hCSV, 'units', 'pixels', 'position', [1 1 1 1], 'color', [0 0 0], 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'buttondownfcn', 'sliceCallBack(''axisClicked'')',...
            'nextplot', 'add', 'yDir', 'reverse', 'linewidth', 2,'visible','on','Tag','scanCompareAxes');
        stateS.handle.CERRAxisLabel1(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.02 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
        stateS.handle.CERRAxisLabel2(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.90 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');

        leftMarginWidth = 195; bottomMarginHeight = 70;
        pos = get(hCSV, 'position');
        figureWidth = pos(3); figureHeight = pos(4);
        wid = (figureWidth-leftMarginWidth-70-10)/2;
        hig = (figureHeight-bottomMarginHeight-20);
        set(stateS.handle.CERRAxis(1), 'position', [leftMarginWidth+60 bottomMarginHeight+10 wid hig]);
        set(stateS.handle.CERRAxis(5), 'position', [leftMarginWidth+wid+10+60 bottomMarginHeight+10 wid hig]);
        axisInfo = get(hCSVA, 'userdata');
        axisInfo.scanObj(1:end) = [];
        axisInfo.doseObj(1:end) = [];
        axisInfo.structureGroup(1:end) = [];
        axisInfo.miscHandles = [];
        axisInfo.coord       = {'Linked', hCSVA};
        axisInfo.view        = {'Linked', hCSVA};
        axisInfo.xRange      = {'Linked', hCSVA};
        axisInfo.yRange      = {'Linked', hCSVA};
        axisInfo.miscHandles = [stateS.handle.CERRAxisLabel1(end) stateS.handle.CERRAxisLabel2(end)];
        set(stateS.handle.CERRAxis(5), 'userdata', axisInfo);
        doseSet = getScanAssociatedDose(2);
        setAxisInfo(stateS.handle.CERRAxis(5),'doseSets',doseSet,'doseSelectMode', 'manual');
        scanSets = 2;
        structureSets = getStructureSetAssociatedScan(2);
        setAxisInfo(stateS.handle.CERRAxis(5),'scanSets',scanSets,'scanSelectMode', 'manual',...
            'structureSets',structureSets,'structSelectMode','manual');
        CERRAxisMenu(stateS.handle.CERRAxis(5));
        CERRRefresh
        sliceCallBack('resize');
    case 'exit'
        stateS.Oldlayout = [];
        if length( stateS.handle.CERRAxis)>4
            delete(stateS.handle.CERRAxis(5:end));
            stateS.handle.CERRAxisLabel1(5:end)=[];
            stateS.handle.CERRAxisLabel2(5:end)=[];
            stateS.handle.CERRAxis(5:end)=[];
        end
        
        for i = 1:length(stateS.handle.CERRAxis)
            setAxisInfo(stateS.handle.CERRAxis(i),'doseSets',stateS.doseSet,...
                'structureSets',stateS.structSet,'scanSets',stateS.scanSet);
            setappdata(stateS.handle.CERRAxis(i),'compareMode',[]);
        end
        
        sliceCallBack('resize');
        CERRRefresh

end
