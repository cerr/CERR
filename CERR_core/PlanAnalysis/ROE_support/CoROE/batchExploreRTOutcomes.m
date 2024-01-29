function batchExploreRTOutcomes(cerrPath,varInFile,scaleMode,outFile,optS)
% Batch script to determine optimal fraction size or number across 
% different fractionation schemes.
% For each schedule, either the (1) fraction size or (2) fraction number
% is optimized over scale factors in [0.5,1]. The optimal schedule
% (producing max TCP without exceeding clinical constraints) and associated 
% values of dose-volume and NTCP criteria are returned. 
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

%% Set default parameters 
% Define DVH bin width, fraction size range etc
binWidth = .05;
plnNum = 1; %Uses 1st available dose plan by default
numHeaderLines = 4; %For spreadsheet o/p

%% Get list of input CERR files
dirS = dir([cerrPath,filesep,'*.mat']);
ptListC = {dirS.name};
anonIdC = cell(1,length(ptListC));
for i = 1:length(anonIdC)
    anonIdC{i} = sprintf('Pt %.2d',i);
end

%% Check for valid ouput file
if exist(outFile,'file')
    prompt = sprintf(['File %s exists. Enter ''y'' to overwrite and ',...
            'continue.\n'],outFile);
    userSel = input(prompt,"s");
    if ~strcmpi(userSel,'y')
        return
    end
    delete(outFile);
end

%% Get list of fractionation schemes
protocolPath = optS.protocolPath;
modelPath = optS.modelPath;
criteriaPath = optS.criteriaPath;
pDirS = dir(protocolPath);
pDirS(1:2) = [];
protocolListC = {pDirS.name};

%% Read model parameters & clinical constraints
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
    modFilesC = {};
    for m = 1:numModels
        protocolS(p).protocol = protocolInfoS.name;
        modelFPath = fullfile(modelPath,protocolInfoS.models.(modelListC{m}).modelFile);
        protocolS(p).model{m} = jsondecode(fileread(modelFPath));
        modFilesC = [modFilesC,modelFPath];
        modelName = protocolS(p).model{m}.name;
    end
    protocolS(p).modelFiles = modFilesC;
    % Store models & criteria  for each protocol
    critFile = fullfile(criteriaPath,protocolInfoS.criteriaFile);
    critS = jsondecode(fileread(critFile));
    protocolS(p).numFractions = protocolInfoS.numFractions;
    protocolS(p).totalDose = protocolInfoS.totalDose;
    protocolS(p).criteria = critS;
end
maxDeltaFrx = round(max([protocolS.numFractions])/2); %For mode-0

%% Get patient-specific clinical factors & prescriptions from input spreadsheet
if ~isempty(varInFile)
    if ~exist(varInFile,'file')
        error('Input file %s does not exist',varInFile)
    else
        [~,~,rawData] = xlsread(varInFile);
        fNameC = rawData(2:end,1);
        fNameC = cellfun(@num2str,fNameC,'un',0);
        prescribedDoseC = rawData(2:end,2);
        prescribedDoseV = [prescribedDoseC{:}];
    end
end

