function DLHGui(command,varargin)
%function DLHGui(command,varargin)
%GUI for Dose Location Histogram (DLH)
%
%APA, 7/6/09
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

if nargin==0
    command = 'INIT';
end

switch upper(command)

    case 'INIT'

        % define margin constraints
        leftMarginWidth = 300;
        topMarginHeight = 50;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;

        str1 = ['Dose Location Histogram'];
        position = [5 40 800 600];

        defaultColor = [0.8 0.9 0.9];

        if isempty(findobj('tag','DLHFig'))
            % initialize main GUI figure
            hFig = figure('tag','DLHFig','name',str1,'numbertitle','off','position',position,...
                'CloseRequestFcn', 'DLHGui(''closeRequest'')','menubar','none','resize','off','color',defaultColor);
        else
            figure(findobj('tag','DLHFig'))
            return
        end
        %stateS.hFig = hFig;

        figureWidth = position(3); figureHeight = position(4);
        posTop = figureHeight-topMarginHeight;

        % create title handles
        handle(1) = uicontrol(hFig,'tag','titleFrame','units','pixels','Position',[150 figureHeight-topMarginHeight+5 500 40 ],'Style','frame','backgroundColor',defaultColor);
        handle(2) = uicontrol(hFig,'tag','title','units','pixels','Position',[151 figureHeight-topMarginHeight+10 498 30 ], 'String','Dose Location Histogram','Style','text', 'fontSize',10,'FontWeight','Bold','HorizontalAlignment','center','backgroundColor',defaultColor);
        handle(3) = uicontrol(hFig,'tag','titleFrame','units','pixels','Position',[leftMarginWidth-20 250 1 figureHeight-topMarginHeight-260 ],'Style','frame','backgroundColor',defaultColor);

        % create Dose and structure handles
        inputH(1) = uicontrol(hFig,'tag','doseStructTitle','units','pixels','Position',[20 posTop-40 150 20], 'String','DOSE & STRUCTURE','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        prefix = 'Select a dose.';
        doseList = {prefix, planC{indexS.dose}.fractionGroupID};
        prefix = 'Select a structure.';
        structList = {prefix, planC{indexS.structures}.structureName};
        inputH(2) = uicontrol(hFig,'tag','doseStatic','units','pixels','Position',[20 posTop-70 120 20], 'String','Select Dose','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','right');
        inputH(3) = uicontrol(hFig,'tag','doseSelect','units','pixels','Position',[150 posTop-70 120 20], 'String',doseList,'Style','popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left');
        inputH(4) = uicontrol(hFig,'tag','structStatic','units','pixels','Position',[20 posTop-100 120 20], 'String','Select Structure','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','right');
        inputH(5) = uicontrol(hFig,'tag','structSelect','units','pixels','Position',[150 posTop-100 120 20], 'String',structList,'Style','popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left');

        inputH(6) = uicontrol(hFig,'tag','criteriaTitle','units','pixels','Position',[20 posTop-140 180 20], 'String','CRITERIA','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        inputH(7) = uicontrol(hFig,'tag','doseStatic','units','pixels','Position',[20 posTop-170 40 20], 'String','Dose','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(8) = uicontrol(hFig,'tag','doseOperator','units','pixels','Position',[70 posTop-170 40 20], 'String',{'<=','>='},'Style','popup', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(9) = uicontrol(hFig,'tag','doseEdit','units','pixels','Position',[120 posTop-170 40 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(10) = uicontrol(hFig,'tag','doseUnitsStatic','units','pixels','Position',[160 posTop-170 80 20], 'String','Gy or cGy','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
       
        %Create Dose-Stats handles
        uicontrol(hFig,'tag','titleFrame','units','pixels','Position',[20 figureHeight-topMarginHeight-525 760 200 ],'Style','frame','backgroundColor',defaultColor);
        
        %Define DLH-plot fraction Axis
        plotH(1) = axes('parent',hFig,'tag','dvhAxisFract','tickdir', 'out','nextplot', 'add','units','pixels','Position',[leftMarginWidth+40 posTop*2/4-00 figureWidth-leftMarginWidth-100 posTop*0.9/2], 'color',[1 1 1],'YAxisLocation','right','fontSize',8,'visible','off');        

        %Define DLH-plot Axis
        plotH(2) = axes('parent',hFig,'tag','dvhAxis','tickdir', 'out','nextplot', 'add','units','pixels','Position',[leftMarginWidth+40 posTop*2/4-00 figureWidth-leftMarginWidth-100 posTop*0.9/2], 'color',[1 1 1],'YAxisLocation','left','fontSize',8,'visible','off');        
        
        yLim = get(plotH(1), 'yLim');
        %dvhStatH(end+1) = line([0 0], [yLim(1) yLim(2)], 'tag','motionLine','color', 'blue', 'parent', plotH(1), 'hittest', 'off','visible','off');
        
        submitH(1) = uicontrol(hFig,'tag','SubmitPush','units','pixels','Position',[20 posTop-225 160 25], 'String','Compute DLH','Style','push', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','callback','DLHGui(''COMPUTE_DVH'')');
        submitH(2) = uicontrol(hFig,'tag','ClearPush','units','pixels','Position',[20 posTop-275 160 25], 'String','Clear all DLHs','Style','push', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','callback','DLHGui(''CLEAR_ALL_DLHS'')');
        
        %Create handles for computed DLH

        %control to display legend in new figure
        dvhStatH(1) = uicontrol(hFig, 'tag','showLegend', 'style', 'checkbox', 'position', [700 posTop-20 100 20], 'string', 'Legend', 'horizontalAlignment', 'center','BackgroundColor',defaultColor, 'callback', 'DLHGui(''LEGENDCALL'')','visible','off');
        
        %Column headings
        dvhStatH(end+1) = uicontrol(hFig,'tag','sNo','units','pixels','Position',[100 posTop-350 35 20], 'String','DLH #','Style','text', 'fontSize',9,'FontWeight','bold','BackgroundColor',defaultColor,'HorizontalAlignment','center');        
        dvhStatH(end+1) = uicontrol(hFig,'tag','doseSelected','units','pixels','Position',[135 posTop-350 120 20], 'String','Dose','Style','text', 'fontSize',9,'FontWeight','bold','BackgroundColor',defaultColor,'HorizontalAlignment','center');        
        dvhStatH(end+1) = uicontrol(hFig,'tag','structSelected','units','pixels','Position',[270 posTop-350 120 20], 'String','Structure','Style','text', 'fontSize',9,'FontWeight','bold','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(end+1) = uicontrol(hFig,'tag','criteriaSelected','units','pixels','Position',[400 posTop-350 150 20], 'String','Criteria','Style','text', 'fontSize',9,'FontWeight','bold','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(end+1) = uicontrol(hFig,'tag','volumeSelected','units','pixels','Position',[560 posTop-350 100 20], 'String','Vol (cc)','Style','text', 'fontSize',9,'FontWeight','bold','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        
        numDLH = 5;
        for i=1:numDLH
            rowIndex = rem(i,5);
            if rowIndex == 0
                rowIndex = 5;
            end
            dvhStatH(end+1) = uicontrol(hFig,'tag',['DeleteDLH',num2str(i)],'units','pixels','Position',[45 posTop-350-30*rowIndex 25 20], 'String','--','Style','push', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment', 'center', 'TooltipString','Delete this DLH', 'callBack',['DLHGui(''DELETE_DVH'',',num2str(i),')']);
            dvhStatH(end+1) = uicontrol(hFig,'tag',['sNo',num2str(i)],'units','pixels','Position',[100 posTop-350-30*rowIndex 30 20], 'String',num2str(i),'Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
            dvhStatH(end+1) = uicontrol(hFig,'tag',['doseSelected',num2str(i)],'units','pixels','Position',[135 posTop-350-30*rowIndex 120 20], 'String','Dose','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
            dvhStatH(end+1) = uicontrol(hFig,'tag',['structSelected',num2str(i)],'units','pixels','Position',[270 posTop-350-30*rowIndex 120 20], 'String','Structure','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
            dvhStatH(end+1) = uicontrol(hFig,'tag',['criteriaSelected',num2str(i)],'units','pixels','Position',[400 posTop-350-30*rowIndex 150 20], 'String','Criteria','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');                       
            dvhStatH(end+1) = uicontrol(hFig,'tag',['volumeSelected',num2str(i)],'units','pixels','Position',[560 posTop-350-30*rowIndex 100 20], 'String','% Total Vol','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');                       
        end
        
        dvhStatH(end+1) = uicontrol(hFig,'tag','DLHslider','units','pixels','Position',[760 figureHeight-topMarginHeight-525 20 200], 'Style','slider', 'BackgroundColor',defaultColor,'HorizontalAlignment','center', 'max', 5, 'min', 1, 'value', 1, 'sliderStep',[1 1], 'callback','DLHGui(''SLIDER_CLICKED'')');
        
        
        DVHInitS = struct('distV','',...
            'volsV','',...
            'binWidth','',...
            'doseNum','',...
            'structNum','',...
            'doseCutoff','',...
            'doseOperatorVal','',...
            'lineStyle','',...
            'hPlot','');
        
        DVHInitS(1) = [];
        
        ud.DVH = DVHInitS;     
        ud.handle.inputH = inputH;
        ud.handle.DVHStatH = dvhStatH;
        set(ud.handle.DVHStatH,'visible','off')
        
        ud.currentDVHS.hLB = [];
        ud.currentDVHS.hUB = [];
        ud.currentDVHS.hObserved = [];
        ud.currentDVHS.hPatch = [];
        
        set(hFig,'userdata',ud);
        
       
    case 'COMPUTE_DVH'
        
        hFig = findobj('tag','DLHFig');
        ud = get(hFig,'userdata');
        
        doseNum         = get(findobj(ud.handle.inputH,'tag','doseSelect'),'value')-1;
        structNum       = get(findobj(ud.handle.inputH,'tag','structSelect'),'value')-1;
        doseCutoff      = str2num(get(findobj(ud.handle.inputH,'tag','doseEdit'),'string'));
        doseOperatorVal = get(findobj(ud.handle.inputH,'tag','doseOperator'),'value');
        
        if doseNum == 0
            warndlg('Please select dose.','Invalid dose','modal')
            return;
        end

        if structNum == 0
            warndlg('Please select structure.','Invalid structure','modal')
            return;
        end

        if isempty(doseCutoff)
            warndlg('Incorrect Dose cutoff. Please specify a valid number.','Invalid dose cutoff','modal')
            return;
        end
               
        [distV, volsV] = getDLH(doseNum, structNum, doseCutoff, doseOperatorVal, planC);
        
        %Compute total volume of the structure
        totalVol = sum(volsV);        
        
        hFig = findobj('tag','DLHFig');
        ud = get(hFig,'userdata');

        numDVH = length(ud.DVH);
        ud.DVH(numDVH+1).doseNum         = doseNum;
        ud.DVH(numDVH+1).structNum       = structNum;
        ud.DVH(numDVH+1).doseCutoff      = doseCutoff;
        ud.DVH(numDVH+1).doseOperatorVal = doseOperatorVal;
        ud.DVH(numDVH+1).totalVolume     = totalVol;
        ud.DVH(numDVH+1).lineStyle       = '';
        ud.DVH(numDVH+1).hPlot           = [];
        ud.DVH(numDVH+1).distV           = distV;
        ud.DVH(numDVH+1).volsV           = volsV;

        set(hFig,'userdata',ud)
        
        DLHGui('PLOT_DVH',numDVH+1)       
        
        DLHGui('REFRESH')
        
        
    case 'PLOT_DVH'

        hFig = findobj('tag','DLHFig');
        
        %Get Robust DVH structure to plot
        ud = get(hFig,'userdata');
        hAxis = findobj('tag','dvhAxis');
        hAxisFract = findobj('tag','dvhAxisFract');
               
        DVHnum = varargin{1};
        hLegend = findobj(ud.handle.DVHStatH,'tag','showLegend');
        if DVHnum == 0           
            try
                delete(ud.currentDVHS.hHighlight)
                set(ud.handle.DVHStatH(3:end),'visible','off')
            end
            ud.currentDVHS.hLB = [];
            ud.currentDVHS.hUB = [];
            ud.currentDVHS.hObserved = [];
            ud.currentDVHS.hPatch = [];
            ud.currentDVHS.hMean = [];
            ud.currentDVHS.hHighlight = [];
            for i=1:length(ud.DVH)
                set(ud.DVH(i).handles,'visible','off')
            end
            set(hAxis,'visible','off')
            set(hAxisFract,'visible','off')
            set(hAxis, 'buttonDownFcn', '');  
            set(hLegend,'visible','off')
            set(hFig,'userdata',ud);
            return;            
        end
        set(hLegend,'visible','on')
                
        DVHs = ud.DVH(DVHnum);
        
        hSlider = findobj(ud.handle.DVHStatH,'tag','DLHslider');
        
        set(hSlider,'value',ceil(length(ud.DVH)/5)-ceil(DVHnum/5)+1,'min',1,'max',ceil(length(ud.DVH)/5),'sliderStep',[1/max(1,(ceil(length(ud.DVH)/5)-1)) 1/max(1,(ceil(length(ud.DVH)/5)-1))])
        
        %Structure color
        colorV = planC{indexS.structures}(DVHs.structNum).structureColor;        
        
        %Delete old handles
        try, delete(DVHs.handles), end
        DVHs.handles = [];
        
        distV = DVHs.distV;
        volsV = DVHs.volsV;
        binWidth = 0.05; %DVHs.binWidth;
        
        %Plot Current DVH
        [distBinsV, volsHistV] = doseHist(distV, volsV, binWidth);
        cumVolsV  = cumsum(volsHistV);
        cumVols2V = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume of the corresponding dose
        %Get lineStyle
        lineStyleC = repmat({'-','--','-.',':'},1,100);
        indPrevious = find(([ud.DVH.doseNum] == ud.DVH(DVHnum).doseNum) | ([ud.DVH.structNum] == ud.DVH(DVHnum).structNum));
        lineStyle = lineStyleC{length(indPrevious)};
        ud.DVH(DVHnum).lineStyle = lineStyle;
        %Cumulative
        %hDLH     = plot(hAxis,distBinsV, cumVols2V,'LineWidth',2,'color',colorV,'parent',hAxis,'lineStyle',lineStyle);
        %Cumulative
        hDLH     = plot(hAxis,distBinsV, cumVolsV,'LineWidth',2,'color',colorV,'parent',hAxis,'lineStyle',lineStyle);
        %Differential
        %hDLH     = plot(hAxis,distBinsV, volsHistV,'LineWidth',2,'color',colorV,'parent',hAxis,'lineStyle',lineStyle);
        ud.DVH(DVHnum).hPlot = hDLH;
        
        totalVol = ud.DVH(DVHnum).totalVolume;
        xDLHVals = [distBinsV];
        yDLHVals = [cumVolsV];
        [xDLHVals, aInd] = unique(xDLHVals);
        yDLHVals = yDLHVals(aInd);
        ud.currentDVHS.xDLHVals = xDLHVals;
        ud.currentDVHS.yDLHVals = yDLHVals;
        ud.currentDVHS.hDLH = hDLH;
        DVHs.handles = [DVHs.handles hDLH];
        
        xlabel(hAxis,'Distance from Surface (cm)')
        ylabel(hAxis,'volume (cc)')
        set(hAxis,'visible','on')
        grid(hAxis,'on')
        axis(hAxis,'tight')
        
        %Compute Fractions of total volume
        set(hAxisFract,'visible','on')
        yLabelsV = get(hAxis,'yTick');
        fractVolsV = linspace(min(cumVolsV(1),yLabelsV(1)),max(cumVolsV(end),yLabelsV(end)),10);
        fractVolsV = fractVolsV/totalVol*100;
        set(hAxisFract,'yLim',[fractVolsV(1) fractVolsV(end)])
        set(hAxisFract,'xTick',[]);        
        ylabel(hAxisFract,'fraction of total volume')

        set(hFig,'userdata',ud)
        
        
    case 'REFRESH'
        
        hFig = findobj('tag','DLHFig');
        
        %Get Robust DVH structure to plot
        ud = get(hFig,'userdata');
        
        numDVH = length(ud.DVH);
        
        %Turn Off all DVH stats
        set(ud.handle.DVHStatH,'visible','off')   
               
        if numDVH > 0
            hSno = findobj(ud.handle.DVHStatH,'tag','sNo');
            hDose = findobj(ud.handle.DVHStatH,'tag','doseSelected');
            hStruct = findobj(ud.handle.DVHStatH,'tag','structSelected');
            hCriteria = findobj(ud.handle.DVHStatH,'tag','criteriaSelected');
            hVolume = findobj(ud.handle.DVHStatH,'tag','volumeSelected');            
            set([hSno hDose hStruct hCriteria hVolume], 'visible','on')
            hLegend = findobj(ud.handle.DVHStatH,'tag','showLegend');
            set(hLegend,'visible','on')
        end

        hSlider = findobj(ud.handle.DVHStatH,'tag','DLHslider');
        if numDVH > 5
            set(hSlider,'visible','on')
        else
            set(hSlider,'visible','off')
        end
        
        sliderVal = get(hSlider,'value');
        sliderMax = get(hSlider,'max');
        sliderVal = sliderMax - sliderVal + 1;
        count = 1;
        for i=(sliderVal-1)*5+1:min(sliderVal*5,numDVH)
            hDelete = findobj(ud.handle.DVHStatH,'tag',['DeleteDLH',num2str(count)]);
            hSno = findobj(ud.handle.DVHStatH,'tag',['sNo',num2str(count)]);
            hDose = findobj(ud.handle.DVHStatH,'tag',['doseSelected',num2str(count)]);
            hStruct = findobj(ud.handle.DVHStatH,'tag',['structSelected',num2str(count)]);
            hCriteria = findobj(ud.handle.DVHStatH,'tag',['criteriaSelected',num2str(count)]);
            hVolume = findobj(ud.handle.DVHStatH,'tag',['volumeSelected',num2str(count)]);
            set([hDelete hSno hDose hStruct hCriteria hVolume], 'visible','on')
            set(hDelete, 'callback', ['DLHGui(''CLEAR_DLH'',',num2str(i),')'])
            set(hSno,'string',num2str(i))
            set(hDose,'string',planC{indexS.dose}(ud.DVH(i).doseNum).fractionGroupID)
            set(hStruct,'string',planC{indexS.structures}(ud.DVH(i).structNum).structureName)
            set(hVolume,'string',num2str(ud.DVH(i).totalVolume))
            criteriaStr = 'Dose ';
            if ud.DVH(i).doseOperatorVal == 1
                criteriaStr = [criteriaStr, '<=', num2str(ud.DVH(i).doseCutoff)];
            else
                criteriaStr = [criteriaStr, '>=', num2str(ud.DVH(i).doseCutoff)];
            end
            set(hCriteria,'string',criteriaStr)
            count = count + 1;
        end        
        
        
    case 'SLIDER_CLICKED'
       
        sliderVal = get(gcbo,'value');
        
        sliderVal = round(sliderVal);
        
        set(gcbo,'value',sliderVal)
        
        DLHGui('REFRESH')
        
        
    case 'CLEAR_DLH'
        
        dlhNum = varargin{1};
        
        hFig = findobj('tag','DLHFig');
        
        %Get Robust DVH structure to plot
        ud = get(hFig,'userdata');
        
        delete(ud.DVH(dlhNum).hPlot)
        
        ud.DVH(dlhNum) = [];
        
        DVHnum = min(length(ud.DVH), dlhNum);
        
        hSlider = findobj(ud.handle.DVHStatH,'tag','DLHslider');
        
        set(hSlider,'value',min(ceil(length(ud.DVH)/5),ceil(length(ud.DVH)/5)-ceil(DVHnum/5)+1),'min',min(1,ceil(length(ud.DVH)/5)),'max',ceil(length(ud.DVH)/5),'sliderStep',[1/max(1,(ceil(length(ud.DVH)/5)-1)) 1/max(1,(ceil(length(ud.DVH)/5)-1))])
        
        set(hFig,'userdata', ud)
        
        if length(ud.DVH) == 0
           DLHGui('CLEAR_ALL_DLHS') 
        else
            DLHGui('REFRESH')            
        end
        
        
    case 'CLEAR_ALL_DLHS'
        
        ButtonName = questdlg('This will delete all DLHs. Do you wish to continue?', 'Delete all DLHs?', 'Yes','No','Yes');
        
        if strcmpi(ButtonName,'no')
            return
        end
        
        hFig = findobj('tag','DLHFig');
        
        %Get Robust DVH structure to plot
        ud = get(hFig,'userdata');
        
        ud.DVH(:) = [];
        
        hAxis = findobj('tag','dvhAxis');
        hAxisFract = findobj('tag','dvhAxisFract');
        set(hAxis,'nextPlot','add')
        set(hAxisFract,'nextPlot','add')
        %delete([ud.DVH.handles])
        cla(hAxis)
        set(hAxis,'visible','off')
        set(hAxisFract,'visible','off')
        %DVHs.handles = [];
        
        set(hFig,'userdata', ud)
        
        DLHGui('REFRESH')
        
        
    
    case 'TOGGLE_VISIBILITY'
        hFig = findobj('tag','DLHFig');
        
        %Get Robust DVH structure to plot
        ud = get(hFig,'userdata');
        
        hDVH_num = findobj(ud.handle.DVHStatH,'tag','dvhSelect');
        DVHnum = get(hDVH_num,'value') - 1;

        value = get(gcbo,'value');
        DVHs = ud.DVH(DVHnum);
        if value
            set(DVHs.handles,'visible','on')
        else
            set(DVHs.handles,'visible','off')
            set(ud.currentDVHS.hHighlight,'visible','off')
        end
        
        
    case 'PLOTMOTION'
    %A DVH is selected, the plot has been clicked and motion is occuring. Update guide line/fields.            
        hFig = findobj('tag','DLHFig');
        hAxis = findobj('tag','dvhAxis');
        ud = get(hFig, 'userdata');
        cP = get(hAxis, 'currentpoint');
        dose = cP(1,1); 
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
        observVol = interp1(ud.currentDVHS.xObsVals, ud.currentDVHS.yObsVals, dose);
        if isnan(observVol)
            observVol = 0;
        end
        meanVol = interp1(ud.currentDVHS.xMeanVals, ud.currentDVHS.yMeanVals, dose);
        if isnan(meanVol)
            meanVol = 0;
        end        
        lbVol = interp1(ud.currentDVHS.xLBVals, ud.currentDVHS.yLBVals, dose);
        if isnan(lbVol)
            lbVol = 0;
        end        
        ubVol = interp1(ud.currentDVHS.xUBVals, ud.currentDVHS.yUBVals, dose);
        if isnan(ubVol)
            ubVol = 0;
        end

        hvolObser = findobj(ud.handle.DVHStatH,'tag','volAbovDoseObserTxt');
        set(hvolObser,'string',num2str(observVol))
        hvolLBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseLBTxt');
        set(hvolLBD,'string',num2str(lbVol))
        hvolUBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseUBTxt');
        set(hvolUBD,'string',num2str(ubVol))
        hDose = findobj(ud.handle.DVHStatH,'tag','volAbovDoseEdit');
        set(hDose,'string',num2str(dose))        
        hvolMeanD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseMeanTxt');
        set(hvolMeanD,'string',num2str(meanVol))       
        hMotionLine = findobj(ud.handle.DVHStatH,'tag','motionLine');        
        set(hMotionLine, 'xdata', [dose dose], 'visible', 'on');

        
        
    case 'CLICKINPLOT'
    %A DVH is selected and the plot has been clicked, update guide line/fields.    
        hFig = findobj('tag','DLHFig');
        hAxis = findobj('tag','dvhAxis');
        ud = get(hFig, 'userdata');
        set(hFig, 'WindowButtonUpFcn', 'DLHGui(''UNCLICKINPLOT'')');
        set(hFig, 'WindowButtonMotionFcn', 'DLHGui(''PLOTMOTION'')');
        cP = get(hAxis, 'currentpoint');
        %Interpolate Vol, display.
        dose = cP(1,1); 
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
        observVol = interp1(ud.currentDVHS.xObsVals, ud.currentDVHS.yObsVals, dose);
        if isnan(observVol)
            observVol = 0;
        end
        meanVol = interp1(ud.currentDVHS.xMeanVals, ud.currentDVHS.yMeanVals, dose);
        if isnan(meanVol)
            meanVol = 0;
        end        
        lbVol = interp1(ud.currentDVHS.xLBVals, ud.currentDVHS.yLBVals, dose);
        if isnan(lbVol)
            lbVol = 0;
        end        
        ubVol = interp1(ud.currentDVHS.xUBVals, ud.currentDVHS.yUBVals, dose);
        if isnan(ubVol)
            ubVol = 0;
        end

        hvolObser = findobj(ud.handle.DVHStatH,'tag','volAbovDoseObserTxt');
        set(hvolObser,'string',num2str(observVol))
        hvolLBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseLBTxt');
        set(hvolLBD,'string',num2str(lbVol))
        hvolUBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseUBTxt');
        set(hvolUBD,'string',num2str(ubVol))
        hDose = findobj(ud.handle.DVHStatH,'tag','volAbovDoseEdit');
        set(hDose,'string',num2str(dose))        
        hvolMeanD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseMeanTxt');
        set(hvolMeanD,'string',num2str(meanVol))               
        hMotionLine = findobj(ud.handle.DVHStatH,'tag','motionLine');        
        set(hMotionLine, 'xdata', [dose dose], 'visible', 'on');

        
    case 'UNCLICKINPLOT'
        hFig = findobj('tag','DLHFig');
        ud = get(hFig, 'userdata');
        set(hFig, 'WindowButtonMotionFcn', '');        
        set(hFig, 'WindowButtonUpFcn', '');        
        set(hFig, 'userdata', ud);
        
    case 'DOSEVAL'
    %A value has been entered into the doseVal field.
        hFig = get(gcbo, 'parent');
        dose = str2double(get(gcbo, 'string'));
        ud = get(hFig, 'userdata');
        hAxis = findobj('tag','dvhAxis');        
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
       
        obserVol = interp1(ud.currentDVHS.xObsVals, ud.currentDVHS.yObsVals, dose);
        if isnan(obserVol)
            obserVol = 0;
        end
        LBVol = interp1(ud.currentDVHS.xLBVals, ud.currentDVHS.yLBVals, dose);
        if isnan(LBVol)
            LBVol = 0;
        end
        UBVol = interp1(ud.currentDVHS.xUBVals, ud.currentDVHS.yUBVals, dose);
        if isnan(UBVol)
            UBVol = 0;
        end
        
        hvolObser = findobj(ud.handle.DVHStatH,'tag','volAbovDoseObserTxt');
        set(hvolObser,'string',num2str(obserVol))
        hvolLBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseLBTxt');
        set(hvolLBD,'string',num2str(LBVol))
        hvolUBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseUBTxt');
        set(hvolUBD,'string',num2str(UBVol))
        hMotionLine = findobj(ud.handle.DVHStatH,'tag','motionLine');        
        set(hMotionLine, 'xdata', [dose dose], 'visible', 'on');
        
        
    case 'LEGENDCALL'
        
        %executes when "Show Legend" is toggled on or off
        value = get(gcbo,'value');
        hLegend = findobj('tag','DVH_Legend');
        close(hLegend)
        if value == 0
            return;
        end
        hFig = get(gcbo, 'parent');        
        ud = get(hFig, 'userdata');
        hLegend = figure('tag','DVH_Legend','name','DVH Legend','numberTitle','off','menubar','none','color','w');
        position = get(hLegend,'position');
        figColor = get(hLegend,'color');
        axisLegend = axes('units', 'normalized', 'Position', [0 0 1 1], 'color', figColor, 'ytick',[],'xtick',[], 'box', 'off', 'parent', hLegend,'nextPlot','add','units','normalized','visible','off');
        numLines = length(ud.DVH);
        dy = 0.8/numLines;
        position(3) = 400;
        position(4) = (numLines+1)*30;
        set(hLegend,'position',position)

        for i = 1:numLines
            Color = planC{indexS.structures}(ud.DVH(i).structNum).structureColor;
            line([0.05 0.15],[0.8-(i-1)*dy 0.8-(i-1)*dy],'LineStyle',ud.DVH(i).lineStyle,'LineWidth',2,'Color',Color,'parent',axisLegend)
            if ud.DVH(i).doseOperatorVal == 1
                criteriaStr = ['dose ', '<= ', num2str(ud.DVH(i).doseCutoff)];
            else
                criteriaStr = ['dose ', '>= ', num2str(ud.DVH(i).doseCutoff)];
            end            
            txt = [planC{indexS.structures}(ud.DVH(i).structNum).structureName,'(',planC{indexS.dose}(ud.DVH(i).doseNum).fractionGroupID,'), ',criteriaStr];
            text(0.18,0.8-(i-1)*dy,txt)
        end
        axis(axisLegend,[0 1 0 1])

    case 'CLOSEREQUEST'

        closereq


end
