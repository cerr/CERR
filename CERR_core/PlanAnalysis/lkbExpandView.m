function lkbExpandView(command, varargin)
%"lkbExpandView"
%   Callbacks for DVH plots, all functions are in the expanded view.
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
%   function lkbExpandView(command, varargin)

global mSState planC stateS
indexS = planC{end};

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
                
        %Actually perform the initialization.
        if ~isfield(ud, 'handles')
            lkbExpandView('INITEXPANDED');
            set(hFig, 'toolbar', 'figure');
        else
 
        end        
        lkbExpandView('UPDATECURVE')
        mSState.expandesView = 1;
        
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
        childH = get(ud.handles.modelAxis,'children');
        delete([childH(:)' ud.handles.labelX ud.handles.labelY])
        frameWidth = framePos(3);
        pos = get(hFig, 'position');
        pos(3) = pos(3) - frameWidth;
        set(hFig, 'position', pos);
                  
        %Return units to normalized.
        figChild = get(hFig, 'children');
        for i=1:length(figChild)
            try
                set(figChild(i), 'units', 'normalized');
            end
        end
        
        set(ud.handles.modelAxis,'visible','off')
        
        mSState.expandesView = 0;
        
    case 'INITEXPANDED'
    %If this is the first time the expanded view is requested, draw all the uicontrols.    
        barW = 200;
        hFig = get(gcbo, 'parent');
        
        pos = get(hFig, 'position');
        h = pos(4); w = pos(3);
        units = 'pixels';
                
        frame.X = w-barW+10;        
        frame.Y = 10;
        frame.W = barW-20;
        frame.H = h-20;
        hTmp = uicontrol(hFig, 'style', 'frame', 'units', units, 'position', [frame.X frame.Y frame.W frame.H]);        
        frameColor = get(hTmp, 'BackgroundColor');
        delete(hTmp);
        %Dummy frame for units.
        ud.handles.modelAxis = axes('units', units, 'Position', [w-barW h/4 barW-30 h/3], 'visible', 'on');
        ud.handles.frame     = axes('units', units, 'Position', [w-barW h/4 barW h/3], 'visible', 'off');

        %Slider uicontrols
        ud.handles.aTxt = uicontrol(hFig,'style','text','string','n','units',units,'position',[w-barW+10 7*h/12+170 30 20],'fontWeight','bold','fontSize',10,'HorizontalAlignment','left','BackgroundColor', [0.9 0.9 0.9]);
        ud.handles.aSld = uicontrol(hFig,'style','slider','min',-30,'max',30,'value',0.67,'units',units,'position',[w-barW+50 7*h/12+170 70 20],'callBack','lkbExpandView(''SETPARAMS'')','BackgroundColor', [0.9 0.9 0.9],'tag','a');

        ud.handles.D50Txt1 = uicontrol(hFig,'style','text','string','D50','units',units,'position',[w-barW+10 7*h/12+140 30 20],'fontWeight','bold','fontSize',10,'HorizontalAlignment','left','BackgroundColor', [0.9 0.9 0.9]);
        ud.handles.D50Sld = uicontrol(hFig,'style','slider','min',0,'max',100,'value',21,'units',units,'position',[w-barW+50 7*h/12+140 70 20],'callBack','lkbExpandView(''SETPARAMS'')','BackgroundColor', [0.9 0.9 0.9],'tag','D50');

        ud.handles.mTxt1 = uicontrol(hFig,'style','text','string','m','units',units,'position',[w-barW+10 7*h/12+110 30 20],'fontWeight','bold','fontSize',10,'HorizontalAlignment','left','BackgroundColor', [0.9 0.9 0.9]);
        ud.handles.mSld = uicontrol(hFig,'style','slider','min',0.001,'max',3,'value',0.59,'units',units,'position',[w-barW+50 7*h/12+110 70 20],'callBack','lkbExpandView(''SETPARAMS'')','BackgroundColor', [0.9 0.9 0.9],'tag','m');
        
        %Return units to normalized.
        figChild = get(hFig, 'children');
        for i=1:length(figChild)
            try
                set(figChild(i), 'units', 'normalized');
            end
        end       
        set(hFig, 'userdata', ud);        
        lkbExpandView('UPDATECURVE')
        
    case 'UPDATECURVE'
        hFig = get(gcbo, 'parent');        
        ud = get(hFig, 'userdata');        
        set(ud.handles.modelAxis,'visible','on')
        n   = mSState.currentMetric.params(3).value;        
        if ~strcmpi(class(n),'double')
            n = str2double(n);
        end
        D50 = mSState.currentMetric.params(4).value;
        if ~strcmpi(class(D50),'double')
            D50 = str2double(D50);
        end
        m   = mSState.currentMetric.params(5).value;
        if ~strcmpi(class(m),'double')
            m = str2double(m);
        end
        EUDv = linspace(0,100,100);
        structNum = mSState.currentMetric.params(1).value;
        doseNumV = get(mSState.handles.doseList,'value');
        try, mdelete(ud.modelCurve), end
        ud.modelCurve = [];
        cla(ud.handles.modelAxis)
        set(ud.handles.modelAxis,'nextPlot','add')
        legendStr = '';
        count = 1;
        for doseNum = doseNumV
            colorV = getColor(doseNum,stateS.optS.colorOrder);
            plot(0,0,'color',colorV,'linewidth',0.5,'parent',ud.handles.modelAxis)
            legendStr{count} = planC{indexS.dose}(doseNum).fractionGroupID;
            count = count + 1;
        end
        pos = get(ud.handles.modelAxis,'position');        
        legend(ud.handles.modelAxis,legendStr,'Location',[pos(1)+0.01 pos(2)+pos(4)+0.005 0.1 0.12],'fontSize',8)
        for doseNum = doseNumV
            colorV = getColor(doseNum,stateS.optS.colorOrder);
            if ~isempty(structNum) && ~isempty(doseNum)
                [ud.doseBinsV, ud.volsHistV] = getDVH(structNum, doseNum,planC);
                ud.EUD = calc_EUD(ud.doseBinsV, ud.volsHistV, 1/n);
                ud.maxDose = max(planC{indexS.dose}(doseNum).doseArray(:));
                ud.eudChanged = 0;
            elseif isempty(structNum) && isempty(doseNum)
                ud.EUD = [];
            end
            %Convert to sigmoidal complication probability:
            tmpv = (EUDv - D50)/(m*D50);
            ntcpV = 1/2 * (1 + erf(tmpv/2^0.5));
            %Compute ntcp for selected dose and structure
            if ~isempty(ud.EUD)
                tmp = (ud.EUD - D50)/(m*D50);
                ntcp = 1/2 * (1 + erf(tmp/2^0.5));
                plot([ud.EUD ud.EUD],[0 ntcp],'color',colorV,'lineStyle','--','parent',ud.handles.modelAxis)
                plot([0 ud.EUD],[ntcp ntcp],'color',colorV,'lineStyle','--','parent',ud.handles.modelAxis)
            end            
        end        
        ud.modelCurve = [ud.modelCurve plot(EUDv,ntcpV,'k','linewidth',2,'parent',ud.handles.modelAxis)];
        ud.handles.labelX = xlabel('Equivalent Uniform Dose (Gy)','parent',ud.handles.modelAxis);
        ud.handles.labelY = ylabel('Normal Tissue Complication Probability','parent',ud.handles.modelAxis);
        set(hFig, 'userdata', ud);

    case 'SETPARAMS'        
        hFig = get(gcbo, 'parent');        
        ud = get(hFig, 'userdata');        
        switch upper(get(gcbo,'tag'))
            case 'N'
                n   = get(ud.handles.aSld,'value');
                set(mSState.handles.params(3),'string',num2str(n))
                metricSelection('parameter_callback',3)
            case 'D50'
                D50 = get(ud.handles.D50Sld,'value');
                set(mSState.handles.params(4),'string',num2str(D50))
                metricSelection('parameter_callback',4)
            case 'M'
                m   = get(ud.handles.mSld,'value');
                set(mSState.handles.params(5),'string',num2str(m))
                metricSelection('parameter_callback',5)
        end
end
