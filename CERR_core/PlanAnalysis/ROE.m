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
        
        % Define margin constraints
        leftMarginWidth = 300;
        topMarginHeight = 50;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;
        screenSizeV = get( 0, 'Screensize' );
        GUIWidth = 950;
        GUIHeight = 550;
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
        posTop = GUIHeight-topMarginHeight;
        
        % create title handles
        titleH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift posTop-shift/2 GUIWidth-2*shift 0.1*GUIHeight ],'Style',...
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
        
        leftMarginWidth = stateS.leftMarginWidth;
        topMarginHeight = stateS.topMarginHeight;
        GUIWidth = hFig.Position(3);
        GUIHeight = hFig.Position(4);
        shift = 10;
        defaultColor = [0.8 0.9 0.9];
        posTop = GUIHeight-topMarginHeight;
        
        % Create plan and structure i/p
        inputH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift shift leftMarginWidth+.12*GUIWidth GUIHeight-topMarginHeight-2*shift ],...
            'Style','frame','backgroundColor',defaultColor);
        inputH(2) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[2*shift posTop-.16*GUIHeight .16*GUIWidth 2*shift], 'String','','Style','text',...
            'fontSize',8, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left');
        inputH(3) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[2*shift posTop-.1*GUIHeight .16*GUIWidth 3*shift], 'String',...
            'Select protocol','Style','push', 'fontSize',9,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'ROE(''LOAD_MODELS'')');
        
        tablePosV = [.22*GUIWidth-2*shift posTop-.1*GUIHeight .23*GUIWidth 4*shift];
        colWidth = tablePosV(3)/2-1;
        inputH(4) = uitable(hFig,'Tag','strSel','Position',tablePosV -[0 tablePosV(4)/2+shift/2 0 tablePosV(4)/2],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'columnEditable',[false,true],'Data',{'structure','Select structure'},'ColumnWidth',{colWidth,colWidth});
        inputH(5) = uitable(hFig,'Tag','dosSel','Position',tablePosV,'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'columnEditable',[false,true],'Data',{'Plan','Select Plan'},'ColumnWidth',{colWidth,colWidth});
        % Create parameter display & editing
        inputH(6) = uicontrol(hFig,'units','pixels','Visible','Off',...
            'Position',tablePosV + [0 -.15*GUIHeight 0 0 ],'String','Model parameters','Style','text',...
            'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor);
        inputH(7) = uitable(hFig,'Tag','fieldEdit','Position',tablePosV + [0 -.7*GUIHeight 0 4*shift],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',{'Fields','Values'},...
            'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'ColumnWidth',{round(tablePosV(3)/2),round(tablePosV(3)/2)},...
            'columnEditable',[false,true],'backgroundcolor',[1 1 1]);
        
        % Save , plot buttons
        inputH(8) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',[.38*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Save','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','ROE(''SAVE_MODELS'' )');
        inputH(9) = uicontrol(hFig,'units','pixels','Tag','plotButton','Position',[.3*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Plot','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','ROE(''PLOT_MODELS'' )');
        inputH(10) = uicontrol(hFig,'units','pixels','Tag','switchPlot','Position',[.2*GUIWidth .1*shift .09*GUIWidth 4*shift],'backgroundColor',defaultColor,...
            'String','Switch plot','Style','popup', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback',@switchFocus);
        
        
        %Define Models-plot Axis
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.14*GUIWidth shift GUIWidth-leftMarginWidth-.15*GUIWidth GUIHeight-topMarginHeight-2*shift ],...
            'color',defaultColor,'ytick',[],'xtick',[],'box','on');
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',...
            [leftMarginWidth+.2*GUIWidth .16*GUIHeight .73*GUIWidth-leftMarginWidth GUIHeight-topMarginHeight-0.2*GUIHeight],...
            'color','none','XAxisLocation','bottom','YAxisLocation','left','ylim',[0 1],...
            'fontSize',8,'box','on','visible','off');
        plotH(3) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
            'color','none','XAxisLocation','bottom','YAxisLocation','right','ylim',[0 1],...
            'xtick',[],'fontSize',8,'box','on','visible','off');
        plotH(4) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.18*GUIWidth 3*shift .75*GUIWidth-leftMarginWidth 2*shift],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',0.5,'Max',1.5,'Value',1);
        addlistener(plotH(4),'ContinuousValueChange',@scaleDose);
        
        % Store handles
        ud.handle.inputH = inputH;
        ud.handle.modelsAxis = plotH;
        ud.sliderPos = plotH(4).Position;
        set(hFig,'userdata',ud);
        
        
    case 'LOAD_MODELS'
        ROE('REFRESH');
        ud = get(hFig,'userdata');
        
        %Get .json files
        fPath = 'M:/Aditi/OutcomesModels/ROE/Protocols'; %Temp (move to options file)
        [protocolListC,protocolIdx,ok] = listFiles(fPath,'Multiple');
        if ~ok
            return
        end
        
        % Get models by protocol
        root = uitreenode('v0', 'Protocol', 'Protocol', [], false);  %Create root node
        for p = 1:numel(protocolIdx)
            [~,protocol] = fileparts(protocolListC{protocolIdx(p)});
            protocolInfoS = loadjson(fullfile(fPath,protocolListC{protocolIdx(p)}),'ShowProgress',1);
            modelListC = fields(protocolInfoS.models);
            numModels = numel(modelListC);
            protocolS(p).modelFiles = [];
            uProt = uitreenode('v0',protocol,protocolInfoS.name,[],false);                    %Create nodes for protocols
            for m = 1:numModels
                protocolS(p).protocol = protocolInfoS.name; 
                modelFPath = protocolInfoS.models.(modelListC{m}).location;
                protocolS(p).model{m} = loadjson(modelFPath,'ShowProgress',1);
                %strNum
                protocolS(p).modelFiles = [protocolS(p).modelFiles,modelFPath];
                modelName = protocolS(p).model{m}.name;
                uProt.add(uitreenode('v0', modelName,modelName, [], true)); %Create nodes for models
            end
            protocolS(p).numFractions = protocolInfoS.numFractions;
            protocolS(p).fCorrect = protocolInfoS.fractionCorrect;
            root.add(uProt);
            % Get clinical criteria files
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
        set(mtree,'Position',[2*shift 5*shift .16*GUIWidth .65*GUIHeight],...
            'Visible',false);
        drawnow;
        %pause(0.05);
        
        %Get info from .json file
        % fileInfo = System.IO.FileInfo(fullfile(pathName,fileName));
        % created = fileInfo.CreationTime.ToString;
        % modified = fileInfo.LastAccessTime.ToString;
        % dummyAccount = System.Security.Principal.NTAccount('dummy');
        % owner = char(fileInfo.GetAccessControl.GetOwner(GetType(dummyAccount)).Value.ToString);
        
        %Store input model parameters
        ud.Protocols = protocolS;
        ud.modelTree = mtree;
        
        %Update name for MODEL to show the protocol
        set(ud.handle.inputH(2),'string','Models');
        
        %Create push buttons for editing model parameters
        set(hFig,'userdata',ud);
        ROE('LIST_MODELS');
        
        
    case 'PLOT_MODELS'
        
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
        
        
        % Define axis handles, slider, color order,foreground plot
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
        
        ntcp = 0;
        tcp = 0;
        %%% TEMP %%%%%
        cCount = 0;
        gCount = 0;
        %%%%%%%%%%%%%
        hWait = waitbar(0,'Generating plots...');
        for p = 1:numel(ud.Protocols)
            %Check for reqd fields
            modelC = ud.Protocols(p).model;
            if ~isfield(ud,'Protocols')|| isempty(modelC)
                msgbox('Please select model files','Plot models');
                return
            end
            %Check for plan/struct input
            isStr = cellfun(@(x)any(~isfield(x,'strNum') || isempty(x.strNum) || x.strNum==0),modelC,'un',0);
            err = find([isStr{:}]);
            if ~isempty(err)
                msgbox(sprintf('Please select structure:\n protocol: %d\tmodels: %d',p,err),'Plot model');
                return
            end
            isPlan = cellfun(@(x)any(~isfield(x,'planNum') || isempty(x.planNum) || x.planNum==0),modelC,'un',0);
            err = find([isPlan{:}]);
            if ~isempty(err)
                msgbox(sprintf('Please select dose plan:\n protocol: %d\tmodels: %d',p,err),'Plot model');
                return
            end
            %Plot model curves
            numModels = numel(modelC);
            dvBinC = cell(1,numModels);
            %Get selected protocol
            if p == ud.foreground
                plotColorM = [colorOrderM,ones(size(colorOrderM,1),1)];
                lineStyle = '-';
            else
                alpha = 0.5;
                %gray = repmat([.5 .5 .5],size(colorOrderM,1),1);
                plotColorM = [colorOrderM,repmat(alpha,size(colorOrderM,1),1)];
                lineStyle = '--';
            end
            % Plot
            for j = 1:numModels
                
                % Get parameters from .json file
                paramS = modelC{j}.parameters;
                %Get struct
                structNumV = modelC{j}.strNum;
                %Get plan
                plnNum = modelC{j}.planNum;
                paramS.structNum = structNumV;
                paramS.planNum = plnNum;
                
                % Get dose bins
                doseBins0C = cell(1,numel(structNumV));
                volsHist0C = cell(1,numel(structNumV));
                
                for nStr = 1:numel(structNumV)
                [~, doseBins0C{nStr}, volsHist0C{nStr}] = getDVHMatrix(planC,structNumV(nStr),plnNum);
                % Apply fractionation correction if required
                if strcmpi(ud.Protocols(p).fCorrect,'yes') % fractionation correction
                    numFractions = ud.Protocols(p).numFractions;
                    abRatio = 3;
                    stdFractionSize = 2;
                    %EQD2
                    fractionSizeV = doseBins0C{nStr}/numFractions;
                    correctedDoseC{nStr} = doseBins0C{nStr} .*(fractionSizeV+abRatio)./(stdFractionSize + abRatio);
                end
                end
                modelC{j}.dv = {correctedDoseC,volsHist0C};
              
                %Caclulate probability
                scaledCPv = scaleV * 0;
                for n = 1 : numel(scaleV)
                    
                    % Scale dose bins
                    scale = scaleV(n);
                    doseBinsC = cellfun(@(x) x*scale,correctedDoseC,'un',0);
                    volsHistC = volsHist0C;
                    % Pass as vector if no. structs == 1
                    if numel(structNumV)==1
                        doseBinsC = doseBinsC{1};
                        volsHistC = volsHist0C{1};
                    end
                    
                    % Compute CP
                    scaledCPv(n) = feval(modelC{j}.function,paramS,doseBinsC,volsHistC);
                    
                    %%%%% TEMP (for testing) %%%%%%%%
                    if n==numel(scaleV)
                    a = 1/0.09;
                    testEUD = calc_EUD(correctedDoseC{1},volsHistC,a);
                    testNTCP = feval(modelC{j}.function,paramS,correctedDoseC{1},volsHistC);
                    fprintf('EUD = %f\n NTCP = %f\n',testEUD,testNTCP);
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end
                
                
                % Set plot color
                colorIdx = mod(j,size(plotColorM,1))+1;
                
                % Plot curves
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
                
            end
            %Store dose/vol bins
            ud.Protocols(p).model = modelC;
            waitbar(p/numel(ud.Protocols));
        end
        close(hWait);
        %Add plot labels, legend
        xlabel(hNTCPAxis,'Dose scaling','Position',[1 -.15]),ylabel(hNTCPAxis,'NTCP');
        ylabel(hTCPAxis,'TCP');
        NTCPLegendC = arrayfun(@(x)x.DisplayName,ud.NTCPCurve,'un',0);
        TCPLegendC = arrayfun(@(x)x.DisplayName,ud.TCPCurve,'un',0);
        legend([ud.NTCPCurve,ud.TCPCurve],[NTCPLegendC,TCPLegendC],'Location','northeast','Color','none');
        %Display slider
        set(hSlider,'Visible','On'); %Slider on
        ud.handle.modelsAxis(4) = hSlider;
        %Plot switch on
        set(ud.handle.inputH(10),'Enable','On','string',{'Switch plot...',ud.Protocols.protocol});
        
        set(hFig,'userdata',ud);
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
        ud = get(hFig,'userdata');
        ud.handle.editModels = [];
        protocolS = ud.Protocols;
        %List models
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
        
        set(ud.handle.inputH(9),'Enable','On'); %Plot button on
        
        
        set(hFig,'userdata',ud);
        
    case 'SAVE_MODELS'
        ud = get(hFig,'userData');
        protocols = ud.Protocols;
        
        %Save changes to model files
        for j = 1: numel(protocols)
            modelC = protocols(j).models;
            outFile = ud.Protocols(p).modelFiles;
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
            remC = {'strNum','dosNum','dv'};
            for m = 1:numel(outFile)
                remIdx = ismember(remC,fieldnames(modelC{m}));
                modelC{m} = rmfield(modelC{m},remC(remIdx));
                fprintf('\nSaving changes to %s ...',outFile{m});
                savejson('',modelC{m},'filename',outFile{m});
            end
        end
        fprintf('\nSave complete.\n');
        
        set(ud.handle.inputH(8),'Enable','Off');  %Disable save
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
                modelsC{modelNum}.planNum = matchIdx - 1;
                modelsC{modelNum}.plan = dosListC{matchIdx};
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
        set(ud.handle.inputH(8),'Enable','On');  %Enable save
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
        posV = [.22*fwidth-2*left .4*fheight 2*rowWidth rowHt];
        row = 1;
        hTab = gobjects(0);
        for k = 1:nPars
            subfieldsC = fieldnames(inS.(parListC{k}));
            valIdxC = cellfun(@(x) ~any(strcmpi(x,reservedFieldsC)),subfieldsC,'un',0);
            valNameC = subfieldsC([valIdxC{:}]);
            %subFieldC = valNameC;
            %subFieldC(strcmpi('default', subFieldC))={'val'};
            nVal = numel(valNameC);
            valTypes = cell(1,nVal);
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


