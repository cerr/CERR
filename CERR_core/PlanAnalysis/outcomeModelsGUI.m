function outcomeModelsGUI(command,varargin)
%  GUI for outcomes modeling (NTCP)
%  This tool uses JSONlab toolbox v1.2, an open-source JSON/UBJSON encoder and decoder
%  for MATLAB and Octave.
%  See : http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files
%
% APA, 05/10/2016
% AI , 05/24/2016  Added dose scaling
% AI , 07/28/2016  Added ability to modify model parameters
% AI , 09/13/2016  Added TCP axis
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
        screenSizeV = get( 0, 'Screensize' );
        GUIWidth = 850;
        GUIHeight = 450;
        position = [(screenSizeV(3)-GUIWidth)/2,(screenSizeV(4)-GUIHeight)/2,GUIWidth,GUIHeight];
        
        str1 = 'Outcomes Models Explorer';
        defaultColor = [0.8 0.9 0.9];
        figColor = [.6 .75 .75];
        if isempty(findobj('tag','outcomeModelsFig'))
            
            % initialize main GUI figure
            hFig = figure('tag','outcomeModelsFig','name',str1,...
                'numbertitle','off','position',position,...
                'CloseRequestFcn', 'outcomeModelsGUI(''closeRequest'')',...
                'menubar','none','resize','off','color',figColor);
        else
            figure(findobj('tag','outcomeModelsFig'))
            return
        end
        
        figureWidth = position(3); figureHeight = position(4);
        posTop = figureHeight-topMarginHeight;
        
        % create title handles
        titleH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[10 posTop-5 830 50 ],'Style',...
            'frame','backgroundColor',defaultColor);
        titleH(2) = uicontrol(hFig,'tag','title','units','pixels',...
            'Position',[151 posTop+1 498 30 ],...
            'String','OUTCOME MODELS EXPLORER','Style','text', 'fontSize',10,...
            'FontWeight','Bold','HorizontalAlignment','center',...
            'backgroundColor',defaultColor);
        
        
        % create Dose and structure handles
        inputH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[10 10 leftMarginWidth+100 figureHeight-topMarginHeight-20 ],...
            'Style','frame','backgroundColor',defaultColor);
        inputH(2) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[20 posTop-35 140 20], 'String','MODELS','Style','text',...
            'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,...
            'HorizontalAlignment','left');
        inputH(3) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[20 posTop-70 140 30], 'String',...
            'Select model files','Style','push', 'fontSize',8.5,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'outcomeModelsGUI(''LOAD_MODELS'')');
        table3PosV = [190 posTop-330 200 240];
        colWidth = table3PosV(3)/2-1;
        inputH(4) = uitable(hFig,'Tag','Table3','Position',table3PosV,'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',{'Parameter','Value'},...
            'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'ColumnWidth',{round(table3PosV(3)/2),round(table3PosV(3)/2)},...
            'columnEditable',[false,true]);
        inputH(5) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',[325 20 65 30],'backgroundColor',defaultColor,...
            'String','Save','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','outcomeModelsGUI(''SAVE_MODELS'' )');
        inputH(6) = uicontrol(hFig,'units','pixels','Tag','plotButton','Position',[250 20 65 30],'backgroundColor',defaultColor,...
            'String','Plot','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','outcomeModelsGUI(''PLOT_MODELS'' )');
        inputH(7) = uitable(hFig,'Tag','Table1','Position',[table3PosV(1) posTop-60 table3PosV(3) 20 ],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'columnEditable',[false,true],'Data',{'structure','Select structure'},'ColumnWidth',{colWidth,colWidth});
        inputH(8) = uitable(hFig,'Tag','Table2','Position',[table3PosV(1) posTop-80 table3PosV(3) 20 ],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'columnEditable',[false,true],'Data',{'dose','Select dose'},'ColumnWidth',{colWidth,colWidth});
        
        
        %Define Models-plot Axis
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+115 10 figureWidth-leftMarginWidth-125 figureHeight-topMarginHeight-20 ],...
            'color',defaultColor,'ytick',[],'xtick',[],'box','on');
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',...
            [leftMarginWidth+170 70 figureWidth-leftMarginWidth-225 figureHeight-topMarginHeight-100],...
            'color','none','XAxisLocation','bottom','YAxisLocation','left','ylim',[0 1],...
            'fontSize',8,'box','on','visible','off' );
        plotH(3) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
            'color','none','XAxisLocation','bottom','YAxisLocation','right','ylim',[0 1],...
            'xtick',[],'fontSize',8,'box','on','visible','off' );
        plotH(4) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+155 28 figureWidth-leftMarginWidth-200 20],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',0.8,'Max',1.2,'Value',1);
        addlistener(plotH(4),'ContinuousValueChange',@scaleDose);
      
        % Store handles
        ud.handle.inputH = inputH;
        ud.handle.modelsAxis = plotH;
        ud.sliderPos = plotH(4).Position;
        set(hFig,'userdata',ud);
        
        
    case 'LOAD_MODELS'
        %Clear plots for previously selected models
        outcomeModelsGUI('CLEAR_PLOT',hFig);
        %Select new model
        ud = get(hFig,'userdata');
        %Get .json files
        fPath = uigetdir(pwd,'Select model folder');
        if fPath==0
            return;
        end
        fPattern = [fPath,filesep,'*.json'];
        fileS = dir(fPattern);
        nameListC = {fileS(:).name};
        [fIdxV,selected] = listdlg('ListString',nameListC,...
            'ListSize',[180,220],'Name','Select model files');
        if ~selected
            return;
        else
            numModels = numel(fIdxV);
            modelC = cell(1,numModels);
            for n = 1:numModels
                modelC{n} = loadjson(fullfile(fPath,fileS(n).name),'ShowProgress',1);
            end
        end
        
        %Get info from .json file
        % fileInfo = System.IO.FileInfo(fullfile(pathName,fileName));
        % created = fileInfo.CreationTime.ToString;
        % modified = fileInfo.LastAccessTime.ToString;
        % dummyAccount = System.Security.Principal.NTAccount('dummy');
        % owner = char(fileInfo.GetAccessControl.GetOwner(GetType(dummyAccount)).Value.ToString);
        
        %Create push buttons for editing model parameters
        outcomeModelsGUI('LIST_MODELS',modelC);
        
        %Store input model parameters
        ud = get(hFig,'userdata');
        ud.Models = modelC;
        ud.modelFile = strcat(fPath,filesep,{fileS(fIdxV).name}) ;
        set(hFig,'userdata',ud);
        
    case 'PLOT_MODELS'
        outcomeModelsGUI('CLEAR_PLOT',hFig);
        ud = get(hFig,'userdata');
        if ~isfield(ud,'NTCPCurve')
            ud.NTCPCurve = [];
        end
        if ~isfield(ud,'TCPCurve')
            ud.TCPCurve = [];
        end
        if ~isfield(ud,'Models')|| isempty(ud.Models)
            msgbox('Please select model files','Plot model');
            return
        end
        
        %Plot model curves
        hNTCPAxis = ud.handle.modelsAxis(2);
        hNTCPAxis.Visible = 'On';
        grid(hNTCPAxis,'On')
        hTCPAxis = ud.handle.modelsAxis(3);
        hTCPAxis.Visible = 'On';
        hSlider = ud.handle.modelsAxis(4);
        modelC = ud.Models;
        numModels = numel(modelC);
        structC = {planC{indexS.structures}.structureName};
        doseC = {planC{indexS.dose}.fractionGroupID};
        scaleV = linspace(0.8,1.2,100);
        
        % Define color order
        colorOrderM = get(gca,'ColorOrder');
        
        ntcp = 0;
        tcp = 0;
        hWait = waitbar(0,'Generating plots...');
        for j = 1:numModels
            
            scaledCPv = scaleV * 0;
            
            % Get parameters from .json file
            paramS = modelC{j}.parameters;
            structNum = 1;                 %Default 
            doseNum = 1;                   %Default
            if isfield(modelC{j}, 'structure')
                structNum = find(strcmp(modelC{j}.structure,structC));
            end
            if isfield(modelC{j}, 'dose')
                doseNum = find(strcmp(modelC{j}.dose,doseC));
            end
            paramS.structNum = structNum;
            paramS.doseNum = doseNum;
            
            % Get dose bins
            [planC, doseBins0V, volsHist0V] = getDVHMatrix(planC,structNum,doseNum);
            
            for n = 1 : numel(scaleV)
                
                % Scale dose bins
                scale = scaleV(n);
                doseBinsV = doseBins0V.*scale;
                
                % Compute CP
                scaledCPv(n) = feval(modelC{j}.function,paramS,doseBinsV,volsHist0V);
            end
            
            % Set plot color
            colorIdx = mod(j,size(colorOrderM,1))+1;
            
            % Plot curves
            if strcmp(modelC{j}.type,'NTCP')
                ntcp = ntcp + 1;
                ud.NTCPCurve = [ud.NTCPCurve plot(hNTCPAxis,scaleV,scaledCPv,'linewidth',2,...
                    'Color',colorOrderM(colorIdx,:))];
                ud.NTCPCurve(ntcp).DisplayName = modelC{j}.name;
            else
                tcp = tcp + 1;
                ud.TCPCurve = [ud.TCPCurve plot(hTCPAxis,scaleV,scaledCPv,'linewidth',2,...
                    'Color',colorOrderM(colorIdx,:))];
                ud.TCPCurve(tcp).DisplayName = modelC{j}.name;
            end
            waitbar(j/numModels);
        end
        close(hWait);
        xlabel(hNTCPAxis,'Dose scaling','Position',[1 -.13]),ylabel(hNTCPAxis,'NTCP');
        ylabel(hTCPAxis,'TCP');
        NTCPLegendC = arrayfun(@(x)x.DisplayName,ud.NTCPCurve,'un',0);
        TCPLegendC = arrayfun(@(x)x.DisplayName,ud.TCPCurve,'un',0);
        legend([ud.NTCPCurve,ud.TCPCurve],[NTCPLegendC,TCPLegendC],'Location','northeast','Color','none');
        
        set(hSlider,'Visible','On'); %Slider on
        ud.handle.modelsAxis(4) = hSlider;
        set(hFig,'userdata',ud);
        scaleDose(hSlider);
        
    case 'CLEAR_PLOT'
        ud = get(hFig,'userdata');
        %Clear data/plots from any previously loaded models/doses/structures
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
        posTop = 400;
        defaultColor = [0.8 0.9 0.9];
        modelC = varargin{1};
        if isfield(ud.handle,'editModels')
            ud.handle = rmfield(ud.handle,'editModels');
        end
        
        %List models
        numModels = length(modelC);
        modelNameC = cell(1,numModels);
        for j = 1:numModels
            
            fieldC = fieldnames(modelC{j});
            fnIdx = strcmpi(fieldC,'function');
            paramIdx = strcmpi(fieldC,'parameters');
            nameIdx = strcmpi(fieldC,'Name');
            
            %Check for 'function' and 'parameter' fields
            if ~any(fnIdx) || isempty(modelC{j}.(fieldC{fnIdx}))
                msgbox('Model file must include ''function'' attribute.','Model file error');
                return
            end
            if ~any(paramIdx) || isempty(modelC{j}.(fieldC{paramIdx}))
                msgbox('Model file must include ''parameters'' attribute.','Model file error');
                return
            end
            %Set default name if missing
            if ~any(nameIdx)
                modelNameC{j} = ['model',num2str(j)];
            else
                modelNameC{j} = modelC{j}.(fieldC{nameIdx});
            end
        end
        
        %Create listbox to display models
        hEdit = uicontrol(hFig,'units','pixels','style','listbox','string',modelNameC,...
            'position',[20 posTop-330 140 250],'callBack',@getParams,'backgroundColor',defaultColor);
        ud.handle.editModels = hEdit;
        
        set(ud.handle.inputH(6),'Enable','On'); %Plot button on
        
        set(hFig,'userdata',ud);
        
    case 'SAVE_MODELS'
        ud = get(hFig,'userData');
        modelC = ud.Models;
        outFile = ud.modelFile;
        numModels = numel(outFile);
        
        %Create UID
        modelNamesC = cellfun(@(x) x.function,modelC,'un',0);
        dateTimeV = clock.';
        dateTimeC = arrayfun(@num2str,dateTimeV,'un',0);
        randC = arrayfun(@num2str,1000.*rand(1,numModels),'un',0);
        UIDC = strcat({'outcomeModels.'},modelNamesC,{'.'},dateTimeC(2),...
            dateTimeC(3),dateTimeC(1),{'.'},dateTimeC{4:6},{'.'},randC);
        modelC = arrayfun(@(i) setfield(modelC{i},'UID',UIDC{i}),1:length(modelC),'un',0);
        
        
        %Save changes to model files
        for m = 1:numel(outFile)
        if isfield (modelC{m},'structNum')
           modelC{m} = rmfield(modelC{m},'structNum'); 
        end
        if isfield (modelC{m},'doseNum')
           modelC{m} = rmfield(modelC{m},'doseNum'); 
        end
        fprintf('\nSaving changes to %s ...',outFile{m});
        savejson('',modelC{m},'filename',outFile{m});
        end
        fprintf('\nSave complete.\n');
        
        set(ud.handle.inputH(5),'Enable','Off');  %Disable save
        set(hFig,'userdata',ud);
        
   
        
    case 'CLOSEREQUEST'
        
        closereq
        
