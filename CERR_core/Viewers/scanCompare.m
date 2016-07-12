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

if length(planC{indexS.scan})<2
    warndlg('Need to have more than one scan to use this mode')
    return
end

switch lower(command)
    case 'init'
        if stateS.layout == 7
            doseCompare('exit');
        end
        if stateS.layout == 6
            scanCompare('exit');
            return;
        end
        hCSV = stateS.handle.CERRSliceViewer;
        %hCSVA = stateS.handle.CERRSliceViewerAxis;
        hCSVA = stateS.handle.CERRAxis(1);

        numScans = length(planC{indexS.scan});
        if numScans < 2
            warndlg('Scan Comparison tool requires 2 or more scans');
            return
        elseif numScans > 4
            newAxis = 3;
        else
            newAxis = numScans-1;            
        end
        stateS.doseCompare.newAxis = newAxis;
        
        stateS.Oldlayout = stateS.layout;
        stateS.layout = 6;        
        if length( stateS.handle.CERRAxis)>4
            delete(stateS.handle.CERRAxis(5:end));
            stateS.handle.CERRAxisLabel1(5:end) = [];
            stateS.handle.CERRAxisLabel2(5:end) = [];
            stateS.handle.CERRAxis(5:end) = [];
            stateS.handle.aI(5:end) = [];
        end
        
        tickV = linspace(0.02,0.1,6);
        for i = 4+(1:newAxis) % create linked axis to the transverse axis
            stateS.handle.CERRAxis(i) = axes('parent',stateS.handle.CERRSliceViewer, 'units', 'pixels', 'position', [1 1 1 1],...
                'color', [0 0 0], 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'buttondownfcn',...
                'sliceCallBack(''axisClicked'')', 'nextplot', 'add', 'yDir', 'reverse', 'linewidth', 2,...
                'visible','off','Tag','scanCompareAxes','ZLim',[-2 2]);
            
            %             stateS.handle.CERRAxisLabel1(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.02 .98 0],...
            %                 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
            %
            %             stateS.handle.CERRAxisLabel2(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.90 .98 0],...
            %                 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
            
            aI = axisInfoFactory;
            aI.coord   = 0;
            aI.view    = 'transverse';
            
            aI.scanObj(1:end) = [];
            aI.doseObj(1:end) = [];
            aI.structureGroup(1:end) = [];
            aI.miscHandles = [];
            aI.coord       = {'Linked', hCSVA};
            aI.view        = {'Linked', hCSVA};
            aI.xRange      = {'Linked', hCSVA};
            aI.yRange      = {'Linked', hCSVA};                        
            
            stateS.handle.aI = dissimilarInsert(stateS.handle.aI,aI,i);

            
%             for j = 1:6
%                 ticks1V(j) = line([tickV(j) tickV(j)], [0.01 0.03], [2 2], 'parent', stateS.handle.CERRAxis(end), 'color', [0.7 0.7 0.7], 'hittest', 'off');
%                 ticks2V(j) = line([0.01 0.03], [tickV(j) tickV(j)], [2 2], 'parent', stateS.handle.CERRAxis(end), 'color', [0.7 0.7 0.7], 'hittest', 'off');
%             end
%             stateS.handle.CERRAxisTicks1(end+1,:) = ticks1V;
%             stateS.handle.CERRAxisTicks2(end+1,:) = ticks2V;
%             stateS.handle.CERRAxisScale1(end+1) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(end), 'color', [0.7 0.7 0.7], 'hittest', 'off');
%             stateS.handle.CERRAxisScale2(end+1) = line([0.02 0.02], [0.02 0.1], [2 2], 'parent', stateS.handle.CERRAxis(end), 'color', [0.7 0.7 0.7], 'hittest', 'off');
%             stateS.handle.CERRAxisLabel3(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '5', 'position', [0.02 0.1 0], 'color', [0.7 0.7 0.7], 'units', 'data', 'visible', 'off','fontSize',8);
%             stateS.handle.CERRAxisLabel4(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '5', 'position', [0.1 0.02 0], 'color', [0.7 0.7 0.7], 'units', 'data', 'visible', 'off','fontSize',8);
%             %stateS.handle.CERRAxisPlaneLocator1(end+1)
%             %stateS.handle.CERRAxisPlaneLocator2(end+1)
%             AI(i).miscHandles = [stateS.handle.CERRAxisLabel1(end) stateS.handle.CERRAxisLabel2(end) stateS.handle.CERRAxisLabel3(end) stateS.handle.CERRAxisLabel4(end) stateS.handle.CERRAxisScale1(end) stateS.handle.CERRAxisScale2(end) stateS.handle.CERRAxisTicks1(end,:) stateS.handle.CERRAxisTicks2(end,:)];
        end

        %axisInfo = get(hCSVA, 'userdata');
