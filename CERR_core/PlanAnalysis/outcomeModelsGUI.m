function outcomeModelsGUI(command,varargin)
%function outcomeModelsGUI(command,varargin)
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
        handle(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[150 figureHeight-topMarginHeight+5 500 40 ],'Style',...
            'frame','backgroundColor',defaultColor);
        handle(2) = uicontrol(hFig,'tag','title','units','pixels',...
            'Position',[151 figureHeight-topMarginHeight+10 498 30 ],...
            'String','Outcome Models Explorer','Style','text', 'fontSize',10,...
            'FontWeight','Bold','HorizontalAlignment','center',...
            'backgroundColor',defaultColor);
        
        
        % create Dose and structure handles
        inputH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[10 250 leftMarginWidth figureHeight-topMarginHeight-260 ],...
            'Style','frame','backgroundColor',defaultColor);
        inputH(end+1) = uicontrol(hFig,'tag','doseStructTitle','units','pixels',...
            'Position',[20 posTop-40 150 20], 'String','DOSE & STRUCTURE',...
            'Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        prefix = 'Select a dose.';
        doseList = {prefix, planC{indexS.dose}.fractionGroupID};
        prefix = 'Select a structure.';
        structList = {prefix, planC{indexS.structures}.structureName};
        inputH(end+1) = uicontrol(hFig,'tag','doseStatic','units','pixels',...
            'Position',[20 posTop-70 120 20], 'String','Select Dose','Style',...
            'text', 'fontSize',8,'FontWeight','normal','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        inputH(end+1) = uicontrol(hFig,'tag','doseSelect','units','pixels',...
            'Position',[120 posTop-70 120 20], 'String',doseList,'Style',...
            'popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',...
            [1 1 1],'HorizontalAlignment','left');
        inputH(end+1) = uicontrol(hFig,'tag','structStatic','units','pixels',...
            'Position',[20 posTop-100 120 20], 'String','Select Structure',...
            'Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        inputH(end+1) = uicontrol(hFig,'tag','structSelect','units','pixels',...
            'Position',[120 posTop-100 120 20], 'String',structList,'Style',...
            'popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],...
            'HorizontalAlignment','left');
        
        inputH(end+1) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[20 posTop-140 180 20], 'String','MODELS','Style','text',...
            'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,...
            'HorizontalAlignment','left');
        inputH(end+1) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[20 posTop-180 180 30], 'String',...
            'Select file containing Models','Style','push', 'fontSize',8.5,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'outcomeModelsGUI(''LOAD_MODELS'')');
        
        %Create Model-Stats handles
        uicontrol(hFig,'tag','titleFrame','units','pixels','Position',...
            [20 figureHeight-topMarginHeight-525 760 200 ],'Style','frame',...
            'backgroundColor',defaultColor);
        dvhStatH(1) = uicontrol(hFig,'tag','modelStatsTitle','units','pixels',...
            'Position',[25 posTop-350 150 20], 'String','Model Stats','Style',...
            'text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        dvhStatH(end+1) = uicontrol(hFig,'tag','modelSelect','units','pixels',...
            'Position',[25 posTop-375 140 20], 'String',{'None'},'Style','popup',...
            'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],...
            'HorizontalAlignment','left','callback',...
            'outcomeModelsGUI(''SHOW_MODEL_STAT'')');
        
        %Define Models-plot Axis
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
                       [leftMarginWidth+30 250 figureWidth-leftMarginWidth-50 figureHeight-topMarginHeight-260 ],...
                       'color',defaultColor,'ytick',[],'xtick',[]);
                        box on;
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
                            'nextplot', 'add','units','pixels','Position',...
                            [leftMarginWidth+60 posTop*2/4-00 figureWidth-leftMarginWidth-100 posTop*0.9/2],...
                            'color','w','YAxisLocation','left','fontSize',8,'box','on','visible','on' );
        
        % Store handles
        ud.handle.inputH = inputH;
        ud.handle.DVHStatH = dvhStatH;
        ud.handles.modelsAxis = plotH;
        
        set(hFig,'userdata',ud);
        
        
    case 'LOAD_MODELS'
        
        ud = get(hFig,'userdata');
        if ~isfield(ud,'modelCurve')
            ud.modelCurve = [];
        end
        
        % Read .json file containing models
        [fileName,pathName,filterIndex]  = uigetfile('*.json','Select model file');
        if ~filterIndex
            return
        else
            modelC = loadjson(fullfile(pathName,fileName),'ShowProgress',1); %Requires JSONlab toolbox
        end
        
        % Plot model curves
        numModels = length(modelC);
        EUDv = linspace(0,100,100);
        
        %Define color order
        colorOrder = get(gca,'ColorOrder');
        
        for i = 1:numModels
            
            %read m,D50 from .json file
            D50 = modelC{i}.params.D50;
            m = modelC{i}.params.m;
            %a = modelC{i}.params.a;
            
            %Compute NTCP
            tmpv = (EUDv - D50)/(m*D50);
            ntcpV = 1/2 * (1 + erf(tmpv/2^0.5));
            
            %Set plot color
            row = mod(i,size(colorOrder,1))+1;
            
            %plot models
            ud.modelCurve = [ud.modelCurve plot(EUDv,ntcpV,'k','linewidth',2,...
                'Color',colorOrder(row,:),'parent',ud.handles.modelsAxis(2))];
            
        end
        
        
    case 'CLOSEREQUEST'
        
        closereq
        
end

end