end


%% Compute statistics

    function getParams(hObj,hEvent)
        
        %Extract fields
        ud = get(hFig,'userdata');
        modelsC = ud.Models;
        modelNum = hObj.Value;
        fieldsC = fieldnames(modelsC{modelNum});
        valuesC = struct2cell(modelsC{modelNum});
        
        
        %Extract sub-fields if any
        idxC = cellfun(@isstruct,valuesC,'un',0);
        idxV = [idxC{:}];
        subFieldsC = fieldsC;
        subValuesC = valuesC;
        if any(idxV)
            structIdxV = find(idxV);
            numSubFieldsV = zeros(1,numel(structIdxV));
            for l = 1:numel(structIdxV)
                strFieldsC = fieldnames(valuesC{structIdxV(l)});
                numSubFieldsV(l) = length(strFieldsC);
                subFieldsC = [subFieldsC(:);strFieldsC(:)];
                strvalueC = struct2cell(valuesC{structIdxV(l)});
                subValuesC{structIdxV(l)} = strFieldsC(:);
                subValuesC = [subValuesC(:);strvalueC];
            end
            
            %Convert numerical values to strings
            idxV = cellfun(@isnumeric,subValuesC);
            subValuesC(idxV) = cellfun(@num2str, subValuesC(idxV), 'un', 0);
            %Convert cell arrays of strings to comma-delimited strings
            idxV = cellfun(@iscellstr, subValuesC);
            toString = @(x){[sprintf('%s, ', x{1:end - 1}) ...
                sprintf('%s', x{end})]};
            subValuesC(idxV) = cellfun(toString, subValuesC(idxV));
        end
        
        %Check for struct/dose name
        structList = {planC{indexS.structures}.structureName};
        doseList = {planC{indexS.dose}.fractionGroupID};
       
        
        nDose = strcmp(subFieldsC,'dose');
        if any(nDose) && ismember(subValuesC{nDose},doseList)
            dosNum = strcmp(doseList,subValuesC{nDose});
            doseList = {doseList{dosNum},doseList{~dosNum}};
            subFieldsC = subFieldsC(~nDose);
            subValuesC = subValuesC(~nDose);
        end
        
        nStr = strcmp(subFieldsC,'structure');
        if any(nStr) && ismember(subValuesC{nStr},structList)
            strNum = strcmp(structList,subValuesC{nStr});
            structList = {structList{strNum},structList{~strNum}};
            subFieldsC =  subFieldsC(~nStr);
            subValuesC = subValuesC(~nStr);
        end
        
        
        %Store strName, doseName to modelsC
        modelsC{modelNum}.structure = structList{1};
        modelsC{modelNum}.dose = doseList{1};
        ud.Models = modelsC;
        
        %Add file properties if missing
        filePropsC = {'modified_at','modified_by','created_at','created_by',};
        missingFilePropsV = ~ismember(filePropsC,lower(fieldsC));
        if any(missingFilePropsV)
            idx = find(missingFilePropsV);
            for k = 1:numel(idx)
                subFieldsC = [filePropsC{k};subFieldsC(:)];
                subValuesC = [{''};subValuesC(:);];
            end
        end
        
        %Display in tables
        %Table1
        hTab1 = ud.handle.inputH(7);
        fmt = {[] structList};
        set(hTab1,'ColumnFormat',fmt,'Data',{'structure',structList{1}},'Visible','On','Enable','On');
        %Table2
        hTab2 = ud.handle.inputH(8);
        fmt = {[] doseList};
        set(hTab2,'ColumnFormat',fmt,'Data',{'dose',doseList{1}},'Visible','On','Enable','On');
        %Table3
        hTab3 = ud.handle.inputH(4);
        set(hTab3,'Data',[subFieldsC,subValuesC],'Visible','On','Enable','On');
        
        ud.handle.inputH(4) = hTab3;
        ud.handle.inputH(8) = hTab2;
        ud.handle.inputH(7) = hTab1;
        set(ud.handle.inputH(5),'Enable','On'); %Enable save
        set(hFig,'userdata',ud);
        
    end

    function editParams(hObj,hData)
        
        ud = get(hFig,'userdata');
        
        %Get input data
        idx = hData.Indices(1);
        val = hData.EditData;
        val2num = str2num(val);
        if isempty(val2num) %Convert from string if numerical
            val2num = val;
        end
        
        %Update modelC
        modelsC = ud.Models;
        modelNum = ud.handle.editModels.Value;
        previousDataC = struct2cell(modelsC{modelNum});
        newDataS = modelsC{modelNum};
        %Copy changes to modelC
        parName = hObj.Data(idx,1);
        parName = parName{1};
        fieldsC = fieldnames(newDataS);
        if any(ismember(fieldsC,parName))
            newDataS.(parName) = val2num;
        else
            idxC = cellfun(@isstruct,previousDataC,'un',0);
            idxV = [idxC{:}];
            structIdxV = find(idxV);
            for l = 1:numel(structIdxV)
                subFieldsC = fieldnames(newDataS.(fieldsC{structIdxV(l)}));
                subIdx = ismember(parName,subFieldsC);
                if any(subIdx)
                    newDataS.(fieldsC{structIdxV(l)}).(parName) = val2num ;
                end
            end
        end
        
        modelsC{modelNum} = newDataS;
        ud.Models = modelsC;
        set(ud.handle.inputH(5),'Enable','On');  %Enable save
        set(hFig,'userdata',ud);
        
    end

    function scaleDose(hObj,hEvent)%#ok
        
        ud = get(hFig,'userdata');
        
        %Get selected scale
        userScale = hObj.Value;
       
        %Clear any previous scaled-dose plots
        hScaledNTCP = findall(ud.handle.modelsAxis(2),'type','line','LineStyle','--');
        hScaledTCP = findall(ud.handle.modelsAxis(3),'type','line','LineStyle','--');
        delete(hScaledNTCP);
        delete(hScaledTCP);
        if isfield(ud,'scaleDisp')
        ud.scaleDisp.String = '';
        end
        hScaleDisp = text(userScale,0.03,'','Parent',ud.handle.modelsAxis(2),...
            'FontSize',8,'Color',[.3 .3 .3]);
        
        
        %Plot selected scale,CP
        modelsC = ud.Models;
        NTCPColorM = flipud(cat(1,ud.NTCPCurve(:).Color)); % Same line colors
        TCPColorM = flipud(cat(1,ud.TCPCurve(:).Color));
        structList = {planC{indexS.structures}.structureName};
        doseList = {planC{indexS.dose}.fractionGroupID};
        
        nTCP = 0;
        nNTCP = 0;
        for k = 1:length(modelsC)
            
            paramsS = modelsC{k}.parameters;
            strNum = 1;             %Default
            dosNum = 1;             %Default
            if isfield(modelsC{k},'structure')
                strNum = find(strcmp(modelsC{k}.structure,structList));
            end
            if isfield(modelsC{k},'dose')
                dosNum = find(strcmp(modelsC{k}.dose,doseList));
            end
            paramsS.structNum = strNum;
            paramsS.doseNum = dosNum;

            [planC, dose0V, vol0V] = getDVHMatrix(planC,strNum,dosNum);
            doseV = dose0V.*userScale;
            cpNew = feval(modelsC{k}.function,paramsS,doseV,vol0V);
            
            if strcmp(modelsC{k}.type,'NTCP')
                nNTCP = nNTCP + 1;
                idx = mod(nNTCP,size(NTCPColorM,1))+1;
                plot([userScale userScale],[0 cpNew],'Color',NTCPColorM(idx,:),'LineStyle','--',...
                    'linewidth',1,'parent',ud.handle.modelsAxis(2));
                plot([hObj.Min userScale],[cpNew cpNew],'Color',NTCPColorM(idx,:),'LineStyle','--',...
                    'linewidth',1,'parent',ud.handle.modelsAxis(2));
            else
                nTCP = nTCP + 1;
                idx = mod(nTCP,size(TCPColorM,1))+1;
                plot([userScale userScale],[0 cpNew],'Color',TCPColorM(idx,:),'LineStyle','--',...
                    'linewidth',1,'parent',ud.handle.modelsAxis(3));
                plot([userScale hObj.Max],[cpNew cpNew],'Color',TCPColorM(idx,:),'LineStyle','--',...
                    'linewidth',1,'parent',ud.handle.modelsAxis(3));
            end
        end
        dispVal = sprintf('%.3f',userScale);
        hScaleDisp.String = dispVal;
        ud.scaleDisp = hScaleDisp;
        set(hFig,'userdata',ud);
        
    end




end