% Get parameter value
    function [parNameC,parIdxV] = getMatchPar(modelS,parName,parListC)
        
        parIn = isfield(modelS,parName);
        if parIn
            if isstruct(modelS.structure)
                parNameC = fieldnames(modelS.(parName));
                parValC = struct2cell(modelS.(parName));
            else
                parNameC = [parName,' 1'];
                parValC = {modelS.(parName)};
            end
            parIdxC = cellfun(@(x)find(strcmpi(x,parListC)),parValC,'un',0);
            notFoundC = cellfun(@isempty,parIdxC,'un',0);
            parIdxC([notFoundC{:}]) = {1}; %Set to default=1 (select par)
            parIdxV = [parIdxC{:}];
        else
            parNameC = [parName,' 1'];
            parIdxV = 1; %Default
        end
        
    end


%Store user inputs to userdata
    function getParams(hObj,hEvt)
        
        ud = get(hFig,'userdata');
        tree = hObj.getTree;
        currNode = hEvt.getCurrentNode;
        %modelNum = hObj.Value;
        
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
            structList = {'Select structure',structList{:}};
            [strNameC,strIdxV] = getMatchPar(modelsC{modelNum},'structure',structList);
            
            %Get plan input
            planList = {planC{indexS.dose}.fractionGroupID};
            planList = {'Select Plan',planList{:}};
            if numel(planList)==2 %Default to 1st plan if only one is available
                planNameC = 'plan 1';
                planIdxV = 2;
            else
                x = strfind(lower(planList),'sum');%Default to plan named 'SUM' if available
                if any([x{:}])
                    idx = find([x{:}],1);
                    planIdxV = find(idx);
                    planNameC = planList{idx};
                else
                     %User selection
                    [planNameC,planIdxV] = getMatchPar(modelsC{modelNum},'plan',planList);
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
            rmC = {'structure','plan','strNum','planNum','parameters','dv'};
            valsC = valsC(~ismember(fieldsC,rmC));
            fieldsC = fieldsC(~ismember(fieldsC,rmC));
            
            
            %Storage/display
            %Table1
            hTab1 = ud.handle.inputH(4);
            fmt = {[] structList};
            strDatC = cat(2,strNameC,structList(strIdxV).');
            set(hTab1,'ColumnFormat',fmt,'Data',strDatC,'Visible','On','Enable','On');
            %Table2
            hTab2 = ud.handle.inputH(5);
            fmt = {[] planList};
            dosDatC = cat(2,planNameC,planList(planIdxV).');
            set(hTab2,'ColumnFormat',fmt,'Data',dosDatC,'Visible','On','Enable','On');
            %Table3
            hTab3 = ud.handle.inputH(7);
            set(hTab3,'Data',[fieldsC,valsC],'Visible','On','Enable','On');
            %Parameters
            [hPar(:).Visible] = deal('On');
            
            
            ud.handle.inputH(4) = hTab1;
            ud.handle.inputH(5) = hTab2;
            set(ud.handle.inputH(6),'Visible','On'); %Parameters header
            ud.handle.inputH(7) = hTab3;
            ud.currentPar = hPar;
            
            %Store str, plan, params to modelsC
            modelsC{modelNum}.strNum = strIdxV-1;
            modelsC{modelNum}.structure = structList{strIdxV};
            modelsC{modelNum}.planNum = planIdxV-1;
            modelsC{modelNum}.plan = planList{planIdxV};
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
        
        dirS = dir(fpath);
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
        hScaleDisp(1) = text(userScale,0.03,'','Parent',ud.handle.modelsAxis(2),...
            'FontSize',8,'Color',[.3 .3 .3]);
        
        %Set color order
        colorM = get(gca,'ColorOrder');
        
        
        %Scale plots as selected
        for l = 1:numel(ud.Protocols)
            nMod = length(ud.Protocols(l).model);
            if l == ud.foreground
                pColorM = [colorM,ones(size(colorM,1),1)];
            else
                wt = 0.4;
                bg = repmat([.5 .5 .5],size(colorM,1),1);
                pColorM = [bg,repmat(wt,size(colorM,1),1)];
            end
            for k = 1:nMod
                % Get params
                modelsC = ud.Protocols(l).model;
                paramsS = modelsC{k}.parameters;
                
                % Get struct
                strNum = modelsC{k}.strNum;
                % Get plan
                planNum = modelsC{k}.planNum;
                paramsS.structNum = strNum;
                paramsS.planNum = planNum;
                
                % Get dose bins
                dose0C = modelsC{k}.dv{1};
                vol0C = modelsC{k}.dv{2};
                scdoseC = cellfun(@(x) x*userScale,dose0C,'un',0);
                %Pass as vector if nStr==1
                if numel(strNum) == 1
                    vol0C = vol0C{1};
                    scdoseC = scdoseC{1};
                end
                
                %Compute probability
                cpNew = feval(modelsC{k}.function,paramsS,scdoseC,vol0C);
                %Set plot color
                clrIdx = mod(k,size(pColorM,1))+1;
                
                if strcmp(modelsC{k}.type,'NTCP')
                    plot([userScale userScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',.5,'parent',ud.handle.modelsAxis(2));
                    plot([hObj.Min userScale],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',.5,'parent',ud.handle.modelsAxis(2));
                    
                else
                    plot([userScale userScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',1,'parent',ud.handle.modelsAxis(3));
                    plot([userScale hObj.Max],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                        'linewidth',1,'parent',ud.handle.modelsAxis(3));
                end
                
            end
        end
        dispVal = sprintf('%.3f',userScale);
        hScaleDisp.String = dispVal;
        ud.scaleDisp = hScaleDisp;
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