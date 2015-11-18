function doseShadowGui(varargin)
%"doseShadowGui"
%   Create a GUI to create and view dose shadows.
%
% JRA 11/19/03
%LM: DK 03/10/05 return warning if dose not present
%   APA 08/31/2006 - 
%            (i) Made goto slice option available.
%           (ii) Declared planC as global and not set as application data. 
%          (iii) Used axis and figure handles instead of gca, gcbo so that
%          the
%                GUI does not break on simultaneous usage of another figure.
%           (iv) Fixed a bug where x,y and z values of stateS.scanUID were
%           used instead of associated scan for the selected structure.
%           (v) Removed ctXVals, ctYVals, ctZVals fields from userdata
%           since they are dynamically obtained based associated scan for
%           the selected structure.
%           (vi) Implemented ability to toggle struct/dose/mode while rendering.
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
%Usage: doseShadowGui('init', planC)

global stateS planC
indexS = planC{end};

switch upper(varargin{1})
    case 'INIT'
        if stateS.imageRegistration
            warning('please exit Fusion before using dose shadow');
            return
        end

        numDose = length(planC{indexS.dose});
        if numDose < 1
            warndlg('Cannot initiate without Dose','Dose Shadow GUI');
            return
        end

        numStructs = length(planC{indexS.structures});
        if numStructs < 1
            warndlg('Cannot initiate without Structure/s','Dose Shadow GUI');
            return
        end
        
        screenSize = get(0,'ScreenSize');
        y = 700; %Initial size of figure in pixels. Figure scales fairly well.
        x = 900;
        units = 'normalized';

        h = figure('name', 'Dose Projections', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'doseShadowGui', 'Color', [.75 .75 .75], 'DoubleBuffer', 'on','WindowButtonDownFcn', 'doseShadowGui(''buttondown'');','WindowButtonUpFcn', 'doseShadowGui(''buttonup'');', 'WindowButtonMotionFcn', 'doseShadowGui(''motion'');', 'interruptible', 'off');
        stateS.handle.doseShadowFig = h;

        %Axes that provide border highlight around shadow axis.
        ud.handles.background.upperleft = axes('position', [.014 .505 .38 .48], 'color', [0 0 0], 'ytick',[],'xtick',[], 'box', 'on');
        ud.handles.background.lowerright= axes('position', [.405 .015 .38 .48], 'color', [0 0 0], 'ytick',[],'xtick',[], 'box', 'on');
        ud.handles.background.lowerleft = axes('position', [.015 .015 .38 .48],  'color', [0 0 0], 'ytick',[],'xtick',[], 'box', 'on');
        ud.handles.background.legend = axes('position', [.795 .015 .19 .97],  'color', [.5 .5 .5], 'ytick',[],'xtick',[], 'box', 'on');

        %Axes that display the shadow.
        ud.handles.axis.upperleft       = axes('position', [.02 .51 .3656 .47], 'tag', 'upperleft', 'color', [0 0 0], 'ytick',[],'xtick',[], 'NextPlot', 'add', 'yDir', 'reverse');
        ud.handles.axis.lowerright      = axes('position', [.41 .02 .3656 .47], 'tag', 'lowerright', 'color', [0 0 0], 'ytick',[],'xtick',[], 'NextPlot', 'add', 'yDir', 'reverse');
        ud.handles.axis.lowerleft       = axes('position', [.02 .02 .3656 .47], 'tag', 'lowerleft', 'color', [0 0 0], 'ytick',[],'xtick',[], 'NextPlot', 'add', 'yDir', 'reverse');
        ud.handles.axis.legend          = axes('position', [.8 .02 .18 .96], 'tag', 'lowerleft', 'color', [0 0 0], 'ytick',[],'xtick',[], 'NextPlot', 'add', 'yDir', 'reverse');
        ud.handles.legendSlider         = uicontrol('style','slider','units','normalized','position', [.972 .02 .015 .96], 'tag', 'lenendSlider', 'backgroundcolor', [0 0 0],'min',0,'max',1,'value',1, 'callback', 'doseShadowGui(''REFRESHLEGEND'');');

        %Store positions of T,C,S axes
        ud.pos.transAxis = get(ud.handles.axis.upperleft,'position');
        ud.pos.corAxis   = get(ud.handles.axis.lowerleft,'position');
        ud.pos.sagAxis   = get(ud.handles.axis.lowerright,'position');
        
        %uicontrol(h, 'units',units,'Position',[.63 .51 .35 .47], 'Style', 'frame');
        uicontrol(h, 'units',units,'Position',[.49 .51 .295 .47], 'Style', 'frame');

        %Labels for controls and fields.
        x=.51;, y=.93;, dx=.095;, dy=.025;
        uicontrol(h, 'units',units,'Position',[x y dx dy],'String','Struct:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.03 dx dy],'String','Mode:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.06 dx dy],'String','doseSet:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.12 dx dy],'String','Dose:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.15 dx dy],'String','Slice:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.18 dx dy],'String','Col:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.21 dx dy],'String','Row:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.24 dx dy],'String','zVal:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.27 dx dy],'String','xVal:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.30 dx dy],'String','yVal:', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol(h, 'units',units,'Position',[x y-.335 dx dy],'String','Print Mode:', 'Style', 'text', 'HorizontalAlignment', 'left', 'enable', 'on');
        uicontrol(h, 'units',units,'Position',[x y-.37 dx dy],'String','Goto Slice:', 'Style', 'text', 'HorizontalAlignment', 'left', 'enable', 'on');
        uicontrol(h, 'units',units,'Position',[x y-.40 dx dy],'String','Crosshairs:', 'Style', 'text', 'HorizontalAlignment', 'left');

        %The actual fields and controls, saved for later access.
        x=.66;, y=.93;, dx=.095;, dy=.025;
        ud.handles.structVal= uicontrol(h, 'units',units,'Position',[x y dx dy],'String',[{''} {planC{indexS.structures}.structureName}], 'Style', 'popupmenu', 'HorizontalAlignment', 'left','callback', 'doseShadowGui(''SELECTSTRUCT'');');
        ud.handles.modeVal  = uicontrol(h, 'units',units,'Position',[x y-.03 dx dy], 'Style', 'popupmenu', 'string', [{'Max'}, {'Min'}, {'Mean'}], 'Tag', 'operation', 'callback', 'doseShadowGui(''SELECTMODE'');');
        ud.handles.doseSet  = uicontrol(h, 'units',units,'Position',[x y-.06 dx dy], 'Style', 'popupmenu', 'string', [{planC{indexS.dose}.fractionGroupID}], 'Tag', 'operation', 'callback', 'doseShadowGui(''SELECTDOSESET'');');
        ud.handles.doseVal  = uicontrol(h, 'units',units,'Position',[x y-.12 dx dy],'String','', 'Style', 'text', 'HorizontalAlignment', 'right');
        ud.handles.sliceVal = uicontrol(h, 'units',units,'Position',[x y-.15 dx dy],'String','', 'Style', 'text', 'HorizontalAlignment', 'right');
        ud.handles.colVal   = uicontrol(h, 'units',units,'Position',[x y-.18 dx dy],'String','', 'Style', 'text', 'HorizontalAlignment', 'right');
        ud.handles.rowVal   = uicontrol(h, 'units',units,'Position',[x y-.21 dx dy],'String','', 'Style', 'text', 'HorizontalAlignment', 'right');
        ud.handles.zVal     = uicontrol(h, 'units',units,'Position',[x y-.24 dx dy],'String','', 'Style', 'text', 'HorizontalAlignment', 'right');
        ud.handles.xVal     = uicontrol(h, 'units',units,'Position',[x y-.27 dx dy],'String','', 'Style', 'text', 'HorizontalAlignment', 'right');
        ud.handles.yVal     = uicontrol(h, 'units',units,'Position',[x y-.30 dx dy],'String','', 'Style', 'text', 'HorizontalAlignment', 'right');
        ud.handles.printBox = uicontrol(h, 'units',units,'Position',[x y-.335 dx dy], 'Style', 'checkbox', 'Value', 0, 'callback', 'doseShadowGui(''toggleprintmode'');');
        ud.handles.gotoBox  = uicontrol(h, 'units',units,'Position',[x y-.37 dx dy], 'Style', 'checkbox', 'Value', 0, 'callback', 'doseShadowGui(''gototoggle'');', 'enable', 'on');
        ud.handles.crossBox = uicontrol(h, 'units',units,'Position',[x y-.40 dx dy], 'Style', 'checkbox', 'Value', 0, 'callback', 'doseShadowGui(''crosshairtoggle'');');
        
        
        %Set default state.
        ud.mode                                 = 'max';
        ud.structure                            = 0;
        ud.dose                                 = 1;
        ud.buttondown                           = 0;
        ud.gotoToggleOn                         = 0;
        ud.crossHairOn                          = 0;
        doseArray                               = getDoseArray(planC{indexS.dose}(ud.dose));
        ud.dMax                                 = double(max(doseArray(:)));
        try
            ud.colormap = CERRColorMap(stateS.optS.doseColormap);
        catch
            ud.colormap = colormap;
        end

        %Prepare and draw colormap & its background.
        frame_color = [0.8314    0.8157    0.7843];
        ax_frame = axes('units',units,'Position',[.41 .51 .07 .47], 'color',frame_color,'ytick',[],'xtick',[]);
        box(ax_frame,'on')
        ud.handles.colorbar = axes('position', [.42 .52 .03 .45], 'tag', 'lowerleft', 'color', [0 0 0]);
        tmpV = 1 : -0.01 : 0;
        imagesc(tmpV', 'Tag', 'Colorbar','parent',ud.handles.colorbar);
        colormap(ax_frame, ud.colormap);
        set(ud.handles.colorbar,'xtick',[]);
        set(ud.handles.colorbar,'ytick',[]);
        ud.colorbarMaxTxt = text(1.75,2,num2str(ud.dMax,'%0.4g'), 'fontsize', 8,'parent',ud.handles.colorbar);
        ud.colorbarMinTxt = text(1.75,100,'0.00', 'fontsize', 8,'parent',ud.handles.colorbar);

        %Create text that indicates current dose on colormap.
        ud.colorbarText = text(1.75,(1-(0/ud.dMax))*98+2,num2str(0,'%0.4g'), 'fontsize', 8, 'tag', 'colorbarText', 'parent',ud.handles.colorbar);
        set(ud.handles.colorbar, 'NextPlot','add')

        %Create line that indicates current dose on colormap.
        ud.colorbarLine = line([1 2],[double((1-(0/ud.dMax))*98+2) double((1-(0/ud.dMax))*98+2)], 'linewidth', 2, 'tag', 'colorbarLine','parent',ud.handles.colorbar);       
       
        set(h, 'userdata', ud);
        
        %Draw Structures
        doseShadowGui('INITSTRUCTS')

        %Draw Structure Legend
        doseShadowGui('REFRESHLEGEND')

        return;

    case 'REFRESHLEGEND'

        ud = get(stateS.handle.doseShadowFig, 'userdata');
        numStructsDisplayed = 30;
        
        %Get the active scan 
        strIndex = get(ud.handles.structVal,'value');        
        if strIndex == 1
            scanNum = 1;
        else
            scanNum = getStructureAssociatedScan(strIndex-1,planC);
        end
        assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
        assocStructsV = find(assocScanV == scanNum);        
        numStructsInScan = length(assocStructsV);
        sliderValue = round(get(ud.handles.legendSlider, 'value'));            
        set(ud.handles.legendSlider, 'value', sliderValue)
        sliderValue = ceil(numStructsInScan/numStructsDisplayed) - sliderValue + 1;         
        structIndDisplayedV = numStructsDisplayed*(sliderValue-1)+1:min(numStructsDisplayed*sliderValue,numStructsInScan);
        assocStructsV = assocStructsV(structIndDisplayedV);        
        numStructs = length(assocStructsV);
        dy = 0.9/numStructsDisplayed;
        %Get handles for structure contours
        hTransSolid = ud.handles.hTransSolid;
        try,
            delete([ud.hLegendRect(:);ud.hLegendText(:)])
        end
        for i = 1:numStructs
            structNum = assocStructsV(i);
            structColor = planC{indexS.structures}(structNum).structureColor;
            x = 0.12;
            y = dy*i;            
            structUD.structNum = structNum;
            structUD.index = i;
            if strcmpi(get(hTransSolid{structNum},'visible'),'on')
                structUD.value = 1;
                hLegendText(i) = text(x,y,planC{indexS.structures}(structNum).structureName,'parent',ud.handles.axis.legend,'color',[1 1 1],'fontsize',8,'interpreter','none');
            else
                structUD.value = 0;
                hLegendText(i) = text(x,y,planC{indexS.structures}(structNum).structureName,'parent',ud.handles.axis.legend,'color',[0.5 0.5 0.5],'fontsize',8,'interpreter','none');
            end            
            hLegendRect(i) = rectangle('parent',ud.handles.axis.legend,'Position', [0.01 y-0.35*dy 0.09 0.02],'facecolor',structColor,'Curvature', [1 1],'buttonDownFcn','doseShadowGui(''structuretoggle'');','userdata',structUD);
        end
        set(ud.handles.axis.legend,'xLim',[0 1],'yLim',[0 1])
        if numStructs > 0
            ud.hLegendRect = hLegendRect;
            ud.hLegendText = hLegendText;
        end
        set(stateS.handle.doseShadowFig, 'userdata', ud);
        
    case 'STRUCTURETOGGLE'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        hLegendRect = ud.hLegendRect;
        hLegendText = ud.hLegendText;
        if length(varargin) == 1
            structUD = get(gcbo,'userdata');
        else
            structNum = varargin{2};
            structUD = get(ud.hLegendRect(structNum),'userdata');
        end
        structNum = structUD.structNum;
        index = structUD.index;
        value = structUD.value;

        hTransSolid = ud.handles.hTransSolid;
        hTransDots = ud.handles.hTransDots;
        hCorSolid = ud.handles.hCorSolid;
        hCorDots = ud.handles.hCorDots;
        hSagSolid = ud.handles.hSagSolid;
        hSagDots = ud.handles.hSagDots;
        if value == 1 %turn off
            set(hLegendText(index),'color',[0.5 0.5 0.5])
            structUD.value = 0;
            set(hLegendRect(index),'userdata',structUD)
            set(hTransSolid{structNum},'visible','off')
            set(hTransDots{structNum},'visible','off')
            set(hCorSolid{structNum},'visible','off')
            set(hCorDots{structNum},'visible','off')
            set(hSagSolid{structNum},'visible','off')
            set(hSagDots{structNum},'visible','off')
        else %turn on
            set(hLegendText(index),'color',[1 1 1])
            structUD.value = 1;
            set(hLegendRect(index),'userdata',structUD)
            set(hTransSolid{structNum},'visible','on')
            set(hTransDots{structNum},'visible','on')
            set(hCorSolid{structNum},'visible','on')
            set(hCorDots{structNum},'visible','on')
            set(hSagSolid{structNum},'visible','on')
            set(hSagDots{structNum},'visible','on')
        end


    case 'INITSTRUCTS'
        %Get handles for T,S,C views
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        hTransverse = ud.handles.axis.upperleft;
        hCoronal = ud.handles.axis.lowerleft;
        hSagittal = ud.handles.axis.lowerright;                
        
        matlab_version = MLVersion;
               
        hWait = waitbar(0,'Initializing Dose Projection. Please wait ...');
        set(gca,'nextPlot','add')
        
        for scanNum = 1:length(planC{indexS.scan})
            tMaxI{scanNum} = 0; tMaxJ{scanNum} = 0;
            tMinI{scanNum} = inf; tMinJ{scanNum} = inf;

            sMaxI{scanNum} = 0; sMaxJ{scanNum} = 0;
            sMinI{scanNum} = inf; sMinJ{scanNum} = inf;

            cMaxI{scanNum} = 0; cMaxJ{scanNum} = 0;
            cMinI{scanNum} = inf; cMinJ{scanNum} = inf;
        end
        
        %Draw on T,S,C views
%         numStructs = length(structsInThisScan);
        numStructs = length(planC{indexS.structures});
        hTransSolid = [];
        hTransDots  = [];
        hSagSolid   = [];
        hSagDots    = [];
        hCorSolid   = [];
        hCorDots    = [];
        
        structCalcNum = ud.structure;
        % Get min, max slice encompassing the structure
        if structCalcNum > 0
            scanNum = getStructureAssociatedScan(structCalcNum, planC);
            [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
            struct3M = getUniformStr(structCalcNum);
            [iV,jV,kV] = find3d(struct3M);
            slcTmin = min(kV);
            slcTmax = max(kV);
            slcCmin = min(iV);
            slcCmax = max(iV);
            slcSmin = min(jV);
            slcSmax = max(jV);
        end
        
        for structNum = 1:numStructs
            
            scanNum = getStructureAssociatedScan(structNum,planC);
            
            waitbar(structNum/numStructs,hWait)
                       
            struct3M = getUniformStr(structNum);
            
            [numRows,numCols,numSlcs] = size(struct3M);
            if structCalcNum <= 0
                slcTmin = 1;
                slcTmax = numSlcs;
                slcCmin = 1;
                slcCmax = numRows;
                slcSmin = 1;
                slcSmax = numCols;
            end

            %Draw on T
            structTM = zeros(numRows,numCols,'uint8');
            % for slc = 1:numSlcs
            for slc = slcTmin:slcTmax
                structTM = structTM | squeeze(struct3M(:,:,slc));                
            end
            
            % Empty structure
            if ~any(structTM(:))
                continue
            end
            
            [iV,jV] = find(structTM);
            tMinI{scanNum} = min(tMinI{scanNum},min(iV));
            tMaxI{scanNum} = max(tMaxI{scanNum},max(iV));
            tMinJ{scanNum} = min(tMinJ{scanNum},min(jV));
            tMaxJ{scanNum} = max(tMaxJ{scanNum},max(jV));

            if matlab_version >= 7 & matlab_version < 7.5
                [c, hStructContour] = contour('v6', 1:numCols, 1:numRows, single(structTM), [.5 .5], '-');
                set(hStructContour, 'parent', hTransverse,'visible','off');
                if stateS.optS.structureDots
                    [c, hStructContourDots] = contour('v6', 1:numCols, 1:numRows, single(structTM), [.5 .5], '-');
                    set(hStructContourDots, 'parent', hTransverse,'visible','off');
                end
            elseif matlab_version >= 7.5
                [c, hStructContour] = contour(hTransverse,1:numCols, 1:numRows, single(structTM), [.5 .5], '-');
                set(hStructContour, 'parent', hTransverse,'visible','off');
                if stateS.optS.structureDots
                    [c, hStructContourDots] = contour(hTransverse,1:numCols, 1:numRows, single(structTM), [.5 .5], '-');
                    set(hStructContourDots, 'parent', hTransverse,'visible','off');
                end
            else
                [c, hStructContour] = contour(1:numCols, 1:numRows, single(structTM), [.5 .5], '-');
                set(hStructContour, 'parent', hTransverse,'visible','off');
                if stateS.optS.structureDots
                    for cNum=1:length(hStructContour);
                        hStructContourDots(cNum) = line(get(hStructContour(cNum), 'xData'), get(hStructContour(cNum), 'yData'), 'parent', hTransverse, 'hittest', 'off');
                    end
                end
            end
            if stateS.optS.structureDots
                set(hStructContourDots, 'linewidth', .5, 'tag', 'structContourDots', 'linestyle', ':', 'color', [0 0 0], 'hittest', 'off')
            end
            set(hStructContour, 'linewidth', stateS.optS.structureThickness);
            set(hStructContour,'color',planC{indexS.structures}(structNum).structureColor, 'hittest', 'off');
            
            %Store transverse contour handles
            hTransSolid{structNum} = hStructContour;
            hTransDots{structNum}  = hStructContourDots;
           
            %Draw on C
            structCM = zeros(numSlcs,numCols,'uint8');
            %for slc = 1:numRows
            for slc = slcCmin:slcCmax
                structCM = structCM | squeeze(permute(struct3M(slc,:,:),[3 2 1]));                
            end
            
            [iV,jV] = find(structCM);
            cMinI{scanNum} = min(cMinI{scanNum},min(iV));
            cMaxI{scanNum} = max(cMaxI{scanNum},max(iV));
            cMinJ{scanNum} = min(cMinJ{scanNum},min(jV));
            cMaxJ{scanNum} = max(cMaxJ{scanNum},max(jV));            

            if matlab_version >= 7 && matlab_version < 7.5
                [c, hStructContour] = contour('v6', 1:numCols, 1:numSlcs, single(structCM), [.5 .5], '-');
                set(hStructContour, 'parent', hCoronal,'visible','off');
                if stateS.optS.structureDots
                    [c, hStructContourDots] = contour('v6', 1:numCols, 1:numSlcs, single(structCM), [.5 .5], '-');
                    set(hStructContourDots, 'parent', hCoronal,'visible','off');
                end
            elseif matlab_version >= 7.5
                [c, hStructContour] = contour(hCoronal,1:numCols, 1:numSlcs, single(structCM), [.5 .5], '-');
                set(hStructContour, 'parent', hCoronal,'visible','off');
                if stateS.optS.structureDots
                    [c, hStructContourDots] = contour(hCoronal,1:numCols, 1:numSlcs, single(structCM), [.5 .5], '-');
                    set(hStructContourDots, 'parent', hCoronal,'visible','off');
                end
            else
                [c, hStructContour] = contour(1:numCols, 1:numSlcs, single(structCM), [.5 .5], '-');
                set(hStructContour, 'parent', hCoronal,'visible','off');
                if stateS.optS.structureDots
                    for cNum=1:length(hStructContour);
                        hStructContourDots(cNum) = line(get(hStructContour(cNum), 'xData'), get(hStructContour(cNum), 'yData'), 'parent', hCoronal, 'hittest', 'off');
                    end
                end
            end
            if stateS.optS.structureDots
                set(hStructContourDots, 'linewidth', .5, 'tag', 'structContourDots', 'linestyle', ':', 'color', [0 0 0], 'hittest', 'off','visible','off')
            end
            set(hStructContour, 'linewidth', stateS.optS.structureThickness);
            set(hStructContour,'color',planC{indexS.structures}(structNum).structureColor, 'hittest', 'off');
            
            %Store coronal contour handles
            hCorSolid{structNum} = hStructContour;
            hCorDots{structNum}  = hStructContourDots;
                        
            %Draw on S
            structSM = zeros(numSlcs,numRows,'uint8');
            % for slc = 1:numCols                
            for slc = slcSmin:slcSmax
                structSM = structSM | squeeze(permute(struct3M(:,slc,:),[3 1 2]));
            end
            
            [iV,jV] = find(structSM);
            sMinI{scanNum} = min(sMinI{scanNum},min(iV));
            sMaxI{scanNum} = max(sMaxI{scanNum},max(iV));
            sMinJ{scanNum} = min(sMinJ{scanNum},min(jV));
            sMaxJ{scanNum} = max(sMaxJ{scanNum},max(jV));            

            if matlab_version >= 7 & matlab_version < 7.5
                [c, hStructContour] = contour('v6', 1:numRows, 1:numSlcs, single(structSM), [.5 .5], '-');
                set(hStructContour, 'parent', hSagittal,'visible','off');
                if stateS.optS.structureDots
                    [c, hStructContourDots] = contour('v6', 1:numRows, 1:numSlcs, single(structSM), [.5 .5], '-');
                    set(hStructContourDots, 'parent', hSagittal,'visible','off');
                end
            elseif matlab_version >= 7.5
                [c, hStructContour] = contour(hSagittal,1:numRows, 1:numSlcs, single(structSM), [.5 .5], '-');
                set(hStructContour, 'parent', hSagittal,'visible','off');
                if stateS.optS.structureDots
                    [c, hStructContourDots] = contour(hSagittal,1:numRows, 1:numSlcs, single(structSM), [.5 .5], '-');
                    set(hStructContourDots, 'parent', hSagittal,'visible','off');
                end
            else
                [c, hStructContour] = contour(1:numRows, 1:numSlcs, single(structSM), [.5 .5], '-');
                set(hStructContour, 'parent', hSagittal,'visible','off');
                if stateS.optS.structureDots
                    for cNum=1:length(hStructContour);
                        hStructContourDots(cNum) = line(get(hStructContour(cNum), 'xData'), get(hStructContour(cNum), 'yData'), 'parent', hSagittal, 'hittest', 'off');
                    end
                end
            end
            if stateS.optS.structureDots
                set(hStructContourDots, 'linewidth', .5, 'tag', 'structContourDots', 'linestyle', ':', 'color', [0 0 0], 'hittest', 'off','visible','off')
            end
            set(hStructContour, 'linewidth', stateS.optS.structureThickness);
            set(hStructContour,'color',planC{indexS.structures}(structNum).structureColor, 'hittest', 'off');            
            
            %Store sagittal contour handles
            hSagSolid{structNum} = hStructContour;
            hSagDots{structNum}  = hStructContourDots;
            
        end
        
        close(hWait)
               
        %Store limits for each scan
        ud.handles.axisLimits.tMaxI = tMaxI; ud.handles.axisLimits.tMaxJ = tMaxJ;
        ud.handles.axisLimits.tMinI = tMinI; ud.handles.axisLimits.tMinJ = tMinJ;

        ud.handles.axisLimits.sMaxI = sMaxI; ud.handles.axisLimits.sMaxJ = sMaxJ;
        ud.handles.axisLimits.sMinI = sMinI; ud.handles.axisLimits.sMinJ = sMinJ;

        ud.handles.axisLimits.cMaxI = cMaxI; ud.handles.axisLimits.cMaxJ = cMaxJ;
        ud.handles.axisLimits.cMinI = cMinI; ud.handles.axisLimits.cMinJ = cMinJ;        

        %Store contour handles for all views
        ud.handles.hTransSolid = hTransSolid;
        ud.handles.hTransDots = hTransDots;
        ud.handles.hCorSolid = hCorSolid;
        ud.handles.hCorDots = hCorDots;
        ud.handles.hSagSolid = hSagSolid;
        ud.handles.hSagDots = hSagDots;
        
        set(stateS.handle.doseShadowFig, 'userdata', ud)
        
        doseShadowGui('SETAXISLIMITS')
        
        %Initialize slider
        strIndex = get(ud.handles.structVal,'value');
        if strIndex == 1
            scanNum = 1;
        else
            scanNum = getStructureAssociatedScan(strIndex-1,planC);
        end       
        numStructsDisplayed = 30;
        %Find Structures associated with scanNum
        assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
        structsInThisScan = find(assocScanV == scanNum);
        numStructs = length(structsInThisScan);
        if ceil(numStructs/numStructsDisplayed) == 1
            set(ud.handles.legendSlider,'max', 1, 'value',1, 'visible', 'off')
        else
            set(ud.handles.legendSlider,'max', 1, 'value',1, 'visible', 'on')
            set(ud.handles.legendSlider,'min', 1, 'max', ceil(numStructs/numStructsDisplayed), 'value',ceil(numStructs/numStructsDisplayed))
            set(ud.handles.legendSlider,'SliderStep',[min(1,numStructsDisplayed/numStructs) min(1,numStructsDisplayed/numStructs)])
        end
                
        
    case 'SETAXISLIMITS'
        
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        
        %Get scanNum
        strIndex = get(ud.handles.structVal,'value');
        
        if strIndex == 1
            scanNum = 1;
        else
            scanNum = getStructureAssociatedScan(strIndex-1,planC);
        end

        %Get scan size
        scanInfo = planC{indexS.scan}(scanNum).uniformScanInfo;
        dim1Units = scanInfo.grid1Units;
        dim2Units = scanInfo.grid2Units;        
        dim3Units = scanInfo.sliceThickness;
        
        %Set limits based on axis position and x,y,z grid of the scan
        transAxisPos = ud.pos.transAxis;      
        corAxisPos   = ud.pos.corAxis;
        sagAxisPos   = ud.pos.sagAxis;        
        
        figPos = get(stateS.handle.doseShadowFig,'position');     
        figAspect = figPos(4)/figPos(3);
        
        %Image aspect
        tMaxI = ud.handles.axisLimits.tMaxI{scanNum}; tMaxJ = ud.handles.axisLimits.tMaxJ{scanNum};
        tMinI = ud.handles.axisLimits.tMinI{scanNum}; tMinJ = ud.handles.axisLimits.tMinJ{scanNum};

        sMaxI = ud.handles.axisLimits.sMaxI{scanNum}; sMaxJ = ud.handles.axisLimits.sMaxJ{scanNum};
        sMinI = ud.handles.axisLimits.sMinI{scanNum}; sMinJ = ud.handles.axisLimits.sMinJ{scanNum};

        cMaxI = ud.handles.axisLimits.cMaxI{scanNum}; cMaxJ = ud.handles.axisLimits.cMaxJ{scanNum};
        cMinI = ud.handles.axisLimits.cMinI{scanNum}; cMinJ = ud.handles.axisLimits.cMinJ{scanNum};        

        tAspect = (tMinI - tMaxI)/(tMinJ - tMaxJ)*dim1Units/dim2Units/figAspect;
        cAspect = (cMinI - cMaxI)/(cMinJ - cMaxJ)*dim3Units/dim1Units/figAspect;
        sAspect = (sMinI - sMaxI)/(sMinJ - sMaxJ)*dim3Units/dim2Units/figAspect;
        
        dxT = transAxisPos(3);
        dyT = transAxisPos(4);
        dxC = corAxisPos(3);
        dyC = corAxisPos(4);
        dxS = sagAxisPos(3);
        dyS = sagAxisPos(4);

        %Axis limits for T
        if tAspect >= 1 % y >= x
            if dxT > dyT/tAspect
                set(ud.handles.axis.upperleft,'position',[transAxisPos(1) transAxisPos(2) dyT/tAspect dyT])
            else
                set(ud.handles.axis.upperleft,'position',[transAxisPos(1) transAxisPos(2) dxT dxT*tAspect])
            end
        elseif tAspect < 1 % x > y
            set(ud.handles.axis.upperleft,'position',[transAxisPos(1) transAxisPos(2) dxT dxT*tAspect])
        end

        %Axis limits for C
        if cAspect >= 1 % y >= x
            if dxC > dyC/cAspect
                set(ud.handles.axis.lowerleft,'position',[corAxisPos(1) corAxisPos(2) dyC/cAspect dyC])
            else
                set(ud.handles.axis.lowerleft,'position',[corAxisPos(1) corAxisPos(2) dxC dxC*cAspect])
            end
        elseif cAspect < 1 % x > y
            set(ud.handles.axis.lowerleft,'position',[corAxisPos(1) corAxisPos(2) dxC dxC*cAspect])
        end

        %Axis limits for S
        if sAspect >= 1 % y >= x
            if dxS > dyS/sAspect
                set(ud.handles.axis.lowerright,'position',[sagAxisPos(1) sagAxisPos(2) dyS/sAspect dyS])
            else
                set(ud.handles.axis.lowerright,'position',[sagAxisPos(1) sagAxisPos(2) dxS dxS*sAspect])
            end
        elseif sAspect < 1 % x > y
            set(ud.handles.axis.lowerright,'position',[sagAxisPos(1) sagAxisPos(2) dxS dxS*sAspect])
        end
        
        if ~isempty(tMinJ)
            set(ud.handles.axis.upperleft,'xLim',[tMinJ tMaxJ],'yLim',[tMinI tMaxI])
        end
        if ~isempty(cMinJ)
            set(ud.handles.axis.lowerleft,'xLim',[cMinJ cMaxJ] ,'yLim',[cMinI cMaxI])
        end
        if ~isempty(sMinJ)
            set(ud.handles.axis.lowerright,'xLim',[sMinJ sMaxJ] ,'yLim',[sMinI sMaxI])
        end
        
        %Get positions for axes
        origPos = [.3656 .47];
        ulPos = ud.pos.transAxis;
        llPos = ud.pos.corAxis;
        lrPos = ud.pos.sagAxis;
        
        %Get center for three axes
        ulPosX = ulPos(1) + ulPos(3)/2;
        ulPosY = ulPos(2) + ulPos(4)/2;
        llPosX = llPos(1) + llPos(3)/2;
        llPosY = llPos(2) + llPos(4)/2;
        lrPosX = lrPos(1) + lrPos(3)/2;
        lrPosY = lrPos(2) + lrPos(4)/2;        
        
        ulPos = get(ud.handles.axis.upperleft,'position');
        llPos = get(ud.handles.axis.lowerleft,'position');
        lrPos =  get(ud.handles.axis.lowerright,'position');   
        ulRatio = ulPos(3:4)./origPos;
        llRatio = llPos(3:4)./origPos;
        lrRatio = lrPos(3:4)./origPos;
        
%         %ul axis has minimum ratio
%         if min(ulRatio) <= min(min(llRatio),min(lrRatio))
%             if ulRatio(1) <= ulRatio(2) % x < y
%                 dx = ulPos(3);
%                 dyLL = llPos(4) / llPos(3) * dx;
%                 dyLR = lrPos(4) / lrPos(3) * dx;
%                 set(ud.handles.axis.lowerleft,'position',[llPosX-dx/2 llPosY-dyLL/2 dx dyLL])
%                 set(ud.handles.axis.lowerright,'position',[lrPosX-dx/2 lrPosY-dyLR/2 dx dyLR])
%             else
%                 dy = ulPos(4);
%                 dxLL = llPos(3) / llPos(4) * dy;
%                 dxLR = lrPos(3) / lrPos(4) * dy;                
%                 set(ud.handles.axis.lowerleft,'position',[llPosX-dxLL/2 llPosY-dy/2 dxLL dy])
%                 set(ud.handles.axis.lowerright,'position',[lrPosX-dxLR/2 lrPosY-dy/2 dxLR dy])
%             end
%         elseif min(llRatio) <= min(min(ulRatio),min(lrRatio))
%             if llRatio(1) <= llRatio(2) % x < y
%                 dx = llPos(3);
%                 dyUL = ulPos(4) / ulPos(3) * dx;
%                 dyLR = lrPos(4) / lrPos(3) * dx;
%                 set(ud.handles.axis.upperleft,'position',[ulPosX-dx/2 ulPosY-dyUL/2 dx dyUL])
%                 set(ud.handles.axis.lowerright,'position',[lrPosX-dx/2 lrPosY-dyLR/2 dx dyLR])
%             else
%                 dy = llPos(4);
%                 dxUL = ulPos(3) / ulPos(4) * dy;
%                 dxLR = lrPos(3) / lrPos(4) * dy;                
%                 set(ud.handles.axis.upperleft,'position',[ulPosX-dxUL/2 ulPosY-dy/2 dxUL dy])
%                 set(ud.handles.axis.lowerright,'position',[lrPosX-dxLR/2 lrPosY-dy/2 dxLR dy])
%             end            
%         elseif min(lrRatio) <= min(min(ulRatio),min(llRatio))
%             if ulRatio(1) <= ulRatio(2) % x < y
%                 dx = lrPos(3);
%                 dyUL = ulPos(4) / ulPos(3) * dx;
%                 dyLL = llPos(4) / llPos(3) * dx;
%                 set(ud.handles.axis.upperleft,'position',[ulPosX-dx/2 ulPosY-dyUL/2 dx dyUL])
%                 set(ud.handles.axis.lowerleft,'position',[lrPosX-dx/2 lrPosY-dyLL/2 dx dyLL])
%             else
%                 dy = lrPos(4);
%                 dxLL = llPos(3) / llPos(4) * dy;
%                 dxUL = ulPos(3) / ulPos(4) * dy;                
%                 set(ud.handles.axis.upperleft,'position',[ulPosX-dxUL/2 ulPosY-dy/2 dxUL dy])
%                 set(ud.handles.axis.lowerleft,'position',[llPosX-dxLL/2 llPosY-dy/2 dxLL dy])                
%             end            
%         end
        
        
    case 'SELECTSTRUCT'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        % Get structure contour handles
        hTransSolid = [ud.handles.hTransSolid{:}]; %cell2mat(ud.handles.hTransSolid(:));
        hTransDots = [ud.handles.hTransDots{:}]; %cell2mat(ud.handles.hTransDots(:));
        hCorSolid = [ud.handles.hCorSolid{:}]; %cell2mat(ud.handles.hCorSolid(:));
        hCorDots = [ud.handles.hCorDots{:}]; %cell2mat(ud.handles.hCorDots(:));
        hSagSolid = [ud.handles.hSagSolid{:}]; %cell2mat(ud.handles.hSagSolid(:));
        hSagDots = [ud.handles.hSagDots{:}]; %cell2mat(ud.handles.hSagDots(:));
        % Turn off all the structures
        set(hTransSolid,'visible','off')
        set(hTransDots,'visible','off')
        set(hCorSolid,'visible','off')
        set(hCorDots,'visible','off')
        set(hSagSolid,'visible','off')
        set(hSagDots,'visible','off')
        %Find the structure index
        oldStruct = ud.structure;
        structNum = get(gcbo, 'Value')-1;
        if structNum == 0
            try, delete(findobj('tag','dose_projection')), end
            return;
        end
        [scanNum, ud.structure] = getStructureAssociatedScan(structNum, planC);
        if oldStruct == ud.structure, return, end
        set(stateS.handle.doseShadowFig, 'userdata', ud);
        % Turn on this structure only
        set(ud.handles.hTransSolid{structNum},'visible','on')
        % commented temporarily
        %set(ud.handles.hTransDots{structNum},'visible','on')
        set(ud.handles.hCorSolid{structNum},'visible','on')
        %set(ud.handles.hCorDots{structNum},'visible','on')
        set(ud.handles.hSagSolid{structNum},'visible','on')
        %set(ud.handles.hSagDots{structNum},'visible','on')        
        %Draw
        doseShadowGui('draw', ud.structure, ud.mode, ud.dose);
        %Update Legend
        numStructsDisplayed = 30;
        %Find Structures associated with scanNum
        assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
        structsInThisScan = find(assocScanV == scanNum);
        numStructs = length(structsInThisScan);
        if ceil(numStructs/numStructsDisplayed) == 1
            set(ud.handles.legendSlider,'max', 1, 'value',1, 'visible', 'off')
        else
            set(ud.handles.legendSlider,'max', 1, 'value',1, 'visible', 'on')
            set(ud.handles.legendSlider,'max', ceil(numStructs/numStructsDisplayed), 'value',ceil(numStructs/numStructsDisplayed))
            set(ud.handles.legendSlider,'SliderStep',[min(1,numStructsDisplayed/numStructs) min(1,numStructsDisplayed/numStructs)])
        end                
        doseShadowGui('REFRESHLEGEND')
        
    case 'SELECTDOSESET'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        oldDose = ud.dose;        
        % ud.dose = get(gcbo, 'Value');
        ud.dose = get(ud.handles.doseSet, 'Value');
        if oldDose == ud.dose, return, end
        doseArray = getDoseArray(planC{indexS.dose}(ud.dose));
        ud.dMax = max(doseArray(:));
        minDose = 0;
        %new
        if isfield(planC{indexS.dose}(ud.dose),'doseOffset') && ~isempty(planC{indexS.dose}(ud.dose).doseOffset)
            ud.dMax = max([planC{indexS.dose}(ud.dose).doseOffset ud.dMax-planC{indexS.dose}(ud.dose).doseOffset]);
            minDose = min([-planC{indexS.dose}(ud.dose).doseOffset -(max(doseArray(:))-planC{indexS.dose}(ud.dose).doseOffset)]);
        end
        set(ud.colorbarMinTxt,'string',num2str(minDose,'%0.4g'))
        %new ends
        set(ud.colorbarMaxTxt,'string',num2str(ud.dMax,'%0.4g'))
        set(ud.colorbarLine, 'yData', [(1-(0/ud.dMax))*98+2 (1-(0/ud.dMax))*98+2]);
        set(stateS.handle.doseShadowFig, 'userdata', ud);
        doseShadowGui('draw', ud.structure, ud.mode, ud.dose);
        
    case 'SELECTMODE'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        modes = get(gcbo, 'String');
        oldMode = ud.mode;
        ud.mode = modes{get(gcbo, 'Value')};
        if strcmpi(oldMode, ud.mode), return, end
        set(stateS.handle.doseShadowFig, 'userdata', ud);
        doseShadowGui('draw', ud.structure, ud.mode, ud.dose);

    case 'BUTTONDOWN'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        if getappdata(stateS.handle.doseShadowFig, 'CallbackRun') == 1
            return;
        end
        ud.buttondown = 1;
        set(stateS.handle.doseShadowFig, 'userdata', ud)
        hAxis = get(stateS.handle.doseShadowFig, 'currentaxes');
        if hAxis == ud.handles.axis.legend
            return;
        end
        mousePos = get(stateS.handle.doseShadowFig, 'currentpoint');
        [x,y] = figToAxis(hAxis, stateS.handle.doseShadowFig, mousePos);
        doseShadowGui('update', x, y, hAxis);


    case 'BUTTONUP'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        ud.buttondown = 0;
        if ud.gotoToggleOn
            gotoCERRslice(ud)
        end
        set(stateS.handle.doseShadowFig, 'userdata', ud)

    case 'MOTION'
        try
            ud = get(stateS.handle.doseShadowFig, 'userdata');
            if ud.buttondown && getappdata(stateS.handle.doseShadowFig, 'CallbackRun') ~= 1
                hAxis = get(stateS.handle.doseShadowFig, 'currentaxes');
                mousePos = get(stateS.handle.doseShadowFig, 'currentpoint');
                [x,y] = figToAxis(hAxis, stateS.handle.doseShadowFig, mousePos);
                doseShadowGui('update', x, y, hAxis);
            end
        catch
            return;
        end

    case 'GOTOTOGGLE'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        ud.gotoToggleOn = ~ud.gotoToggleOn;  
        set(stateS.handle.doseShadowFig, 'userdata', ud)
        % display nearest slices in CERR if this option if checked on
        if ud.gotoToggleOn & getappdata(stateS.handle.doseShadowFig, 'CallbackRun') ~= 1
            gotoCERRslice(ud)
        end                

    case 'CROSSHAIRTOGGLE'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        ud.crossHairOn = xor(ud.crossHairOn, 1);
        if ud.crossHairOn
            set([ud.line1 ud.line2 ud.line3 ud.line4 ud.line5 ud.line6], 'visible', 'on');
        else
            set([ud.line1 ud.line2 ud.line3 ud.line4 ud.line5 ud.line6], 'visible', 'off');
        end
        set(stateS.handle.doseShadowFig, 'userdata', ud)

        case 'UPDATE'        %Update UIControls for motion. In order to remain fast, do not store any ud.
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        col = varargin{2};
        row = varargin{3};
        hAxis = varargin{4};
        axisName = get(hAxis, 'tag');

        switch axisName
            case 'upperleft'
                data = getfield(ud.indices, axisName);
                x = col;
                y = row;
                z = data(row,col);
                if strcmpi(ud.mode, 'mean')
                    z = NaN;
                end
            case 'lowerright'
                data = getfield(ud.indices, axisName);
                x = data(row,col);
                y = col;
                z = row;
                if strcmpi(ud.mode, 'mean')
                    x = NaN;
                end
            case 'lowerleft'
                data = getfield(ud.indices, axisName);
                x = col;
                y = data(row,col);
                z = row;
                if strcmpi(ud.mode, 'mean')
                    y = NaN;
                end
            otherwise
                return;
        end

        if get(getfield(ud.handles.background,(axisName)), 'color')==[.5 .5 .5]
            set(ud.handles.background.upperleft, 'color', [.5 .5 .5]);
            set(ud.handles.background.lowerright, 'color', [.5 .5 .5]);
            set(ud.handles.background.lowerleft, 'color', [.5 .5 .5]);
            set(getfield(ud.handles.background,(axisName)), 'color', [1 1 1]);
        end

        shadow = getfield(ud.shadow, axisName);

        [ctXVals, ctYVals, ctZVals] = getUniformScanXYZVals(planC{indexS.scan}(getStructureAssociatedScan(ud.structure)));
        [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(getStructureAssociatedScan(ud.structure)));
        if z>0 & z<=length(ctZVals)
            slice = findnearest(ctZVals(z),zV);
        else
            slice = 0;
        end        
        dose = shadow(row, col);
        if isfield(planC{indexS.dose}(ud.dose),'doseOffset') && ~isempty(planC{indexS.dose}(ud.dose).doseOffset)
            doseOffset = planC{indexS.dose}(ud.dose).doseOffset;
            doseRange = 2*ud.dMax;
        else
            doseOffset = 0;
            doseRange = ud.dMax;
        end
        dose = dose-doseOffset;
        set(ud.handles.sliceVal,'String',num2str(slice));
        set(ud.handles.rowVal,'String',num2str(y));
        set(ud.handles.colVal,'String',num2str(x));
        set(ud.handles.doseVal,'String',num2str(dose));

        try, set(ud.handles.xVal, 'String', num2str(ctXVals(x))), catch, set(ud.handles.xVal, 'String', num2str(NaN)), end;
        try, set(ud.handles.yVal, 'String', num2str(ctYVals(y))), catch, set(ud.handles.yVal, 'String', num2str(NaN)), end;
        try, set(ud.handles.zVal, 'String', num2str(zV(slice))), catch, set(ud.handles.zVal, 'String', num2str(NaN)), end;

        oldAxes = get(stateS.handle.doseShadowFig, 'currentaxes');
        set(stateS.handle.doseShadowFig, 'currentaxes', ud.handles.colorbar);
        if dose ~= inf && dose ~= -inf && ~isnan(dose)
            set(ud.colorbarText, 'visible', 'on');
            set(ud.colorbarText, 'position', [1.75 (1-((dose+doseOffset)/doseRange))*98+2 0]);
            set(ud.colorbarText, 'String', num2str(dose,'%0.4g'));
            set(ud.colorbarLine, 'visible', 'on');      
            set(ud.colorbarLine, 'yData', [(1-((dose+doseOffset)/doseRange))*98+2 (1-((dose+doseOffset)/doseRange))*98+2]);            
        else
            set(ud.colorbarText, 'visible', 'off');
            set(ud.colorbarLine, 'visible', 'off');      
        end
        set(stateS.handle.doseShadowFig, 'currentaxes',oldAxes);

        crosshairs(ud.handles.axis.upperleft, x, y, ud.line1, ud.line2);
        crosshairs(ud.handles.axis.lowerleft, x, z, ud.line3, ud.line4);
        crosshairs(ud.handles.axis.lowerright, y, z, ud.line5, ud.line6);

        return;

    case 'DRAW'

        ud = get(stateS.handle.doseShadowFig, 'userdata');
        setappdata(stateS.handle.doseShadowFig, 'CallbackRun', 1);
        
        structNum = varargin{2};
        if structNum == 0
            return;
        end

        %Clear all data fields, they contain old data.
        set(ud.handles.doseVal, 'string', '');
        set(ud.handles.sliceVal, 'string', '');
        set(ud.handles.colVal, 'string', '');
        set(ud.handles.rowVal, 'string', '');
        set(ud.handles.zVal, 'string', '');
        set(ud.handles.xVal, 'string', '');
        set(ud.handles.yVal, 'string', '');
        set(ud.colorbarText, 'visible', 'off');
        
        try
            h_dose_proj = findobj('tag', 'dose_projection');
            delete(h_dose_proj)
        end
        
        hTransSolid = [ud.handles.hTransSolid{:}]; %cell2mat(ud.handles.hTransSolid(:));
        hTransDots  = [ud.handles.hTransDots{:}]; %cell2mat(ud.handles.hTransDots(:));

        hCorSolid = [ud.handles.hCorSolid{:}]; %cell2mat(ud.handles.hCorSolid(:));
        hCorDots  = [ud.handles.hCorDots{:}]; %cell2mat(ud.handles.hCorDots(:));

        hSagSolid = [ud.handles.hSagSolid{:}]; %cell2mat(ud.handles.hSagSolid(:));
        hSagDots  = [ud.handles.hSagDots{:}]; %cell2mat(ud.handles.hSagDots(:));
        
        mode = varargin{3};
        dose = varargin{4};

        if isfield(planC{indexS.dose}(ud.dose),'doseOffset') && ~isempty(planC{indexS.dose}(ud.dose).doseOffset)
            doseRange = [-ud.dMax ud.dMax];
        else
            doseRange = [0 ud.dMax];            
        end

        %set(ud.handles.axis.upperleft,'xLim',[1 sizeV(2)],'yLim',[1 sizeV(1)])
        [ud.shadow.upperleft, ud.indices.upperleft, iserror] = calcDoseShadow(structNum, dose, planC, 3, mode, ud.handles.axis.upperleft);
        if (getappdata(stateS.handle.doseShadowFig, 'CallbackRun') == 1)
            if iserror, return, end
            image(colorize(ud.shadow.upperleft, ud.colormap, doseRange), 'parent', ud.handles.axis.upperleft, 'tag', 'dose_projection');
            kids = get(ud.handles.axis.upperleft,'children');
            index_struct = find(ismember(kids,[hTransSolid; hTransDots]));
            kids(index_struct) = [];
            set(ud.handles.axis.upperleft, 'children', [hTransDots(:); hTransSolid(:);  kids(:)]);            
            axis(ud.handles.axis.upperleft, 'off');
            set(ud.handles.axis.upperleft, 'tag','upperleft');
            %setLimits(ud.handles.axis.upperleft,ud.shadow.upperleft, dim1Units/dim2Units);
            ud.handles.text.upperleft = text(0,1, 'Transverse', 'color', [1 1 1], 'units', 'normalized', 'verticalalignment', 'top', 'parent', ud.handles.axis.upperleft);

            %set(ud.handles.axis.lowerright,'xLim',[0 sizeV(1)],'yLim',[0 sizeV(3)])
        end
        
        [ud.shadow.lowerright, ud.indices.lowerright, iserror] = calcDoseShadow(structNum, dose, planC, 1, mode, ud.handles.axis.lowerright);
        if (getappdata(stateS.handle.doseShadowFig, 'CallbackRun') == 1)
            if iserror, return, end
            image(colorize(ud.shadow.lowerright, ud.colormap, doseRange), 'parent', ud.handles.axis.lowerright, 'tag', 'dose_projection');
            kids = get(ud.handles.axis.lowerright,'children');
            index_struct = find(ismember(kids,[hSagSolid; hSagDots]));
            kids(index_struct) = [];
            set(ud.handles.axis.lowerright, 'children', [hSagDots(:); hSagSolid(:);  kids(:)]);            
            axis(ud.handles.axis.lowerright, 'off');
            set(ud.handles.axis.lowerright, 'tag','lowerright');
            %setLimits(ud.handles.axis.lowerright,ud.shadow.lowerright, dim3Units/dim2Units);
            ud.handles.text.lowerright = text(0,1, 'Sagittal', 'color', [1 1 1], 'units', 'normalized', 'verticalalignment', 'top', 'parent', ud.handles.axis.lowerright);

            %set(ud.handles.axis.lowerleft,'xLim',[0 sizeV(2)],'yLim',[0 sizeV(3)])
        end
        
        [ud.shadow.lowerleft, ud.indices.lowerleft, iserror] = calcDoseShadow(structNum, dose, planC, 2, mode, ud.handles.axis.lowerleft);
        if (getappdata(stateS.handle.doseShadowFig, 'CallbackRun') == 1)
            if iserror, return, end            
            image(colorize(ud.shadow.lowerleft, ud.colormap, doseRange), 'parent', ud.handles.axis.lowerleft, 'tag', 'dose_projection');
            kids = get(ud.handles.axis.lowerleft,'children');
            index_struct = find(ismember(kids,[hCorSolid; hCorDots]));
            kids(index_struct) = [];
            set(ud.handles.axis.lowerleft, 'children', [hCorDots(:); hCorSolid(:); kids(:)]);            
            axis(ud.handles.axis.lowerleft, 'off');
            set(ud.handles.axis.lowerleft, 'tag','lowerleft');
            %setLimits(ud.handles.axis.lowerleft,ud.shadow.lowerleft, dim3Units/dim1Units);
            ud.handles.text.lowerleft = text(0,1, 'Coronal', 'color', [1 1 1], 'units', 'normalized', 'verticalalignment', 'top', 'parent', ud.handles.axis.lowerleft);

            %Prepare crosshairs
            if ~isfield(ud,'line1') || (isfield(ud,'line1') && isempty(ud.line1))
                ud.line1 = line([0 0], [0 0],'ButtonDownFcn', 'doseShadowGui(''UPDATESTATS'')', 'visible', 'on', 'parent', ud.handles.axis.upperleft);
                ud.line2 = line([0 0], [0 0],'ButtonDownFcn', 'doseShadowGui(''UPDATESTATS'')', 'visible', 'on', 'parent', ud.handles.axis.upperleft);
                ud.line3 = line([0 0], [0 0],'ButtonDownFcn', 'doseShadowGui(''UPDATESTATS'')', 'visible', 'on', 'parent', ud.handles.axis.lowerleft);
                ud.line4 = line([0 0], [0 0],'ButtonDownFcn', 'doseShadowGui(''UPDATESTATS'')', 'visible', 'on', 'parent', ud.handles.axis.lowerleft);
                ud.line5 = line([0 0], [0 0],'ButtonDownFcn', 'doseShadowGui(''UPDATESTATS'')', 'visible', 'on', 'parent', ud.handles.axis.lowerright);
                ud.line6 = line([0 0], [0 0],'ButtonDownFcn', 'doseShadowGui(''UPDATESTATS'')', 'visible', 'on', 'parent', ud.handles.axis.lowerright);
            else
                set([ud.line1 ud.line2 ud.line3 ud.line4 ud.line5 ud.line6],'visible','off')
                set(ud.handles.crossBox,'value',0)
                ud.crossHairOn = 0;
            end
            set(ud.handles.gotoBox,'value',0)
            ud.gotoToggleOn = 0;
            set(stateS.handle.doseShadowFig, 'userdata', ud);
        end
        printmode = get(ud.handles.printBox,'value');
        if printmode
            % set([ud.handles.text.upperleft, ud.handles.text.lowerleft, ud.handles.text.lowerright],'color',[0 0 0])
            set([ud.handles.text.upperleft, ud.handles.text.lowerleft, ud.handles.text.lowerright],'visible','off')
        else
            % set([ud.handles.text.upperleft, ud.handles.text.lowerleft, ud.handles.text.lowerright],'color',[1 1 1])
            set([ud.handles.text.upperleft, ud.handles.text.lowerleft, ud.handles.text.lowerright],'visible','on')            
        end
        %****
        setappdata(stateS.handle.doseShadowFig, 'CallbackRun', 0);
        
        
    case 'TOGGLEPRINTMODE'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        strIndex = get(ud.handles.structVal,'value') - 1;
        if strIndex == 0
            return;
        end
        modeValue = get(ud.handles.modeVal,'value');
        modeString = get(ud.handles.modeVal,'string');    
        doseNum = get(ud.handles.doseSet,'value');
        doseShadowGui('draw', strIndex, modeString{modeValue}, doseNum)
        
    case 'SLIDERCLICKED'
        ud = get(stateS.handle.doseShadowFig, 'userdata');
        ud.handles.legendSlider
        
end
%************************************************%

function cData3M  = colorize(dataM, c, range) %range is [min max]

global stateS

minVal = range(1);
maxVal = range(2);
if minVal == 0
    maskM = (~isnan(dataM) & dataM ~= inf & dataM ~= -inf & dataM > 0);
else
    % maskM = (dataM ~= NaN & dataM ~= inf & dataM ~= -inf & dataM >= max+min & dataM <= max-min);
    maskM = (~isnan(dataM) & dataM ~= inf & dataM ~= -inf & dataM >= minVal & dataM <= maxVal);
end

partialDataM = dataM(maskM);
%partialData = (partialDataM/(maxVal-minVal)) * (size(c,1) + 0.5);
partialData = ((partialDataM-minVal)/(maxVal-minVal)) * (size(c,1) + 0.5);
roundPartialData = round(partialData);
partialDataClip = clip(roundPartialData,1,size(c,1),'limits');

%build RGB Matrix by indexing into colormap.
partialCData3M = c(partialDataClip, 1:3);

cData3M = repmat(0, [size(dataM) 3]);

mask3M = repmat(maskM, [1 1 3]);
cData3M(mask3M) = partialCData3M(:);
%Get printmode state
ud = get(stateS.handle.doseShadowFig, 'userdata');
printmode = get(ud.handles.printBox,'value');
if printmode
    cData3M(~mask3M) = 1;
    set([ud.handles.axis.upperleft, ud.handles.axis.lowerleft, ud.handles.axis.lowerright],'color',[1 1 1]);
    set([ud.handles.background.upperleft, ud.handles.background.lowerleft, ud.handles.background.lowerright],'color',[1 1 1])
else
    set([ud.handles.axis.upperleft, ud.handles.axis.lowerleft, ud.handles.axis.lowerright],'color',[0 0 0]);
    set([ud.handles.background.upperleft, ud.handles.background.lowerleft, ud.handles.background.lowerright],'color',[0 0 0])
end
%************************************************%


function [x, y] = figToAxis(hAxis, hFigure, mousePos)
global stateS
xLim = get(hAxis, 'XLim');
yLim = get(hAxis, 'YLim');

figurePos = get(stateS.handle.doseShadowFig, 'position');

axisPos = get(hAxis, 'position');

axisXStart = axisPos(1) * figurePos(3);
axisYStart = axisPos(2) * figurePos(4);
axisXSize = axisPos(3) * figurePos(3);
axisYSize = axisPos(4) * figurePos(4);

if mousePos(1) < axisXStart
    x = xLim(1);
elseif mousePos(1) > (axisXStart + axisXSize)
    x = xLim(2);
else
    x = ((mousePos(1)-axisXStart)/axisXSize) * (xLim(2)- xLim(1)) + xLim(1);
end

if mousePos(2) < axisYStart
    y = yLim(1);
elseif mousePos(2) > (axisYStart + axisYSize)
    y = yLim(2);
else
    y = ((mousePos(2)-axisYStart)/axisYSize) * (yLim(2)- yLim(1)) - yLim(1);
end

x = round(x);
y = (yLim(2) - yLim(1))-round(y);
%************************************************%


function [hLine1, hLine2] = crosshairs(hAxis, x, y, hLine1, hLine2)
global stateS
oldAxis = get(stateS.handle.doseShadowFig, 'currentaxes');
set(stateS.handle.doseShadowFig, 'currentaxes', hAxis);
if ~isnan(y) && y~= inf && y~= -inf
    set(hLine1, 'xdata', get(hAxis, 'xLim'), 'ydata', [y y]);
end
if ~isnan(x) && x~= inf && x~= -inf
    set(hLine2, 'xdata', [x x], 'ydata', get(hAxis, 'yLim'));
end
set(stateS.handle.doseShadowFig, 'currentaxes', oldAxis);
%************************************************%


function setLimits(hAxis, dataM, aspect)
%Scales and sets limits for the best fit of data.
maskM = (~isnan(dataM) & dataM ~= inf & dataM >= 0);
[row,col] = find(maskM);

maxX = max(col);
minX = min(col);
maxY = max(row);
minY = min(row);

width = maxX-minX;
height = maxY-minY;

if width > height*aspect
    set(hAxis, 'xlim', [minX maxX]);
    margin = max(1,round((width/aspect-height)/2));
    set(hAxis, 'ylim', [max(1,minY-margin) min(maxY+margin,size(maskM,1))]);
else
    set(hAxis, 'ylim', [minY maxY]);
    margin = max(1,round((height*aspect-width)/2));
    set(hAxis, 'xlim', [max(1,minX-margin) min(maxX+margin,size(maskM,2))]);
end
%************************************************%

function gotoCERRslice(ud)
% displays the nearest transverse, sagittal and coronal slices in CERR
% views based upon ud.handles.x,y and zVal
global stateS planC
indexS = planC{end};
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(getStructureAssociatedScan(ud.structure)));
refreshFlag = 0;
for i = 1:length(stateS.handle.CERRAxis)
    hAxis = stateS.handle.CERRAxis(i);
    view = getAxisInfo(hAxis,'view');
    if strcmpi(view,'transverse') && ~strcmpi(get(ud.handles.zVal,'string'),'NaN') && ~isempty(get(ud.handles.zVal,'string'))
        sliceNum     = findnearest(str2num(get(ud.handles.zVal,'string')),zV);
        setAxisInfo(hAxis,'coord',zV(sliceNum))
        refreshFlag = 1;
    end
    if strcmpi(view,'sagittal') && ~strcmpi(get(ud.handles.xVal,'string'),'NaN') && ~isempty(get(ud.handles.xVal,'string'))
        sliceNumSag  = findnearest(str2num(get(ud.handles.xVal,'string')),xV);
        setAxisInfo(hAxis,'coord',xV(sliceNumSag))
        refreshFlag = 1;
    end
    if strcmpi(view,'coronal') && ~strcmpi(get(ud.handles.yVal,'string'),'NaN') && ~isempty(get(ud.handles.yVal,'string'))
        sliceNumCor  = findnearest(str2num(get(ud.handles.yVal,'string')),yV);
        setAxisInfo(hAxis,'coord',yV(sliceNumCor))
        refreshFlag = 1;
    end
end
if refreshFlag
    sliceCallBack('refresh')
end
return;

%************************************************%
