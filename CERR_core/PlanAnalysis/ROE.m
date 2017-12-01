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
% AI , 11/13/17    Modified to handle multiple structures
% AI , 11/24/17    Modified to display clinical criteria/limits
% -------------------------------------------------------------------------
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
binWidth = .05;


% Get GUI fig handle
hFig = findobj('Tag','ROEFig');

if nargin==0
    command = 'INIT';
end

switch upper(command)
    
    case 'INIT'
        %Initialize main GUI figure
        
        % Define GUI size, margins, position, color & title
        leftMarginWidth = 360;
        topMarginHeight = 60;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;
        screenSizeV = get( 0, 'Screensize' );
        GUIWidth = 1200;
        GUIHeight = 750;
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
        pos = get(hFig,'Position');
        GUIWidth = pos(3);
        GUIHeight = pos(4);
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
            'Select protocol','Style','push', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'ROE(''LOAD_MODELS'')');
        
        % Pop-up menus to select structures & dose plans
        tablePosV = [.22*GUIWidth-2.5*shift posTop-.1*GUIHeight .22*GUIWidth 2.4*shift];
        colWidth = tablePosV(3)/2-1;
        inputH(4) = uitable(hFig,'Tag','strSel','Position',tablePosV-[0 2.5*shift 0 0],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off',...
            'backgroundColor',defaultColor,'columnEditable',[true,true],'Data',...
            {'Select structure','List of structures'},'ColumnWidth',{colWidth,colWidth},'FontSize',10);
        inputH(5) = uitable(hFig,'Tag','doseSel','Position',tablePosV,'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off',...
            'backgroundColor',defaultColor,'columnEditable',[true,true],'Data',...
            {'Select dose plan','List of plans'},'ColumnWidth',{colWidth,colWidth},'FontSize',10);
        
        % Tables to display & edit model parameters
        inputH(6) = uicontrol(hFig,'units','pixels','Visible','Off','fontSize',10,...
            'Position',tablePosV + [0 -.1*GUIHeight 0 0 ],'String','Model parameters','Style','text',...
            'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor); %Title: Model parameters
        inputH(7) = uicontrol(hFig,'units','pixels','Visible','Off','String','',...
            'Position',tablePosV + [0 -.15*GUIHeight 0 0 ],'FontSize',10,'Style','text',...
            'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor,...
            'foregroundColor',[.6 0 0]); %Model name display
        inputH(8) = uitable(hFig,'Tag','fieldEdit','Position',tablePosV + [0 -.75*GUIHeight 0 8*shift],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',{'Fields','Values'},'FontSize',10,...
            'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'ColumnWidth',{round(tablePosV(3)/2),round(tablePosV(3)/2)},...
            'columnEditable',[false,true],'backgroundcolor',[1 1 1]); %Parameter tables
        
        % Push-buttons to save, plot, switch focus
        inputH(9) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',[.36*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Save','Style','Push', 'fontSize',10,'FontWeight','normal','Enable','Off','Callback','ROE(''SAVE_MODELS'' )');
        inputH(10) = uicontrol(hFig,'units','pixels','Tag','plotButton','Position',[.29*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Plot','Style','Push', 'fontSize',10,'FontWeight','normal','Enable','Off','Callback','ROE(''PLOT_MODELS'' )');
        inputH(11) = uicontrol(hFig,'units','pixels','Tag','switchPlot','Position',[.2*GUIWidth .1*shift .08*GUIWidth 4*shift],'backgroundColor',defaultColor,...
            'String','Switch plot','Style','popup', 'fontSize',10,'FontWeight','normal','Enable','Off','Callback',@switchFocus);
        
        
        %Plot axes
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.14*GUIWidth shift GUIWidth-leftMarginWidth-.15*GUIWidth...
            GUIHeight-topMarginHeight-2*shift ],'color',defaultColor,'ytick',[],...
            'xtick',[],'box','on'); %Right frame
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',...
            [leftMarginWidth+.2*GUIWidth .16*GUIHeight .73*GUIWidth-leftMarginWidth,...
            GUIHeight-topMarginHeight-0.2*GUIHeight],'color',[1 1 1],...
            'XAxisLocation','bottom','YAxisLocation','left','xlim',[.5 1.5],'ylim',[0 1],...
            'fontSize',9,'fontWeight','bold','box','on','visible','off'); %NTCP plot axis
        plotH(3) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
            'color','none','XAxisLocation','bottom','YAxisLocation','right',...
            'xlim',[.5 1.5],'ylim',[0 1],'xtick',[],'fontSize',9,'fontWeight',...
            'bold','box','on','visible','off'); %TCP plot axis
        plotH(4) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.2*GUIWidth 3*shift .75*GUIWidth-leftMarginWidth 1.8*shift],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',0.5,'Max',1.5,'Value',1); %Slider (dose scale)
        addlistener(plotH(4),'ContinuousValueChange',@scaleDose);
        
        %Turn off datacursor mode
        cursorMode = datacursormode(hFig);
        cursorMode.removeAllDataCursors;
        set(cursorMode, 'Enable','Off');
        
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
            protocolS(p).totalDose = protocolInfoS.totalDose;
            root.add(uProt); %Add protocol to tree
            
            %Load associated clinical criteria/guidelines
            critFile = fullfile(criteriaPath,protocolInfoS.criteriaFile);
            critS = loadjson(critFile,'ShowProgress',0);
            protocolS(p).criteria = critS;
        end
        
        %Create tree to list models by protocol
        shift = 10;
        pos = get(hFig,'Position');
        GUIWidth = pos(3);
        GUIHeight = pos(4);
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
        if ~isfield(ud,'TCPCurve')
            ud.TCPCurve = [];
        end
        if ~isfield(ud,'criteria')
            ud.criteria = [];
        end
        if ~isfield(ud, 'guidelines')
            ud.guidelines = [];
        end
        
        
        % Define axis handles, slider, color order, foreground protocol
        hNTCPAxis = ud.handle.modelsAxis(2);
        hNTCPAxis.Visible = 'On';
        grid(hNTCPAxis,'On');
        hTCPAxis = ud.handle.modelsAxis(3);
        hTCPAxis.Visible = 'On';
        hSlider = ud.handle.modelsAxis(4);
        scaleV = linspace(0.5,1.5,100);
        %colorOrderM = get(gca,'ColorOrder');
        colorOrderM = [0 229 238;123 104 238;0 238 118;218 165 32;...
            196	196	196;0 139 0;28 134 238;238 223 204;255 131 250]/255;
        if ~isfield(ud,'foreground') || isempty(ud.foreground)
            ud.foreground = 1;
        end
        
        %% Plot models
        protocolS = ud.Protocols;
        indexS = planC{end};
        numModelC = arrayfun(@(x)numel(x.model),protocolS,'un',0);
        numModelsV = [numModelC{:}];
        ntcp = 0;
        tcp = 0;
        jTot = 0;
        hWait = waitbar(0,'Generating plots...');
        for p = 1:numel(protocolS)
            %Check inputs
            %----Check that valid model file was passed---
            modelC = protocolS(p).model;
            if isempty(modelC)
                msgbox('Please select model files','Plot models');
                close(hWait);
                return
            end
            %----Check for valid structure & dose plan---
            isStr = cellfun(@(x)any(~isfield(x,'strNum') | isempty(x.strNum) | x.strNum==0),modelC,'un',0);
            err = find([isStr{:}]);
            if ~isempty(err)
                msgbox(sprintf('Please select structure:\n protocol: %d\tmodels: %d',p,err),'Plot model');
                close(hWait);
                return
            end
            isPlan = isfield(protocolS,'planNum') && ~isempty(protocolS(p).planNum);
            if ~isPlan
                msgbox(sprintf('Please select dose plan:\n protocol: %d',p),'Plot model');
                close(hWait);
                return
            end
            
            %Set plot transparency
            if p == ud.foreground
                plotColorM = [colorOrderM,ones(size(colorOrderM,1),1)];
                lineStyle = '-';
            else
                alpha = 0.5;
                %gray = repmat([.5 .5 .5],size(colorOrderM,1),1);
                plotColorM = [colorOrderM,repmat(alpha,size(colorOrderM,1),1)];
                lineStyleC = {'--',':','-.'};
                lineStyle = lineStyleC{p};
            end
            
            %Scale planned dose array
            plnNum = protocolS(p).planNum;
            numFrxProtocol = protocolS(p).numFractions;
            protDose = protocolS(p).totalDose;
            prescribedDose = planC{indexS.dose}(plnNum).prescribedDose;
            dA = getDoseArray(plnNum,planC);
            dAscale = protDose/prescribedDose;  %CHECK!!
            dAscaled = dA * dAscale;
            planC{indexS.dose}(plnNum).doseArray = dAscaled;
            
            %% Plot model-based predictions
            numModels = numModelsV(p);
            availableStructsC = {planC{indexS.structures}.structureName};
            for j = 1:numModels
                
                %% Create parameter dictionary
                paramS = [modelC{j}.parameters];
                structNumV = modelC{j}.strNum;
                %Copy relevant fields from protocol file
                %-No. of fractions
                paramS.numFractions.val = numFrxProtocol;
                %-alpha/beta
                abRatio = modelC{j}.abRatio;
                paramS.abratio.val = abRatio;
                
                %% Scale dose bins
                if isfield(modelC{j},'dv')
                    storedDVc = modelC{j}.dv;
                    doseBinsC = storedDVc{1} ;
                    volHistC = storedDVc{2};
                else
                    doseBinsC = cell(1,numel(structNumV));
                    volHistC = cell(1,numel(structNumV));
                    for nStr = 1:numel(structNumV)
                        [dosesV,volsV] = getDVH(structNumV(nStr),plnNum,planC);
                        [doseBinsC{nStr},volHistC{nStr}] = doseHist(dosesV,volsV,binWidth);
                    end
                    modelC{j}.dv = {doseBinsC,volHistC};
                end
                scaledCPv = scaleV * 0;
                for n = 1 : numel(scaleV)
                    %Scale dose bins
                    scale = scaleV(n);
                    scaledDoseBinsC = cellfun(@(x) x*scale,doseBinsC,'un',0);
                    %Apply fractionation correction as required
                    correctedScaledDoseC = frxCorrect(modelC{j},structNumV,numFrxProtocol,scaledDoseBinsC);
                    
                    %% Compute TCP/NTCP
                    if numel(structNumV)==1
                        scaledCPv(n) = feval(modelC{j}.function,paramS,correctedScaledDoseC{1},volHistC{1});
                    else
                        scaledCPv(n) = feval(modelC{j}.function,paramS,correctedScaledDoseC,volHistC);
                    end
                    
                    %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                    if n==numel(scaleV)
                        %Get corrected dose at scale == 1
                        testDoseC = frxCorrect(modelC{j},structNumV,numFrxProtocol,doseBinsC);
                        %Display mean dose, EUD, GTD(if applicable)
                        outType = modelC{j}.type;
                        temp_a = 1/0.09;
                        testMeanDose = calc_meanDose(testDoseC{1},volHistC{1});
                        testEUD = calc_EUD(testDoseC{1},volHistC{1},temp_a);
                        if strcmp(modelC{j}.name,'Lung TCP')
                            additionalParamS = paramS.gTD.params;
                            for fn = fieldnames(additionalParamS)'
                                paramS.(fn{1}) = additionalParamS.(fn{1});
                            end
                            testGTD = calc_gTD(testDoseC{1},volHistC{1},paramS);
                            fprintf(['\n---------------------------------------\n',...
                                'GTD  = %f'],testGTD);
                        end
                        %Display TCP/NTCP
                        testOut = feval(modelC{j}.function,paramS,testDoseC,volHistC);
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
                    ud.NTCPCurve = [ud.NTCPCurve plot(hNTCPAxis,scaleV,scaledCPv,'linewidth',3,...
                        'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                    ud.NTCPCurve(ntcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                    hCurr = hNTCPAxis;
                else
                    tcp = tcp + 1;
                    ud.TCPCurve = [ud.TCPCurve plot(hTCPAxis,scaleV,scaledCPv,'linewidth',3,...
                        'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                    ud.TCPCurve(tcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                    hCurr = hTCPAxis;
                end
                jTot = jTot+1; %No. of models displayed
                waitbar(j/sum(numModelsV));
            end
            %Store model parameters
            protocolS(p).model = modelC;
            
            %% Plot criteria & guidelines
            critS = protocolS(p).criteria;
            fractionSize = prescribedDose/protocolS(p).numFractions;
            structC = fieldnames(critS.structures);
            cCount = 0;
            gCount = 0;
            %Loop over structures
            for m = 1:numel(structC)
                cStr = find(strcmpi(structC{m}, availableStructsC));
                if ~isempty(cStr)              %If structure is available in plan
                    %Extract criteria
                    strCritS = critS.structures.(structC{m}).criteria;
                    criteriaC = fieldnames(strCritS);
                    %Get alpha/beta ratio
                    abRatio = critS.structures.(structC{m}).abRatio;
                    %Get DVH
                    [doseV,volsV] = getDVH(cStr,plnNum,planC);
                    [doseBinV,volHistV] = doseHist(doseV, volsV, binWidth);
                    %------------ Loop over criteria ----------------------
                    for n = 1:length(criteriaC)
                        %Idenitfy NTCP limits
                        if strcmp(strCritS.(criteriaC{n}).function,'ntcp')
                            strC = cellfun(@(x) x.strNum,modelC,'un',0);
                            cIdx = [strC{:}]==cStr;
                            ntcpV = ud.NTCPCurve(cIdx).YData;
                            exceedIdx = ntcpV >= strCritS.(criteriaC{n}).limit;
                            if ~any(exceedIdx)
                                cVal = inf;
                                cScale = inf;
                            else
                                exceedIdx = find(exceedIdx,1,'first');
                                cVal = ntcpV(exceedIdx);
                                cScale = scaleV(exceedIdx);
                            end
                        else
                            %Idenitfy dose/volume limits
                            nFrx = planC{indexS.dose}(plnNum).numFractions;
                            [cScale,cVal] = calc_Limit(doseBinV,volHistV,strCritS.(criteriaC{n}),...
                                nFrx,fractionSize,abRatio);
                        end
                        %Display line indicating clinical criteria/guidelines
                        x = [cScale cScale];
                        y = [0 1];
                        critLineH = line(hTCPAxis,x,y,'LineWidth',1,...
                            'Color','red','LineStyle','--','Tag','criteria');
                        critLineUdS.structure = structC{m};
                        critLineUdS.label = criteriaC{n};
                        critLineUdS.limit = strCritS.(criteriaC{n}).limit;
                        critLineUdS.val = cVal;
                        set(critLineH,'userdata',critLineUdS);
                        ud.criteria = [ud.criteria,critLineH];
                        cCount = cCount + 1;
                        if cCount == 1
                            firstcViolation = 1;
                            currcMin = cScale;
                        else
                            if cScale < currcMin
                                firstcViolation = cCount;
                                currcMin = cScale;
                            end
                        end
                    end
                    
                    %------------ Loop over guidelines --------------------
                    %Extract guidelines
                    if isfield(critS.structures.(structC{m}),'guidelines')
                        strGuideS = critS.structures.(structC{m}).guidelines;
                        guidelinesC = fieldnames(strGuideS);
                        for n = 1:length(guidelinesC)
                            %Idenitfy NTCP limits
                            if strcmp(strGuideS.(guidelinesC{n}).function,'ntcp')
                                strC = cellfun(@(x) x.strNum,modelC,'un',0);
                                gIdx = [strC{:}]==cStr;
                                ntcpV = ud.NTCPCurve(gIdx).YData;
                                exceedIdx = ntcpV >= strGuideS.(guidelinesC{n}).limit;
                                if ~any(exceedIdx)
                                    gVal = inf;
                                    gScale = inf;
                                else
                                    exceedIdx = find(exceedIdx,1,'first');
                                    gVal = ntcpV(exceedIdx);
                                    gScale = scaleV(exceedIdx);
                                end
                            else
                                %Idenitfy dose/volume limits
                                nFrx = planC{indexS.dose}(plnNum).numFractions;
                                [gScale,gVal] = calc_Limit(doseBinV,volHistV,strGuideS.(guidelinesC{n}),...
                                    nFrx,fractionSize,abRatio);
                            end
                            %Display line indicating clinical criteria/guidelines
                            x = [gScale gScale];
                            y = [0 1];
                            guideLineH = line(hTCPAxis,x,y,'LineWidth',2,...
                                'Color',[239 197 57]/255,'LineStyle','--','Tag','guidelines');
                            guideLineUdS.structure = structC{m};
                            guideLineUdS.label = guidelinesC{n};
                            guideLineUdS.limit = strGuideS.(guidelinesC{n}).limit;
                            guideLineUdS.val = gVal;
                            set(guideLineH,'userdata',guideLineUdS);
                            ud.guidelines = [ud.guidelines,guideLineH];
                            gCount = gCount + 1;
                            if gCount == 1
                                firstgViolation = 1;
                                currgMin = gScale;
                            else
                                if gScale < currgMin
                                    firstgViolation = gCount;
                                end
                            end
                        end
                    end
                    
                end
            end
            planC{indexS.dose}(plnNum).doseArray = dA;
        end
        close(hWait);
        
        %Add plot labels, legend
        xlabel(hNTCPAxis,'Dose scale factor'),ylabel(hNTCPAxis,'NTCP');
        ylabel(hTCPAxis,'TCP');
        NTCPLegendC = arrayfun(@(x)x.DisplayName,ud.NTCPCurve,'un',0);
        TCPLegendC = arrayfun(@(x)x.DisplayName,ud.TCPCurve,'un',0);
        legend([ud.NTCPCurve,ud.TCPCurve,ud.criteria(end),ud.guidelines(end)],...
            [NTCPLegendC,TCPLegendC,'Clinical criteria','Clinical guidelines'],...
            'Location','northwest','Color','none','FontSize',10,'AutoUpdate','off');
       
        %Display slider
        set(hSlider,'Visible','On'); %Slider on
        ud.handle.modelsAxis(4) = hSlider;
        %Turn protocol display switch control on
        set(ud.handle.inputH(11),'Enable','On','string',{'Switch plot...',ud.Protocols.protocol});
        
        %Store userdata
        ud.Protocols = protocolS;
        set(hFig,'userdata',ud);
        %Display current dose/probability
        scaleDose(hSlider);
        
        
        %Get datacursor mode 
        cursorMode = datacursormode(hFig);
        
        %Display first clinical criterion/guideline that is violated
        hcFirst = ud.criteria(firstcViolation);
        hgFirst = ud.guidelines(firstgViolation);
        if hcFirst.XData(1) <= hgFirst.XData(1)
        hDatatip = cursorMode.createDatatip(hcFirst);
        else
        hDatatip = cursorMode.createDatatip(hgFirst);
        end
        set(hDatatip,'Visible','Off','OrientationMode','Manual',...
            'UpdateFcn',@expandDataTip,'Tag','guidelines');
      
        %Set datacursor update function
        set(cursorMode, 'Enable','On','SnapToDataVertex','off',...
            'UpdateFcn',@expandDataTip);
       
    case 'CLEAR_PLOT'
        ud = get(hFig,'userdata');
        %Clear data/plots from any previously loaded models/plans/structures
        ud.NTCPCurve = [];
        ud.TCPCurve = [];
        ud.criteria = [];
        ud.guidelines = [];
        cla(ud.handle.modelsAxis(2));
        legend(ud.handle.modelsAxis(2),'off')
        cla(ud.handle.modelsAxis(3));
        
        %Turn off datacursor mode
        cursorMode = datacursormode(hFig);
        cursorMode.removeAllDataCursors;
        set(cursorMode, 'Enable','Off');
        
        %Set slider back to default position
        hSlider = ud.handle.modelsAxis(4);
        hSlider.Value = 1;
        hSlider.Visible = 'Off';
        ud.handle.modelsAxis(4)= hSlider;
        ud.scaleDisp = [];
        set(hFig,'userdata',ud);
        
    case 'LIST_MODELS'
        %Get selected protocols
        ud = get(hFig,'userdata');
        ud.handle.editModels = [];
        protocolS = ud.Protocols;
        %Check models for required fields ('function' and 'parameter')
        %%%%%FIX : ADD STRUCTURE
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
                %%%% FIX : Should check structure subfiedls?%%%% Or remove
                %%%% check for now
                %                 if ~any(paramIdx) || isempty(modelC{i}.(fieldC{paramIdx}))
                %                     msgbox('Model file must include ''parameters'' attribute.','Model file error');
                %                     return
                %                 end
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

% Calculate scale factor at which criteria are first violated
    function [cScale, critVal] = calc_Limit(doseBinV,volHistV,critS,planNumFrx,protocolFrxSize,abRatio)
        cFunc =  critS.function;
        cLim = critS.limit;
        scaleFactorV = linspace(0.5,1.5,100);
        critVal = -inf;
        count = 0;
        s = 0;
        while critVal <= cLim && count<length(scaleFactorV)
            count = count + 1;
            %Scale dose bins
            s = scaleFactorV(count);
            scaledDoseBinsV = s*doseBinV;
            %Fractionation correction
            scaledFrxSizeV = scaledDoseBinsV/planNumFrx;
            correctedScaledDoseV = scaledDoseBinsV .*(scaledFrxSizeV + abRatio)...
                ./(protocolFrxSize + abRatio);
            if isfield(critS,'parameters')
                cParamS = critS.parameters;
                critVal = feval(cFunc,correctedScaledDoseV,volHistV,cParamS);
            else
                critVal = feval(cFunc,correctedScaledDoseV,volHistV);
            end
        end
        if s == max(scaleFactorV)
            cScale = inf;
            critVal = inf;
        else
            cScale = s;
        end
    end

% Edit model parameters
    function editParams(hObj,hData)
        
        ud = get(hFig,'userdata');
        tag = get(hObj,'Tag');
        
        %Get input data
        idx = hData.Indices(1);
        val = hData.EditData;
        val2num = str2num(val);
        if isempty(val2num) %Convert from string if numerical
            val2num = val;
        end
        prtcNum = ud.PrtcNum;
        modelsC = ud.Protocols(prtcNum).model;
        if isfield(ud,'ModelNum')
          modelNum = ud.ModelNum;
        end
        
        %Update parameter
        switch(tag)
            case 'strSel'
                if hData.Indices(2)==1
                    parameterS = modelsC{modelNum}.parameters;
                    inputStructC = fieldnames(parameterS.structures);
                    inputStructC = strcat('Select structure',{' '},inputStructC);
                    matchIdx = find(strcmp(inputStructC,val));
                    modelsC{modelNum}.inputStrNum = matchIdx;
                else
                    strListC = {'Select structure',planC{indexS.structures}.structureName};
                    matchIdx = find(strcmp(strListC,val));
                    inputStrNum = modelsC{modelNum}.inputStrNum;
                    modelsC{modelNum}.strNum(inputStrNum) = matchIdx - 1;
                end
            case 'doseSel'
                if hData.Indices(2)==1
                    return
                else
                    dosListC = {'Select Plan',planC{indexS.dose}.fractionGroupID};
                    matchIdx = find(strcmp(dosListC,val));
                    %modelsC{modelNum}.planNum = matchIdx - 1;
                    ud.Protocols(prtcNum).planNum = matchIdx - 1;
                end
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


%Display clinical criteria on selection
    function txt = expandDataTip(hObj,hEvt)
        %Get userdata
        ud = get(hFig,'Userdata');
        
        if isempty(hEvt)                 %Initialize (display 1st violation)
            posV = get(hObj,'Position');
            lscale = posV(1);
        else
            %Update (display selected limit)
            cLine = hEvt.Target;         
            lscale = cLine.XData(1);
        end
        
        %Check for all violations at same scale
        %---Criteria:---
        limitM = get(ud.criteria,'xData');
        if iscell(limitM)
            limitM = cell2mat(limitM);
        end
        nCrit =  sum(limitM(:,1) == lscale);
        txt = {};
        if nCrit>0
        limitIdx = find(limitM(:,1) == lscale);
        for k = 1:numel(limitIdx)
            lUd = ud.criteria(limitIdx(k)).UserData;
            start = (k-1)*5 + 1;
            txt(start : start+4) = {[num2str(k),'. Structure: ',lUd.structure],['Constraint: ', lUd.label],...
                ['Clinical limit :', num2str(lUd.limit)],...
                ['Current value :', num2str(lUd.val)],['Current scale factor: ',num2str(lscale)]};
        end
        end
        
        %---Guidelines:---
        limitM = get(ud.guidelines,'xData');
        if iscell(limitM)
            limitM = cell2mat(limitM);
        end
        nGuide =  sum(limitM(:,1) == lscale);
        k0 = length(txt);
        if nGuide>0
        limitIdx = find(limitM(:,1) == lscale);
        %Get structures, limits
        for k = 1:numel(limitIdx)
            lUd = ud.guidelines(limitIdx(k)).UserData;
            start = k0 + (k-1)*5 + 1;
            txt(start : start+4) = {[num2str(nCrit+k),'. Structure: ',lUd.structure],['Constraint: ', lUd.label],...
                ['Clinical guideline :', num2str(lUd.limit)],...
                ['Current value :', num2str(lUd.val)],['Current scale factor: ',num2str(lscale)]};
        end
        end
      
        
        
        %Display
        set(hObj,'Visible','On');
    end

% Extract model parameters & values and display in table
    function hTab = extractParams(modelS)
        
        %Delete any previous param tables
        ud = get(hFig,'userdata');
        if isfield(ud,'currentPar')
            delete(ud.currentPar);
        end
        
        %Get parameter names
        modelParS = modelS.parameters;
        genParListC = fieldnames(modelParS);
        nPars = numel(genParListC);
        reservedFieldsC = {'type','cteg','desc'};
        
        %Define table dimensions
        rowHt = 25;
        rowSep = 10;
        rowWidth = 130;
        pos = get(hFig,'Position');
        fwidth = pos(3);
        fheight = pos(3);
        left = 10;
        columnWidth ={rowWidth-1,rowWidth-1};
        posV = [.22*fwidth-2.5*left .4*fheight 2*rowWidth rowHt];
        row = 1;
        hTab = gobjects(0);
        % Create rows displaying model parameters
        for k = 1:nPars
            if strcmpi(genParListC{k},'structures')
                if isstruct(modelParS.(genParListC{k}))
                    structS = modelParS.(genParListC{k});
                    strListC = fieldnames(structS);
                    for s = 1:length(strListC)
                        strParListC = fieldnames(structS.(strListC{s}));
                        for t = 1:numel(strParListC)
                            parS = structS.(strListC{s}).(strParListC{t});
                            parName = [strListC{s},' ',strParListC{t}];
                            [columnFormat,dispVal] = extractVal(parS);
                            dataC = {parName,dispVal};
                            hTab(row) = uitable(hFig,'Tag','paramEdit','Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
                                'columnformat',columnFormat,'Data',dataC,'Visible','Off','FontSize',10,...
                                'columneditable',[false,true],'columnname',[],'rowname',[],...
                                'columnWidth',columnWidth,'celleditcallback',@editParams);
                            row = row+1;
                        end
                    end
                end
            else
                if ~strcmpi(genParListC{k},reservedFieldsC)
                    parName = genParListC{k};
                    [columnFormat,dispVal] = extractVal(modelParS.(genParListC{k}));
                    dataC = {parName,dispVal};
                    hTab(row) = uitable(hFig,'Tag','paramEdit','Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
                        'columnformat',columnFormat,'Data',dataC,'Visible','Off','FontSize',10,...
                        'columneditable',[false,true],'columnname',[],'rowname',[],...
                        'columnWidth',columnWidth,'celleditcallback',@editParams);
                    row = row+1;
                end
            end
        end
    end

    function [columnFormat,dispVal] = extractVal(parS)
        val = parS.val;
        switch(lower(parS.type{1}))
            case 'string'
                columnFormat = {'char','char'};
                dispVal = val;
            case'cont'
                columnFormat = {'numeric','numeric'};
                dispVal = val ;
            case 'bin'
                descV = parS.desc;
                descC = cellstr(descV);
                columnFormat = {'char',descC};
                dispVal = parS.desc{val+1};
        end
    end


% Perform fractionation correction
    function eqScaledDoseC = frxCorrect(modelParS,strNumV,numFrx,scaledDoseC)
        if strcmpi(modelParS.fractionCorrect,'yes') & isfield(modelParS,'abCorrect')
            eqScaledDoseC = cell(1,numel(strNumV));
            if strcmpi(modelParS.abCorrect,'yes')
                %Convert to EQD in std fraction size
                stdFrxSize = modelParS.stdFractionSize;
                for s = 1:numel(strNumV)
                    scaledFrxSizeV = scaledDoseC{s}/numFrx;
                    eqScaledDoseC{s} = scaledDoseC{s} .*(scaledFrxSizeV+modelParS.abRatio)...
                        ./(stdFrxSize + modelParS.abRatio);
                end
            else %Different flag?
                %Convert to standard no. fractions
                Na = numFrx;
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



%Store user inputs to userdata
    function getParams(hObj,hEvt)
        
        ud = get(hFig,'userdata');
        tree = hObj.getTree;
        currNode = hEvt.getCurrentNode;
        
        if  currNode.getLevel==0 %Expand to list protocols
            tree.expandRow(tree.getSelectionRows);
            
        elseif currNode.getLevel==1  %Expand protocol node to list models
            
            %Get selected protocol no.
            protS = ud.Protocols;
            if isfield(ud,'PrtcNum')
                prtcNum = ud.PrtcNum;
            else
                protListC = {protS.protocol};
                prtcNum = strcmp(currNode.getName,protListC);
                ud.PrtcNum = find(prtcNum);
            end
            
            %Get dose plan input
            planListC = {'Select dose plan',planC{indexS.dose}.fractionGroupID};
            if isfield(protS(prtcNum),'planNum') & ~isempty(protS(prtcNum).planNum)
                planIdx = protS(prtcNum).planNum + 1;
            else
                if numel(planListC)==2 %Default to 1st plan if only one is available
                    planIdx = 2;
                    ud.Protocols(prtcNum).planNum = 1;
                else
                    %User selection
                    planIdx = 1;
                    ud.Protocols(prtcNum).planNum = [];
                end
            end
            
            %Table for selecting dose plan
            hTab = ud.handle.inputH(5);
            fmt = {'char' planListC};
            dosDat = {'Select dose plan',planListC{planIdx}};
            set(hTab,'ColumnFormat',fmt,'Data',dosDat,'Visible','On','Enable','On');
            ud.handle.inputH(5) = hTab;
            set(hFig,'userdata',ud);
            
            %Expand protocol node to list models
            tree.expandRow(tree.getSelectionRows);
            
        else
            %Allow selection of structures & parameters for each model
            modS = ud.Protocols;
            prtcol = currNode.getParent.getName;
            prtListC = {modS.protocol};
            prtcNum = strcmp(prtcol,prtListC);
            modelsC = modS(prtcNum).model;
            modListC = cellfun(@(x) x.name,modelsC,'un',0);
            modelNum = strcmp(currNode.getName,modListC);
            modName = modelsC{modelNum}.name;
            
            %Get structure input
            
            if ~isstruct(modelsC{modelNum}.parameters.structures)
                %If model has no structure-specific parameters
                inputStructC = {modelsC{modelNum}.parameters.structures};
            else
                inputStructC = fieldnames(modelsC{modelNum}.parameters.structures);
            end
            numStruct = length(inputStructC);
            structListC = {'Select from list',planC{indexS.structures}.structureName};
            structDispC = cell(numel(inputStructC),1);
            
            
            if isfield(ud,'strNum')
                strIdxV = ud.strNum;
                for s = 1:numel(inputStructC)
                    structDispC{s} = ['Select structure ',inputStructC{s}];
                end
            else
                strIdxV = zeros(1,numStruct);
                for s = 1:numel(inputStructC)
                    structDispC{s} = ['Select structure ',inputStructC{s}];
                    strMatch = strcmpi(inputStructC{s},structListC);
                    if ~any(strMatch)
                        strIdxV(s) = 1;
                    else
                        strIdxV(s) = find(strMatch);
                    end
                end
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
            
            
            %Display parameters from .json file
            %Table1 : Structure selection
            hTab1 = ud.handle.inputH(4);
            fmtC = {structDispC.',structListC};
            if isfield(modelsC{modelNum},'inputStrNum')
                inputStrNum = modelsC{modelNum}.inputStrNum;
            else
                inputStrNum = 1;
                modelsC{modelNum}.inputStrNum = 1;
            end
            strDat = [structDispC{inputStrNum},structListC(strIdxV(inputStrNum))];
            set(hTab1,'ColumnFormat',fmtC,'Data',strDat,...
                'Visible','On','Enable','On');
       
            %Table3 : Miscellaneous fields from .json file
            hTab3 = ud.handle.inputH(8);
            set(hTab3,'Data',[fieldsC,cellfun(@num2str,valsC,'un',0)],'Visible','On','Enable','On');
            %Parameters
            for k = 1:numel(hPar)
                set(hPar(k),'Visible','On');
            end
            
            %Store tables to userdata
            ud.handle.inputH(4) = hTab1;
            set(ud.handle.inputH(6),'Visible','On'); %Parameters header
            set(ud.handle.inputH(7),'String',['MODEL:  ',modName],'Visible','On'); %Display name of currently selected model
            ud.handle.inputH(8) = hTab3;
            ud.currentPar = hPar;
            
            %Store strnum, plannum, params to userdata
            modelsC{modelNum}.strNum = strIdxV-1;
            modS(prtcNum).model = modelsC;
            ud.Protocols = modS;
            
            %set current model nos
            ud.ModelNum = find(modelNum);
            
            %Enable save
            set(ud.handle.inputH(9),'Enable','On');
            
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
        userScale = get(hObj,'Value');
        
        %Clear any previous scaled-dose plots
        hScaledNTCP = findall(ud.handle.modelsAxis(2),'type','line','LineStyle','-.');
        hScaledTCP = findall(ud.handle.modelsAxis(3),'type','line','LineStyle','-.');
        delete(hScaledNTCP);
        delete(hScaledTCP);
        if isfield(ud,'scaleDisp')
            set(ud.scaleDisp,'String','');
        end
        hScaleDisp = text(userScale,-.06,'','Parent',ud.handle.modelsAxis(2),...
            'FontSize',8,'Color',[.3 .3 .3]);
        
        %Set color order
        colorM = [0 229 238;123 104 238;0 238 118;218 165 32;...
            196	196	196;0 139 0;28 134 238;238 223 204;255 131 250]/255;
        
        %Scale plots as selected
        modNum = 0;
        for l = 1:numel(ud.Protocols)
            nMod = length(ud.Protocols(l).model);
            if l == ud.foreground
                pColorM = [colorM,ones(size(colorM,1),1)];
            else
                wt = 0.4;
                pColorM = [colorM,repmat(wt,size(colorM,1),1)];
            end
            %Get plan no.
            planNum = ud.Protocols(l).planNum;
            %Loop over models 
            for k = 1:nMod
                modNum = modNum+1;
                
                % Get params
                modelsC = ud.Protocols(l).model;
                paramsS = modelsC{k}.parameters;
                
                % Get struct
                strNum = modelsC{k}.strNum;
                paramsS.structNum = strNum;
                
                % Get plan
                paramsS.planNum = planNum;
                paramsS.numFractions.val = ud.Protocols(l).numFractions;
                paramsS.abRatio.val = modelsC{k}.abRatio;
                
                % Get dose bins
                dose0C = modelsC{k}.dv{1};
                vol0C = modelsC{k}.dv{2};
                
                
                %Scale
                scdoseC = cellfun(@(x) x*userScale,dose0C,'un',0);
                %Apply fractionation correction where required
                eqScaledDoseC = frxCorrect(modelsC{k},strNum,paramsS.numFractions.val,scdoseC);
                
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
                    plot([userScale userScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',2,'parent',plotAxis);
                    plot([loc userScale],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',2,'parent',plotAxis);
                else
                    loc = hObj.Max;
                    plotAxis = ud.handle.modelsAxis(3);
                    plot([userScale userScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',2,'parent',plotAxis);
                    plot([userScale loc],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',2,'parent',plotAxis);
                end
            end
        end
        scaleVal = sprintf('%.3f',userScale);
        set(hScaleDisp,'String',scaleVal);
        ud.scaleDisp = hScaleDisp;
        set(hFig,'userdata',ud);
        
    end

% Switch focus between plots for different protocols
    function switchFocus(hObj,~)
        ud = get(hFig,'userData');
        sel = get(hObj,'Value')-1;
        ud.foreground=sel;
        set(hFig,'userData',ud);
        ROE('PLOT_MODELS');
    end







end