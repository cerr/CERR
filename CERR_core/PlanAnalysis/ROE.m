function ROE(command,varargin)
%  The Radiotherapy Outcomes Estimator (ROE) is a plug-in to CERR for
%  interactively exploring the impact of scaling dose on Tumor Control
%  Probability (TCP) and Normal Tissue Complication Probability (NTCP).
%
%  This tool uses draggable by William Warriner (2021)
%    draggable (https://github.com/wwarriner/draggable/releases/tag/v0.1.0),
%    GitHub. Retrieved May 17, 2021
% =======================================================================================================================
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

%% Globals
global planC stateS
indexS = planC{end};

%% Check for loaded plan
if isempty(planC)
    if  ~strcmpi(command,'closerequest')
        msgbox('Please load valid plan to begin','Error!');
        return
    end
end

%% Default command
if nargin==0
    command = 'INIT';
end

%% Default hyperparameters
binWidth = .05;
ROEoptS = opts4Exe(fullfile(getCERRPath,'CERRoptions.json'));
if isfield(ROEoptS,'ROEDoseScaleRange')
    %Use sclae factors from CERRoptions.jsonif available  
    doseScaleRangeV = ROEoptS.ROEDoseScaleRange;
else
    %Use default range of scale factors
    doseScaleRangeV = [0.5,1.5];
end
%Check for valid range
assert((doseScaleRangeV(2)>= 1 && doseScaleRangeV(1)<=1),...
    'Invalid dose scale range.')
assert((doseScaleRangeV(2)>doseScaleRangeV(1)),...
    'Invalid dose scale range.')


% Get GUI fig handle
hFig = findobj('Tag','ROEFig');
  
% % Clear plots on loading new CERR file w
% if ~strcmp(currCERRfile,CERRfile)
%     CERRfile = currCERRfile;
%     ROE('CLEAR_PLOT',hFig) -> Store fig handle to stateS and call this
%     from slicecallback when new plan is loaded.
% end


switch upper(command)

    case 'INIT'
        %Initialize main GUI figure

        if isempty(findobj('tag','ROEFig'))

            % initialize main GUI figure
            hFig = figure('tag','ROEFig','name','ROE',...
                'numbertitle','off','CloseRequestFcn',...
                'ROE(''closeRequest'')','menubar','none',...
                'resize','off');
        else
            figure(findobj('tag','ROEFig'))
            return
        end

        % Define GUI size, margins, position, colors, fonts, & title
        ud = guidata(hFig);
        size_pixels = get(gcf,'Position');
        set(gcf,'Units','characters')
        size_characters = get(gcf,'Position');
        scaleV = size_pixels(3:4)./size_characters(3:4);

        ud.FigSettings = struct();
        screenSizeV = get( 0, 'Screensize' );
        GUIWidth = 1200;
        GUIHeight = 750;
        ud.FigSettings.charScale = scaleV;
        ud.FigSettings.screenSize = screenSizeV(3:4)./scaleV;
        ud.FigSettings.leftMarginWidth = 360/scaleV(1);
        ud.FigSettings.topMarginHeight = 60/scaleV(2);
        
        ud.FigSettings.GUIWidth = GUIWidth/scaleV(1);
        ud.FigSettings.GUIHeight = GUIHeight/scaleV(2);
        ud.FigSettings.position = [(ud.FigSettings.screenSize(1)-...
            ud.FigSettings.GUIWidth)/2, (ud.FigSettings.screenSize(2)- ...
            ud.FigSettings.GUIHeight)/2, ud.FigSettings.GUIWidth,...
            ud.FigSettings.GUIHeight];
        ud.FigSettings.defaultColor = [0.8 0.9 0.9];
        ud.FigSettings.figColor = [.6 .75 .75];

        if ispc
            ud.FigSettings.fontSize = 10;
            ud.FigSettings.smFontSize = 9;
            ud.FigSettings.lgFontSize = 11;
        else
            if ismac
                ud.FigSettings.fontSize = 12;
                ud.FigSettings.smFontSize = 10;
                ud.FigSettings.lgFontSize = 14;
            end
        end

        %stateS.leftMarginWidth = ud.FigSettings.leftMarginWidth;
        %stateS.topMarginHeight = ud.FigSettings.topMarginHeight;

        %Store (user-input) range of dose scale factors
        ud.userScaleRange = doseScaleRangeV;

        set(hFig,'color',ud.FigSettings.figColor);
        set(hFig,'position',ud.FigSettings.position,'units','characters');
        guidata(hFig,ud);

        %Draw uicontrols
        if nargin<2
            ROE('refresh',hFig);
        else
            ROE('refresh',hFig,varargin{:});
        end

        %Display figure
        figure(hFig);


    case 'REFRESH'

        if isempty(hFig)
            return
        end


        if nargin<3                %default (research use)
            createUIControlsROE(hFig,planC);
        else


            %Create UI controls (clinical use)
            createUIControlsROEPreset(hFig,planC,varargin);
            %Load models from config file
            refreshFlag = 0;
            listProtocolsFlag = 0;
            configFile = varargin{3};
            %'G:\CERR_test\CERR\CERR_core\PlanAnalysis\sampleFilesForROE\ultracentalLungConfig.json';
            ROE('LOAD_MODELS',configFile,refreshFlag,listProtocolsFlag);
            %Set default dose plan
            ud = guidata(hFig);
            ud.structsChecked = 0;
            hObj = ud.handle.tab1H(4);
            hData.Indices = [0,0];
            hData.EditData = planC{indexS.dose}(1).fractionGroupID;
            editParamsROE(hObj,hData,hFig,planC)
            %Check input structures
            checkInputStrROE(hFig,planC);
            ud = guidata(hFig);
            strCheckFigH = ud.handle.strCheckH;
            uiwait(strCheckFigH)
            ud = guidata(hFig);
            if isfield(ud,'structsChecked') && ud.structsChecked
                %Set default plot mode
                ud.plotMode = 3;
                guidata(hFig,ud);
                %Plot models
                ROE('PLOT_MODELS');
                %Switch to constraints tab
                hObj = ud.handle.inputH(4);
                switchTabsROE(hObj,[],hFig)
            end
        end


    case 'LOAD_MODELS'


        refreshFlag = 1;%default;
        showProgFlag = 0;%default
        listProtocolsFlag = 1;
        if nargin<2
            ROE('REFRESH');
            showProgFlag = 1;
        else
            if nargin>2
                refreshFlag = varargin{2};
            end
            if nargin>3
                listProtocolsFlag = varargin{3};
            end
            if refreshFlag
                ROE('REFRESH',hFig,planC,varargin);
            end
        end

        ud = guidata(hFig);

        %Get paths to JSON files
        if nargin<2
            %Get path from CERRoptions.json
            ROEoptS = opts4Exe('CERRoptions.json');
            %NOTE: Define path to .json files for protocols, models & clinical criteria in CERROptions.json
            %optS.ROEProtocolPath = 'your/path/to/protocols';
            %optS.ROEModelPath = 'your/path/to/models';
            %optS.ROECriteriaPath = 'your/path/to/criteria';
        else
            configFile = varargin{1};
            ROEoptS = loadjson(configFile);
        end

        if contains(ROEoptS.ROEProtocolPath,'getCERRPath')
            protocolPath = eval(ROEoptS.ROEProtocolPath);
        else
            protocolPath = ROEoptS.ROEProtocolPath;
        end
        if contains(ROEoptS.ROEModelPath,'getCERRPath')
            modelPath = eval(ROEoptS.ROEModelPath);
        else
            modelPath = ROEoptS.ROEModelPath;
        end
        if contains(ROEoptS.ROECriteriaPath,'getCERRPath')
            criteriaPath = eval(ROEoptS.ROECriteriaPath);
        else
            criteriaPath = ROEoptS.ROECriteriaPath;
        end

        % List available protocols for user selection
        [protocolListC,protocolIdx,ok] = listFilesROE(protocolPath,...
            listProtocolsFlag);
        if ~ok
            return
        end


        % Load models associated with selected protocol(s)
        root = uitreenode('v0', 'Fractionation', 'Baseline fractionations',...
            [], false);      %Create root node (for tree display)
        protocolS(numel(protocolIdx)) = struct();
        for p = 1:numel(protocolIdx)                                       %Cycle through selected protocols
            [~,protocol] = fileparts(protocolListC{protocolIdx(p)});
            protcolFile = fullfile(protocolPath,protocolListC{protocolIdx(p)});
            protocolInfoS = jsondecode(fileread(protcolFile));
            %Load .json for protocol
            modelListC = fields(protocolInfoS.models);                     %Get list of relevant models
            numModels = numel(modelListC);
            protocolS(p).modelFiles = [];
            uProt = uitreenode('v0',protocol,protocolInfoS.name,[],false); %Create nodes for protocols
            for m = 1:numModels
                protocolS(p).protocol = protocolInfoS.name;
                modelFPath = fullfile(modelPath,protocolInfoS.models.(modelListC{m}).modelFile);
                %Get path to .json for model
                protocolS(p).model{m} = jsondecode(fileread(modelFPath));
                %Load model parameters from .json file
                protocolS(p).modelFiles = [protocolS(p).modelFiles,modelFPath];
                modelName = protocolS(p).model{m}.name;
                uProt.add(uitreenode('v0', modelName,modelName, [], true));%Create nodes for models
            end
            protocolS(p).numFractions = protocolInfoS.numFractions;
            protocolS(p).totalDose = protocolInfoS.totalDose;
            root.add(uProt);                                               %Add protocol to tree

            %Load associated clinical criteria/guidelines
            if isfield(protocolInfoS,'criteriaFile')
                critFile = fullfile(criteriaPath,protocolInfoS.criteriaFile);
                critS = jsondecode(fileread(critFile));
                protocolS(p).constraints = critS;
            end
        end

        %Create tree to list models by protocol
        scaleV = ud.FigSettings.charScale;
        shiftV = [10,10]./scaleV;
        GUIWidth = ud.FigSettings.GUIWidth;
        GUIHeight = ud.FigSettings.GUIHeight; 
        mtree = uitree('v0', 'Root', root, 'SelectionChangeFcn',...
            @(hObj,hEvt)getParamsROE(hObj,hEvt,hFig,planC));
        set(mtree,'units','characters','Position',...
            [2*shiftV(1) 5*shiftV(2) .16*GUIWidth .68*GUIHeight],...
            'Visible',false);
        drawnow;
        set(ud.handle.tab1H(1),'string','Fractionation & Models'); %Tree title

        %Store protocol & model parameters from JSON files to GUI userdata
        ud.Protocols = protocolS;
        ud.modelTree = mtree;
        guidata(hFig,ud);

        ROE('LIST_MODELS');


    case 'PLOT_MODELS'

            %% Get plot mode
            ud = guidata(hFig);
            if ~isfield(ud,'plotMode') || isempty(ud.plotMode) || isequal(ud.plotMode,0)
                msgbox('Please select display mode','Plot models');
                return
            else
                plotMode = ud.plotMode;
            end


            %% Clear previous plots
            ROE('CLEAR_PLOT',hFig);

            ud = guidata(hFig);
            if ~isfield(ud,'planNum') || isempty(ud.planNum) || ud.planNum==0
                msgbox('Please select valid dose plan.','Selection required');
                return
            end
            RxField = ud.handle.tab1H(12);
            if isempty(get(RxField,'String'))
                msgbox('Please provide prescribed dose (Gy).','Missing parameter');
                return
            else
                prescribedDose = str2double(get(RxField,'String'));
            end

            %% Initialize plot handles
            if ~isfield(ud,'NTCPCurve')
                ud.NTCPCurve = [];
            end
            if ~isfield(ud,'TCPCurve')
                ud.TCPCurve = [];
                ud.TCPCurveDots = [];
            end
            if ~isfield(ud,'BEDCurve')
                ud.BEDCurve = [];
                ud.BEDCurveDots = [];
            end
            if ~isfield(ud,'cMarker')
                ud.cMarker = [];
            end
            if ~isfield(ud,'gMarker')
                ud.gMarker = [];
            end

            %% Define color order, foreground protocol
            colorOrderM = [0 229 238;123 104 238;255 131 250;0 238 118;
                218 165 32;28 134 238;255 153 153;0 139 0;28 134 238;...
                238 223 204;196 196 196]/255;
            if ~isfield(ud,'foreground') || isempty(ud.foreground)
                ud.foreground = 1;
            end
            ud.plotColorOrderM = colorOrderM;

            %% Font sizes
            fontSize = ud.FigSettings.fontSize;

            %% Define loop variables
            protocolS = ud.Protocols;
            cScaleV = [];
            cValV = [];
            gScaleV = [];
            gValV = [];
            ntcp = 0;
            tcp = 0;
            bed = 0;
            jTot = 0;
            cCount = 0;
            gCount = 0;


            %% Handle missing structure input
            guidata(hFig,ud);
            if ~isfield(ud,'structsChecked') || ~(ud.structsChecked)
                checkInputStrROE(hFig,planC);
                ud = guidata(hFig);
            end

            %% Mode-specific computations
            switch plotMode
                case {1,2} %NTCP vs BED/TCP

                    %maxDeltaFrx = round(max([protocolS.numFractions])/2);
                    minFrx = doseScaleRangeV(1)*max([protocolS.numFractions]);
                    maxFrx = doseScaleRangeV(end)*max([protocolS.numFractions]);
                    minDeltaFrx = round(minFrx - max([protocolS.numFractions]));
                    maxDeltaFrx = round(maxFrx - max([protocolS.numFractions]));
                    nfrxScaleV = linspace(minDeltaFrx,maxDeltaFrx,99);

                    hNTCPAxis = ud.handle.modelsAxis(1);
                    hNTCPAxis.Visible = 'On';
                    grid(hNTCPAxis,'On');

                    tcpM = nan(numel(protocolS),length(nfrxScaleV));
                    %Compute BED/TCP
                    for p = 1:numel(protocolS)

                        modelC = protocolS(p).model;
                        modTypeC = cellfun(@(x)(x.type),modelC,'un',0);
                        xIndx = find(strcmp(modTypeC,'BED') | strcmp(modTypeC,'TCP')); %Identify TCP/BED models

                        %Scale planned dose array
                        plnNum = ud.planNum;
                        numFrxProtocol = protocolS(p).numFractions;
                        protDose = protocolS(p).totalDose;
                        dpfProtocol = protDose/numFrxProtocol;
                        %prescribedDose = planC{indexS.dose}(plnNum).prescribedDose;
                        dA = getDoseArray(plnNum,planC);
                        dAscale = protDose/prescribedDose;
                        dAscaled = dA * dAscale;
                        planC{indexS.dose}(plnNum).doseArray = dAscaled;

                        %Compute BED/TCP

                        %Create parameter dictionary
                        paramS = [modelC{xIndx}.parameters];
                        structNumV = modelC{xIndx}.strNum;
                        structNumV(structNumV==0)=[]; %test
                        %-No. of fractions
                        paramS.numFractions.val = numFrxProtocol;
                        %-fraction size
                        paramS.frxSize.val = dpfProtocol;
                        %-alpha/beta
                        if isfield(modelC{xIndx},'abRatio')
                            abRatio = modelC{xIndx}.abRatio;
                            paramS.abRatio.val = abRatio;
                        end

                        %Get DVH
                        if isfield(modelC{xIndx},'dv')
                            storedDVc = modelC{xIndx}.dv;
                            doseBinsC = storedDVc{1} ;
                            volHistC = storedDVc{2};
                        else
                            doseBinsC = cell(1,numel(structNumV));
                            volHistC = cell(1,numel(structNumV));
                            strC = modelC{xIndx}.parameters.structures;
                            strFlag = 0;
                            if isstruct(strC)
                                strFlag = 1;
                                strC = fieldnames(strC);
                            end
                            for nStr = 1:numel(structNumV)
                                if strFlag
                                    strS = modelC{xIndx}.parameters.structures.(strC{nStr});
                                else
                                    strS = [];
                                end
                                %---------------temp : update reqd ------------
                                if isfield(strS,'dDIL')
                                    doseBinsC{nStr} = strS.dDIL.val;
                                    volHistC{nStr} = [];
                                else
                                    [dosesV,volsV] = getDVH(structNumV(nStr),plnNum,planC);
                                    [doseBinsC{nStr},volHistC{nStr}] = doseHist(dosesV,volsV,binWidth);
                                end
                                %----------------end temp --------------
                            end
                            modelC{xIndx}.dv = {doseBinsC,volHistC};
                        end

                        xScaleV = nfrxScaleV(nfrxScaleVnumFrxProtocol>=1);

                        for n = 1 : numel(xScaleV)

                            %Scale dose bins
                            newNumFrx = xScaleV(n) + numFrxProtocol;
                            scaleV = newNumFrx/numFrxProtocol;
                            scaledDoseBinsC = cellfun(@(x) x*scaleV,doseBinsC,'un',0);


                            %Apply fractionation correction as required
                            correctedScaledDoseC = frxCorrectROE(modelC{xIndx},structNumV,newNumFrx,scaledDoseBinsC);

                            %Update nFrx parameter
                            paramS.numFractions.val = newNumFrx;

                            %Compute TCP/BED
                            if numel(structNumV)==1
                                tcpM(p,n) = feval(modelC{xIndx}.function,paramS,correctedScaledDoseC{1},volHistC{1});
                            else
                                tcpM(p,n) = feval(modelC{xIndx}.function,paramS,correctedScaledDoseC,volHistC);
                            end

                            %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                            if n==numel(xScaleV)
                                %Get corrected dose at scale == 1
                                paramS.frxSize.val = dpfProtocol;
                                testDoseC = frxCorrectROE(modelC{xIndx},structNumV,numFrxProtocol,doseBinsC);
                                %Display mean dose, EUD, GTD(if applicable)
                                outType = modelC{xIndx}.type;
                                testMeanDose = calc_meanDose(testDoseC{1},volHistC{1});
                                if isfield(paramS,'n')
                                    temp_a = 1/paramS.n.val;
                                    testEUD = calc_EUD(testDoseC{1},volHistC{1},temp_a);
                                    fprintf(['\n---------------------------------------\n',...
                                        'Protocol:%d, Model:\nMean Dose = %f\n%s = %f\n'],p,testEUD);
                                end
                                if strcmp(modelC{xIndx}.name,'Lung TCP')
                                    additionalParamS = paramS.gTD.params;
                                    for fn = fieldnames(additionalParamS)'
                                        paramS.(fn{1}) = additionalParamS.(fn{1});
                                    end
                                    testGTD = calc_gTD(testDoseC{1},volHistC{1},paramS);
                                    fprintf(['\n---------------------------------------\n',...
                                        'GTD  = %f'],testGTD);
                                end
                                %Display TCP/BED
                                if numel(testDoseC)>1
                                    testOut = feval(modelC{xIndx}.function,paramS,testDoseC,volHistC);
                                else
                                    testOut = feval(modelC{xIndx}.function,paramS,testDoseC{1},volHistC{1});
                                end
                                fprintf(['\n---------------------------------------\n',...
                                    'Protocol:%d, Model:\nMean Dose = %f\n%s = %f\n'],p,testMeanDose,outType,testOut);
                            end
                            %---------------------------------END TEMP-----------------------------------%
                        end
                        planC{indexS.dose}(plnNum).doseArray = dA;
                    end
                    protocolS(p).model = modelC;
                    hSlider = ud.handle.modelsAxis(7); %Invisible; just for readout at scale=1
                    ud.scaleFactors = xScaleV;

                case 3 %vs. scaled frx size

                    hNTCPAxis = ud.handle.modelsAxis(2);
                    hNTCPAxis.Visible = 'On';
                    grid(hNTCPAxis,'On');
                    hTCPAxis = ud.handle.modelsAxis(3);
                    hTCPAxis.Visible = 'On';

                    typesC = cellfun(@(x) x.type,protocolS(1).model,'un',0);
                    if any(strcmpi(typesC,'BED'))
                        set(hTCPAxis,'yLim',[0 200]);
                        ylabel(hTCPAxis,'BED (Gy)','fontsize',fontSize);
                    else
                        ylabel(hTCPAxis,'TCP','fontsize',fontSize);
                    end

                    hSlider = ud.handle.modelsAxis(6);
                    xlab = 'Dose scale factor';

                    numModelC = arrayfun(@(x)numel(x.model),protocolS,'un',0);
                    numModelsV = [numModelC{:}];

                    xScaleV = linspace(doseScaleRangeV(1),...
                        doseScaleRangeV(end),99);
                    ud.scaleFactors = xScaleV;

                case 4 %vs. scaled nfrx


                    hNTCPAxis = ud.handle.modelsAxis(4);
                    hNTCPAxis.Visible = 'On';
                    grid(hNTCPAxis,'On');
                    hTCPAxis = ud.handle.modelsAxis(5);
                    hTCPAxis.Visible = 'On';

                    typesC = cellfun(@(x) x.type,protocolS(1).model,'un',0);
                    if any(strcmpi(typesC,'BED'))
                        set(hTCPAxis,'yLim',[0 200]);
                        ylabel(hTCPAxis,'BED (Gy)','fontsize',fontSize);
                    else
                        ylabel(hTCPAxis,'TCP','fontsize',fontSize);
                    end

                    hSlider = ud.handle.modelsAxis(7);
                    xlab = 'Change in no. of fractions';

                    numModelC = arrayfun(@(x)numel(x.model),protocolS,'un',0);
                    numModelsV = [numModelC{:}];

                    maxProtFrx = max([protocolS.numFractions]);
                    minFrx = doseScaleRangeV(1)*maxProtFrx;
                    maxFrx = doseScaleRangeV(end)*maxProtFrx;
                    minDeltaFrx = round(minFrx - maxProtFrx);
                    maxDeltaFrx = round(maxFrx - maxProtFrx);
                    nfrxScaleV = linspace(minDeltaFrx,maxDeltaFrx,99);
                    scaleFactorsV = nfrxScaleV./maxProtFrx;
                    ud.scaleFactors = scaleFactorsV;
            end


            %% Plot model-based predictions
            hWait = waitbar(0,'Generating plots...');
            for p = 1:numel(protocolS)
                %Check inputs
                %1. Check that valid model file was passed
                modelC = protocolS(p).model;
                if isempty(modelC)
                    msgbox('Please select model files','Plot models');
                    close(hWait);
                    return
                end
                %2. Check for valid structure & dose plan
                %             isStr = cellfun(@(x)any(~isfield(x,'strNum') | isempty(x.strNum) | x.strNum==0),modelC,'un',0);
                %             err = find([isStr{:}]);
                %             if ~isempty(err)
                %                 msgbox(sprintf('Please select structure:\n protocol: %d\tmodels: %d',p,err),'Plot model');
                %                 close(hWait);
                %                 return
                %             end
                isPlan = isfield(ud,'planNum') && ~isempty(ud.planNum);
                if ~isPlan
                    msgbox(sprintf('Please select valid dose plan.'),'Plot model');
                    close(hWait);
                    return
                end
                %Check for existing handles to criteria
                if ~isfield(protocolS(p),'criteria')
                    protocolS(p).criteria = [];
                end
                if ~isfield(protocolS(p),'guidelines')
                    protocolS(p).guidelines = [];
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
                    lineStyle = lineStyleC{p-1};
                end

                %Scale planned dose array
                plnNum = ud.planNum;
                numFrxProtocol = protocolS(p).numFractions;
                protDose = protocolS(p).totalDose;
                dpfProtocol = protDose/numFrxProtocol;
                %prescribedDose = planC{indexS.dose}(plnNum).prescribedDose;
                dA = getDoseArray(plnNum,planC);
                dAscale = protDose/prescribedDose;
                dAscaled = dA * dAscale;
                planC{indexS.dose}(plnNum).doseArray = dAscaled;

                % Plot model-based predictions
                availableStructsC = {planC{indexS.structures}.structureName};
                if plotMode==1 || plotMode==2
                    modTypeC = cellfun(@(x)(x.type),modelC,'un',0);
                    modIdxV = find(strcmp(modTypeC,'NTCP'));
                    numModels = length(modIdxV);
                    numModelsV(p) = numModels;
                else
                    numModels = numModelsV(p);
                    modIdxV = 1:numModels;
                end

                for j = 1:numModels
                    %Create parameter dictionary
                    paramS = [modelC{modIdxV(j)}.parameters];
                    structNumV = modelC{modIdxV(j)}.strNum;
                    structNumV(structNumV==0)=[];  %test
                    %Copy relevant fields from protocol file
                    %-No. of fractions
                    paramS.numFractions.val = numFrxProtocol;
                    %-fraction size
                    paramS.frxSize.val = dpfProtocol;
                    %-alpha/beta
                    if isfield(modelC{modIdxV(j)},'abRatio')
                        abRatio = modelC{modIdxV(j)}.abRatio;
                        paramS.abRatio.val = abRatio;
                    end

                    %Scale dose bins
                    if isfield(modelC{modIdxV(j)},'dv')
                        storedDVc = modelC{modIdxV(j)}.dv;
                        doseBinsC = storedDVc{1} ;
                        volHistC = storedDVc{2};
                    else

                        doseBinsC = cell(1,numel(structNumV));
                        volHistC = cell(1,numel(structNumV));
                        for nStr = 1:numel(structNumV)
                            [dosesV,volsV] = getDVH(structNumV(nStr),plnNum,planC);
                            [doseBinsC{nStr},volHistC{nStr}] = doseHist(dosesV,volsV,binWidth);
                        end
                        modelC{modIdxV(j)}.dv = {doseBinsC,volHistC};
                    end
                    if plotMode==3 %vs. scaled frx size
                        scaledCPv = xScaleV * 0;
                        for n = 1 : numel(xScaleV)

                            %Scale dose bins
                            scaleV = xScaleV(n);
                            scaledDoseBinsC = cellfun(@(x) x*scaleV,doseBinsC,'un',0);

                            %Apply fractionation correction as required
                            correctedScaledDoseC = frxCorrectROE(modelC{modIdxV(j)},structNumV,numFrxProtocol,scaledDoseBinsC);

                            %Correct frxSize parameter
                            paramS.frxSize.val = scaleV*dpfProtocol;

                            %Compute TCP/NTCP
                            if numel(structNumV)==1
                                scaledCPv(n) = feval(modelC{modIdxV(j)}.function,paramS,correctedScaledDoseC{1},volHistC{1});
                            else
                                scaledCPv(n) = feval(modelC{modIdxV(j)}.function,paramS,correctedScaledDoseC,volHistC);
                            end

                            %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                            if n==numel(xScaleV)
                                %Get corrected dose at scale == 1
                                paramS.frxSize.val = dpfProtocol;
                                if any(structNumV)
                                    testDoseC = frxCorrectROE(modelC{modIdxV(j)},structNumV,numFrxProtocol,doseBinsC);
                                    %Display mean dose, EUD, GTD(if applicable)
                                    outType = modelC{modIdxV(j)}.type;
                                    testMeanDose = calc_meanDose(testDoseC{1},volHistC{1});
                                    if isfield(paramS,'n')
                                        temp_a = 1/paramS.n.val;
                                        testEUD = calc_EUD(testDoseC{1},volHistC{1},temp_a);
                                        fprintf(['\n---------------------------------------\n',...
                                            'Protocol:%d, Model:%d\nMean Dose = %f\n%s = %f\n'],p,modIdxV(j),testEUD);
                                    end
                                    if strcmp(modelC{modIdxV(j)}.name,'Lung TCP')
                                        additionalParamS = paramS.structures.GTV.gTD.params;
                                        for fn = fieldnames(additionalParamS)'
                                            paramS.(fn{1}) = additionalParamS.(fn{1});
                                        end
                                        testGTD = calc_gTD(testDoseC{1},volHistC{1},paramS);
                                        fprintf(['\n---------------------------------------\n',...
                                            'GTD  = %f'],testGTD);
                                    end
                                    %Display TCP/NTCP
                                    if numel(testDoseC)>1
                                        testOut = feval(modelC{modIdxV(j)}.function,paramS,testDoseC,volHistC);
                                    else
                                        testOut = feval(modelC{modIdxV(j)}.function,paramS,testDoseC{1},volHistC{1});
                                    end
                                    fprintf(['\n---------------------------------------\n',...
                                        'Protocol:%d, Model:%d\nMean Dose = %f\n%s = %f\n'],p,modIdxV(j),testMeanDose,outType,testOut);
                                end
                            end
                            %---------------------------------END TEMP-----------------------------------%
                        end
                        set(hSlider,'Value',1);
                        set(hSlider,'Visible','On');
                        ud.handle.modelsAxis(6) = hSlider;

                    else %Scale by no. fractions (plot modes : 1,2,4)

                        xScaleV = nfrxScaleV(nfrxScaleV+numFrxProtocol>=1);
                        scaledCPv = xScaleV * 0;
                        for n = 1 : numel(xScaleV)

                            %Scale dose bins
                            newNumFrx = xScaleV(n) + numFrxProtocol;
                            scaleV = newNumFrx/numFrxProtocol;
                            scaledDoseBinsC = cellfun(@(x) x*scaleV,doseBinsC,'un',0);

                            %Apply fractionation correction as required
                            correctedScaledDoseC = frxCorrectROE(modelC{j},structNumV,newNumFrx,scaledDoseBinsC);

                            %Correct nFrx parameter
                            paramS.numFractions.val = newNumFrx;

                            %% Compute NTCP
                            if numel(structNumV)==1
                                scaledCPv(n) = feval(modelC{j}.function,paramS,correctedScaledDoseC{1},volHistC{1});
                            else
                                scaledCPv(n) = feval(modelC{j}.function,paramS,correctedScaledDoseC,volHistC);
                            end

                            %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                            if n==numel(nfrxScaleV)
                                %Get corrected dose at scale == 1
                                paramS.numFractions.val = numFrxProtocol;
                                testDoseC = frxCorrectROE(modelC{j},structNumV,numFrxProtocol,doseBinsC);
                                %Display mean dose, EUD, GTD(if applicable)
                                outType = modelC{j}.type;
                                if isfield(paramS,'n')
                                    temp_a = 1/paramS.n.val;
                                    testEUD = calc_EUD(testDoseC{1},volHistC{1},temp_a);
                                end
                                testMeanDose = calc_meanDose(testDoseC{1},volHistC{1});
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
                                if numel(testDoseC)>1
                                    testOut = feval(modelC{j}.function,paramS,testDoseC,volHistC);
                                else
                                    testOut = feval(modelC{j}.function,paramS,testDoseC{1},volHistC{1});
                                end
                                fprintf(['\n---------------------------------------\n',...
                                    'Protocol:%d, Model:%d\nMean dose = %f\n%s = %f\n'],p,j,testMeanDose,outType,testOut);
                            end
                            %---------------------------------END TEMP-----------------------------------%
                        end
                        step = 2*maxDeltaFrx;
                        set(hSlider,'Min',-maxDeltaFrx,'Max',maxDeltaFrx,'SliderStep',[1/step,1/step]);
                        set(hSlider,'Value',0);
                        set(hSlider,'Visible','On');
                        ud.handle.modelsAxis(7) = hSlider;
                    end

                    %% Plot NTCP vs.TCP/BED
                    %Set plot color
                    colorIdx = mod(j,size(plotColorM,1)) + 1;
                    %Display curves
                    if plotMode==1 || plotMode ==2
                        if strcmp(modelC{j}.type,'NTCP')
                            ntcp = ntcp + 1;
                            if plotMode == 1
                                xLmt = get(hNTCPAxis,'xlim');
                                set(hNTCPAxis,'xlim',[min(xLmt(1),tcpM(p,1)), max(xLmt(2),tcpM(p,end))]);
                            else
                                set(hNTCPAxis,'xlim',[0,1]);
                            end
                            tcpV = tcpM(p,:);
                            ud.NTCPCurve = [ud.NTCPCurve plot(hNTCPAxis,tcpV(~isnan(tcpV)),scaledCPv,'linewidth',3,...
                                'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];

                            ud.NTCPCurve(ntcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{modIdxV(j)}.name];
                            hCurr = hNTCPAxis;
                        end

                    else %plotModes 3&4

                        if plotMode == 4
                            set(hNTCPAxis,'xLim',[-maxDeltaFrx,maxDeltaFrx]);
                            set(hTCPAxis,'xLim',[-maxDeltaFrx,maxDeltaFrx]);
                        end

                        if strcmp(modelC{j}.type,'NTCP')
                            ntcp = ntcp + 1;
                            ud.NTCPCurve = [ud.NTCPCurve plot(hNTCPAxis,xScaleV,scaledCPv,'linewidth',3,...
                                'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                            ud.NTCPCurve(ntcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                            hCurr = hNTCPAxis;
                        elseif strcmp(modelC{j}.type,'TCP')
                            tcp = tcp + 1;
                            ud.TCPCurve = [ud.TCPCurve plot(hTCPAxis,xScaleV,...
                                scaledCPv,'linewidth',3,'Color',...
                                plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                            ud.TCPCurveDots = [ud.TCPCurveDots plot(hTCPAxis,...
                                xScaleV,scaledCPv,'linewidth',2,'Color','w',...
                                'lineStyle',':')];
                            ud.TCPCurve(tcp).DisplayName = ...
                                [ud.Protocols(p).protocol,': ',modelC{j}.name];
                            hCurr = hTCPAxis;
                            %                       ud.axisHighlight = line(hTCPAxis,1.5*ones(1,11),0:0.1:1,'linewidth',2,...
                            %                             'color',plotColorM(colorIdx,:));
                        elseif strcmp(modelC{j}.type,'BED')
                            bed = bed + 1;
                            ud.BEDCurve = [ud.BEDCurve plot(hTCPAxis,xScaleV,...
                                scaledCPv,'linewidth',3,'Color',...
                                plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                            ud.BEDCurveDots = [ud.BEDCurveDots plot(hTCPAxis,...
                                xScaleV,scaledCPv,'linewidth',2,'Color','w',...
                                'lineStyle',':')];
                            ud.BEDCurve(bed).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                            hCurr = hTCPAxis;
                            %                       ud.axisHighlight =line(hTCPAxis,zeros(1,11),0:20:200,'linewidth',2,...
                            %                             'color',plotColorM(colorIdx,:));
                        end
                    end
                    jTot = jTot + 1; %No. of models displayed
                    waitbar(j/sum(numModelsV));
                end
                %% Store model parameters
                %protocolS(p).model = modelC;


                %% Plot criteria & guidelines
                if plotMode==3 %vs. scaled frx size
                    cgScaleV = xScaleV;
                else
                    nFrxV = xScaleV + numFrxProtocol;
                    cgScaleV = nFrxV./numFrxProtocol;
                end


                if isfield(protocolS(p),'constraints')
                    critS = protocolS(p).constraints;
                    nFrxProtocol = protocolS(p).numFractions;
                    structC = fieldnames(critS.structures);

                    %Loop over structures
                    for m = 1:numel(structC)
                        conStr = find(strcmpi(structC{m}, availableStructsC));
                        %------------ Loop over guidelines --------------------
                        %Extract guidelines
                        if ~isempty(conStr) && isfield(critS.structures.(structC{m}),'guidelines')
                            strGuideS = critS.structures.(structC{m}).guidelines;
                            guidelinesC = fieldnames(strGuideS);

                            %Get alpha/beta ratio
                            if isfield(critS.structures.(structC{m}),'abRatio')
                                abRatio = critS.structures.(structC{m}).abRatio;
                            else
                                abRatio = [];
                            end
                            %Get DVH
                            [doseV,volsV] = getDVH(conStr,plnNum,planC);
                            [doseBinV,volHistV] = doseHist(doseV, volsV, binWidth);
                            dvAvailable = 1;
                            for n = 1:length(guidelinesC)

                                %Idenitfy NTCP limits
                                if strcmp(strGuideS.(guidelinesC{n}).function,'ntcp')

                                    %Get NTCP over range of scale factors
                                    strC = cellfun(@(x) x.strNum,modelC,'un',0);
                                    %find([strC{:}]==cStr);
                                    gIdx = [];
                                    for gStr = 1:length(modelC)
                                        if ismember(conStr,strC{gStr})
                                            gIdx = gStr;
                                            break;
                                        end
                                    end

                                    if p == 1
                                        gProtocolStart(p) = 0;
                                    else
                                        prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                        prevIdxV = strcmpi('ntcp',prevC);
                                        gProtocolStart(p) = sum(prevIdxV);
                                    end
                                    if ~isempty(gIdx)
                                        xV = ud.NTCPCurve(gProtocolStart(p)+...
                                            gIdx).XData;

                                        %Identify where guideline is exceeded
                                        ntcpV = ud.NTCPCurve(gProtocolStart(p) + ...
                                            gIdx).YData;
                                        exceedIdxV = ntcpV >= strGuideS.(guidelinesC{n}).limit;
                                        gCount = gCount +  1;
                                        if ~any(exceedIdxV)
                                            gValV(gCount) = inf;
                                            gScaleV(gCount) = inf;
                                            gXv(gCount) = inf;
                                        else
                                            exceedIdxV = find(exceedIdxV,1,'first');
                                            gValV(gCount) = ntcpV(exceedIdxV);
                                            gScaleV(gCount) = cgScaleV(exceedIdxV);
                                            ind =  cgScaleV == gScaleV(gCount);
                                            gXv(gCount) = xV(ind);
                                            clr = [239 197 57]./255;
                                            if p==ud.foreground
                                                ud.gMarker = [ud.cMarker,...
                                                    plot(hNTCPAxis,gXv(gCount),...
                                                    gValV(gCount),'o',...
                                                    'MarkerSize',8,...
                                                    'MarkerFaceColor',...
                                                    clr,'MarkerEdgeColor','k')];
                                            else
                                                addMarker = scatter(hNTCPAxis,...
                                                    gXv(gCount),gValV(gCount),...
                                                    60,'MarkerFaceColor',clr,...
                                                    'MarkerEdgeColor','k');
                                                addMarker.MarkerFaceAlpha = .3;
                                                addMarker.MarkerEdgeAlpha = .3;
                                                ud.gMarker = [ud.cMarker,addMarker];
                                            end
                                        end
                                    else
                                        gCount = gCount + 1;
                                        gScaleV(gCount) = inf;
                                        gValV(gCount) = -inf;
                                    end

                                    %Get guideline label
                                    gLabel = strtok(strGuideS.(guidelinesC{n}).parameters.modelFile,'.');
                                else
                                    if p == 1
                                        gProtocolStart(p) = 0;
                                    else
                                        prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                        prevIdxV = strcmpi('ntcp',prevC);
                                        gProtocolStart(p) = sum(prevIdxV);
                                    end
                                    xV = ud.NTCPCurve(gProtocolStart(p) + 1).XData;
                                    %Idenitfy dose/volume limits
                                    gCount = gCount + 1;
                                    %nFrx = planC{indexS.dose}(plnNum).numFractions;
                                    [gScaleV(gCount),gValV(gCount)] = ...
                                        calcLimitROE(doseBinV,volHistV,...
                                        strGuideS.(guidelinesC{n}),...
                                        nFrxProtocol,critS.numFrx,abRatio,cgScaleV);

                                    %Get guideline label
                                    gLabel = guidelinesC{n};
                                end

                                %Display line indicating clinical criteria/guidelines
                                if isinf(gScaleV(gCount))
                                    gXv(gCount) = inf;
                                else
                                    ind = cgScaleV == gScaleV(gCount);
                                    gXv(gCount) = xV(ind);
                                end
                                x = [gXv(gCount) gXv(gCount)];
                                y = [0 1];
                                if p==ud.foreground
                                    guideLineH = line(hNTCPAxis,x,y,'LineWidth',1,...
                                        'Color',[239 197 57]/255,'LineStyle','--',...
                                        'Tag','guidelines','Visible','Off');
                                else
                                    guideLineH = line(hNTCPAxis,x,y,'LineWidth',1.5,...
                                        'Color',[239 197 57]/255,'LineStyle',':',...
                                        'Tag','guidelines','Visible','Off');
                                end
                                guideLineUdS.protocol = p;
                                guideLineUdS.structure = structC{m};
                                guideLineUdS.label = gLabel;
                                guideLmt = strGuideS.(guidelinesC{n}).limit;
                                guideLineUdS.limit = guideLmt(1);
                                guideLineUdS.scale = gScaleV(gCount);
                                guideLineUdS.val = gValV(gCount);
                                set(guideLineH,'userdata',guideLineUdS);
                                protocolS(p).guidelines = [protocolS(p).guidelines,guideLineH];
                            end
                        else

                            dvAvailable = 0;
                        end
                        %----- Loop over hard constraints--------

                        %If structure & clinical criteria are available
                        if ~isempty(conStr) && ...
                                isfield(critS.structures.(structC{m}),'criteria')
                            strCritS = critS.structures.(structC{m}).criteria;
                            criteriaC = fieldnames(strCritS);

                            if ~dvAvailable
                                %Get alpha/beta ratio
                                abRatio = critS.structures.(structC{m}).abRatio;
                                %Get DVH
                                [doseV,volsV] = getDVH(conStr,plnNum,planC);
                                [doseBinV,volHistV] = doseHist(doseV, volsV, binWidth);
                            end

                            for n = 1:length(criteriaC)

                                %Idenitfy NTCP limits
                                if strcmp(strCritS.(criteriaC{n}).function,'ntcp')

                                    %Get NTCP over entire scale
                                    strC = cellfun(@(x) x.strNum,modelC,'un',0);
                                    %cIdx = find([strC{:}]==cStr);
                                    cIdx = [];
                                    for cStr = 1:length(modelC)
                                        if ismember(conStr,strC{cStr})
                                            cIdx = cStr;
                                            break;
                                        end
                                    end

                                    if p == 1
                                        cProtocolStart(p) = 0;
                                    else
                                        prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                        prevIdxV = strcmpi('ntcp',prevC);
                                        cProtocolStart(p) = sum(prevIdxV);
                                    end

                                    if ~isempty(cIdx)
                                        xV = ud.NTCPCurve(cProtocolStart(p) + ...
                                            cIdx).XData;

                                        %Identify where limit is exceeded
                                        ntcpV = ud.NTCPCurve(cProtocolStart(p) + ...
                                            cIdx).YData;
                                        cCount = cCount + 1;
                                        exceedIdxV = ntcpV >= strCritS.(criteriaC{n}).limit;
                                        if ~any(exceedIdxV)
                                            cValV(cCount) = inf;
                                            cScaleV(cCount) = inf;
                                            cXv(cCount) = inf;
                                        else
                                            exceedIdxV = find(exceedIdxV,1,'first');
                                            cValV(cCount) = ntcpV(exceedIdxV);
                                            cScaleV(cCount) = cgScaleV(exceedIdxV);
                                            ind = cgScaleV == cScaleV(cCount);
                                            cXv(cCount) = xV(ind);
                                            if p==ud.foreground
                                                ud.cMarker = [ud.cMarker,...
                                                    plot(hNTCPAxis,cXv(cCount),...
                                                    cValV(cCount),'o',...
                                                    'MarkerSize',8,...
                                                    'MarkerFaceColor',...
                                                    'r','MarkerEdgeColor','k')];
                                            else
                                                addMarker = scatter(hNTCPAxis,...
                                                    cXv(cCount),cValV(cCount),...
                                                    60,'MarkerFaceColor','r',...
                                                    'MarkerEdgeColor','k');
                                                addMarker.MarkerFaceAlpha = .3;
                                                addMarker.MarkerEdgeAlpha = .3;
                                                ud.cMarker = [ud.cMarker,addMarker];
                                            end
                                        end
                                    else
                                        cCount = cCount + 1;
                                        cScaleV(cCount) = inf;
                                        cValV(cCount) = -inf;
                                    end

                                    %Get crit label
                                    cLabel = strtok(strCritS.(criteriaC{n}).parameters.modelFile,'.');
                                else

                                    if p == 1
                                        cProtocolStart(p) = 0;
                                    else
                                        prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                        prevIdxV = strcmpi('ntcp',prevC);
                                        cProtocolStart(p) = sum(prevIdxV);
                                    end
                                    xV = ud.NTCPCurve(cProtocolStart(p) + 1).XData;

                                    %Idenitfy dose/volume limits
                                    cCount = cCount + 1;
                                    %nFrx = planC{indexS.dose}(plnNum).numFractions;
                                    [cScaleV(cCount),cValV(cCount)] = ...
                                        calcLimitROE(doseBinV,volHistV,...
                                        strCritS.(criteriaC{n}),...
                                        nFrxProtocol,critS.numFrx,abRatio,cgScaleV);

                                    %Get crit label
                                    cLabel = criteriaC{n};
                                end

                                %Display line indicating clinical criteria/guidelines
                                if isinf(cScaleV(cCount))
                                    cXv(cCount) = inf;
                                    x = [cXv(cCount) cXv(cCount)];
                                else
                                    ind = cgScaleV == cScaleV(cCount);
                                    cXv(cCount) = xV(ind);
                                    x = [cXv(cCount) cXv(cCount)];
                                end
                                y = [0 1];
                                %Set criteria line transparency
                                if p==ud.foreground
                                    critLineH = line(hNTCPAxis,x,y,'LineWidth',...
                                        1,'Color',[1 0 0],'LineStyle','--',...
                                        'Tag','criteria','Visible','Off');
                                else
                                    critLineH = line(hNTCPAxis,x,y,'LineWidth',...
                                        1.5,'Color',[1 0 0 alpha],'LineStyle',...
                                        ':','Tag','criteria','Visible','Off');
                                end
                                critLineUdS.protocol = p;
                                critLineUdS.structure = structC{m};
                                critLineUdS.label = cLabel;
                                critLineUdS.limit = strCritS.(criteriaC{n}).limit;
                                critLineUdS.scale = cScaleV(cCount);
                                critLineUdS.val = cValV(cCount);
                                set(critLineH,'userdata',critLineUdS);
                                protocolS(p).criteria = [protocolS(p).criteria,critLineH];
                            end
                        end
                    end
                end
                planC{indexS.dose}(plnNum).doseArray = dA;
                if p>1
                    protocolS(p).origModel = ud.Protocols(p).model;
                    ud.Protocols(p) = protocolS(p);
                else
                    ud.Protocols(p) = protocolS(p);
                    ud.Protocols(p).origModel = ud.Protocols(p).model;
                end
                ud.Protocols(p).model = modelC;
            end

            close(hWait);

            %Add plot labels
            ylabel(hNTCPAxis,'NTCP','fontsize',fontSize);
            if plotMode == 1
                xlabel(hNTCPAxis,'BED (Gy)','fontsize',fontSize);
            elseif plotMode == 2
                xlabel(hNTCPAxis,'TCP','fontsize',fontSize);
            else
                xlabel(hNTCPAxis,xlab,'fontsize',fontSize);
            end

            %Add legend
            NTCPLegendC = arrayfun(@(x)x.DisplayName,ud.NTCPCurve,'un',0);
            hax = ud.NTCPCurve;
            key = NTCPLegendC;
            legFontSize = ud.FigSettings.lgFontSize;    

            constraintS = protocolS(ud.foreground);
            if isfield(constraintS,'criteria') && ~isempty(constraintS.criteria)
                if isempty(ud.BEDCurve)
                    if isfield(ud,'TCPCurve') && ~isempty(ud.TCPCurve)
                        TCPlegendC = arrayfun(@(x)x.DisplayName,ud.TCPCurve,'un',0);
                        hax = [hax,ud.TCPCurve];
                        key = [key,TCPlegendC];
                    end
                    if isfield(constraintS,'guidelines') && ~isempty(constraintS.guidelines)
                        hax = [hax,constraintS.criteria(end),constraintS.guidelines(end)];
                        key = [key,'Clinical limits','Clinical guidelines'];
                    else
                        hax = [hax,constraintS.criteria(end)];
                        key = [key,'Clinical limits'];
                    end
                else
                    if isfield(constraintS,'guidelines') && ~isempty(constraintS.guidelines)
                        BEDlegendC = arrayfun(@(x)x.DisplayName,ud.BEDCurve,'un',0);
                        hax = [hax,ud.BEDCurve,constraintS.criteria(end),constraintS.guidelines(end)];
                        key = [key,BEDlegendC,'Clinical limits','Clinical guidelines'];
                    else
                        BEDlegendC = arrayfun(@(x)x.DisplayName,ud.BEDCurve,'un',0);
                        hax = [hax,ud.BEDCurve,constraintS.criteria(end)];
                        key = [key,BEDlegendC,'Clinical limits'];
                    end
                end
                [legH,lineObjH] = legend(hax,key,'Location','northwest',...
                    'Color','none','FontName','Arial','FontWeight',...
                    'normal','FontSize',legFontSize,'AutoUpdate','off');

            else
                [legH,lineObjH] = legend(hax,key,'Location','northwest',...
                    'Color','none','FontName','Arial','FontWeight',...
                    'normal','FontSize',legFontSize,'AutoUpdate','off');

            end

            %% Toggle model visibility
            iconH = findobj(lineObjH,'Type','Line');
            tagC = arrayfun(@(x) x.Tag,iconH,'un',0);
            tcpIdx = cellfun(@(x) ~isempty(strfind(x,'TCP')),...
                tagC) | cellfun(@(x) ~isempty(strfind(x,'BED')),tagC);
            set(iconH(tcpIdx),'LineStyle',':');

            %Store userdata
            ud.handle.legend = legH;
            guidata(hFig,ud);

            %Display current dose/probability
            guidata(hFig,ud);
            scaleDoseROE(hSlider,[],hFig);
            ud = guidata(hFig);

            %Copy dvs and store original model info
            for p = 1:length(ud.Protocols)
                origModC = ud.Protocols(p).origModel;
                origModNameC = cellfun(@(x)x.name,origModC,'un',0);
                modelC = ud.Protocols(p).model;
                for m = 1:length(modelC)
                    modIdx = strcmp(modelC{m}.name,origModNameC);
                    origModC{modIdx}.dv = modelC{m}.dv;
                end
                ud.Protocols(p).model = origModC;
                rmfield(ud.Protocols(p),'origModel');
            end

            %Enable user-entered scale entry
            set(ud.handle.modelsAxis(9),'enable','On');


            %Populate constraints table
            guidata(hFig,ud);
            [structsC,numCriteria,numGuide,limC,typeC] = ...
                getConstraintsForDisplayROE(hFig);
            ud = guidata(hFig);
            data(:,1) = num2cell(false(numCriteria + numGuide,1));
            data(:,2) = structsC(:);
            data(:,3) = limC(:);
            data = [{false},{'All'},{' '};{false},{'None'},{' '};data];
            uiTabH = ud.handle.tab2H(5);
            set(uiTabH,'data',data,'userdata',typeC)
            ud.ConstraintsInit = 1;

            %Get datacursor mode
            guidata(hFig,ud);
            if ~isempty([protocolS.criteria])
                cursorMode = datacursormode(hFig);
                set(cursorMode,'Enable','On');

                legH = ud.handle.legend;

                %Display first clinical criterion/guideline that is violated
                for p = 1:numel(ud.Protocols)

                    hcFirst =[];
                    hgFirst = [];

                    if p==1
                        i1 = 1;
                        j1 = 1;
                    else
                        i1 = length([protocolS(1:p-1).criteria]) + 1;
                        j1 = length([protocolS(1:p-1).guidelines]) + 1;
                    end

                    if ~isempty([protocolS(p).criteria])
                        i2 = length([protocolS(p).criteria]);
                        firstcViolation = cXv(i1:i1+i2-1) == min(cXv(i1:i1+i2-1));
                        %firstcViolation = find(firstcViolation)  i1;
                        critH = [protocolS(p).criteria];
                        hcFirst = critH(firstcViolation);
                    end

                    if ~isempty([protocolS(p).guidelines])
                        j2 = length([protocolS(p).guidelines]);
                        firstgViolation = gXv(j1:j1+j2-1)==min(gXv(j1:j1+j2-1));
                        %firstgViolation = find(firstgViolation)  i1;
                        guidH = [protocolS(p).guidelines];
                        hgFirst = guidH(firstgViolation);
                    end

                    if isempty(hcFirst) && isempty(hgFirst)
                        %Skip
                    elseif(~isempty(hcFirst) && isempty(hgFirst)) || hcFirst(1).XData(1)<= hgFirst(1).XData(1)
                        %firstcViolation = [false(1:i1-1),firstcViolation];
                        dttag = 'criteria';
                        dispSelCriteriaROE([],[],hFig,dttag,firstcViolation,p);

                        hDatatip = createDataTipROE(hFig,hcFirst(1));
                        ud = guidata(hFig);
                        set(hDatatip,'Tag',dttag);

                        constDatC = get(ud.handle.tab2H(5),'data');
                        strMatchIdx = strcmpi(constDatC(:,2),...
                            hcFirst(1).UserData.structure);
                        metricMatchIdx = strcmpi(constDatC(:,3),...
                            hcFirst(1).UserData.label);
                        selMatchIdx = strMatchIdx & metricMatchIdx;
                        constDatC{selMatchIdx,1} = true;
                        set(ud.handle.tab2H(5),'data',constDatC);

                        %Enable legend entry for constraints
                        drawnow;
                        legH.EntryContainer.NodeChildren(2).Label.Color = [0,0,0];
                    else
                        %firstgViolation = [false(1:j1-1),firstgViolation];
                        dttag = 'guidelines';
                        dispSelCriteriaROE([],[],hFig,dttag,firstgViolation,p);

                        hDatatip = createDataTipROE(hFig,hgFirst(1));
                        set(hDatatip,'Tag',dttag);
                        ud = guidata(hFig);

                        constDatC = get(ud.handle.tab2H(5),'data');
                        strMatchIdx = strcmpi(constDatC(:,2),...
                            hgFirst(1).UserData.structure);
                        metricMatchIdx = strcmpi(constDatC(:,3),...
                            [hgFirst(1).UserData.label,' (guideline)']);
                        selMatchIdx = strMatchIdx & metricMatchIdx;
                        constDatC{selMatchIdx,1} = true;
                        set(ud.handle.tab2H(5),'data',constDatC);

                        %Enable legend entry for guidelines
                        drawnow;
                        legH.EntryContainer.NodeChildren(1).Label.Color = [0,0,0];
                    end

                end

                if ~isfield(ud.handle,'datatips')
                    ud.handle.datatips = hDatatip;
                end

                %Set datacursor update function
                set(cursorMode, 'Enable','On','SnapToDataVertex','off',...
                    'UpdateFcn',@(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                % set(cursorMode,'Enable','Off');

                ud.handle.legend = legH;
            end

            %Make labels draggable
            for nLabel = 1:length(ud.y1Disp)
                hLabel = ud.y1Disp(nLabel);
                draggable(hLabel, "v", [0.01 0.1]);
            end
            if isfield(ud,'y2Disp') && ~isempty(ud.y2Disp)
                for nLabel = 1:length(ud.y2Disp)
                    hLabel = ud.y2Disp(nLabel);
                    draggable(hLabel, "v", [0.01 0.1]);
                end
            end
            %Enable data label toggle control
            set(ud.handle.modelsAxis(11),'Visible','On');

            guidata(hFig,ud);


        case 'CLEAR_PLOT'
            ud = guidata(hFig);
            %Clear data/plots from any previously loaded models/plans/structures
            ud.NTCPCurve = [];
            ud.TCPCurve = [];
            ud.TCPCurveDots = [];
            ud.BEDCurveDots = [];
            ud.BEDCurve = [];
            protocolS = ud.Protocols;
            for p = 1:numel(protocolS)
                protocolS(p).criteria = [];
                protocolS(p).guidelines = [];
                % TEMP: Fix by checking prev/curr plot mode differnt instead
                for m = 1:length(protocolS(p).model)
                    if isfield(protocolS(p).model{m},'dv')
                        protocolS(p).model{m} = rmfield(protocolS(p).model{m},'dv');
                    end
                end
            end
            ud.Protocols = protocolS;
            for ax = 1:5
                cla(ud.handle.modelsAxis(ax));
                legend(ud.handle.modelsAxis(ax),'off')
                set(ud.handle.modelsAxis(ax),'Visible','Off');
            end


            %Clear text readouts
            if isfield(ud,'scaleDisp')
                ud = rmfield(ud,'scaleDisp');
            end
            if isfield(ud,'y1Disp')
                ud = rmfield(ud,'y1Disp');
            end
            if isfield(ud,'y2Disp')
                ud = rmfield(ud,'y2Disp');
            end

            %Clear user-input scale factor/no. frx
            set(ud.handle.modelsAxis(9),'String','')


            %Clear datatips
            constDatC = get(ud.handle.tab2H(5),'data');
            constDatC(:,1) = {false};
            set(ud.handle.tab2H(5),'data',constDatC);
            miscFieldsC = {'datatips','axisHighlight'};
            for f = 1:length(miscFieldsC)
                if isfield(ud.handle,miscFieldsC{f})
                    ud.handle = rmfield(ud.handle,miscFieldsC{f});
                end
            end


            %Turn off datacursor mode
            cursorMode = datacursormode(hFig);
            cursorMode.removeAllDataCursors;
            set(cursorMode, 'Enable','Off');

            %turn slider display off
            set(ud.handle.modelsAxis(6),'Visible','Off');
            set(ud.handle.modelsAxis(7),'Visible','Off');
            set(ud.handle.modelsAxis(9),'enable','Off');
            set(ud.handle.modelsAxis(11),'Visible','Off');
            guidata(hFig,ud);

        case 'LIST_MODELS'
            %Get selected protocols
            ud = guidata(hFig);
            ud.handle.editModels = [];
            protocolS = ud.Protocols;
            currProtocol = get(gcbo,'Value');
            ud.PrtcNum = currProtocol;

            %Check models for required fields ('function' and 'parameter')
            numProtocols = length(protocolS);
            for j = 1:numProtocols
                modelC = protocolS(j).model;
                numModels = length(modelC);

                for i = 1:numModels
                    %modelNameC = cell(1,numModels);
                    fieldC = fieldnames(modelC{i});
                    fnIdx = strcmpi(fieldC,'function');
                    paramIdx = strcmpi(fieldC,'parameters');

                    %Check for 'function' and 'parameter' fields
                    if ~any(fnIdx) || isempty(modelC{i}.(fieldC{fnIdx}))
                        msgbox('Model file must include ''function'' attribute.','Model file error');
                        return
                    end
                    if ~any(paramIdx) || isempty(modelC{i}.(fieldC{paramIdx}))
                        msgbox('Model file must include ''parameters'' attribute.','Model file error');
                        return
                    end

                    %Check for 'structures' field
                    strIdx = strcmpi(fieldnames(modelC{i}.parameters),'structures');
                    if ~any(strIdx) || isempty(modelC{i}.parameters.structures)
                        msgbox('Model file must include ''parameters'' attribute.','Model file error');
                        return
                    end

                end
            end

            set(ud.modelTree,'Visible',true);
            set(ud.handle.tab1H(9),'Enable','On'); %Plot button on
            %set(ud.handle.tab1H(11),'Enable','On'); %Allow x-axis selection
            %set(ud.handle.tab1H(12),'Enable','On'); %Allow y-axis selection
            guidata(hFig,ud);

            %% Expand model tree
            mtree = ud.modelTree;
            root = mtree.Root;
            mtree.setSelectedNode(root);
            hEvt.getCurrentNode = root;
            getParamsROE(mtree,hEvt,hFig,planC);
            protocolNodes = root.getNextNode;
            mtree.setSelectedNode(protocolNodes);
            hEvt.getCurrentNode = protocolNodes;
            getParamsROE(mtree,hEvt,hFig,planC);
            ud = guidata(hFig);
            guidata(hFig,ud);

        case 'SAVE_MODELS'
            ud = guidata(hFig);
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

            set(ud.handle.tab1H(8),'Enable','Off');  %Disable save
            guidata(hFig,ud);



        case 'CLOSEREQUEST'

            closereq

        end

end