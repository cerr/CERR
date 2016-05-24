function outcomeModelsGUI(command,varargin)
%  GUI for outcomes modeling (NTCP)
%  This tool uses JSONlab toolbox v1.2, an open-source JSON/UBJSON encoder and decoder
%  for MATLAB and Octave.
%  See : http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files
%
% APA, 05/10/2016
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


% Globals
global planC stateS
indexS = planC{end};

% Get GUI fig handle
hFig = findobj('Tag','outcomeModelsFig');

if nargin==0
    command = 'INIT';
end

switch upper(command)
    
    case 'INIT'
        
        % Define margin constraints
        leftMarginWidth = 300;
        topMarginHeight = 50;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;
        
        str1 = 'Outcomes Models Explorer';
        position = [5 40 800 600];
        
        defaultColor = [0.8 0.9 0.9];
        
        if isempty(findobj('tag','outcomeModelsFig'))
            
            % initialize main GUI figure
            hFig = figure('tag','outcomeModelsFig','name',str1,...
                'numbertitle','off','position',position,...
                'CloseRequestFcn', 'outcomeModelsGUI(''closeRequest'')',...
                'menubar','none','resize','off','color',defaultColor);
        else
            figure(findobj('tag','outcomeModelsFig'))
            return
        end
        
        figureWidth = position(3); figureHeight = position(4);
        posTop = figureHeight-topMarginHeight;
        
        % create title handles
        titleH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[150 figureHeight-topMarginHeight+5 500 40 ],'Style',...
            'frame','backgroundColor',defaultColor);
        titleH(2) = uicontrol(hFig,'tag','title','units','pixels',...
            'Position',[151 figureHeight-topMarginHeight+10 498 30 ],...
            'String','Outcome Models Explorer','Style','text', 'fontSize',10,...
            'FontWeight','Bold','HorizontalAlignment','center',...
            'backgroundColor',defaultColor);
        
        
        % create Dose and structure handles
        inputH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[10 220 leftMarginWidth figureHeight-topMarginHeight-230 ],...
            'Style','frame','backgroundColor',defaultColor);
        inputH(end+1) = uicontrol(hFig,'tag','doseStructTitle','units','pixels',...
            'Position',[20 posTop-50 150 20], 'String','DOSE & STRUCTURE',...
            'Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        prefix = 'Select a dose.';
        doseList = {prefix, planC{indexS.dose}.fractionGroupID};
        prefix = 'Select a structure.';
        structList = {prefix, planC{indexS.structures}.structureName};
        inputH(end+1) = uicontrol(hFig,'tag','doseStatic','units','pixels',...
            'Position',[20 posTop-80 120 20], 'String','Select Dose','Style',...
            'text', 'fontSize',8,'FontWeight','normal','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        inputH(end+1) = uicontrol(hFig,'tag','doseSelect','units','pixels',...
            'Position',[120 posTop-80 120 20], 'String',doseList,'Style',...
            'popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',...
            [1 1 1],'HorizontalAlignment','left','Callback','outcomeModelsGUI(''GET_DOSE'')');
        inputH(end+1) = uicontrol(hFig,'tag','structStatic','units','pixels',...
            'Position',[20 posTop-110 120 20], 'String','Select Structure',...
            'Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        inputH(end+1) = uicontrol(hFig,'tag','structSelect','units','pixels',...
            'Position',[120 posTop-110 120 20], 'String',structList,'Style',...
            'popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],...
            'HorizontalAlignment','left','Callback','outcomeModelsGUI(''GET_STRUCT'')');
        inputH(end+1) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[20 posTop-150 180 20], 'String','MODELS','Style','text',...
            'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,...
            'HorizontalAlignment','left');
        inputH(end+1) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[20 posTop-180 180 30], 'String',...
            'Select file containing Models','Style','push', 'fontSize',8.5,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'outcomeModelsGUI(''LOAD_MODELS'')');
        inputH(end+1) = annotation(hFig,'textbox','Tag','dispModel','Position',[0.05,0.4,0.3,0.2],...
            'Visible','Off','EdgeColor',[0.6 0.6 0.6]);
        inputH(end+1) = uicontrol(hFig,'units','pixels','Tag','plot','Position',[230 posTop-300 65 30],...
            'String','Plot','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','outcomeModelsGUI(''PLOT_MODELS'')');
        
        %Create Model-Stats handles
        dvhStatH(1) = axes('Parent',hFig,'units','Pixels','Position',[10 figureHeight-topMarginHeight-530 770 190 ],...
            'Color',defaultColor,'ytick',[],'xtick',[], 'box', 'on');
        dvhStatH(end+1) = uicontrol(hFig,'tag','modelStatsTitle','units','pixels',...
            'Position',[25 posTop-380 150 20], 'String','Model Stats','Style',...
            'text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        statsC = {'None','stat1','stat2'}; %%?Stats --add!
        dvhStatH(end+1) = uicontrol(hFig,'tag','statSelect','units','pixels',...
            'Position',[25 posTop-400 140 20], 'String',statsC,'Style','popup',...
            'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],...
            'HorizontalAlignment','left','callback',...
            'outcomeModelsGUI(''SHOW_MODEL_STAT'')');
        dvhStatH(end+1) = annotation('textbox','Tag','outBoxStat','Position',[0.3,0.12,0.3,0.2],...
            'Visible','Off','EdgeColor',[0.6 0.6 0.6]);
        
        %Define Models-plot Axis
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+20 220 figureWidth-leftMarginWidth-40 figureHeight-topMarginHeight-230 ],...
            'color',defaultColor,'ytick',[],'xtick',[],'box','on');
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',...
            [leftMarginWidth+60 posTop*2/4+10 figureWidth-leftMarginWidth-100 posTop*0.9/2],...
            'color','w','ytick',[],'xtick',[],'fontSize',8,'box','on','visible','off' );
        plotH(3) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+60 posTop*2/4-35 figureWidth-leftMarginWidth-100 20],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',0,'Max',2);
        addlistener(plotH(3),'ContinuousValueChange',@scaleDose);
        plotH(4) = uicontrol('parent',hFig,'units','pixels','Style','Text','Visible','Off','Tag','sliderVal',...
            'BackgroundColor',defaultColor);
        
        % Store handles
        ud.handle.inputH = inputH;
        ud.handle.DVHStatH = dvhStatH;
        ud.handle.modelsAxis = plotH;
        set(hFig,'userdata',ud);
        
    case 'GET_DOSE'
        
        ud = get(hFig,'userdata');
        dose = get(findobj('tag','doseSelect'),'Value');
        ud.doseNum = dose - 1;
        set(hFig,'userdata',ud);
        
    case 'GET_STRUCT'
        
        ud = get(hFig,'userdata');
        strNum = get(findobj('tag','structSelect'),'Value');
        ud.structNum = strNum - 1;
        set(hFig,'userdata',ud);
        
    case 'LOAD_MODELS'
        
        ud = get(hFig,'userdata');
        % Read .json file containing models
        [fileName,pathName,filterIndex]  = uigetfile('*.json','Select model file');
        if ~filterIndex
            return
        else
            modelC = loadjson(fullfile(pathName,fileName),'ShowProgress',1);
        end
        
        %Clear data/plots from any previously loaded models
        ud.EUD = [];
        ud.modelCurve = [];
        cla(ud.handle.modelsAxis(2));
        
        %Store data for current model
        ud.Models = modelC;
        set(findobj('Tag','plot'),'Enable','On');
        set(hFig,'userdata',ud);
        
        
    case 'PLOT_MODELS'
        
        ud = get(hFig,'userdata');
        if ~isfield(ud,'modelCurve')
            ud.modelCurve = [];
        end
        if ~isfield(ud,'doseNum') || ud.doseNum==0
            msgbox('Please select dose','Plot model');
            return
        end
        if ~isfield(ud,'structNum')|| ud.structNum==0
            msgbox('Please select a structure','Plot model');
            return
        end
        
        % Plot model curves
        modelC = ud.Models;
        numModels = length(modelC);
        EUDv = linspace(0,100,100);
        %Define color order
        colorOrderM = get(gca,'ColorOrder');
        
        for i = 1:numModels
            %Read parameters from .json file
            paramS = modelC{i}.params;
            
            %Compute EUD,NTCP for selected struct/dose
            [EUD,ntcp] = feval(modelC{i}.function,[],paramS,ud.structNum,ud.doseNum,1);
            
            %Compute NTCPv
            [~,ntcpV,modelConfidence] = feval(modelC{i}.function,EUDv,paramS);
            
            %Set plot color
            colorIdx = mod(i,size(colorOrderM,1))+1;
            
            %plot curves
            ud.EUD = [ud.EUD, plot([EUD EUD],[0 ntcp],'linewidth',2,'Color',...
                colorOrderM(colorIdx,:),'parent',ud.handle.modelsAxis(2))];
            ud.modelCurve = [ud.modelCurve plot(EUDv,ntcpV,'linewidth',2,...
                'Color',colorOrderM(colorIdx,:),'parent',ud.handle.modelsAxis(2))];
            ud.modelCurve(i).DisplayName = modelC{i}.name;
            
            %TO DO : model conf
        end
        
        modelAxis = findobj('Tag','modelsAxis');
        modelAxis.Visible = 'On';
        xlabel('Dose scaling'),ylabel('Complication Probability');
        set(findobj('Tag','Scale'),'Visible','On');
        set(hFig,'userdata',ud);
        
    case 'SHOW_MODEL_STAT'
        ud = get(hFig,'userdata');
        if ~isfield(ud,'modelCurve') || isempty(ud.modelCurve)
            return
        end
        
        %Display output
        outStatBox = findall(gcf,'Tag','outBoxStat');
        %Get selected statistic
        selection = get(findobj('tag','statSelect'),'Value');
        if selection==1  %'None'
            outStatBox.String = [];
            outStatBox.Visible = 'Off';
        else
            statC = getStat({ud.modelCurve.YData},selection);
            statC = cellfun(@num2str,statC,'un',0);
            outStatBox.Visible = 'On';
            dispTextC = strcat({ud.modelCurve.DisplayName},{': '},statC).';
            outStatBox.String = dispTextC;
        end
        
        set(hFig,'userdata',ud);
        
    case 'CLOSEREQUEST'
        
        closereq
        