%% Create error log 
basePath = fileparts(protocolPath);
fid = fopen(fullfile(basePath,'Log.txt'),'w');


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
        matchIdxV = strcmp(anonIdC{ptNum},fNameC);
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

        % Extract available models
        modelC = protocolS(p).model;
        modelFileC = protocolS(p).modelFiles;
        modTypesC = cellfun(@(x)x.type,modelC,'un',0);
        ntcpModIdxV = strcmpi(modTypesC,'ntcp');
        numModels = sum(ntcpModIdxV);
        NTCPmodelC = modelC(ntcpModIdxV);
        %numModels = numel(modelC);
        
        mCount = 0;
        %scaledCPm = nan(numModels,numel(xScaleV));
        scaledCPm = [];
        firstNTCPViolV = [];
        violC = {};

        %% Loop over all available models
        for m = 1:numModels

            %Create parameter dictionary
            %paramS = [modelC{m}.parameters];
            paramS = [NTCPmodelC{m}.parameters];
            %strC = modelC{m}.parameters.structures;
            strC = NTCPmodelC{m}.parameters.structures;
            if isstruct(strC)
                %strC = fieldnames(modelC{m}.parameters.structures);
                strC = fieldnames(NTCPmodelC{m}.parameters.structures);
            end
            if iscell(strC)
                strName = strC{1};
            else
                strName = strC;
            end

            structNumV = find(strcmpi(strC,availableStructsC));

            % For NTCP models,record associated structure, model config file,
            % and clinical constraints
            %if strcmpi(modelC{m}.type,'ntcp')
            if strcmpi(NTCPmodelC{m}.type,'ntcp')

                % Associated normal structure
                if isstruct(NTCPmodelC{m}.parameters.structures)
                    modelStr = fieldnames(NTCPmodelC{m}.parameters.structures);
                    modelStr = modelStr{1};
                else
                    modelStr = NTCPmodelC{m}.parameters.structures;
                end

                %Model config file
                [~,modelFile,ext] = fileparts(modelFileC{m});
                %limIdx = contains(fieldnames(critS.structures),...
                %    modelStr);

                % NTCP constraints
                limitV = extractNTCPconstraints(critS,modelStr,[modelFile,ext]);
                if isempty(limitV)
                    NTCPmodelC{m}.limit = [];
                    limitV = inf;
                end

            end

            %For available structures
            if ~isempty(structNumV)

                %% Extract/update model parameter dictionary
                paramS.structNum = structNumV;
                %Store frx size, num frx, alpha/beta
                paramS.numFractions.val = numFrxProtocol;
                paramS.frxSize.val = protFrxSize;
                if isfield(modelC{m},'abRatio')
                    abRatio = NTCPmodelC{m}.abRatio;
                    paramS.abratio.val = abRatio;
                end
                %Store required clinical factors
                paramS = addClinicalFactors(paramS,patientID,rawData);

                %% Get DVH
                if ~isempty(structNumV)
                    doseBinsC = cell(1,numel(structNumV));
                    volHistC = cell(1,numel(structNumV));
                    for nStr = 1:numel(structNumV)
                        [dosesV,volsV] = getDVH(structNumV(nStr),plnNum,planC);
                        [doseBinsC{nStr},volHistC{nStr}] = doseHist(dosesV,volsV,binWidth);
                    end
                    NTCPmodelC{m}.dv = {doseBinsC,volHistC};
                end

                %% Record violations
                %if strcmpi(modelC{m}.type,'ntcp')

                start = mCount+1;
                fin = start+numel(limitV)-1;

                if scaleMode == 1
                    [firstNTCPViolV(start:fin),scaledCPv] = ...
                        calc_NTCPLimit(paramS,NTCPmodelC{m},...
                        scaleMode);
                else
                    [firstNTCPViolV(start:fin) ,scaledCPv] =...
                        calc_NTCPLimit(paramS,NTCPmodelC{m},...
                        scaleMode,maxDeltaFrx);
                end
                scaledCPm(start:fin,:) = repmat(scaledCPv,[fin-start+1,1]);

                %Record limits
                if fin>start
                    violC{start} = [strName, ': ',NTCPmodelC{m}.name,' NTCP guideline'];
                    violC{fin} = [strName,': ', NTCPmodelC{m}.name,' NTCP limit'];
                else
                    violC{start} = [strName,': ', NTCPmodelC{m}.name,' NTCP limit'];
                end

                %else
                %Skip
                %    start = mCount;%+1;
                %    fin = start;%+numel(limitV)-1;
                %    limitV = []; %added
                %    %scaledCPm(m,:) = nan; %default, not reqd
                %end
                % Handle limits on missing structures
            else
                %limitV = []; %added
                start = mCount+1;
                if ~isempty(limitV)
                    fin = start+numel(limitV)-1;
                else
                    fin = start;
                end
                %scaleAtLim = nan;
                %scaledCPm(m,:) = nan; %default, not reqd
                firstNTCPViolV(start:fin) = nan; %scaleAtLim
                if fin>start
                    violC{start} = [strName, ': ',NTCPmodelC{m}.name,' NTCP guideline'];
                    violC{fin} = [strName,': ', NTCPmodelC{m}.name,' NTCP limit'];
                else
                    violC{start} = [strName,': ', NTCPmodelC{m}.name,' NTCP limit'];
                end
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
                        limitV = critnS.limit; %assumed non-empty
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
                            start = cCount + gCount + 1;
                            fin = cCount + gCount + numel(limitV); %assumed non-empty
                            firstCGViolV(start:fin) = nan;
                            nRow = fin-start+1;
                            cgValM(start:fin,:) = nan(nRow,numel(xScaleV));
                        end
                        %Record constraint name
                        violC([start:fin] + mCount) = {[structC{s},': ',criteriaC{n},...
                            ' limit']};
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
                %Loop over guidelines
                for n = 1:length(guidesC)
                    if ~contains(lower(guidesC{n}),'ntcp')
                        %Idenitfy dose/volume limits
                        guidnS = strGuideS.(guidesC{n});
                        guidnS.isGuide = 1;
                        limitV = guidnS.limit; %assumed non-empty
                        start = cCount + gCount+1;
                        %fin = cCount + gCount + numel(limitV); 
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
                                    nRow = fin-start+1;
                                    cgValM(start:fin,:) = nan(nRow,numel(xScaleV));
                                    cgValM(start:fin,rxIdx)= 1;
                                end
                                addStr = 'limit';
                            else
                                addStr = 'guideline';
                            end
                            violC([start:fin] + mCount) = {[structC{s},': ',guidesC{n},...
                                ' ',addStr]};
                            %gCount = gCount + numel(limitV);
                        else
                            start = cCount + gCount + 1;
                            fin = start;
                            firstCGViolV(start:fin) = nan;
                            cgValM(start:fin,:) = nan;
                            violC([start:fin] + mCount) = {[structC{s},': ',guidesC{n},...
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
        BEDIdx = ismember(modTypesC,'BED');
        TCPIdx = ismember(modTypesC,'TCP');
        BEDparS = [];
        TCPparS = [];
        if ~isempty(BEDIdx)
            BEDparS = modelC{BEDIdx}.parameters;
            BEDparS.abRatio.val =  modelC{BEDIdx}.abRatio;
            BEDparS.function =  modelC{BEDIdx}.function;
        end
        if ~isempty(TCPIdx)
            TCPparS = modelC{TCPIdx}.parameters;
            TCPparS.abRatio.val = modelC{TCPIdx}.abRatio;
            TCPparS.function = modelC{TCPIdx}.function;
        end

        
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
                 
                % Parameters for tumor BED calc. at limit
                if ~isempty(BEDIdx)
                    BEDparS.numFractions.val = numFrxProtocol;
                    BEDparS.frxSize.val = frxSizeAtLimit;
                    if isempty(BEDparS.treatmentDays.val)
                        schedule = 'weekdays';
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    elseif ~isnumeric([BEDparS.treatmentDays.val])
                        schedule = BEDparS.treatmentDays.params;
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    end
                end
                % Parameters for TCP calc. at limit
                if ~isempty(TCPIdx)
                    TCPparS.numFractions.val = numFrxProtocol;
                    TCPparS.frxSize.val = frxSizeAtLimit;
                    treatmentDays = TCPparS.treatmentSchedule.val;
                    if ~isnumeric(treatmentDays)
                        treatmentDays = str2num(treatmentDays);
                    end
                    if isempty(treatmentDays)
                        schedule = 'weekdays';
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        TCPparS.treatmentSchedule.val = treatmentDays;
                    elseif ~isnumeric(treatmentDays)
                        schedule = TCPparS.treatmentSchedule.params;
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        TCPparS.treatmentSchedule.val = treatmentDays;
                    end
                end
            else
                firstScaleIdxV = xScaleV == violV(1);
                scaleAtLimit1 = rangeV(firstScaleIdxV);
                numFrxAtLimit1 = numFrxProtocol+scaleAtLimit1;
                dLimit1 = protFrxSize*(numFrxAtLimit1);
                firstViol = strjoin(violC(vOrderV(violV==xScaleV(firstScaleIdxV))),',');
                % Parameters for BED calc. at limit
                if ~isempty(BEDIdx)
                    BEDparS.numFractions.val = numFrxAtLimit1;
                    BEDparS.frxSize.val = protFrxSize;
                    if isempty(BEDparS.treatmentDays.val)
                        schedule = 'weekdays';
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit1,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    elseif ~isnumeric([BEDparS.treatmentDays.val])
                        schedule = BEDparS.treatmentDays.params;
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit1,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    end
                end
                % Parameters for TCP calc. at limit
                if ~isempty(TCPIdx)
                    TCPparS.numFractions.val = numFrxAtLimit1;
                    TCPparS.frxSize.val = protFrxSize;
                    if isfield(TCPparS,'treatmentSchedule') ||...
                        isempty(TCPparS.treatmentSchedule.val)
                        schedule = 'weekday';
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit1,schedule);
                        TCPparS.treatmentSchedule.val = treatmentDays;
                    elseif ~isnumeric([TCPparS.treatmentDays.val])
                        schedule = TCPparS.treatmentDays.params;
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit1,schedule);
                        TCPparS.treatmentSchedule.val = treatmentDays;
                    end
                end
                prevIdxV = violV==xScaleV(firstScaleIdxV);
            end

            [BEDatLimit1,TCPatLimit1] = calc_TCPBEDLimit(BEDparS,TCPparS,...
                plnNum,binWidth,planC);

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
                if ~isempty(BEDIdx)
                    BEDparS.numFractions.val = numFrxProtocol;  
                    BEDparS.frxSize.val = frxSizeAtLimit;
                    if isempty(BEDparS.treatmentDays.val)
                        schedule = 'weekdays';
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    elseif ~isnumeric([BEDparS.treatmentDays.val])
                        schedule = BEDparS.treatmentDays.params;
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    end
                end
                % Parameters for TCP calc. at limit
                if ~isempty(TCPIdx)
                    TCPparS.numFractions.val = numFrxProtocol;
                    TCPparS.frxSize.val = frxSizeAtLimit;
                    treatmentDays = TCPparS.treatmentSchedule.val;
                    if ~isnumeric(treatmentDays)
                        treatmentDays = str2num(treatmentDays);
                    end
                    if isempty(treatmentDays)
                        schedule = 'weekdays';
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        TCPparS.treatmentSchedule.val = treatmentDays;
                    elseif ~isnumeric(treatmentDays)
                        schedule = TCPparS.treatmentSchedule.params;
                        treatmentDays = getTreatmentSchedule(numFrxProtocol,schedule);
                        TCPparS.treatmentDays.val = treatmentDays;
                    end
                end
            else
                secondScaleIdxV = xScaleV == viol2V(1);
                scaleAtLimit2 = rangeV(secondScaleIdxV);
                numFrxAtLimit2 = numFrxProtocol+scaleAtLimit2;
                dLimit2 = protFrxSize*(numFrxAtLimit2);
                secondViol = strjoin(violC(vOrderV(viol2V==xScaleV(secondScaleIdxV))),',');
                if ~isempty(BEDIdx)
                    BEDparS.numFractions.val = numFrxAtLimit2;
                    BEDparS.frxSize.val = protFrxSize;
                    if isempty(BEDparS.treatmentDays.val)
                        schedule = 'weekdays';
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit2,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    elseif ~isnumeric([BEDparS.treatmentDays.val])
                        schedule = BEDparS.treatmentDays.params;
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit2,schedule);
                        BEDparS.treatmentDays.val = treatmentDays;
                    end
                end
                % Parameters for TCP calc. at limit
                if ~isempty(TCPIdx)
                    TCPparS.numFractions.val = numFrxAtLimit2;
                    TCPparS.frxSize.val = protFrxSize;
                    if ~isfield(TCPparS,'treatmentSchedule') || ...
                       isempty(TCPparS.treatmentSchedule.val)
                        schedule = 'weekdays';
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit2,schedule);
                        TCPparS.treatmentSchedule.val = treatmentDays;
                    elseif ~isnumeric([TCPparS.treatmentSchedule.val])
                        schedule = TCPparS.treatmentSchedule.params;
                        treatmentDays = getTreatmentSchedule(numFrxAtLimit2,schedule);
                        TCPparS.treatmentSchedule.val = treatmentDays;
                    end
                end
            end
            [BEDatLimit2,TCPatLimit2] = calc_TCPBEDLimit(BEDparS,TCPparS,...
                plnNum,binWidth,planC);

            %Get NTCP values at 2nd violation
            valM = [scaledCPm;cgValM];
            val2V = valM(:,secondScaleIdxV);
        end

        % Restore original dose array
        planC{indexS.dose}(plnNum).doseArray = dA;

        %% Write output to spreadsheet
        try
            errFlag = false;

            sheet = 1;
            headLine1C = {'Patient','Candidate protocol','1st limit'};
            headLine2FixedC = {'BED tumor (Gy)','TCP','Scale','Rx (Gy)'};
            headLine2Len = length(headLine2FixedC);
            BED1col = 3;
            TCP1col = 4;
            headCol = 3;


            [strPrintC,constraintC]  = strtok(violC,':'); 
            %uqStrPrintC = unique(strPrintC,'stable');
            constraintC  = strrep(strrep(strtok(constraintC,':'),...
                'guideline',''),'limit',''); 
            [violUqC,uqStrIdx,~] = unique(strcat(strPrintC,{' '},...
                constraintC),'stable');
            strPrintC = strPrintC(uqStrIdx);
            val1V = val1V(uqStrIdx);
            val2V = val2V(uqStrIdx);

            % Column headers
            if ptNum==1 && p ==1
                xlswrite(outFile,headLine1C,sheet,'A1:C1');

                %Compile list of constraining strutctures
                %headLine2C = [headLine2FixedC,uqStrPrintC];
                headLineRep2C = [headLine2FixedC,strPrintC];
                headLineRep2C{end+1} = 'Violated constraint(s)'; %'Limit'
                [uqHeadLine2C,pos,posIn] = unique(headLineRep2C,'stable');
                currCol = headCol;
                for c = 1:length(uqHeadLine2C)
                    if c==1
                        spaces = 0;
                    else
                        spaces = sum(posIn==c-1);
                    end
                    outColV(c) = currCol+spaces;
                    outColChar = getXLScol(outColV(c));
                    xlswrite(outFile,uqHeadLine2C(c),sheet,[outColChar,'2']);
                    currCol = outColV(c);
                end
            end

            %% First violation
            % List scale factor, BED/TCP 
            %ptID = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.PatientID;
            ptInfoC = {anonIdC{ptNum},protocolS(p).protocol,...
                BEDatLimit1,TCPatLimit1,scaleAtLimit1,dLimit1};
            info1Len = length(ptInfoC);
            xlswrite(outFile,ptInfoC,sheet,...
                ['A',num2str(lineNum),':',getXLScol(info1Len)...
                ,num2str(lineNum)]);

            %List normal structure constraints
            colSt = headLine2Len;
            violPosV = outColV(info1Len-1:end-1) - 4;
            strUqC = uqHeadLine2C(info1Len-1:end-1);
            if ptNum==1 && p==1
                %outColEnd = writeConstraints(strUqC,violUqC,val1V,violPosV,...
                %    colSt,lineNum,outFile,true);
                outColEnd = writeConstraints(strPrintC,violUqC,val1V,violPosV,...
                    colSt,lineNum,outFile,true);
            else
                %outColEnd = writeConstraints(strUqC,violUqC,val1V,violPosV,...
                %    colSt,lineNum,outFile,false);
                outColEnd = writeConstraints(strPrintC,violUqC,val1V,violPosV,...
                    colSt,lineNum,outFile,false);
            end
            xlswrite(outFile,{firstViol},sheet,...
                [getXLScol(outColEnd+1),num2str(lineNum)]);
            lim1EndCol = outColEnd+1;

            %% 2nd violation
            % List constraining structures
            colSt = lim1EndCol+headLine2Len;
            if ptNum == 1 && p ==1
                lim2StartCol = lim1EndCol+1;
                lim2StartChar = getXLScol(lim2StartCol);
                xlswrite(outFile,{'2nd limit'},sheet,[lim2StartChar,'1']);
                for c = 1:length(outColV)
                    col = lim1EndCol+outColV(c)-2;
                    colChar = getXLScol(col);
                    xlswrite(outFile,uqHeadLine2C(c),sheet,[colChar,'2']);
                end

                %List constraints
                outColEnd = writeConstraints(strUqC,violUqC,val2V,violPosV-2,...
                    colSt,lineNum,outFile,true);
            end
            ptInfoC = {BEDatLimit2,TCPatLimit2,scaleAtLimit2,dLimit2};
            info2Len = length(ptInfoC);
            xlswrite(outFile,ptInfoC,sheet,...
                [lim2StartChar,num2str(lineNum),':',...
                getXLScol(lim2StartCol+info2Len-1),num2str(lineNum)]);
            outColEnd = writeConstraints(strUqC,violUqC,val2V,violPosV-2,...
                colSt,lineNum,outFile,false);
            xlswrite(outFile,{secondViol},sheet,...
                [getXLScol(outColEnd+1),num2str(lineNum)])

            %Indicate best protocol
            protCol = getXLScol(outColEnd + 2);
            xlswrite(outFile,{'Selected protocol'},sheet,[protCol,'2']);
                
        catch err
            % Log errors 
            errMsg = err.message;
            fprintf(fid,'\nPt %d: Failed with error %s',ptNum,errMsg);
        end

    end
    fprintf('\nComplete\n');
