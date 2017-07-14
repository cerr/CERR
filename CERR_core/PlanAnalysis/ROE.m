function ROE(command,varargin)
%  GUI for outcomes modeling (TCP, NTCP)
%  This tool uses JSONlab toolbox v1.2, an open-source JSON/UBJSON encoder and decoder
%  for MATLAB and Octave.
%  See : http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files
% =======================================================================================================================
% APA, 05/10/2016
% AI , 05/24/2016  Added dose scaling
% AI , 07/28/2016  Added ability to modify model parameters
% AI , 09/13/2016  Added TCP axis
% AI , 02/17/17    Added popup to edit structure/plan inputs
% AI , 02/20/17    Added model selection by protocol
% AI , 04/24/17    Added plot focus-switching, changed name to ROE
% AI , 05/23/17    Default plan selection
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
% =========================================================================================================================

% Globals
global planC stateS
indexS = planC{end};

% Get GUI fig handle
hFig = findobj('Tag','ROEFig');

if nargin==0
    command = 'INIT';
end

switch upper(command)
    
    case 'INIT'
        %Initialize main GUI figure
        
        % Define GUI size, margins, position, color & title
        leftMarginWidth = 300;
        topMarginHeight = 50;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;
        screenSizeV = get( 0, 'Screensize' );
        GUIWidth = 1000;
        GUIHeight = 600;
        shift = 10;
        position = [(screenSizeV(3)-GUIWidth)/2,(screenSizeV(4)-GUIHeight)/2,GUIWidth,GUIHeight];
        str1 = 'ROE';
        defaultColor = [0.8 0.9 0.9];
        figColor = [.6 .75 .75];
        
        if isempty(findobj('tag','ROEFig'))
            
            % initialize main GUI figure
            hFig = figure('tag','ROEFig','name',str1,...
                'numbertitle','off','position',position,...
                'CloseRequestFcn', 'ROE(''closeRequest'')',...
                'menubar','none','resize','off','color',figColor);
        else
            figure(findobj('tag','ROEFig'))
            return
        end
        
        
        %Create title handles
        posTop = GUIHeight-topMarginHeight;
        titleH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift posTop-shift/2 GUIWidth-2*shift 0.08*GUIHeight ],'Style',...
            'frame','backgroundColor',defaultColor);
        titleH(2) = uicontrol(hFig,'tag','title','units','pixels',...
            'Position',[.3*GUIHeight+1 posTop+1 .6*GUIWidth 3*shift ],...
            'String','ROE: Radiotherapy Outcomes Estimator','Style','text', 'fontSize',12,...
            'FontWeight','Bold','HorizontalAlignment','center',...
            'backgroundColor',defaultColor);
        
        ud.handle.title = titleH;
        set(hFig,'userdata',ud);
        ROE('refresh',hFig);
        figure(hFig);
        
        
        
    case 'REFRESH'
        
        if isempty(hFig)
            return
        end
        
        % Get GUI size, margins
        leftMarginWidth = stateS.leftMarginWidth;
        topMarginHeight = stateS.topMarginHeight;
        GUIWidth = hFig.Position(3);
        GUIHeight = hFig.Position(4);
        shift = 10;
        defaultColor = [0.8 0.9 0.9];
        posTop = GUIHeight-topMarginHeight;
        
        % Push button for protocol selection
        inputH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift shift leftMarginWidth+.12*GUIWidth GUIHeight-topMarginHeight-2*shift ],...
            'Style','frame','backgroundColor',defaultColor);
        inputH(2) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[2*shift posTop-.16*GUIHeight .16*GUIWidth 2*shift], 'String','','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left');
        inputH(3) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[2*shift posTop-.1*GUIHeight .16*GUIWidth 3*shift], 'String',...
            'Select protocol','Style','push', 'fontSize',9,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'ROE(''LOAD_MODELS'')');
        
        % Pop-up menus to select structures & dose plans 
        tablePosV = [.22*GUIWidth-2*shift posTop-.1*GUIHeight .22*GUIWidth 4*shift];
        colWidth = tablePosV(3)/2-1;
        inputH(4) = uitable(hFig,'Tag','strSel','Position',tablePosV -[0 4*shift 0 0],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'columnEditable',[false,true],'Data',{'structure','Select structure'},'ColumnWidth',{colWidth,colWidth});
        inputH(5) = uitable(hFig,'Tag','dosSel','Position',tablePosV,'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'columnEditable',[false,true],'Data',{'Plan','Select Plan'},'ColumnWidth',{colWidth,colWidth});
        
        % Tables to display & edit model parameters
        inputH(6) = uicontrol(hFig,'units','pixels','Visible','Off','fontSize',9,...
            'Position',tablePosV + [0 -.15*GUIHeight 0 0 ],'String','Model parameters','Style','text',...
            'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor); %Title: Model parameters
        inputH(7) = uicontrol(hFig,'units','pixels','Visible','Off','String','',...
            'Position',tablePosV + [0 -.2*GUIHeight 0 0 ],'fontSize',9,'Style','text',...
            'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor,...
            'foregroundColor',[.6 0 0]); %Model name display
        inputH(8) = uitable(hFig,'Tag','fieldEdit','Position',tablePosV + [0 -.7*GUIHeight 0 4*shift],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',{'Fields','Values'},...
            'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'ColumnWidth',{round(tablePosV(3)/2),round(tablePosV(3)/2)},...
            'columnEditable',[false,true],'backgroundcolor',[1 1 1]); %Parameter tables
        
        % Push-buttons to save, plot, switch focus 
        inputH(9) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',[.36*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Save','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','ROE(''SAVE_MODELS'' )');
        inputH(10) = uicontrol(hFig,'units','pixels','Tag','plotButton','Position',[.29*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Plot','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','ROE(''PLOT_MODELS'' )');
        inputH(11) = uicontrol(hFig,'units','pixels','Tag','switchPlot','Position',[.2*GUIWidth .1*shift .08*GUIWidth 4*shift],'backgroundColor',defaultColor,...
            'String','Switch plot','Style','popup', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback',@switchFocus);
        
        
        %Plot axes
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.14*GUIWidth shift GUIWidth-leftMarginWidth-.15*GUIWidth GUIHeight-topMarginHeight-2*shift ],...
            'color',defaultColor,'ytick',[],'xtick',[],'box','on'); %Right frame
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',...
            [leftMarginWidth+.2*GUIWidth .16*GUIHeight .73*GUIWidth-leftMarginWidth GUIHeight-topMarginHeight-0.2*GUIHeight],...
            'color','none','XAxisLocation','bottom','YAxisLocation','left','xlim',[.5 1.5],'ylim',[0 1],...
            'fontSize',8,'fontWeight','bold','box','on','visible','off'); %NTCP plot axis
        plotH(3) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
            'color','none','XAxisLocation','bottom','YAxisLocation','right','xlim',[.5 1.5],'ylim',[0 1],...
            'xtick',[],'fontSize',8,'fontWeight','bold','box','on','visible','off'); %TCP plot axis
        plotH(4) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.18*GUIWidth 3*shift .75*GUIWidth-leftMarginWidth 2*shift],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',0.5,'Max',1.5,'Value',1); %Slider (dose scale)
        addlistener(plotH(4),'ContinuousValueChange',@scaleDose);
        
        % Store handles
        ud.handle.inputH = inputH;
        ud.handle.modelsAxis = plotH;
        ud.sliderPos = plotH(4).Position;
        set(hFig,'userdata',ud);
        
        
    case 'LOAD_MODELS'
        ROE('REFRESH');
        ud = get(hFig,'userdata');
        
        %Get path to .json files
        optS = CERROptions; %NOTE: Define path to .json files for protocols, models & clinical criteria in CERROptions.m
                            % optS.ROEProtocolPath = 'yourpathtoprotocols';   
                            % optS.ROEModelPath = 'yourpathtomodels';
                            % optS.ROECriteriaPath = 'yourpathtocriteria'
        protocolPath = optS.ROEProtocolPath;
        modelPath = optS.ROEModelPath;
        criteriaPath = optS.ROECriteriaPath;
        
        % List available protocols for user selection
        [protocolListC,protocolIdx,ok] = listFiles(protocolPath,'Multiple');
        if ~ok
            return
        end
        
        % Load models associated with selected protocol(s)
        root = uitreenode('v0', 'Protocols', 'Protocols', [], false);  %Create root node (for tree display)
        for p = 1:numel(protocolIdx) %Cycle through selected protocols
            [~,protocol] = fileparts(protocolListC{protocolIdx(p)});
            protocolInfoS = loadjson(fullfile(protocolPath,protocolListC{protocolIdx(p)}),'ShowProgress',1); %Load .json for protocol
            modelListC = fields(protocolInfoS.models); %Get list of relevant models
            numModels = numel(modelListC);
            protocolS(p).modelFiles = [];
            uProt = uitreenode('v0',protocol,protocolInfoS.name,[],false);  %Create nodes for protocols
            for m = 1:numModels
                protocolS(p).protocol = protocolInfoS.name; 
                modelFPath = fullfile(modelPath,protocolInfoS.models.(modelListC{m}).modelFile); %Get path to .json for model
                protocolS(p).model{m} = loadjson(modelFPath,'ShowProgress',1); %Load model parameters from .json file
                protocolS(p).modelFiles = [protocolS(p).modelFiles,modelFPath];
                modelName = protocolS(p).model{m}.name;
                uProt.add(uitreenode('v0', modelName,modelName, [], true)); %Create nodes for models
            end
            protocolS(p).numFractions = protocolInfoS.numFractions;
            root.add(uProt); %Add protocol to tree
            % % Get clinical criteria files
            %         critPath = fullfile(fPath,protocol,'Clinical criteria','*.json');
            %         fileS = dir(critPath);
            %         if ~isempty(fileS)
            %         critFile = fileS.name;
            %         critS = loadjson(fullfile(fPath,protocol,'Clinical criteria',critFile),'ShowProgress',0);
            %         ud.criteria = critS;
            %         end
        end
        
        %Create tree to list models by protocol
        shift = 10;
        GUIWidth = hFig.Position(3);
        GUIHeight = hFig.Position(4);
        mtree = uitree('v0', 'Root', root, 'SelectionChangeFcn',@getParams);
        set(mtree,'Position',[2*shift 5*shift .16*GUIWidth .68*GUIHeight],...
            'Visible',false);
        drawnow;
        set(ud.handle.inputH(2),'string','Protocols & Models'); %Tree title 
        
        %Get info from .json file
        % fileInfo = System.IO.FileInfo(fullfile(pathName,fileName));
        % created = fileInfo.CreationTime.ToString;
        % modified = fileInfo.LastAccessTime.ToString;
        % dummyAccount = System.Security.Principal.NTAccount('dummy');
        % owner = char(fileInfo.GetAccessControl.GetOwner(GetType(dummyAccount)).Value.ToString);
        
        %Store protocol & model parameters from .json files to GUI userdata
        ud.Protocols = protocolS;
        ud.modelTree = mtree;
        
        %Create push buttons for editing model parameters
        set(hFig,'userdata',ud);
        ROE('LIST_MODELS');
        
        
    case 'PLOT_MODELS'
        %Clear previous plots          
        ROE('CLEAR_PLOT',hFig);
        ud = get(hFig,'userdata');
        
        %Initialize plot handles
        if ~isfield(ud,'NTCPCurve')
            ud.NTCPCurve = [];
        end
        if isfield(ud,'criteria')
            ud.TCPCurve = [];
            if ~isfield(ud.criteria,'cMarkers')
                ud.criteria.cMarkers = [];
            end
            if ~isfield(ud.criteria,'gMarkers')
                ud.criteria.gMarkers = [];
            end
        end
        
        
        % Define axis handles, slider, color order, foreground protocol
        hNTCPAxis = ud.handle.modelsAxis(2);
        hNTCPAxis.Visible = 'On';
        grid(hNTCPAxis,'On');
        hTCPAxis = ud.handle.modelsAxis(3);
        hTCPAxis.Visible = 'On';
        hSlider = ud.handle.modelsAxis(4);
        scaleV = linspace(0.5,1.5,100);
        colorOrderM = get(gca,'ColorOrder');
        if ~isfield(ud,'foreground') || isempty(ud.foreground)
            ud.foreground = 1;
        end
        
        %% Plot models                                                             
        ntcp = 0;
        tcp = 0;
        %----------TEMP -----------%
        cCount = 0;
        gCount = 0;
        %--------- End temp -------%
        hWait = waitbar(0,'Generating plots...');
        protocolS = ud.Protocols; 
        numModelC = arrayfun(@(x)numel(x.model),protocolS,'un',0);
        numModelsV = [numModelC{:}];
        jTot = 0;
        for p = 1:numel(protocolS)
            %Check that valid model file was passed
            modelC = protocolS(p).model;
            if isempty(modelC)
                msgbox('Please select model files','Plot models');
                close(hWait);
                return
            end
            %Check for valid structure & dose plan 
            isStr = cellfun(@(x)any(~isfield(x,'strNum') | isempty(x.strNum) | x.strNum==0),modelC,'un',0);
            err = find([isStr{:}]);
            if ~isempty(err)
                msgbox(sprintf('Please select structure:\n protocol: %d\tmodels: %d',p,err),'Plot model');
                close(hWait);
                return
            end
            isPlan = cellfun(@(x)any(~isfield(x,'planNum') | isempty(x.planNum) | x.planNum==0),modelC,'un',0);
            err = find([isPlan{:}]);
            if ~isempty(err)
                msgbox(sprintf('Please select dose plan:\n protocol: %d\tmodels: %d',p,err),'Plot model');
                close(hWait);
                return
            end
            % Set plot transparency
            if p == ud.foreground
                plotColorM = [colorOrderM,ones(size(colorOrderM,1),1)];
                lineStyle = '-';
            else
                alpha = 0.5;
                %gray = repmat([.5 .5 .5],size(colorOrderM,1),1);
                plotColorM = [colorOrderM,repmat(alpha,size(colorOrderM,1),1)];
                lineStyle = '--';
            end
            %% Plot
            numModels = numModelsV(p);
            for j = 1:numModels
                
                %% Store parameters from .json file to parameter dictionary paramS
                paramS = modelC{j}.parameters;
                %Add structure number
                structNumV = modelC{j}.strNum;
                paramS.structNum = structNumV;  
                %Add plan no., alpha/beta
                plnNumV = modelC{j}.planNum;
                abRatio = modelC{j}.abRatio;
                paramS.planNum = plnNumV;
                paramS.abRatio = abRatio;
                %Add no. of fractions 
                numFractionsPlan = protocolS(p).numFractions;
                paramS.numFractions = numFractionsPlan;
                
                %% Scale dose bins
                doseBinsC = cell(1,numel(structNumV));
                volsC = cell(1,numel(structNumV));
                scaledCPv = scaleV * 0;
                %Get (physical) dose bins    
                for nStr = 1:numel(structNumV)
                [doseBinsC{nStr}, volsC{nStr}] = getDVH(structNumV(nStr),plnNumV(nStr),planC); 
                end
                modelC{j}.dv = {doseBinsC,volsC};
                for n = 1 : numel(scaleV)
                    %Scale dose bins
                    scale = scaleV(n);
                    scaledDoseBinsC = cellfun(@(x) x*scale,doseBinsC,'un',0);
                    %Apply fractionation correction where required
                    correctedScaledDoseC = frxCorrect(modelC{j},structNumV,numFractionsPlan,scaledDoseBinsC);
                    
                    % ---------- Temp : change to avoid passing cell array (loop??) -------
                    if numel(structNumV)==1 % Pass as vector if no. structs == 1
                        inDoseBins = correctedScaledDoseC{1};
                        inVolsHist = volsC{1};
                    else
                        inDoseBins = correctedScaledDoseC;
                        inVolsHist = volsC;
                    end
                    % --------------------------------------------------------------------
                    
                    %% Compute TCP/NTCP
                    scaledCPv(n) = feval(modelC{j}.function,paramS,inDoseBins,inVolsHist);
                    
                    %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                    if n==numel(scaleV)
                        %Get corrected dose at scale == 1
                        testDoseC = frxCorrect(modelC{j},structNumV,numFractionsPlan,doseBinsC);
                        if numel(structNumV)==1
                            testDoseC = testDoseC{1};
                        end
                        %Display mean dose, EUD, GTD(if applicable)
                        outType = modelC{j}.type;
                        a = 1/0.09;
                        testMeanDose = calc_meanDose(testDoseC,volsC{1});
                        testEUD = calc_EUD(testDoseC,volsC{1},a);
                        if strcmp(modelC{j}.name,'Lung TCP')
                            additionalParamS = paramS.gTD.params;
                            for fn = fieldnames(additionalParamS)'
                                paramS.(fn{1}) = additionalParamS.(fn{1});
                            end
                            testGTD = calc_gTD(testDoseC,volsC{1},paramS);
                            fprintf(['\n---------------------------------------\n',...
                                'GTD  = %f'],testGTD);
                        end
                        %Display TCP/NTCP
                        testOut = feval(modelC{j}.function,paramS,testDoseC,volsC{1});
                        fprintf(['\n---------------------------------------\n',...
                            'Protocol:%d, Model:%d\nMean Dose = %f\nEUD = %f\n%s = %f\n'],p,j,testMeanDose,testEUD,outType,testOut);
                    end
                    %---------------------------------END TEMP-----------------------------------%
                end
                
                %% Plot TCP/NTCP vs. physical dose scale factor
                %Set plot color
                colorIdx = mod(j,size(plotColorM,1))+1;
                %Display curves
                if strcmp(modelC{j}.type,'NTCP')
                    ntcp = ntcp + 1;
                    ud.NTCPCurve = [ud.NTCPCurve plot(hNTCPAxis,scaleV,scaledCPv,'linewidth',2,...
                        'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                    ud.NTCPCurve(ntcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                    hCurr = hNTCPAxis;
                else
                    tcp = tcp + 1;
                    ud.TCPCurve = [ud.TCPCurve plot(hTCPAxis,scaleV,scaledCPv,'linewidth',2,...
                        'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                    ud.TCPCurve(tcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                    hCurr = hTCPAxis;
                end
                
                %             %%%%%%%%%%%%%%%%%%% TEMP ADDED %%%%%%%%%
                %             if isfield(ud,'criteria')
                %                 strName = modelC{j}.structure;
                %                 if isfield(ud.criteria.Structures,strName)
                %                     if isfield(ud.criteria.Structures.(strName),'criteria')
                %                         criteriaS = ud.criteria.Structures.(strName);
                %                         [limitV, valV, ntcpLim,tcpLim,cStrC] = getLimits(criteriaS,'criteria',structNumV,planNum,1); %scale = 1;
                %                         scV = limitV./valV;
                %                         ltCheck = bsxfun(@ge,scaleV.',scV);
                %                         [valid,scIdx] = max(ltCheck,[],1);
                %                         markerxV = scaleV(scIdx);
                %                         markeryV = scaledCPv(scIdx);
                %
                %                         if ~isempty(ntcpLim)
                %                             cpLt = find(scaledCPv >= ntcpLim(1),1);
                %                             if ~isempty(cpLt)
                %                                 ins = ntcpLim(2)-1;
                %                                 markerxV = [markerxV(1:ins),scaleV(cpLt),markerxV(ins+2:end)];
                %                                 markeryV = [markeryV(1:ins),scaledCPv(cpLt),markeryV(ins+2:end)];
                %                                 valid = [valid(1:ins),true,valid(ins+2:end)];
                %                             end
                %                         end
                %                         markerxV = markerxV(valid);  %~valid=> out of scale range
                %                         markeryV = markeryV(valid);
                %                         cStrC = cStrC(valid);
                %
                %                         hcmenu = uicontextmenu('Parent',hFig);
                %                         for i = 1:numel(cStrC)
                %                         uimenu(hcmenu, 'Label', cStrC{i});
                %                         end
                %
                %                         % PLOT
                %                         ud.criteria.cMarkers =  [ud.criteria.cMarkers plot(hCurr,markerxV,markeryV,'ko',...
                %                             'MarkerFaceColor','r','markerSize',8,'uicontextmenu',hcmenu)];
                %                     end
                %
                %                     if isfield(ud.criteria.Structures.(strName),'guidelines')
                %                         guidesS = ud.criteria.Structures.(strName);
                %                         [limitV, valV, ~,~,gStrC] = getLimits(guidesS,'guidelines',structNumV,planNum,1); %scale = 1;
                %                         scV = limitV./valV;
                %                         ltCheck = bsxfun(@ge,scaleV.',scV);
                %                         [valid,scIdx] = max(ltCheck,[],1);
                %                         scMarkIdx = scIdx(valid);
                %                         markerxV = scaleV(scMarkIdx);
                %                         markeryV = scaledCPv(scMarkIdx);
                %                         gStrC = gStrC(valid);
                %
                %                         hcmenu = uicontextmenu('Parent',hFig);
                %                         for i = 1:numel(gStrC)
                %                         uimenu(hcmenu, 'Label', gStrC{i});
                %                         end
                %
                %                         hp = plot(hCurr,markerxV,markeryV,'ko',...
                %                             'MarkerFaceColor','y','markerSize',8);
                %                         set(hp,'uicontextmenu',hcmenu);
                %                         ud.criteria.gMarkers = [ud.criteria.gMarkers hp];
                %                     end
                %                 end
                %             end
                %             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               jTot = jTot+1; %No. of models dispalyed
               waitbar(j/sum(numModelsV));
            end
            %Store parameters
            protocolS(p).model = modelC;
        end
        close(hWait);
        %Add plot labels, legend
        xlabel(hNTCPAxis,'Dose scale factor'),ylabel(hNTCPAxis,'NTCP');
        ylabel(hTCPAxis,'TCP');
        NTCPLegendC = arrayfun(@(x)x.DisplayName,ud.NTCPCurve,'un',0);
        TCPLegendC = arrayfun(@(x)x.DisplayName,ud.TCPCurve,'un',0);
        legend([ud.NTCPCurve,ud.TCPCurve],[NTCPLegendC,TCPLegendC],'Location','northeast','Color','none');
        %Display slider
        set(hSlider,'Visible','On'); %Slider on
        ud.handle.modelsAxis(4) = hSlider;
        %Plot switch on
        set(ud.handle.inputH(11),'Enable','On','string',{'Switch plot...',ud.Protocols.protocol});
        
        %Store userdata
        ud.Protocols = protocolS;
        set(hFig,'userdata',ud);
        %Display current dose/probability
        scaleDose(hSlider);
        
    case 'CLEAR_PLOT'
        ud = get(hFig,'userdata');
        %Clear data/plots from any previously loaded models/plans/structures
        ud.NTCPCurve = [];
        ud.TCPCurve = [];
        cla(ud.handle.modelsAxis(2));
        legend(ud.handle.modelsAxis(2),'hide')
        cla(ud.handle.modelsAxis(3));
        %Set slider back to default position
        hSlider = ud.handle.modelsAxis(4);
        hSlider.Value = 1;
        hSlider.Visible = 'Off';
        ud.handle.modelsAxis(4)= hSlider;
        ud.scaleDisp = [];
        set(hFig,'userdata',ud);
        
    case 'LIST_MODELS'
        %Check for required fields in .json for model & display protocol tree
        
        %Get selected protocols
        ud = get(hFig,'userdata');
        ud.handle.editModels = [];
        protocolS = ud.Protocols;
        %Check models for required fields ('function' and 'parameter')
        numProtocols = length(protocolS);
        for j = 1:numProtocols
            modelC = protocolS(j).model;
            numModels = length(modelC);
            for i = 1:numModels
                modelNameC = cell(1,numModels);
                fieldC = fieldnames(modelC{i});
                fnIdx = strcmpi(fieldC,'function');
                paramIdx = strcmpi(fieldC,'parameters');
                nameIdx = strcmpi(fieldC,'Name');
                %Check for 'function' and 'parameter' fields
                if ~any(fnIdx) || isempty(modelC{i}.(fieldC{fnIdx}))
                    msgbox('Model file must include ''function'' attribute.','Model file error');
                    return
                end
                if ~any(paramIdx) || isempty(modelC{i}.(fieldC{paramIdx}))
                    msgbox('Model file must include ''parameters'' attribute.','Model file error');
                    return
                end
                %Set default name if missing
                if ~any(nameIdx)
                    modelNameC{i} = ['Model: ',num2str(i)];
                else
                    modelNameC{i} = modelC{i}.(fieldC{nameIdx});
                end
            end
        end
        
        set(ud.modelTree,'Visible',true);
        
        set(ud.handle.inputH(10),'Enable','On'); %Plot button on
        
        
        set(hFig,'userdata',ud);
        
    case 'SAVE_MODELS'
        ud = get(hFig,'userData');
        protocolS = ud.Protocols;
        
        %Save changes to model files
        for j = 1: numel(protocolS)
            modelC = protocolS(j).model;
            outFile = {protocolS(j).modelFiles};
            numModels = numel(outFile);
            %Create UID
            modelNamesC = cellfun(@(x) x.function,modelC,'un',0);
            dateTimeV = clock.';
            dateTimeC = arrayfun(@num2str,dateTimeV,'un',0);
            randC = arrayfun(@num2str,1000.*rand(1,numModels),'un',0);
            UIDC = strcat({'outcomeModels.'},modelNamesC,{'.'},dateTimeC(2),...
                dateTimeC(3),dateTimeC(1),{'.'},dateTimeC{4:6},{'.'},randC);
            modelC = arrayfun(@(i) setfield(modelC{i},'UID',UIDC{i}),1:length(modelC),'un',0);
            %Remove fields
            remC = {'plan','strNum','dosNum','dv','planNum'};
            for m = 1:numel(outFile)
                remIdx = ismember(remC,fieldnames(modelC{m}));
                modelC{m} = rmfield(modelC{m},remC(remIdx));
                fprintf('\nSaving changes to %s ...',outFile{m});
                savejson('',modelC{m},'filename',outFile{m});
            end
        end
        fprintf('\nSave complete.\n');
        
        set(ud.handle.inputH(9),'Enable','Off');  %Disable save
        set(hFig,'userdata',ud);
        
        
        
    case 'CLOSEREQUEST'
        
        closereq
        
end


%% -----------------------------------------------------------------------------------------
% Edit model parameters
    function editParams(hObj,hData)
        
        ud = get(hFig,'userdata');
        
        %Get input data
        idx = hData.Indices(1);
        val = hData.EditData;
        val2num = str2num(val);
        if isempty(val2num) %Convert from string if numerical
            val2num = val;
        end
        prtcNum = ud.PrtcNum;
        modelNum = ud.ModelNum;
        modelsC = ud.Protocols(prtcNum).model;
        
        
        %Update parameter
        switch(hObj.Tag)
            case 'strSel'
                strListC = {'Select structure',planC{indexS.structures}.structureName};
                matchIdx = find(strcmp(strListC,val));
                modelsC{modelNum}.strNum(idx) = matchIdx - 1;
                modelsC{modelNum}.structure = strListC{matchIdx};
            case 'dosSel'
                dosListC = {'Select Plan',planC{indexS.dose}.fractionGroupID};
                matchIdx = find(strcmp(dosListC,val));
                modelsC{modelNum}.planNum(idx) = matchIdx - 1;
                modelsC{modelNum}.plan.(['plan',num2str(idx)]) = dosListC{matchIdx};
            case 'fieldEdit'
                modelsC{modelNum} = modelsC{modelNum};
                parName = hObj.Data{idx,1};
                modelsC{modelNum}.(parName) = val2num;
                modelsC{modelNum} = modelsC{modelNum};
            case 'paramEdit'
                %Update modelC
                parName = hObj.Data{idx,1};
                type = modelsC{modelNum}.parameters.(parName).type;
                if strcmpi(type{1},'bin')
                    desc = modelsC{modelNum}.parameters.(parName).desc;
                    ctgIdx = strcmp(desc,val2num);
                    value = modelsC{modelNum}.parameters.(parName).cteg(ctgIdx);
                    modelsC{modelNum}.parameters.(parName).val = value;
                else
                    modelsC{modelNum}.parameters.(parName).val = val2num;
                end
        end
        set(ud.handle.inputH(9),'Enable','On');  %Enable save
        ud.Protocols(prtcNum).model = modelsC;
        set(hFig,'userdata',ud);
        
    end

% Display model parameters & values 
    function hTab = extractParams(modelS)
        
        %Delete any previous param tables
        ud = get(hFig,'userdata');
        if isfield(ud,'currentPar')
            delete(ud.currentPar);
        end
        
        %Get parameter names
        inS = modelS.parameters;
        parListC = fieldnames(inS);
        nPars = numel(parListC);
        reservedFieldsC = {'type','cteg','desc'};
        
        
        %Create GUI input elements
        rowHt = 20;
        rowSep = 10;
        rowWidth = 110;
        fwidth = hFig.Position(3);
        fheight = hFig.Position(3);
        left = 10;
        columnWidth ={rowWidth-1,rowWidth-1};
        posV = [.22*fwidth-2*left .38*fheight 2*rowWidth rowHt];
        row = 1;
        hTab = gobjects(0);
        for k = 1:nPars
            subfieldsC = fieldnames(inS.(parListC{k}));
            valIdxC = cellfun(@(x) ~any(strcmpi(x,reservedFieldsC)),subfieldsC,'un',0);
            valNameC = subfieldsC([valIdxC{:}]);
            nVal = numel(valNameC);
            valTypes = inS.(parListC{k}).type;
            for l = 1:nVal
                if strcmp(valNameC{l},'val');
                    dispVal = inS.(parListC{k}).(valNameC{l});
                    switch(lower(valTypes{l}))
                        case 'string'
                            columnFormat = {[],[]};
                            Data = {parListC{k},dispVal};
                        case'cont'
                            columnFormat = {[],[]};
                            Data = {parListC{k},dispVal} ;
                        case 'bin'
                            columnFormat = {[],inS.(parListC{k}).desc};
                            Data = {parListC{k},inS.(parListC{k}).desc{dispVal+1}};
                    end
                    hTab(row) = uitable(hFig,'Tag','paramEdit','Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
                        'columnformat',columnFormat,'Data',Data,'Visible','Off',...
                        'columneditable',[false,true],'columnname',[],'rowname',[],...
                        'columnWidth',columnWidth,'celleditcallback',@editParams);
                    row = row+1;
                end
            end
        end
        
    end

% Perform fractionation correction
    function eqScaledDoseC = frxCorrect(modelParS,strNumV,numFractions,scaledDoseC)
        if strcmpi(modelParS.fractionCorrect,'yes') & isfield(modelParS,'abCorrect')
            if strcmpi(modelParS.abCorrect,'yes')
                %Convert to EQD in std fraction size
                stdFrxSize = modelParS.stdFractionSize;
                for s = 1:numel(strNumV)
                    scaledFrxSizeV = scaledDoseC{s}/numFractions;
                    eqScaledDoseC{s} = scaledDoseC{s} .*(scaledFrxSizeV+modelParS.abRatio)./(stdFrxSize + modelParS.abRatio);
                end
            else %Different flag?
                %Convert to standard no. fractions
                Na = numFractions;
                Nb = modelParS.stdNumFractions;
                a = Na;
                b = Na*Nb*modelParS.abRatio;
                for s = 1:numel(strNumV)
                    scaledDoseBinsV = scaledDoseC{s};
                    c = -scaledDoseBinsV.*(b + scaledDoseBinsV*Nb);
                    eqScaledDoseC{s}= (-b + sqrt(b^2 - 4*a*c))/(2*a);
                end
            end
        else
            eqScaledDoseC = scaledDoseC;
        end
        
    end


% Get parameter value
    function [parNameC,parIdxV] = getMatchPar(modelS,parType,parName,parListC)
        
        parIn = isfield(modelS,parType);
        if parIn
            if isstruct(modelS.(parType))
                parNameC = fieldnames(modelS.(parType));
                parValC = struct2cell(modelS.(parType));
            else
                parNameC = parName;
                parValC = {modelS.(parType)};
            end
            parIdxC = cellfun(@(x)find(strcmpi(x,parListC)),parValC,'un',0);
            notFoundC = cellfun(@isempty,parIdxC,'un',0);
            parIdxC([notFoundC{:}]) = {1}; %Set to default=1 (select par)
            parIdxV = [parIdxC{:}];
        else
            parNameC = parName;
            parIdxV = 1; %Default
        end
        
    end


%Store user inputs to userdata
    function getParams(hObj,hEvt)
        
        ud = get(hFig,'userdata');
        tree = hObj.getTree;
        currNode = hEvt.getCurrentNode;
        
        if  currNode.getLevel<2
            tree.expandRow(tree.getSelectionRows);
        else
            modS = ud.Protocols;
            prtcol = currNode.getParent.getName;
            prtListC = {modS.protocol};
            prtcNum = strcmp(prtcol,prtListC);
            modelsC = modS(prtcNum).model;
            modListC = cellfun(@(x) x.name,modelsC,'un',0);
            modelNum = strcmp(currNode.getName,modListC);
            
            %Get structure input
            structList = {planC{indexS.structures}.structureName};
            structList = {'Select structure',structList{:}}.';
            [strNameC,strIdxV] = getMatchPar(modelsC{modelNum},'structure','Structure',structList);
            
            %Get plan input
            planList = {planC{indexS.dose}.fractionGroupID};
            planList = {'Select Plan',planList{:}}.';
            planNameC = cell(numel(strIdxV),1);
            dispPlanC = cell(numel(strIdxV),1);
            for s = 1:numel(strIdxV)
            if numel(planList)==2 %Default to 1st plan if only one is available
                if numel(strIdxV)==1
                dispPlanC{1} = 'Dose plan';
                else
                dispPlanC{s} = ['Dose plan ',num2str(s)];
                end
                planNameC{s} = ['plan',num2str(s)];
                planIdxV(s) = 2;
            else
                x = strfind(lower(planList),'sum');%Default to plan named 'SUM' if available
                if any([x{:}])
                    idx = find([x{:}],1);
                    planIdxV(s) = find(idx);
                    planNameC{s} = planList{idx};
                else
                    %User selection
                    [planNameC{s},planIdxV(s)] = getMatchPar(modelsC{modelNum},['plan.','plan',num2str(s)],['plan',num2str(s)],planList);
                    if numel(strIdxV)==1
                        dispPlanC{1} = 'Dose plan';
                    else
                        dispPlanC{s}= ['Dose plan',num2str(s)];
                    end
                end
            end
            modelsC{modelNum}.plan.(planNameC{s}) = planList(planIdxV(s));
            end
            
            %Get parameters
            hPar = extractParams(modelsC{modelNum});
            
            %Add file properties if missing
            fieldsC = fieldnames(modelsC{modelNum});
            valsC = struct2cell(modelsC{modelNum});
            filePropsC = {'modified_at','modified_by','created_at','created_by',};
            missingFilePropsV = ~ismember(filePropsC,lower(fieldsC));
            if any(missingFilePropsV)
                idx = find(missingFilePropsV);
                for k = 1:numel(idx)
                    fieldsC = [fieldsC(:);filePropsC{k}];
                    valsC = [valsC(:);{''}];
                end
            end
            tab3C = {'name','type','stdFractionSize','prescribedDose','abRatio','function','created_by',...
                'created_at','modified_by','modified_at'};
            valsC = valsC(ismember(fieldsC,tab3C));
            fieldsC = fieldsC(ismember(fieldsC,tab3C));
            
            
            %Storage/display
            %Table1
            hTab1 = ud.handle.inputH(4);
            fmt = {[] structList.'};
            strDatC = [strNameC,structList(strIdxV)];
            set(hTab1,'ColumnFormat',fmt,'Data',strDatC,'Visible','On','Enable','On');
            %Table2
            hTab2 = ud.handle.inputH(5);
            fmt = {[] planList.'};
            dosDatC = [dispPlanC,planList(planIdxV)];
            set(hTab2,'ColumnFormat',fmt,'Data',dosDatC,'Visible','On','Enable','On');
            %Table3
            hTab3 = ud.handle.inputH(8);
            set(hTab3,'Data',[fieldsC,cellfun(@num2str,valsC,'un',0)],'Visible','On','Enable','On');
            %Parameters
            [hPar(:).Visible] = deal('On');
            
            
            ud.handle.inputH(4) = hTab1;
            ud.handle.inputH(5) = hTab2;
            ud.handle.inputH(8) = hTab3;
            set(ud.handle.inputH(6),'Visible','On'); %Parameters header
            modName = modelsC{modelNum}.name;
            set(ud.handle.inputH(7),'String',['MODEL:  ',modName],'Visible','On'); %Display currently selected model name
            ud.currentPar = hPar;
            
            %Store str, plan, params to modelsC
            modelsC{modelNum}.strNum = strIdxV-1;
            modelsC{modelNum}.structure = structList{strIdxV};
            modelsC{modelNum}.planNum = planIdxV-1;
            modS(prtcNum).model = modelsC;
            ud.Protocols = modS;
            %set current model,protocol nos
            ud.PrtcNum = find(prtcNum);
            ud.ModelNum = find(modelNum);
            
            set(ud.handle.inputH(8),'Enable','On'); %Enable save
            set(hFig,'userdata',ud);
            
        end
    end

%Listdlg for folder selection
    function [dirListC,dirIdx,selected] = listFiles(fpath,mode)
        
        dirS = dir([fpath,filesep,'*.json']);
        dirListC = {dirS(:).name};
        dirListC = dirListC(~ismember(dirListC,{'.','..'}));
        [dirIdx,selected] = listdlg('ListString',dirListC,...
            'ListSize',[300 100],'Name','Select protocols','SelectionMode',mode);
        
    end

% Compute TCP/NTCP at scaled dose
    function scaleDose(hObj,hEvent)
        
        ud = get(hFig,'userdata');
        
        %Get selected scale
        userScale = hObj.Value;
        
        %Clear any previous scaled-dose plots
        hScaledNTCP = findall(ud.handle.modelsAxis(2),'type','line','LineStyle','-.');
        hScaledTCP = findall(ud.handle.modelsAxis(3),'type','line','LineStyle','-.');
        delete(hScaledNTCP);
        delete(hScaledTCP);
        if isfield(ud,'scaleDisp')
            ud.scaleDisp.String = '';
        end
        if isfield(ud,'outDisp')
            [ud.outDisp.String] = deal('');
        end
        hScaleDisp = text(userScale,-.06,'','Parent',ud.handle.modelsAxis(2),...
            'FontSize',8,'Color',[.3 .3 .3]);
        
        %Set color order
        colorM = get(gca,'ColorOrder');
        
        
        %Scale plots as selected
        modNum = 0;
        for l = 1:numel(ud.Protocols)
            nMod = length(ud.Protocols(l).model);
            if l == ud.foreground
                pColorM = [colorM,ones(size(colorM,1),1)];
            else
                wt = 0.4;
%                 bg = repmat([.5 .5 .5],size(colorM,1),1);
%                 pColorM = [bg,repmat(wt,size(colorM,1),1)];
                pColorM = [colorM,repmat(wt,size(colorM,1),1)];
            end
            for k = 1:nMod
                modNum = modNum+1;
                
                % Get params
                modelsC = ud.Protocols(l).model;
                paramsS = modelsC{k}.parameters;
                
                % Get struct
                strNum = modelsC{k}.strNum;
                paramsS.structNum = strNum;
                
                % Get plan
                paramsS.planNum = modelsC{k}.planNum;
                paramsS.numFractions = ud.Protocols(l).numFractions; 
                paramsS.abRatio = modelsC{k}.abRatio;
                
                % Get dose bins
                dose0C = modelsC{k}.dv{1};
                vol0C = modelsC{k}.dv{2};
                %Scale
                scdoseC = cellfun(@(x) x*userScale,dose0C,'un',0);
                %Apply fractionation correction where required
                eqScaledDoseC = frxCorrect(modelsC{k},strNum,paramsS.numFractions,scdoseC);
                
                % Pass as vector if nStr==1
                if numel(strNum) == 1
                    vol0C = vol0C{1};
                    eqScaledDoseC = eqScaledDoseC{1};
                end
                
                % Compute probability
                cpNew = feval(modelsC{k}.function,paramsS,eqScaledDoseC,vol0C);
                
                % Set plot color
                clrIdx = mod(k,size(pColorM,1))+1;
                
                if strcmp(modelsC{k}.type,'NTCP')
                    plotAxis = ud.handle.modelsAxis(2);
                    loc = hObj.Min;
                    tshift = -.08;
                    plot([userScale userScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',.5,'parent',plotAxis);
                    plot([loc userScale],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',.5,'parent',plotAxis);
                else
                    loc = hObj.Max;
                    tshift = .03;
                    plotAxis = ud.handle.modelsAxis(3);
                    plot([userScale userScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',.5,'parent',plotAxis);
                    plot([userScale loc],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',.5,'parent',plotAxis);
                end
                
                outcomeVal = sprintf('%.3f',cpNew);
                hOutcomeDisp(modNum) = text(loc+tshift,cpNew,outcomeVal,'Parent',plotAxis,...
                                  'FontSize',8,'Color',[.3 .3 .3]);
                
            end
        end
        scaleVal = sprintf('%.3f',userScale);
        hScaleDisp.String = scaleVal;
        ud.scaleDisp = hScaleDisp;
        ud.outDisp = hOutcomeDisp;
        set(hFig,'userdata',ud);
        
    end

% Switch focus between plots for different protocols
    function switchFocus(hObj,~)
        ud = get(hFig,'userData');
        sel = hObj.Value-1;
        ud.foreground=sel;
        set(hFig,'userData',ud);
        ROE('PLOT_MODELS');
    end


    




end