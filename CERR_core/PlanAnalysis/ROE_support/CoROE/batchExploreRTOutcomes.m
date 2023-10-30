function batchExploreRTOutcomes(cerrPath,varInFile,scaleMode,outFile,optS)
% Batch script for radiotherapy oucomes analysis.
% Usage: batchExploreRTOutcomes(cerrPath,presFile,scaleMode,outFile,optS);
% ------------------------------------------------------------------------------
% Inputs:
% cerrPath  - Path to CERR files
% varInFile - Spreadsheet with pt information (prescribed dose, clinical factors)
%             Format: Required- Row-1: Column names,
%             Col1-CERR file name, Col2-prescribed dose
%             Optional - Col3,4,...-clinical factors.
% scaleMode - 0-Scale no. fractions, 1: Scale fraction size
% outFile   - Output excel filename with path.
% optS      - Structure with paths to protocol , model, criteria files (.json)
%             optS.protocolPath = 'Path/to/JSON/protocols';
%             optS.modelPath = 'Path/to/JSON/models';
%             optS.criteriaPath = 'Path/to/JSON/criteria';
%-------------------------------------------------------------------------------
% AI 01/08/2020

% Define DVH bin width, fraction size range etc
binWidth = .05;
plnNum = 1; %Uses 1st available dose plan by default
numHeaderLines = 4; %For spreadsheet o/p

%% Get list of CERR files
dirS = dir([cerrPath,filesep,'*.mat']);
ptListC = {dirS.name};
anonIdC = cell(1,length(ptListC));
for i = 1:length(anonIdC)
    anonIdC{i} = sprintf('Pt %.2d',i);
end

%% Get list of protcols
protocolPath = optS.protocolPath;
modelPath = optS.modelPath;
criteriaPath = optS.criteriaPath;
pDirS = dir(protocolPath);
pDirS(1:2) = [];
protocolListC = {pDirS.name};

% Create log file
basePath = fileparts(protocolPath);
fid = fopen(fullfile(basePath,'Log.txt'),'w');

%% Get model parameters & clinical constraints
% Cycle through selected protocols
for p = 1:numel(protocolListC)
    % Load protocol info
    protocolFile = fullfile(protocolPath,protocolListC{p});
    protocolInfoS = jsondecode(fileread(protocolFile)); %Load .json for protocol
    % Get list of associated models
    modelListC = fields(protocolInfoS.models);
    numModels = numel(modelListC);
    protocolS(p).modelFiles = [];
    % Load model parameters
    for m = 1:numModels
        protocolS(p).protocol = protocolInfoS.name;
        modelFPath = fullfile(modelPath,protocolInfoS.models.(modelListC{m}).modelFile);
        protocolS(p).model{m} = jsondecode(fileread(modelFPath));
        protocolS(p).modelFiles = [protocolS(p).modelFiles,modelFPath];
        modelName = protocolS(p).model{m}.name;
    end
    % Store models & criteria  for each protocol
    critFile = fullfile(criteriaPath,protocolInfoS.criteriaFile);
    critS = jsondecode(fileread(critFile));
    protocolS(p).numFractions = protocolInfoS.numFractions;
    protocolS(p).totalDose = protocolInfoS.totalDose;
    protocolS(p).criteria = critS;
end
maxDeltaFrx = round(max([protocolS.numFractions])/2); %For mode-0

% Get prescribed dose & clinical factors
[~,~,rawData] = xlsread(varInFile);
fNameC = rawData(2:end,1);
prescribedDoseV = rawData(2:end,2);
prescribedDoseV = [prescribedDoseV{:}];

%% Analyze protocols

