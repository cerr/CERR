function outcomeModelsGUI(command,varargin)
%  GUI for outcomes modeling (NTCP)
%  This tool uses JSONlab toolbox v1.2, an open-source JSON/UBJSON encoder and decoder
%  for MATLAB and Octave.
%  See : http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files
%
% APA, 05/10/2016
% AI , 05/24/2016  Added dose scaling
% AI , 07/28/2016  Added ability to modify model parameters 
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
            'Position',[10 figureHeight-topMarginHeight-5 780 50 ],'Style',...
            'frame','backgroundColor',defaultColor);
        titleH(2) = uicontrol(hFig,'tag','title','units','pixels',...
            'Position',[151 figureHeight-topMarginHeight+1 498 30 ],...
            'String','OUTCOME MODELS EXPLORER','Style','text', 'fontSize',10,...
            'FontWeight','Bold','HorizontalAlignment','center',...
            'backgroundColor',defaultColor);
        
        
        % create Dose and structure handles
        inputH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[10 210 leftMarginWidth+5 figureHeight-topMarginHeight-220 ],...
            'Style','frame','backgroundColor',defaultColor);
        inputH(2) = uicontrol(hFig,'tag','doseStructTitle','units','pixels',...
            'Position',[20 posTop-50 150 20], 'String','DOSE & STRUCTURE',...
            'Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        prefix = 'Select a dose.';
        doseList = {prefix, planC{indexS.dose}.fractionGroupID};
        prefix = 'Select a structure.';
        structList = {prefix, planC{indexS.structures}.structureName};
        inputH(3) = uicontrol(hFig,'tag','doseStatic','units','pixels',...
            'Position',[20 posTop-80 120 20], 'String','Select Dose','Style',...
            'text', 'fontSize',10,'FontWeight','normal','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        inputH(4) = uicontrol(hFig,'tag','doseSelect','units','pixels',...
            'Position',[120 posTop-80 120 20], 'String',doseList,'Style',...
            'popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',...
            [1 1 1],'HorizontalAlignment','left','Callback','outcomeModelsGUI(''GET_DOSE'')');
        inputH(5) = uicontrol(hFig,'tag','structStatic','units','pixels',...
            'Position',[20 posTop-110 120 20], 'String','Select Structure',...
            'Style','text', 'fontSize',10,'FontWeight','normal','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        inputH(6) = uicontrol(hFig,'tag','structSelect','units','pixels',...
            'Position',[120 posTop-110 120 20], 'String',structList,'Style',...
            'popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],...
            'HorizontalAlignment','left','Callback','outcomeModelsGUI(''GET_STRUCT'')');
        inputH(7) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[20 posTop-150 180 20], 'String','MODELS','Style','text',...
            'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,...
            'HorizontalAlignment','left');
        inputH(8) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[20 posTop-180 180 30], 'String',...
            'Select file containing Models','Style','push', 'fontSize',8.5,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'outcomeModelsGUI(''LOAD_MODELS'')');
        inputH(9) = annotation(hFig,'textbox','Tag','dispModel','Position',[0.05,0.4,0.3,0.2],...
            'Visible','Off','EdgeColor',[0.6 0.6 0.6]);
        inputH(10) = uicontrol(hFig,'units','pixels','Tag','plot','Position',[245 215 65 30],'backgroundColor',defaultColor,...
            'String','Plot','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','outcomeModelsGUI(''PLOT_MODELS'')');
        inputH(11) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',[175 215 65 30],'backgroundColor',defaultColor,...
            'String','Save','Style','Push', 'fontSize',9,'FontWeight','normal','Enable','Off','Callback','outcomeModelsGUI(''SAVE_MODELS'' )');
        
        %Create Model-Stats handles
        dvhStatH(1) = axes('Parent',hFig,'units','Pixels','Position',[10 figureHeight-topMarginHeight-540 780 195 ],...
            'Color',defaultColor,'ytick',[],'xtick',[], 'box', 'on');
        dvhStatH(2) = uicontrol(hFig,'tag','modelStatsTitle','units','pixels',...
            'Position',[25 posTop-380 150 20], 'String','Model Stats','Style',...
            'text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',...
            defaultColor,'HorizontalAlignment','left');
        statsC = {'None','stat1','stat2'}; %%?Stats --add!
        dvhStatH(3) = uicontrol(hFig,'tag','statSelect','units','pixels',...
            'Position',[25 posTop-400 140 20], 'String',statsC,'Style','popup',...
            'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],...
            'HorizontalAlignment','left','callback',...
            'outcomeModelsGUI(''SHOW_MODEL_STAT'')');
        dvhStatH(4) = annotation('textbox','Tag','outBoxStat','Position',[0.3,0.02,0.65,0.3],...
            'Visible','Off','EdgeColor',[0.6 0.6 0.6]);
        
        %Define Models-plot Axis
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+20 210 figureWidth-leftMarginWidth-30 figureHeight-topMarginHeight-220 ],...
            'color',defaultColor,'ytick',[],'xtick',[],'box','on');
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',...
            [leftMarginWidth+60 posTop*2/4 figureWidth-leftMarginWidth-100 posTop*0.9/2],...
            'color','w','ytick',[],'xtick',[],'fontSize',8,'box','on','visible','off' );
        plotH(3) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+60 posTop*2/4-45 figureWidth-leftMarginWidth-100 20],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',0,'Max',2,'Value',1);
        addlistener(plotH(3),'ContinuousValueChange',@scaleDose);
        plotH(4) = uicontrol('parent',hFig,'units','pixels','Style','Text','Visible','Off','Tag','sliderVal',...
            'BackgroundColor',defaultColor);
        
        % Store handles
        ud.handle.inputH = inputH;
        ud.handle.DVHStatH = dvhStatH;
        ud.handle.modelsAxis = plotH;
        ud.sliderPos = plotH(3).Position;
        set(hFig,'userdata',ud);
        
    case 'GET_DOSE'
        %Get new dose
        ud = get(hFig,'userdata');
        hDoseSelect = ud.handle.inputH(4);
        dose = get(hDoseSelect,'Value');
        ud.doseNum = dose - 1;
        set(hFig,'userdata',ud);
        if isfield (ud,'Models') && ~isempty(ud.Models) && isfield(ud,'structNum') && ud.structNum~=0  %Update plot for new dose
            outcomeModelsGUI('PLOT_MODELS',hFig)
        end
        
    case 'GET_STRUCT'
        %Select new structure
        ud = get(hFig,'userdata');
        hStructSelect = ud.handle.inputH(6);
        strNum = get(hStructSelect,'Value');
        ud.structNum = strNum - 1;
        set(hFig,'userdata',ud);
        if isfield (ud,'Models') && ~isempty(ud.Models) && isfield(ud,'doseNum') && ud.doseNum~=0  %Update plot for new structure
            outcomeModelsGUI('PLOT_MODELS',hFig);
        end
        
    case 'LOAD_MODELS'
        %Clear plots for previously selected models
        outcomeModelsGUI('CLEAR_PLOT',hFig);
        %Select new model
        ud = get(hFig,'userdata');
        % Read .json file containing models
        [fileName,pathName,filterIndex]  = uigetfile('*.json','Select model file');
        if ~filterIndex
            return
        else
            modelC = loadjson(fullfile(pathName,fileName),'ShowProgress',1);
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
        ud.Models = modelC;
        ud.modelFile = fullfile(pathName,fileName);
        hPlot = ud.handle.inputH(10);
        set(hPlot,'Enable','On');
        set(hFig,'userdata',ud);
        
    case 'PLOT_MODELS'
        outcomeModelsGUI('CLEAR_PLOT',hFig);
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
        if ~isfield(ud,'Models')|| isempty(ud.Models)
            msgbox('Please choose a model file','Plot model');
            return
        end
        
        % Plot model curves
        hModelAxis = ud.handle.modelsAxis(2);
        hModelAxis.Visible = 'On';
        modelC = ud.Models;
        numModels = numel(modelC);
        EUDv = linspace(0,100,100);
        %Define color order
        colorOrderM = get(gca,'ColorOrder');
        
        for i = 1:numModels
            %Read parameters from .json file
            paramS = modelC{i}.parameters;
            
            %Compute EUD,NTCP for selected struct/dose
            [EUD,ntcp] = feval(modelC{i}.function,[],paramS,ud.structNum,ud.doseNum,1);
            
            %Compute NTCPv
            [~,ntcpV,modelConfidence] = feval(modelC{i}.function,EUDv,paramS);
            
            %Set plot color
            colorIdx = mod(i,size(colorOrderM,1))+1;
            
            %plot curves
            ud.EUD = [ud.EUD, plot([EUD EUD],[0 ntcp],'linewidth',1,'Color',...
                colorOrderM(colorIdx,:),'parent',ud.handle.modelsAxis(2))];
            ud.ntcp = [ud.ntcp plot([0 EUD],[ntcp ntcp],'linewidth',1,'Color',...
                colorOrderM(colorIdx,:),'parent',ud.handle.modelsAxis(2))];
            ud.modelCurve = [ud.modelCurve plot(EUDv,ntcpV,'linewidth',2,...
                'Color',colorOrderM(colorIdx,:),'parent',ud.handle.modelsAxis(2))];
            ud.modelCurve(i).DisplayName = modelC{i}.name;
            %TO DO : model confidence
        end
        
        xlabel('Dose scaling'),ylabel('Complication Probability');
        legend([ud.modelCurve],flip(cellfun(@(x) x.name,ud.Models,'un',0)),'Location','best');
        hSlider = ud.handle.modelsAxis(3);
        set(hSlider,'Visible','On');
        set(hFig,'userdata',ud);
        scaleDose(hSlider);
        
    case 'CLEAR_PLOT'
        ud = get(hFig,'userdata');
        %Clear data/plots from any previously loaded models/dose/structures
        ud.EUD = [];
        ud.ntcp = [];
        ud.modelCurve = [];
        cla(ud.handle.modelsAxis(2));
        legend(ud.handle.modelsAxis(2),'hide')
        hSlider = ud.handle.modelsAxis(3);
        hSlider.Value = 1;
        hSlider.Visible = 'Off';
        hSliderValDisp = ud.handle.modelsAxis(4);
        set(hSliderValDisp,'String','1');
        set(hSliderValDisp,'Visible','Off');
        set(hFig,'userdata',ud);
        
    case 'LIST_MODELS'
        
        ud = get(hFig,'userdata');
        buttonWidth = 100;
        buttonHeight = 30;
        top = 365;
        defaultColor = [0.8 0.9 0.9];
        
        modelC = varargin{1};
        if isfield(ud.handle,'editButtons')
            ud.handle = rmfield(ud.handle,'editButtons');
        end
        
        for j = 1:length(modelC)
            
            fieldC = fieldnames(modelC{j});
            nameIdx = strcmpi(fieldC,'Name');
            if ~any(nameIdx)
                modelName = ['model',num2str(j)];
            else
                modelName= modelC{j}.(fieldC{nameIdx});
            end
            
            hEdit(j) = uicontrol(hFig,'units','pixels','style','push','string',['Edit model ',modelName],...
                'position',[20,top-j*buttonHeight,buttonWidth,buttonHeight],'Tag',['model-',num2str(j)],'callBack',@editParams,'backgroundColor',defaultColor);
        end
        
        ud.handle.editButtons = hEdit;
        set(hFig,'userdata',ud);
        
    case 'SAVE_MODELS'
        ud = get(hFig,'userData');
        modelC = ud.Models; 
        outFile = ud.modelFile;
        fprintf('\n Saving to %s ...',outFile);
        savejson('',modelC,outFile);
        fprintf('\n Save complete.\n');
        hSave = ud.handle.inputH(11);
        set(hSave,'Enable','Off');
        set(hFig,'userdata',ud);
        
    case 'SHOW_MODEL_STAT'
        ud = get(hFig,'userdata');
        if ~isfield(ud,'modelCurve') || isempty(ud.modelCurve)
            return
        end
        
        %Display output
        outStatBox = findall(gcf,'Tag','outBoxStat');
        %Get selected statistic
        hStatSel = ud.handle.DVHStatH(3);
        selection = get(hStatSel,'Value');
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

    function editParams(hObj,hEvent)
        
        %Extract fields
        ud = get(hFig,'userdata');
        modelsC = ud.Models;
        idx = strfind(hObj.Tag,'-');
        modelNum = str2num(hObj.Tag(idx+1:end));
        fieldsC = fieldnames(modelsC{modelNum});
        valuesC = struct2cell(modelsC{modelNum});
        nFields = length(fieldsC);

        %Extract sub-fields
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
        
        %Add file properties if missing
        filePropsC = {'modified_at','modified_by','created_at','created_by',};
        missingFilePropsV = ~ismember(filePropsC,lower(fieldsC));
        if any(missingFilePropsV)
            idx = find(missingFilePropsV);
            for k = 1:numel(idx)
                subFieldsC = [filePropsC{k};subFieldsC(:)];
                subValuesC = [{''};subValuesC(:);];
            end
        nFields = nFields + numel(idx);
        end
                
        %Edit input parameters
        userInputC = inputdlg(subFieldsC,'Model parameters',[1,50],subValuesC);
        if isempty(userInputC)
        userInputS = cell2struct(subValuesC,subFieldsC,1);  
        else
        numericalC = cellfun(@str2num,userInputC,'un',0);
        strIdxC = cellfun(@isempty,numericalC,'un',0);
        userInputC(~[strIdxC{:}]) = numericalC(~[strIdxC{:}]);
        userInputS = cell2struct(userInputC,subFieldsC,1);
        %Update input parameter structure
        if ~isempty(structIdxV)
        for k = 1:numel(structIdxV)
        nSubFields = numSubFieldsV(k);
        copyFieldsC = subFieldsC(nFields+1 : nFields+nSubFields);
        subStructS = cell2struct(userInputC(nFields+1 : nFields+nSubFields),copyFieldsC,1);
        userInputS.(fieldsC{structIdxV(k)}) = subStructS;
        userInputS = rmfield(userInputS,copyFieldsC);
        subFieldsC = fieldnames(userInputS);
        userInputC = struct2cell(userInputS);
        end
        end
        end
        
        modelsC{modelNum} = userInputS;
        ud.Models = modelsC;
        hSave = ud.handle.inputH(11);
        set(hSave,'Enable','On');
        set(hFig,'userData',ud);
        
    end


    function scaleDose(hObj,hEvent)%#ok
        
        ud = get(hFig,'userdata');
        
        %Get selected scale
        scale = hObj.Value;
        posV = hObj.Position;
        left = posV(1)+(scale/hObj.Max)*posV(3)-5;
        hSliderVal = ud.handle.modelsAxis(4);
        hSliderVal.Position = [left,posV(2)-15,25,15];
        hSliderVal.String = num2str(scale);
        hSliderVal.Visible = 'On';
        
        %Clear any previous scaled-dose plots
        hScaled = findall(ud.handle.modelsAxis(2),'type','line','LineStyle','--');
        delete(hScaled);
        
        %Plot EUD,ntcp for scaled dose
        modelsC = ud.Models;
        colorM = flipud(cat(1,ud.EUD(:).Color)); % Same line colors
        for k = 1:length(modelsC)
            paramsS = modelsC{k}.parameters;
            [EUDnew,ntcpNew] = feval(modelsC{k}.function,[],paramsS,ud.structNum,ud.doseNum,scale);
            idx = mod(k,size(colorM,1))+1;
            plot([EUDnew EUDnew],[0 ntcpNew],'Color',colorM(idx,:),'LineStyle','--',...
                'linewidth',1,'parent',ud.handle.modelsAxis(2));
            plot([0 EUDnew],[ntcpNew ntcpNew],'Color',colorM(idx,:),'LineStyle','--',...
                'linewidth',1,'parent',ud.handle.modelsAxis(2));
        end
        
        set(hFig,'userdata',ud);
        
    end


end