%         axisInfo.scanObj(1:end) = [];
%         axisInfo.doseObj(1:end) = [];
%         axisInfo.structureGroup(1:end) = [];
%         axisInfo.miscHandles = [];
%         axisInfo.coord       = {'Linked', hCSVA};
%         axisInfo.view        = {'Linked', hCSVA};
%         axisInfo.xRange      = {'Linked', hCSVA};
%         axisInfo.yRange      = {'Linked', hCSVA};

        scanNum = getAxisInfo(hCSVA,'scanSets');
        scanNums = [scanNum setdiff(1:numScans,scanNum)];
        for i = 1:newAxis
            %axisInfo.miscHandles = AI(i).miscHandles;
            %set(stateS.handle.CERRAxis(4+i), 'userdata', axisInfo);
            setAxisInfo(stateS.handle.CERRAxis(4+i),'scanSets',scanNums(i+1),'scanSelectMode', 'manual');
            CERRAxisMenu(stateS.handle.CERRAxis(4+i));
            set(stateS.handle.CERRAxis(4+i),'visible','on');
        end
        
        %%% new
        
        % Create a pool of line objects to display contours
        for axNum = 4+(1:newAxis) %length(stateS.handle.CERRAxis)
            aI = stateS.handle.aI(axNum);
            for i = 1:stateS.optS.linePoolSize
                aI.lineHandlePool(1).lineV(i) = line(NaN, NaN, 'parent', stateS.handle.CERRAxis(axNum), 'linestyle', '-', 'hittest', 'off', 'visible', 'off');
                aI.lineHandlePool(1).dotsV(i) = line(NaN, NaN, 'parent', stateS.handle.CERRAxis(axNum), 'linestyle', ':', 'hittest', 'off', 'visible', 'off');
            end
            aI.lineHandlePool(1).currentHandle = 0;
            stateS.handle.aI(axNum) = aI;
        end
        
        %Create in-axis labels for each axis.
        tickV = linspace(0.02,0.1,6);
        for i=4+(1:newAxis)
            
            stateS.handle.CERRAxisLabel1(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '', 'position', [.02 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
            stateS.handle.CERRAxisLabel2(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '', 'position', [.90 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
            for j = 1:6
                ticks1V(j) = line([tickV(j) tickV(j)], [0.01 0.03], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', 'y', 'hittest', 'off', 'visible', 'off');
                ticks2V(j) = line([0.01 0.03], [tickV(j) tickV(j)], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', 'y', 'hittest', 'off', 'visible', 'off');
            end
            stateS.handle.CERRAxisTicks1(i,:) = ticks1V;
            stateS.handle.CERRAxisTicks2(i,:) = ticks2V;
            stateS.handle.CERRAxisScale1(i) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', [1 0.5 0.5], 'hittest', 'off', 'visible', 'off');
            stateS.handle.CERRAxisScale2(i) = line([0.02 0.02], [0.02 0.1], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', [1 0.5 0.5], 'hittest', 'off', 'visible', 'off');
            stateS.handle.CERRAxisLabel3(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '5', 'position', [0.02 0.1 0], 'color', 'y', 'units', 'data', 'visible', 'off', 'hittest', 'off','fontSize',8);
            stateS.handle.CERRAxisLabel4(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '5', 'position', [0.1 0.02 0], 'color', 'y', 'units', 'data', 'visible', 'off', 'hittest', 'off','fontSize',8);
            
            %aI = get(stateS.handle.CERRAxis(i), 'userdata');
            aI = stateS.handle.aI(i);
            stateS.handle.CERRAxisPlnLoc{i} = [];
            stateS.handle.CERRAxisPlnLocSdw{i} = [];
            if ~strcmpi(aI.view, 'Legend')
                
                for count = 1:10
                    if stateS.MLVersion < 8.4
                        stateS.handle.CERRAxisPlnLocSdw{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'horz', 'trans', i}, 'hittest', 'off', 'linewidth', 1, 'erasemode','xor');
                        stateS.handle.CERRAxisPlnLoc{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocator',  'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'vert', 'trans', i}, 'linewidth', 1, 'erasemode','xor');
                    else
                        stateS.handle.CERRAxisPlnLocSdw{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'horz', 'trans', i}, 'hittest', 'off', 'linewidth', 1);
                        stateS.handle.CERRAxisPlnLoc{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocator',  'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'vert', 'trans', i}, 'linewidth', 1);
                    end
                end
                
            end
            
            aI.miscHandles = [aI.miscHandles stateS.handle.CERRAxisLabel1(i) ...
                stateS.handle.CERRAxisLabel2(i) stateS.handle.CERRAxisLabel3(i) ...
                stateS.handle.CERRAxisLabel4(i) stateS.handle.CERRAxisScale1(i) ...
                stateS.handle.CERRAxisScale2(i) stateS.handle.CERRAxisTicks1(i,:) ...
                stateS.handle.CERRAxisTicks2(i,:) stateS.handle.CERRAxisPlnLoc{i} ...
                stateS.handle.CERRAxisPlnLocSdw{i}];
            %set(stateS.handle.CERRAxis(i), 'userdata', aI);
            stateS.handle.aI(i) = aI;
        end
        
        %%% new ends
        
        if stateS.MLVersion >= 8.4
            set(stateS.handle.CERRAxis,'ClippingStyle','rectangle')
        end
        
        stateS.scanSetChanged = 1;
        CERRRefresh
        sliceCallBack('RESIZE');
        hScanCompare = findobj('tag','scanCompareMenu');
        set(hScanCompare,'checked','on')
        
        
% ---------------------- Two panels
%         stateS.handle.CERRAxis(end+1)=axes('parent',hCSV, 'units', 'pixels', 'position', [1 1 1 1], 'color', [0 0 0], 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'buttondownfcn', 'sliceCallBack(''axisClicked'')',...
%             'nextplot', 'add', 'yDir', 'reverse', 'linewidth', 2,'visible','on','Tag','scanCompareAxes');
%         stateS.handle.CERRAxisLabel1(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.02 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
%         stateS.handle.CERRAxisLabel2(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.90 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
% 
%         leftMarginWidth = 195; bottomMarginHeight = 70;
%         pos = get(hCSV, 'position');
%         figureWidth = pos(3); figureHeight = pos(4);
%         wid = (figureWidth-leftMarginWidth-70-10)/2;
%         hig = (figureHeight-bottomMarginHeight-20);
%         set(stateS.handle.CERRAxis(1), 'position', [leftMarginWidth+60 bottomMarginHeight+10 wid hig]);
%         set(stateS.handle.CERRAxis(5), 'position', [leftMarginWidth+wid+10+60 bottomMarginHeight+10 wid hig]);
%         axisInfo = get(hCSVA, 'userdata');
%         axisInfo.scanObj(1:end) = [];
%         axisInfo.doseObj(1:end) = [];
%         axisInfo.structureGroup(1:end) = [];
%         axisInfo.miscHandles = [];
%         axisInfo.coord       = {'Linked', hCSVA};
%         axisInfo.view        = {'Linked', hCSVA};
%         axisInfo.xRange      = {'Linked', hCSVA};
%         axisInfo.yRange      = {'Linked', hCSVA};
%         axisInfo.miscHandles = [stateS.handle.CERRAxisLabel1(end) stateS.handle.CERRAxisLabel2(end)];
%         set(stateS.handle.CERRAxis(5), 'userdata', axisInfo);
%         doseSet = getScanAssociatedDose(2);
%         setAxisInfo(stateS.handle.CERRAxis(5),'doseSets',doseSet,'doseSelectMode', 'manual');
%         scanSets = 2;
%         structureSets = getStructureSetAssociatedScan(2);
%         setAxisInfo(stateS.handle.CERRAxis(5),'scanSets',scanSets,'scanSelectMode', 'manual',...
%             'structureSets',structureSets,'structSelectMode','manual');
%         CERRAxisMenu(stateS.handle.CERRAxis(5));
%         CERRRefresh
%         sliceCallBack('resize');
%         hScanCompare = findobj('tag','scanCompareMenu');
%         set(hScanCompare,'checked','on')
        
    case 'exit'
        %sliceCallBack('layout',stateS.Oldlayout)     
        delete([findobj('tag', 'spotlight_patch'); findobj('tag', 'spotlight_xcrosshair'); findobj('tag', 'spotlight_ycrosshair'); findobj('tag', 'spotlight_trail')]);
        CERRStatusString('');
        
        stateS.layout = stateS.Oldlayout;
        stateS.Oldlayout = [];
        
        % Find and delete the duplicate (linked) views        
        for i = length(stateS.handle.CERRAxis):-1:1
            hAxis = stateS.handle.CERRAxis(i);
            view = stateS.handle.aI(i).view;            
            if iscell(view)
                sliceCallBack('selectaxisview', hAxis, 'delete view');
            else
                viewC{i} = view;
            end            
        end
        
%         % Set Axes order
%         for i = 1:length(stateS.handle.CERRAxis)
%             viewC{i} = getAxisInfo(stateS.handle.CERRAxis(i),'view');
%         end
        
        transIndex = strmatch('transverse',viewC);
        sagIndex = strmatch('sagittal',viewC);
        corIndex = strmatch('coronal',viewC);
        legIndex = strmatch('legend',viewC);
        
        orderV = [transIndex(:)', sagIndex(:)', corIndex(:)', legIndex(:)'];
        
        stateS.handle.CERRAxis = stateS.handle.CERRAxis(orderV);
        stateS.handle.CERRAxisLabel1 = stateS.handle.CERRAxisLabel1(orderV);
        stateS.handle.CERRAxisLabel2 = stateS.handle.CERRAxisLabel2(orderV);
        stateS.handle.CERRAxisLabel3 = stateS.handle.CERRAxisLabel3(orderV);
        stateS.handle.CERRAxisLabel4 = stateS.handle.CERRAxisLabel4(orderV);
        stateS.handle.CERRAxisScale1 = stateS.handle.CERRAxisScale1(orderV);
        stateS.handle.CERRAxisScale2 = stateS.handle.CERRAxisScale2(orderV);
        stateS.handle.CERRAxisTicks1 = stateS.handle.CERRAxisTicks1(orderV,:);
        stateS.handle.CERRAxisTicks2 = stateS.handle.CERRAxisTicks2(orderV,:);
        stateS.handle.CERRAxisPlnLocSdw = stateS.handle.CERRAxisPlnLocSdw(orderV);
        stateS.handle.CERRAxisPlnLoc = stateS.handle.CERRAxisPlnLoc(orderV);
        stateS.handle.aI = stateS.handle.aI(orderV);
        %stateS.handle.CERRAxisPlaneLocator1 = stateS.handle.CERRAxisPlaneLocator1(orderV);
        %stateS.handle.CERRAxisPlaneLocator2 = stateS.handle.CERRAxisPlaneLocator2(orderV);
        
        for i = 1:length(stateS.handle.CERRAxis)
            setAxisInfo(stateS.handle.CERRAxis(i),'doseSets',stateS.doseSet,...
                'structureSets',stateS.structSet,'scanSets',stateS.scanSet);
            setappdata(stateS.handle.CERRAxis(i),'compareMode',[]);
        end
        sliceCallBack('resize');
        CERRRefresh
        hScanCompare = findobj('tag','scanCompareMenu');
        set(hScanCompare,'checked','off')        
        
end
