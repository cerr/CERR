function plotIVHCallback(command, varargin)
%"plotIVHCallback"
%   Callbacks for IVH plots, all functions are in the expanded view.
%
%JRA 5/20/04
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
%   function plotIVHCallback(command, varargin)

switch upper(command)
    case 'EXPANDEDVIEW'
    %Request to expand the DVH view.
        hFig = get(gcbo, 'parent');        
        ud = get(hFig, 'userdata');
        set(hFig, 'doublebuffer', 'on');
        
        %Freeze all other figure objects.
        figChild = get(hFig, 'children');
        for i=1:length(figChild)
            try
                set(figChild(i), 'units', 'pixels');
            end
        end
        
        %Add margin on right side of figure.
        pos = get(hFig, 'position');
        if ~isfield(ud, 'handles')        
            pos(3) = pos(3) + 200;
        else
            framePos = get(ud.handles.frame, 'position');
            frameWidth = framePos(3);
            pos(3) = pos(3) + frameWidth;
        end
        set(hFig, 'position', pos);
        
        %Return units to normalized.
        figChild = get(hFig, 'children');
        for i=1:length(figChild)
            try
                set(figChild(i), 'units', 'normalized');
            end
        end
        
        %Change menubar item to reflect change back option.
        set(gcbo, 'label', 'Simple Options', 'callback',['plotIVHCallback(''SIMPLEVIEW'')']);
        
        %Actually perform the initialization.
        if ~isfield(ud, 'handles')
            plotIVHCallback('INITEXPANDED');
            set(hFig, 'toolbar', 'figure');
        else
            try
                set(ud.handles.motionline, 'visible', 'on')
            end
            
            try
                n = get(ud.handles.strList, 'value');
                if n > 0
                    set(ud.plots(n-1).hLine, 'selected', 'on');
                    hAxis = get(ud.plots(n-1).hLine, 'parent');
                    set(hAxis, 'buttonDownFcn', 'plotIVHCallback(''CLICKINPLOT'')');                    
                end
            end
        end
        for i=1:length(ud.plots)
            set(ud.plots(i).hLine, 'hittest', 'on', 'buttondownfcn',['plotIVHCallback(''IVHCLICKED'', ' num2str(i) ')']);
        end
        
    case 'IVHCLICKED'
        clicked = varargin{1};
        hAxis = get(gcbo, 'parent');
        hFig = get(hAxis, 'parent');
        ud = get(hFig, 'userdata');
        set(ud.handles.strList, 'value', clicked+1);
        plotIVHCallback('SELECTIVH');
        return;
        
    case 'SIMPLEVIEW'
    %Return to the simple view by contracting the margin.    
        hFig = get(gcbo, 'parent');
        ud = get(hFig, 'userdata');
        
        %Freeze all other figure objects.
        figChild = get(hFig, 'children');
        for i=1:length(figChild)
            try
                set(figChild(i), 'units', 'pixels');
            end
        end

        %Remove the margin, using the frame size as guide.
        framePos = get(ud.handles.frame, 'position');
        frameWidth = framePos(3);
        pos = get(hFig, 'position');
        pos(3) = pos(3) - frameWidth;
        set(hFig, 'position', pos);
        
        try
            set(ud.handles.motionline, 'visible', 'off')
        end
        
        for i=1:length(ud.plots)
            hAxis = get(ud.plots(i).hLine, 'parent');            
            set(ud.plots(i).hLine, 'selected', 'off', 'hittest', 'off');
        end
        set(hAxis, 'buttonDownFcn', '');
                       
        %Return units to normalized.
        figChild = get(hFig, 'children');
        for i=1:length(figChild)
            try
                set(figChild(i), 'units', 'normalized');
            end
        end
        
        set(gcbo, 'label', 'Expanded Options', 'callback',['plotIVHCallback(''EXPANDEDVIEW'')']);        
        
    case 'INITEXPANDED'
    %If this is the first time the expanded view is requested, draw all the uicontrols.    
        barW = 200;
        hFig = get(gcbo, 'parent');
        
        ud = get(hFig, 'userdata');
        plots = ud.plots;
        
        hAxis = get(plots(1).hLine, 'parent');
        
        pos = get(hFig, 'position');
        h = pos(4); w = pos(3);
        units = 'pixels';
        
        for i=1:length(plots)
            strNames{i} = [plots(i).struct '--' num2str(plots(i).doseNum)];
            set(plots(i).hLine, 'hittest', 'off');
        end
        strNames = {'None' strNames{:}};
        
        frame.X = w-barW+10;        
        frame.Y = 10;
        frame.W = barW-20;
        frame.H = h-20;
        hTmp = uicontrol(hFig, 'style', 'frame', 'units', units, 'position', [frame.X frame.Y frame.W frame.H]);        
        frameColor = get(hTmp, 'BackgroundColor');
        delete(hTmp);
        %Dummy frame for units.
        ud.handles.frame = axes('units', units, 'Position', [w-barW 0 barW h], 'visible', 'off');
        axes('units', units, 'Position', [frame.X frame.Y frame.W frame.H], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on', 'parent', hFig);
 
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-25 80 15], 'string', 'Selected DVH:', 'horizontalAlignment', 'left');
        ud.handles.strList = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-25 80 15], 'string', strNames, 'horizontalAlignment', 'left', 'callback', 'plotIVHCallback(''SELECTIVH'');');

        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-50 80 15], 'string', 'Linestyle:', 'horizontalAlignment', 'left');
        hTmp = axes('units', units, 'Position', [frame.X+90 frame.Y+frame.H-50 80 15], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'off', 'parent', hFig, 'xcolor', frameColor, 'ycolor', frameColor);        
        ud.handles.lineStyle = line([0 1], [.5 .5], 'color', 'red', 'linestyle', '-', 'visible', 'off', 'parent', hTmp);
        
        ud.handles.doseTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-75 80 15], 'string', 'FromDose:', 'horizontalAlignment', 'left');
        ud.handles.doseVal = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-75 80 15], 'string', '.', 'horizontalAlignment', 'right');
        
        ud.handles.statTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-100 80 15], 'string', 'DVH Stats:', 'horizontalAlignment', 'left');
        
        ud.handles.meanTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+20 frame.Y+frame.H-125 80 15], 'string', 'Mean Scan:', 'horizontalAlignment', 'left');
        ud.handles.meanVal = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-125 80 15], 'string', '.', 'horizontalAlignment', 'right');
        
        ud.handles.totalTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+20 frame.Y+frame.H-150 80 15], 'string', 'Total Vol:', 'horizontalAlignment', 'left');
        ud.handles.totalVal = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-150 80 15], 'string', '.', 'horizontalAlignment', 'right');
        
        ud.handles.maxTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+20 frame.Y+frame.H-175 80 15], 'string', 'Max Scan:', 'horizontalAlignment', 'left');
        ud.handles.maxVal = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-175 80 15], 'string', '.', 'horizontalAlignment', 'right');
        
        ud.handles.minTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+20 frame.Y+frame.H-200 80 15], 'string', 'Min Scan:', 'horizontalAlignment', 'left');
        ud.handles.minVal = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-200 80 15], 'string', '.', 'horizontalAlignment', 'right');
        
        ud.handles.abovePtTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-250 170 15], 'string', 'Vol above point in DVH:', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-275 80 15], 'string', 'Scan', 'horizontalAlignment', 'center');
        ud.handles.volTxt = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-275 80 15], 'string', 'Volume', 'horizontalAlignment', 'center');        
              
        ud.handles.scanDoseVal = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-300 80 20], 'string', '.', 'horizontalAlignment', 'center', 'callback', 'plotIVHCallback(''DOSEVAL'')');    
        ud.handles.scanVolVal = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [frame.X+90 frame.Y+frame.H-300 80 15], 'string', '.', 'horizontalAlignment', 'center'); 
                        
        %control to display legend in new figure
        ud.handles.legendChk = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-350 150 20], 'string', 'Show Legend', 'horizontalAlignment', 'center', 'callback', 'plotIVHCallback(''LEGENDCALL'')');
        
        %control to export IVH to excel
        ud.handles.exportIVH = uicontrol(hFig, 'style', 'push', 'units', units, 'position', [frame.X+10 frame.Y+frame.H-380 100 20], 'string', 'Export IVH', 'horizontalAlignment', 'center', 'callback', 'plotIVHCallback(''EXPORTIVH'')');
        
        yLim = get(hAxis, 'yLim');
        ud.handles.motionline = line([0 0], [yLim(1) yLim(2)], 'color', 'blue', 'parent', hAxis, 'hittest', 'off');                    
        
        %Return units to normalized.
        figChild = get(hFig, 'children');
        for i=1:length(figChild)
            try
                set(figChild(i), 'units', 'normalized');
            end
        end       
        set(hFig, 'userdata', ud);        
        
    case 'SELECTIVH'
        %An IVH has been selected from the list, populate fields.
        if strcmpi(get(gcbo, 'type'), 'line')
            hAxis = get(gcbo, 'parent');
            hFig = get(hAxis, 'parent');
            ud = get(hFig, 'userdata');
            hPopup = ud.handles.strList;
        elseif strcmpi(get(gcbo, 'type'), 'uicontrol')
            hFig = get(gcbo, 'parent');                
            ud = get(hFig, 'userdata');
            hPopup = ud.handles.strList;
        end
        val = get(hPopup, 'value');
        val = val - 1;
        hPlots = [ud.plots.hLine];
        set(hPlots, 'selected', 'off');        
        if val > 0
            hAxis = get(hPlots(val), 'parent');
            set(hAxis, 'buttonDownFcn', 'plotIVHCallback(''CLICKINPLOT'')');
            set(hPlots(val), 'selected', 'on');
            lS = get(hPlots(val), 'linestyle');
            col = get(hPlots(val), 'color');
            lW = get(hPlots(val), 'linewidth');
            set(ud.handles.lineStyle, 'linestyle', lS, 'color', col, 'linewidth', lW, 'visible', 'on');   
            
            dose = str2double(get(ud.handles.scanDoseVal, 'string'));
            currentPlot = get(ud.handles.strList, 'value') - 1;
            xLim = get(hAxis, 'xLim');              
            if dose < xLim(1)
                dose = xLim(1);    
            elseif dose > xLim(2)
                dose = xLim(2);
            end            
            surfVol = interp1(ud.plots(currentPlot).xVals, ud.plots(currentPlot).yVals, dose);
            if isnan(surfVol)
                surfVol = 0;
            end
            if ~strcmpi(ud.plots(currentPlot).abs, 'ABS')
                surfVol = surfVol*100;    
            end        
            set(ud.handles.motionline, 'xdata', [dose dose], 'visible', 'on');
            set(ud.handles.scanDoseVal, 'string', num2str(dose));
            set(ud.handles.scanVolVal, 'string', num2str(surfVol));                                       
            %If we are dealing with a DSH, rename fields and use different
            %metrics calculations from DVH.
            if strcmpi(ud.plots(val).type, 'DSH')
                areaV = ud.plots(val).volsV;
                dosesV = ud.plots(val).doseBins;
                meanD = sum(dosesV.*areaV)/sum(areaV);
                totalArea = sum(areaV);
                maxDose = max(dosesV);
                minDose = min(dosesV);
                set(ud.handles.statTxt, 'string', 'DSH Stats:')
                set(ud.handles.totalTxt, 'string', 'Total Surface:')
                set(ud.handles.meanVal, 'string', num2str(meanD))
                set(ud.handles.totalVal, 'string', num2str(totalArea))
                set(ud.handles.maxVal, 'string', num2str(maxDose));
                set(ud.handles.minVal, 'string', num2str(minDose));
                set(ud.handles.doseVal, 'string', ud.plots(val).doseName);
                if strcmpi(ud.plots(val).abs, 'ABS')
                    set(ud.handles.abovePtTxt, 'string', 'Abs Surface above selected level:')
                    set(ud.handles.volTxt, 'string', 'Abs Surface');                
                else
                    set(ud.handles.abovePtTxt, 'string', '% Surface above selected level:')
                    set(ud.handles.volTxt, 'string', '% Surface');                                                     
                end
                
            %If we are dealing with a IVH, rename fields and use different
            %metrics calculations from ISH.                                     
            elseif strcmpi(ud.plots(val).type, 'IVH')
                volHistV = ud.plots(val).volsV;
                doseBinsV = ud.plots(val).doseBins;
                meanD = sum(doseBinsV.*volHistV)/sum(volHistV);
                totalVol = sum(volHistV);
                ind = max(find([volHistV~=0]));
                maxD = doseBinsV(ind);
                ind = min(find([volHistV~=0]));
                minD = doseBinsV(ind);
                set(ud.handles.statTxt, 'string', 'IVH Stats:')
                set(ud.handles.totalTxt, 'string', 'Total Volume:')
                set(ud.handles.meanVal, 'string', num2str(meanD))
                set(ud.handles.totalVal, 'string', num2str(totalVol))
                set(ud.handles.maxVal, 'string', num2str(maxD));
                set(ud.handles.minVal, 'string', num2str(minD));      
                set(ud.handles.doseVal, 'string', ud.plots(val).doseName);                
                if strcmpi(ud.plots(val).abs, 'ABS')
                    set(ud.handles.abovePtTxt, 'string', 'Abs Volume above selected level:')
                    set(ud.handles.volTxt, 'string', 'Abs Volume');                
                else
                    set(ud.handles.abovePtTxt, 'string', '% Volume above selected level:')
                    set(ud.handles.volTxt, 'string', '% Volume');                                                     
                end
            else
                error('Not a valid plot type for IVH callback.')
            end
        else
            hAxis = get(hPlots(1), 'parent');
            set(hAxis, 'buttonDownFcn', '')            
            set(ud.handles.lineStyle, 'visible', 'off'); 
            set(ud.handles.motionline, 'visible', 'off');             
        end
        set(hFig, 'userdata', ud);
        
    case 'CLICKINPLOT'
    %A DVH is selected and the plot has been clicked, update guide line/fields.    
        hAxis = gcbo;
        hFig = get(hAxis, 'parent');
        ud = get(hFig, 'userdata');
        set(hFig, 'WindowButtonUpFcn', 'plotIVHCallback(''UNCLICKINPLOT'')');
        set(hFig, 'WindowButtonMotionFcn', 'plotIVHCallback(''PLOTMOTION'')');
        currentPlot = get(ud.handles.strList, 'value') - 1;
        cP = get(hAxis, 'currentpoint');
        %Interpolate Surf/Vol, display.
        dose = cP(1,1); 
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
        surfVol = interp1(ud.plots(currentPlot).xVals, ud.plots(currentPlot).yVals, dose);
        if isnan(surfVol)
            surfVol = 0;
        end        
        if ~strcmpi(ud.plots(currentPlot).abs, 'ABS')
            surfVol = surfVol*100;    
        end
        set(ud.handles.motionline, 'xdata', [dose dose], 'visible', 'on');
        set(ud.handles.scanDoseVal, 'string', num2str(dose));
        set(ud.handles.scanVolVal, 'string', num2str(surfVol));
        
    case 'UNCLICKINPLOT'
        hFig = gcbo;
        ud = get(hFig, 'userdata');
        set(hFig, 'WindowButtonMotionFcn', '');        
        set(hFig, 'WindowButtonUpFcn', '');        
        set(hFig, 'userdata', ud);
        
    case 'DOSEVAL'
    %A value has been entered into the doseVal field.
        hFig = get(gcbo, 'parent');
        dose = str2double(get(gcbo, 'string'));
        ud = get(hFig, 'userdata');
        currentPlot = get(ud.handles.strList, 'value') - 1;
        hAxis = get(ud.plots(currentPlot).hLine, 'parent');
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
        surfVol = interp1(ud.plots(currentPlot).xVals, ud.plots(currentPlot).yVals, dose);
        if isnan(surfVol)
            surfVol = 0;
        end
        if ~strcmpi(ud.plots(currentPlot).abs, 'ABS')
            surfVol = surfVol*100;    
        end
        set(ud.handles.motionline, 'xdata', [dose dose], 'visible', 'on');
        set(ud.handles.scanDoseVal, 'string', num2str(dose));
        set(ud.handles.scanVolVal, 'string', num2str(surfVol));            
        
    case 'PLOTMOTION'
    %An IVH is selected, the plot has been clicked and motion is occuring. Update guide line/fields.            
        hFig = gcbo;        
        ud = get(hFig, 'userdata');
        currentPlot = get(ud.handles.strList, 'value') - 1;
        hAxis = get(ud.plots(currentPlot).hLine, 'parent');
        cP = get(hAxis, 'currentpoint');
        dose = cP(1,1); 
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
        surfVol = interp1(ud.plots(currentPlot).xVals, ud.plots(currentPlot).yVals, dose);
        if isnan(surfVol)
            surfVol = 0;
        end
        if ~strcmpi(ud.plots(currentPlot).abs, 'ABS')
            surfVol = surfVol*100;    
        end       
        set(ud.handles.motionline, 'xdata', [dose dose], 'visible', 'on');
        set(ud.handles.scanDoseVal, 'string', num2str(dose));
        set(ud.handles.scanVolVal, 'string', num2str(surfVol));    
        
    case 'LEGENDCALL'
        %executes when "Show Legend" is toggled on or off
        
        value = get(gcbo,'value');
        hLegend = findobj('tag','IVH_Legend');
        close(hLegend)
        if value == 0
            return;
        end
        hFig = get(gcbo, 'parent');        
        ud = get(hFig, 'userdata');
        hLegend = figure('tag','IVH_Legend','name','IVH Legend','numberTitle','off','menubar','Figure','color','w');
        position = get(hLegend,'position');
        figColor = get(hLegend,'color');
        axisLegend = axes('units', 'normalized', 'Position', [0 0 1 1], 'color', figColor, 'ytick',[],'xtick',[], 'box', 'off', 'parent', hLegend,'nextPlot','add','units','normalized','visible','off');
        numLines = length(ud.plots);
        dy = 0.8/numLines;
        position(3) = 400;
        position(4) = (numLines+1)*30;
        set(hLegend,'position',position)

        for i = 1:numLines
            LineStyle = get(ud.plots(i).hLine,'LineStyle');
            LineWidth = get(ud.plots(i).hLine,'LineWidth');
            Color = get(ud.plots(i).hLine,'Color');
            line([0.05 0.15],[0.8-(i-1)*dy 0.8-(i-1)*dy],'LineStyle',LineStyle,'LineWidth',LineWidth,'Color',Color,'parent',axisLegend)
            txt = ['Struct = ',ud.plots(i).struct,', Scan = ',ud.plots(i).doseName];
            text(0.18,0.8-(i-1)*dy,txt)
        end
        axis(axisLegend,[0 1 0 1])
        

    case 'EXPORTIVH'
        hFig = get(gcbo, 'parent');        
        ud = get(hFig, 'userdata');
        currentIVH = get(ud.handles.strList, 'value') - 1;
        if currentIVH == 0
            warndlg('Please select IVH to be exported.','IVH not selected','modal')
            return;
        end
        
        M = [ud.plots(currentIVH).xVals; ud.plots(currentIVH).yVals];
        %Export only NumPts points
        NumPts = 65000;
        if size(M,2)>NumPts
            indAll = round(linspace(1,size(M,2),NumPts));
            M = M(:,indAll);
        end
        [fname, pname] = uiputfile('*.xls','Save the IVH data as:');
        if isnumeric(fname)
            return;
        end
        try
            xlswrite(fullfile(pname,fname), M');
        catch
            csvwrite(fullfile(pname,fname), M'); 
        end

end