end


%% Identify best protocol (highest TCP)
if ~errFlag
    if ~isempty(TCPIdx)
    TCPoutV = xlsread(outFile,[getXLScol(TCP1col),'5:',getXLScol(TCP1col),...
        num2str(lineNum)]);
    outV = nan(numel(anonIdC)*numel(protocolListC),1);
    start = 0;
    for k = 1:numel(anonIdC)
        compareV = TCPoutV(start+1:start+numel(protocolListC));
        idxV = find(compareV==max(compareV));
        outV(start+1:start+numel(protocolListC)) = 0;
        outV(start+idxV) = 1;
        start = start + numel(protocolListC);
    end

    %Write to spreadsheet
    xlswrite(outFile,outV,sheet,[protCol,'5:',protCol,...
        num2str(lineNum)]) ; %Incl dose
    else
        BEDoutV = xlsread(outFile,[getXLScol(BED1col),'5:',getXLScol(BED1col),...
            num2str(lineNum)]);
        outV = nan(numel(anonIdC)*numel(protocolListC),1);
        start = 0;
        for k = 1:numel(anonIdC)
            compareV = BEDoutV(start+1:start+numel(protocolListC));
            idxV = find(compareV==max(compareV));
            outV(start+1:start+numel(protocolListC)) = 0;
            outV(start+idxV) = 1;
            start = start + numel(protocolListC);
        end
    end