end


%% Compute statistics

    function statC = getStat(dataC,userSel)
        nModels = length(dataC);
        statC = cell(1,nModels);
        switch userSel
            case 2
                %fn1
            case 3
                %fn2
        end
        
    end

    function scaleDose(hObj,hEvent)%#ok
        
        %Get selected scale
        scale = hObj.Value;
        posV = hObj.Position;
        left = posV(1)+(scale/hObj.Max)*posV(3)-5;
        hSliderVal =  findobj('Tag','sliderVal');
        hSliderVal.Position = [left,posV(2)-15,25,15];
        hSliderVal.String = num2str(scale);
        hSliderVal.Visible = 'On';
        
        %Clear any previous scaled-dose plots
        ud = get(hFig,'userdata');
        hScaled = findall(ud.handle.modelsAxis(2),'type','line','LineStyle','--');
        delete(hScaled);
        
        %Plot EUD,ntcp for scaled dose
        modelsC = ud.Models;
        colorM = flipud(cat(1,ud.EUD(:).Color)); % Same line colors
        for k = 1:length(modelsC)
            paramsS = modelsC{k}.params;
            [EUDnew,ntcpNew] = feval(modelsC{k}.function,[],paramsS,ud.structNum,ud.doseNum,scale);
            idx = mod(k,size(colorM,1))+1;
            plot([EUDnew EUDnew],[0 ntcpNew],'Color',colorM(idx,:),'LineStyle','--','linewidth',1,'parent',ud.handle.modelsAxis(2));
        end
        
        set(hFig,'userdata',ud);
        
    end

end
