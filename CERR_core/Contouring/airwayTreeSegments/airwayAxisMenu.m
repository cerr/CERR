function airwayAxisMenu(command, varargin)
%"airwayAxisMenu"
%   Handles callbacks from the right click menus for all CERR axes.  Also
%   creates new right click menus in passed axes, and interfaces with the
%   ud.axisInfo field that all CERR viewer axes have.
%
%APA 5/11/2021
%
%Usage:
%   function airwayAxisMenu(command, varargin)
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

global airwayStateS stateS

if ishandle(command) & strcmpi(get(command, 'type'), 'axes')
    varargin{1} = command;
    command     = 'init';
elseif ~ischar(command)
    error('Invalid call to airwayAxisMenu.');
end

switch upper(command)
    
    
    case 'UPDATE_MENU'
        hMenu = gcbo;
        ud = get(hMenu, 'userdata');
        hpV = ud{1};
        elemDoseV = ud{2};
        elemRadV = ud{3};
        elemDiffDistV = ud{4};
        
        %Wipe out old submenus.
        kids = get(hMenu, 'children');
        delete(kids);
        
        %Create top level menus.
        hDose        = uimenu(hMenu, 'Label', 'dose - Gy','Callback',...
            'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hpV, elemDoseV});
        hSize        = uimenu(hMenu, 'Label', 'min surface dist - cm', 'Callback',...
            'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hpV, elemRadV});
        %hArea        = uimenu(hMenu, 'Label', 'Area', 'Callback',...
        %    'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hpV, elemAreaV});
        hSizeChange  = uimenu(hMenu, 'Label', 'change in min surface distance - %','Callback',...
            'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hpV, elemDiffDistV});
        nodeStart  = uimenu(hMenu, 'Label', 'Select starting node','Callback',...
            'airwayAxisMenu(''SELECT_START_NODE'')', 'userdata', {hpV});
        nodeStop  = uimenu(hMenu, 'Label', 'Select ending node','Callback',...
            'airwayAxisMenu(''SELECT_END_NODE'')', 'userdata', {hpV});
        
    case 'INIT_START_STOP_VIEW_NODES'
        hMenu = gcbo;
        %Wipe out old submenus.
        kids = get(hMenu, 'children');
        delete(kids);
        ud = get(hMenu, 'userdata');
        axisType = ud{1};
        hAxis = ud{2};
        hPlot = ud{3};
        basePt = ud{4};
%         hStartStop  = uimenu(hMenu, 'Label', 'Add nodes','Callback',...
%             'airwayAxisMenu(''ADD_START_STOP_NODES'')', 'userdata', {hAxis,hPlot,axisType});
%         hRemoveNodes  = uimenu(hMenu, 'Label', 'Remove nodes','Callback',...
%             'airwayAxisMenu(''REMOVE_START_STOP_NODES'')', 'userdata', {hAxis,hPlot,axisType});
        if strcmpi(axisType,'base')
            %             vf = ud{5};
            %             xFieldV = ud{6};
            %             yFieldV = ud{7};
            %             zUnifV = ud{8};
            %             followupPt = ud{9};
            %             minDistBaseV = ud{10};
            %             radiusDiffV = ud{11};
            %             nodeOrigDoseV = ud{12};
            nodeXyzInterpM = ud{5};
            followupPt = ud{6};
            minDistBaseV = ud{7};
            radiusDiffV = ud{8};
            nodeOrigDoseV = ud{9};
%             hCerrViewer  = uimenu(hMenu, 'Label', 'View location in viewer','Callback',...
%                 'airwayAxisMenu(''SHOW_IN_CERR_VIEWER'')', 'userdata', ...
%                 {hPlot,axisType,basePt,vf,xFieldV,yFieldV,zUnifV,followupPt});
%             hCerrViewer  = uimenu(hMenu, 'Label', 'View location in viewer','Callback',...
%                 'airwayAxisMenu(''SHOW_IN_CERR_VIEWER'')', 'userdata', ...
%                 {hPlot,axisType,basePt,nodeXyzInterpM,followupPt});
            hDose        = uimenu(hMenu, 'Label', 'dose - Gy','Callback',...
                'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hPlot, nodeOrigDoseV});
            hSize        = uimenu(hMenu, 'Label', 'min surface dist - cm', 'Callback',...
                'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hPlot, minDistBaseV});
            %hArea        = uimenu(hMenu, 'Label', 'Area', 'Callback',...
            %    'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hpV, elemAreaV});
            hSizeChange  = uimenu(hMenu, 'Label', 'change in min surface distance - %','Callback',...
                'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hPlot, radiusDiffV});
            hNoColor  = uimenu(hMenu, 'Label', 'No color','Callback',...
                'airwayAxisMenu(''CHANGE_MAP'')', 'userdata', {hPlot, [0.5,0.5,0.5]});
            
%             if airwayStateS.baseAddNodes
%                 set(hStartStop,'checked', 'on')
%             end
%             if airwayStateS.baseShowInCerrViewer
%                 set(hCerrViewer,'checked', 'on')
%             end
%             if airwayStateS.baseRemoveNodes
%                 set(hRemoveNodes,'checked', 'on')
%             end
        else
%             hCerrViewer  = uimenu(hMenu, 'Label', 'View location in viewer','Callback',...
%                 'airwayAxisMenu(''SHOW_IN_CERR_VIEWER'')', 'userdata', {hPlot,axisType,basePt});
%             if airwayStateS.followupAddNodes
%                 set(hStartStop,'checked', 'on')
%             end
%             if airwayStateS.followupShowInCerrViewer
%                 set(hCerrViewer,'checked', 'on')
%             end
%             if airwayStateS.followupRemoveNodes
%                 set(hRemoveNodes,'checked', 'on')
%             end
        end
        
    case 'ADD_START_STOP_NODES'
        disp('starting node')
        menuLabel   = get(gcbo, 'Label');
        ud       = get(gcbo, 'userdata');
        hAxis = ud{1};
        hPlot = ud{2};
        axisType = ud{3};
        if strcmpi(axisType,'base')
            airwayStateS.baseAddNodes = 1;
            airwayStateS.baseShowInCerrViewer = 0;
            airwayStateS.baseRemoveNodes = 0;
        else
            airwayStateS.followupAddNodes = 1;
            airwayStateS.followupShowInCerrViewer = 0;
            airwayStateS.followupRemoveNodes = 0;
        end
        % Callback to add nodes
        buttonDownFcn = @pickStatrStopNodes;
        set(hPlot,'ButtonDownFcn',{buttonDownFcn,hAxis,axisType});
        %hp = ud{1};
        %set(hp,'ButtonDownFcn',{@pickStatrStopNodes});
        
    case 'REMOVE_START_STOP_NODES'
        disp('ending node')
        ud       = get(gcbo, 'userdata');
        hAxis = ud{1};
        hPlot = ud{2};
        axisType = ud{3};
        if strcmpi(axisType,'base')
            airwayStateS.baseAddNodes = 0;
            airwayStateS.baseShowInCerrViewer = 0;
            airwayStateS.baseRemoveNodes = 1;
        else
            airwayStateS.followupAddNodes = 0;
            airwayStateS.followupShowInCerrViewer = 0;
            airwayStateS.followupRemoveNodes = 1;
        end
        % Callback to add nodes
        buttonDownFcn = @pickStatrStopNodes;
        set(hPlot,'ButtonDownFcn',{buttonDownFcn,hAxis,axisType});
        %hp = ud{1};
        %set(hp,'ButtonDownFcn',{@pickStatrStopNodes});
        
    case 'SHOW_IN_CERR_VIEWER'
        airwayStateS.addNodes = 0;
        airwayStateS.showInCerrViewer = 1;
        airwayStateS.removeNodes = 0;
        disp('location in viewer')
        ud       = get(gcbo, 'userdata');
        %axisType = ud{1};
        hPlot = ud{1};
        % Callback to show nodes in Viewer
        buttonDownFcn = @showNodeInCerrViewer;
        %set(hPlotBase,'ButtonDownFcn',{buttonDownFcn,axisType,vf,xFieldV,yFieldV,zUnifV,...
        %    basePt,followupPt})
        set(hPlot,'ButtonDownFcn',{buttonDownFcn,ud{2:end}})
        
        
    case 'CHANGE_MAP'
        %         stateS.viewChanged = 1;
        if isfield(airwayStateS,'hCbar') && ishandle(airwayStateS.hCbar)
            delete(airwayStateS.hCbar)
        end
        menuLabel   = get(gcbo, 'Label');
        ud       = get(gcbo, 'userdata');
        hp = ud{1};
        elemValV = ud{2};
        hAxis = get(hp,'parent');
        set(hp,'cData',elemValV)
        if length(elemValV)==3 %assume single rgb color
            title(hAxis,'Baseline')
            return;
        end
        minDist = min(elemValV);
        maxDist = max(elemValV);
        %         maxMinusMinDist = maxDist - minDist;
        cmapM = CERRColorMap('jetmod');
        %         cmapSiz = size(cmapM,1)-1;
        %         cmapIndV = round((elemValV - minDist) / maxMinusMinDist * cmapSiz) + 1;
        %         for i = 1:length(hp)
        %             if ~isnan(cmapIndV(i))
        %             set(hp,'MarkerFaceColor',[cmapM(cmapIndV(i),:)])
        %             end
        %         end
        set(hAxis,'cLim',[minDist,maxDist])
        colormap(cmapM)
        ticksV = linspace(minDist,maxDist,5);
        tickC = {};
        for i = 1:length(ticksV)
            tickC{i} = num2str(ticksV(i));
        end
        airwayStateS.hCbar = colorbar(hAxis,'Ticks',ticksV,'TickLabels',tickC,...
            'units','normalized','position',[0.45,0.7,0.02,0.2]);
        titleStr = ['Baseline (',menuLabel,')'];
        title(hAxis,titleStr)
        %hCbarLine = line('parent',hCbar,'xdata',[-5 5],...
        %    'ydata',[level level],'color','k','LineWidth',3);
        
end