end

fclose(fid);

%% --------------------- Supporting functions -------------------------

% Convert col no. to alphabet
    function outC = getXLScol(colV)
        lastChar = 26;
        outC = cell(1,length(colV));
        indV = colV > lastChar;
        if any(indV)
            colIdxV = colV(indV);
            quo = colIdxV./lastChar;
            setN = floor(quo);
            if setN==quo
                c1 = char(setN-1 + 64);
                c2 = 'Z';
            else
                c1 = char(setN + 64);
                c2 = mod(colIdxV,lastChar);
                c2 = char(c2 + 64);
            end
            cout = string([c1,c2]);
            outC(indV) = cellstr(cout).';
        end
        cout = char(colV(~indV) + 64);
        outC(~indV) = cellstr(cout);
        if length(outC)==1
            outC = outC{1};
        end
    end

% Write constraints to spreadsheet

    function outColEnd = writeConstraints(strUqC,violC,valV,violPosV,colSt,...
            lineNum,outFile,writeHeaderFlag)
        
        %Replace NaNs with N/A
        valC = num2cell(valV).';
        nanIdxV = isnan(valV);
        valC(nanIdxV) = {'N/A'};
        
        sheetNum = 1;
        for v = 1:length(violPosV)
            strt = violPosV(v);
            strIdxV = contains(violC,strUqC{v});
            if v==length(violPosV)
                stop = strt+ sum(strIdxV)-1;
            else
                stop = violPosV(v+1)-1;
            end
            strConstrC = violC(strIdxV);
            printViolC = extractAfter(strConstrC,strUqC{v});
            outColStart = colSt+strt;
            outColEnd = colSt+stop;
            if writeHeaderFlag
                xlswrite(outFile,printViolC,[getXLScol(outColStart),...
                    '3:',getXLScol(outColEnd),'3']);
            end
            outLtC = valC(strIdxV);
            xlswrite(outFile,outLtC,sheetNum,[getXLScol(outColStart),...
                num2str(lineNum),':',getXLScol(outColEnd),num2str(lineNum)]);
        end
        
    end


end