% Loop over CERR files
for ptNum = 1:numel(anonIdC)

    fprintf('\nProcessing patient %d...\n',ptNum);

    %Load plan
    fname = fullfile(cerrPath,ptListC{ptNum});
    planC = loadPlanC(fname,tempdir);
    indexS = planC{end};

    %Get patient ID
    H = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders;
    patientID = H.PatientID;

    %Get list of available structures
    availableStructsC = {planC{indexS.structures}.structureName};

    % Loop over protocols
    for p = 1:numel(protocolS)

        % Get protocol details
        numFrxProtocol = protocolS(p).numFractions;
        protDose = protocolS(p).totalDose;
        protFrxSize = protDose/numFrxProtocol;

        % Get prescribed dose
        matchIdxV = strcmp(anonIdC{p},fNameC);
        prescribedDose = prescribedDoseV(matchIdxV);
        protDose = protocolS(p).totalDose;

        %Scale input dose distribution
        dA = getDoseArray(plnNum,planC);
        dAscale = protDose/prescribedDose;
        dAscaled = dA * dAscale;
        planC{indexS.dose}(plnNum).doseArray = dAscaled;


        % Spreadsheet format:
        lineNum = numHeaderLines + (ptNum-1)*numel(protocolS)+p;


        % Get scaling mode
        if scaleMode == 1
            %Scale fraction size
            xScaleV = linspace(0.5,1.5,100);
        else
            %Scale no. fractions
            rangeV = linspace(-maxDeltaFrx,maxDeltaFrx,2*maxDeltaFrx+1);
            rangeV = rangeV(rangeV+numFrxProtocol>=1);
            xScaleV = (rangeV+numFrxProtocol)/numFrxProtocol;
        end

        % Loop over NTCP models
        modelC = protocolS(p).model;
        numModels = numel(modelC);
        firstNTCPViolV = [];
        scaledCPm = nan(numModels,numel(xScaleV));
        mCount = 0;

        for m = 1:numModels

            %Create parameter dictionary
            paramS = [modelC{m}.parameters];
            strC = modelC{m}.parameters.structures;
            if isstruct(strC)
                strC = fieldnames(modelC{m}.parameters.structures);
            end
            
            structNumV = find(strcmpi(strC,availableStructsC));
            if ~isempty(structNumV)
                paramS.structNum = structNumV;

                %Store frx size, num frx, alpha/beta
                paramS.numFractions.val = numFrxProtocol;
                paramS.frxSize.val = protFrxSize;
                if isfield(modelC{m},'abRatio')
                    abRatio = modelC{m}.abRatio;
                    paramS.abratio.val = abRatio;
                end

                %Store required clinical factors
                paramS = addClinicalFactors(paramS,patientID,rawData);

                %Get DVH
                doseBinsC = cell(1,numel(structNumV));
                volHistC = cell(1,numel(structNumV));
                for nStr = 1:numel(structNumV)
                    [dosesV,volsV] = getDVH(structNumV,plnNum,planC);
                    [doseBinsC{nStr},volHistC{nStr}] = doseHist(dosesV,volsV,binWidth);
                end
                modelC{m}.dv = {doseBinsC,volHistC};

                %Record 1st violation of NTCP constraints
                if isstruct(modelC{m}.parameters.structures)
                    modelStr = fieldnames(modelC{m}.parameters.structures);
                    modelStr = modelStr{1};
                else
                    modelStr = modelC{m}.parameters.structures;
                end

                modelFile = modelC{m}.name;
                %limIdx = contains(fieldnames(critS.structures),...
                %    modelStr);

                if strcmpi(modelC{m}.type,'ntcp')
                    limitV = extractNTCPconstraints(critS,modelStr,modelFile);
                    modelC{m}.limit = limitV;

                    start = mCount+1;
                    fin = start+numel(limitV)-1;
                    if scaleMode == 1
                        [ntcpAtLim,scaledCPm(m,:)] = calc_NTCPLimit(paramS,modelC{m},...
                            scaleMode);
                    else
                        [ntcpAtLim,scaledCPm(m,:)] = calc_NTCPLimit(paramS,modelC{m},...
                            scaleMode,maxDeltaFrx);
                    end
                    firstNTCPViolV(start:fin) = ntcpAtLim;
                end

            else
                start = mCount+1;
                fin = start+numel(limitV)-1;
                ntcpAtLim = nan;
                scaledCPm(m,:) = nan;
                firstNTCPViolV(start:fin) = ntcpAtLim;
            end

            %Record limits
            if iscell(strC)
                strName = strC{1};
            else
                strName = strC;
            end
            if fin>start
                violC{start} = [strName,' NTCP guideline'];
                violC{fin} = [strName,' NTCP constraint'];
            else
                violC{start} = [strName,' NTCP constraint'];
            end

            mCount = mCount+numel(limitV);
        end

        %Record violations of dose/volume constraints
        firstCGViolV = [];
        cgValM = [];

        %Get constraints
        critS = protocolS(p).criteria;
        structC = fieldnames(critS.structures);
        stdNumFrx = critS.numFrx; %No. fractions used in defining criteria
        cCount = 0;
        gCount = 0;
        %Loop over structures
        for s = 1:numel(structC)
            cStr = find(strcmpi(structC{s}, availableStructsC));
            if isfield(critS.structures.(structC{s}),'criteria')
                %Extract associated criteria
                strCritS = critS.structures.(structC{s}).criteria;
                criteriaC = fieldnames(strCritS);
                %Get alpha/beta ratio
                abRatio = critS.structures.(structC{s}).abRatio;
                if ~isempty(cStr)              %If structure is available
                    %Get DVH
                    [doseV,volsV] = getDVH(cStr,plnNum,planC);
                    [doseBinV,volHistV] = doseHist(doseV, volsV, binWidth);
                end
                %Loop over criteria
                for n = 1:length(criteriaC)
                    if ~contains(lower(criteriaC{n}),'ntcp')
                        %Idenitfy dose/volume limits
                        critnS = strCritS.(criteriaC{n});
                        critnS.isGuide = 0;
                        limitV = critnS.limit;
                        start = gCount + cCount + 1;
                        fin =   gCount + cCount + numel(limitV);
                        if ~isempty(cStr)
                            %Check availability of associated structures
                            if scaleMode == 1
                                [firstCGViolV(start:fin),cgValM(start:fin,:)] = ...
                                    calc_DVLimit(doseBinV,volHistV,critnS,numFrxProtocol,...
                                    stdNumFrx,abRatio,scaleMode);
                            else
                                [firstCGViolV(start:fin),cgValM(start:fin,:)] = ...
                                    calc_DVLimit(doseBinV,volHistV,critnS,numFrxProtocol,...
                                    stdNumFrx,abRatio,scaleMode,maxDeltaFrx,numFrxProtocol);
                            end
                        else
                            %Skip constraint
                            firstCGViolV(start:fin) = nan;
                            cgValM(start:fin,:) = nan;
                        end
                        %Record constraint name
                        violC([start:fin] + mCount) = {[structC{s},' ',criteriaC{n},...
                            ' constraint']};
                        cCount = cCount + numel(limitV);
                    end
                end
            end

            if isfield(critS.structures.(structC{s}),'guidelines')
                %Extract associated guidelines
                strGuideS = critS.structures.(structC{s}).guidelines;
                guidesC = fieldnames(strGuideS);
                %Get alpha/beta ratio
                abRatio = critS.structures.(structC{s}).abRatio;
                if ~isempty(cStr)
                    %Get DVH
                    [doseV,volsV] = getDVH(cStr,plnNum,planC);
                    [doseBinV,volHistV] = doseHist(doseV, volsV, binWidth);
                end
                %Loop over criteria
                for n = 1:length(guidesC)
                    if ~contains(lower(guidesC{n}),'ntcp')
                        %Idenitfy dose/volume limits
                        guidnS = strGuideS.(guidesC{n});
                        guidnS.isGuide = 1;
                        limitV = guidnS.limit;
                        start = cCount + gCount+1;
                        %fin = cCount + gCount+numel(limitV);
                        fin = start;
                        if ~isempty(cStr)
                            %Check availability of associated structures
                            if scaleMode == 1
                                [firstCGViolV(start:fin),cgValM(start:fin,:)] = ...
                                    calc_DVLimit(doseBinV,volHistV,guidnS,numFrxProtocol,stdNumFrx,...
                                    abRatio,scaleMode);
                            else
                                [firstCGViolV(start:fin),cgValM(start:fin,:)] = ...
                                    calc_DVLimit(doseBinV,volHistV,guidnS,numFrxProtocol,stdNumFrx,...
                                    abRatio,scaleMode,maxDeltaFrx,numFrxProtocol);
                            end

                            if numel(limitV)==2 && limitV(2)>limitV(1) && firstCGViolV(fin)==1
                                if scaleMode==1
                                    tol = mean(diff(xScaleV))/2;
                                    rxIdx = abs(xScaleV-firstCGViolV(fin))<=tol;
                                    cgValM(start:fin,:) = nan;
                                    cgValM(start:fin,rxIdx)= 1;
                                end
                                addStr = 'constraint';
                            else
                                addStr = 'guideline';
                            end
                            violC([start:fin] + mCount) = {[structC{s},' ',guidesC{n},...
                                ' ',addStr]};
                            %gCount = gCount + numel(limitV);
                        else
                            firstCGViolV(start:fin) = nan;
                            cgValM(start:fin,:) = nan;
                            violC([start:fin] + mCount) = {[structC{s},' ',guidesC{n},...
                                ' ','guideline']};
                        end
                        gCount = gCount + 1;

                    end
                end
            end

        end

        %Record details of 1st limit violated
        %Identify 1st violation
        violV = [firstNTCPViolV,firstCGViolV];
        [violV,vOrderV] = sort(violV);

        %Get dose, BED at 1st violation
        modTypesC = cellfun(@(x)x.type,modelC,'un',0);
        BEDIdx = ismember(modTypesC,'BED');
        BEDparS = modelC{BEDIdx}.parameters;
        BEDparS.abRatio.val = modelC{BEDIdx}.abRatio;
        if isinf(violV(1))
            scaleAtLimit1 = -1;
            dLimit1 = -1;
            valM = [scaledCPm;cgValM];
            val1V = repmat(-1,size(valM,1),1);
            firstViol = -1;
            BEDatLimit1 = -1;
        else
            if scaleMode==1
                scaleAtLimit1 = violV(1);
                %--For limit at prescription--
                if scaleAtLimit1==1
                    tol = mean(diff(xScaleV))/2;
                    firstScaleIdxV = abs(xScaleV-scaleAtLimit1)<=tol;
                    prevIdxV = violV==1;
                else
                    firstScaleIdxV = xScaleV == scaleAtLimit1;
                    prevIdxV = violV==xScaleV(firstScaleIdxV);
                end
                %--end prescription limit---
                frxSizeAtLimit =  scaleAtLimit1*protFrxSize;
                dLimit1 = frxSizeAtLimit*numFrxProtocol;
                firstViol = strjoin(violC(vOrderV(violV==scaleAtLimit1)),',');
                 % BED parameter  dictionary
                BEDparS.numFractions.val = numFrxProtocol;
                BEDparS.frxSize.val = frxSizeAtLimit;
                BEDparS.treatmentDays = get tx sched for current scheme
                %Calculate tumor BED at 1st violation
                BEDatLimit1 = calc_BED(BEDparS);
            else
                firstScaleIdxV = xScaleV == violV(1);
                scaleAtLimit1 = rangeV(firstScaleIdxV);
                numFrxAtLimit1 = numFrxProtocol+scaleAtLimit1;
                dLimit1 = protFrxSize*(numFrxAtLimit1);
                firstViol = strjoin(violC(vOrderV(violV==xScaleV(firstScaleIdxV))),',');
                % BED parameter  dictionary
                BEDparS.numFractions.val = numFrxAtLimit1;
                BEDparS.frxSize.val = protFrxSize;
                BEDparS.treatmentDays = get tx sched for current scheme
                %Calculate tumor BED at 1st violation
                BEDatLimit1 = calc_BED(BEDparS);
                prevIdxV = violV==xScaleV(firstScaleIdxV);
            end
            %Get NTCP, d-v metrics at 1st violation
            valM = [scaledCPm;cgValM];
            val1V = valM(:,firstScaleIdxV);
        end

        %Record details of 2nd limit violated
        %Identify 2nd violation
        viol2V = violV(~prevIdxV);
        vOrderV = vOrderV(~prevIdxV);

        if isinf(viol2V(1))
            scaleAtLimit2 = -1;
            dLimit2 = -1;
            val2V = repmat(-1,size(valM,1),1);
            secondViol = -1;
            BEDatLimit2 = -1;
        else
            if scaleMode==1
                scaleAtLimit2 = viol2V(1);
                %For prescription lt
                if scaleAtLimit2==1
                    tol = mean(diff(xScaleV))/2;
                    secondScaleIdxV = abs(xScaleV-scaleAtLimit2)<=tol;
                else
                    secondScaleIdxV = xScaleV == scaleAtLimit2;
                end
                %--end prescription lt---
                frxSizeAtLimit =  scaleAtLimit2*protFrxSize;
                dLimit2 = frxSizeAtLimit*numFrxProtocol;
                secondViol = strjoin(violC(vOrderV(viol2V==scaleAtLimit2)),',');
                % BED parameter  dictionary
                BEDparS.numFractions.val = numFrxProtocol;
                BEDparS.frxSize.val = frxSizeAtLimit;
                BEDparS.treatmentDays = get tx sched for current scheme
                %Calculate tumor BED at 2nd violation
                BEDatLimit1 = calc_BED(BEDparS);
            else
                secondScaleIdxV = xScaleV == viol2V(1);
                scaleAtLimit2 = rangeV(secondScaleIdxV);
                numFrxAtLimit2 = numFrxProtocol+scaleAtLimit2;
                dLimit2 = protFrxSize*(numFrxAtLimit2);
                secondViol = strjoin(violC(vOrderV(viol2V==xScaleV(secondScaleIdxV))),',');
                % BED parameter  dictionary
                BEDparS.numFractions.val = numFrxAtLimit2;
                BEDparS.frxSize.val = protFrxSize;
                BEDparS.treatmentDays = get tx sched for current scheme
                %Calculate tumor BED at 2nd violation
                BEDatLimit1 = calc_BED(BEDparS);
            end
            %Get NTCP values at 2nd violation
            valM = [scaledCPm;cgValM];
            val2V = valM(:,secondScaleIdxV);
        end

        %Restore original dose array
        planC{indexS.dose}(plnNum).doseArray = dA;

        %Write output to spreadsheet
        try

            % Incl dose
            colC = {['Pt ',num2str(ptNum),' prot ',num2str(p)],...
                BEDatLimit1,scaleAtLimit1,dLimit1,val1V(1)*100,val1V(3),val1V(2)*100,...
                val1V(5)*100,val1V(6)*100,val1V(7),val1V(8),val1V(9),val1V(10),...
                val1V(11)*100,val1V(12)*100,val1V(13),val1V(14),val1V(15),-val1V(16),...
                firstViol,BEDatLimit2,scaleAtLimit2,...
                dLimit2,val2V(1)*100,val2V(3),val2V(2)*100,val2V(5)*100,val2V(6)*100,...
                val2V(7),val2V(8),val2V(9),val2V(10),val2V(11)*100,val2V(12)*100,...
                val2V(13),val2V(14),val2V(14),-val2V(16),secondViol};

            for k = 1:numel(colC)
                if isnan(colC{k})
                    colC{k} = 'N/A';
                end
            end


            xlRange = ['A',num2str(lineNum),':AM',num2str(lineNum)];

            %Rm dose
            %             colC = {['Pt ',num2str(ptNum),' prot ',num2str(p)],...
            %                 BEDatLimit1,scaleAtLimit1,dLimit1,val1V(1)*100,...
            %                 val1V(3),val1V(2)*100,val1V(4)*100,val1V(5),firstViol,...
            %                 BEDatLimit2,scaleAtLimit2,dLimit2,val2V(1)*100,...
            %                 val2V(3),val2V(2)*100,val2V(4)*100,val2V(5),secondViol};
            %             xlRange = ['A',num2str(lineNum),':S',num2str(lineNum)];
            sheet = 1;
            xlswrite(outFile,colC,sheet,xlRange) ;
        catch err
            errMsg = err.message;
            fprintf(fid,'\nPt %d: Failed with error %s',ptNum,errMsg);
        end

    end
    fprintf('\nComplete\n');
end


%% Identify best protocol (highest BED)
BEDoutV = xlsread(outFile,['B5:B',num2str(lineNum)]);
outV = nan(numel(anonIdC)*numel(protocolListC),1);

start = 0;
for k = 1:numel(anonIdC)
    compareV = BEDoutV(start+1:start+numel(protocolListC));
    idxV = find(compareV==max(compareV));
    outV(start+1:start+numel(protocolListC)) = 0;
    outV(start+idxV) = 1;
    start = start + numel(protocolListC);
end

%Write to spreadsheet
xlswrite(outFile,outV,sheet,['AN5:AN',num2str(lineNum)]) ; %Incl dose
%xlswrite(outFile,outV,sheet,['T5:T',num2str(lineNum)]) ;  %Rm dose


end